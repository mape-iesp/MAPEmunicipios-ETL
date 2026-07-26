# A interface de consumo -----------------------------------------------------
#
# As funções aqui são a resposta ao objetivo (b) do projeto: acesso modular às
# dimensões. Elas são a mesma superfície que o pacote MAPEmunicipios expõe para
# fora, com uma diferença de origem — aqui as tabelas vêm do disco do
# repositório, e lá vêm de um release do GitHub.
#
# A diferença entre estas funções e mape_ler_tabela()/mape_join(), que já
# existiam, é o público. As de baixo nível assumem que quem chama conhece o
# slug exato e a camada; estas aceitam "meio ambiente" e descobrem o resto.

#' Lê uma tabela publicada, pelo nome que a pessoa lembra
#'
#' A função de baixo nível `mape_ler_tabela()` exige o slug exato
#' (`"03_meio_ambiente"`) e a camada certa. Isso é razoável dentro do pipeline e
#' hostil fora dele: ninguém decora o número da dimensão. Aqui `"meio ambiente"`,
#' `"meio_ambiente"`, `"03_meio_ambiente"` e `"Meio Ambiente"` levam ao mesmo
#' lugar, e um nome ambíguo devolve a lista de candidatos em vez de escolher um.
#'
#' @param tabela Nome ou slug. Dimensão (`"saude"`) ou fonte
#'   (`"educacao/ideb"`).
#' @param painel Se TRUE e a tabela for uma fonte com granularidade menor que
#'   município-ano, expande para o painel marcando o que foi imputado. Ver
#'   `mape_expandir_painel()`.
#' @param territorio Se TRUE, junta o bloco territorial de `00_diretorios`
#'   (nome do município, UF, região). É o que a maioria das pessoas quer e
#'   nenhuma dimensão carrega, por decisão de propriedade única.
#' @param anos Vetor ou intervalo de anos para filtrar. NULL traz tudo.
#' @param municipios Vetor de `id_municipio` para filtrar. NULL traz todos.
#' @return Data frame.
#' @examples
#' \dontrun{
#' mape_ler("saude")
#' mape_ler("educacao/ideb", territorio = TRUE, anos = 2019:2023)
#' }
mape_ler <- function(tabela, painel = FALSE, territorio = FALSE,
                     anos = NULL, municipios = NULL) {
  slug <- mape_resolver_tabela(tabela)
  camada <- if (grepl("/", slug)) "fonte" else "dimensao"
  x <- mape_ler_tabela(slug, camada = camada)

  if (painel) {
    tabs <- mape_dicionario("tabelas")
    regra <- tabs$regra_preenchimento_temporal[tabs$slug_tabela == slug]
    regra <- if (length(regra)) regra[1] else "nenhuma"
    if (!is.na(regra) && regra != "nenhuma" && "ano" %in% names(x)) {
      x$ano_ref <- x$ano
      metodo <- if (regra == "carry_forward") "carry_forward" else "replicar"
      x <- mape_expandir_painel(x, de = "ano_ref", metodo = metodo)
    } else {
      message("[", slug, "] a tabela já é município x ano; nada a expandir.")
    }
  }

  if (!is.null(anos) && "ano" %in% names(x)) {
    x <- x[x$ano %in% as.integer(anos), , drop = FALSE]
  }
  if (!is.null(municipios)) {
    x <- x[x$id_municipio %in% mape_como_codigo(municipios, avisar = FALSE), , drop = FALSE]
  }

  if (territorio) {
    dir_mun <- mape_ler_tabela("00_diretorios/municipios")
    cols <- intersect(c("id_municipio", "nome_municipio", "sigla_uf", "nome_uf",
                        "nome_regiao", "nome_mesorregiao", "nome_microrregiao"),
                      names(dir_mun))
    x <- mape_join(x, dir_mun[, cols, drop = FALSE], by = "id_municipio",
                   tipo = "left", relationship = "many-to-one",
                   nome = paste0(slug, " + territorio"))
    x <- x[, c(intersect(cols, names(x)),
               setdiff(names(x), cols)), drop = FALSE]
  }

  rownames(x) <- NULL
  x
}

#' Resolve um nome livre para o slug de uma tabela publicada
#'
#' @param tabela Nome ou slug.
#' @return O slug exato.
mape_resolver_tabela <- function(tabela) {
  stopifnot(is.character(tabela), length(tabela) == 1)
  disponiveis <- mape_tabelas_publicadas()$slug

  if (tabela %in% disponiveis) return(tabela)

  # Normaliza: minúsculo, sem acento, espaço e hífen viram sublinhado.
  #
  # A transliteração é feita por chartr e não por iconv(to = "ASCII//TRANSLIT"),
  # porque o resultado do iconv depende da implementação de libiconv do sistema:
  # no macOS "ç" vira "c" precedido de til em vez de "c", e "Educação" deixa de
  # casar com "educacao". Um mapa explícito dá o mesmo resultado em toda parte.
  normalizar <- function(s) {
    de <- "áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ"
    para <- "aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC"
    s <- tolower(chartr(de, para, s))
    s <- gsub("[^a-z0-9/]+", "_", s)
    gsub("^_+|_+$", "", s)
  }
  alvo <- normalizar(tabela)
  # O prefixo numérico é opcional na busca, mas obrigatório no slug.
  sem_num <- function(s) gsub("(^|/)[0-9]{2}_", "\\1", s)

  candidatos <- disponiveis[
    normalizar(disponiveis) == alvo |
      sem_num(normalizar(disponiveis)) == alvo |
      sem_num(normalizar(disponiveis)) == sem_num(alvo)
  ]
  if (length(candidatos) == 1) return(candidatos)

  if (!length(candidatos)) {
    parciais <- disponiveis[grepl(alvo, sem_num(normalizar(disponiveis)), fixed = TRUE)]
    if (length(parciais) == 1) return(parciais)
    if (length(parciais)) candidatos <- parciais
  }

  stop("Tabela '", tabela, "' ",
       if (length(candidatos)) "é ambígua." else "não encontrada.", "\n",
       if (length(candidatos))
         paste0("Candidatas: ", paste(candidatos, collapse = ", "), "\n")
       else "",
       "Use mape_tabelas_publicadas() para ver as ", length(disponiveis),
       " tabelas disponíveis.", call. = FALSE)
}

#' Tabelas publicadas em disco
#'
#' @param camada "dimensao", "fonte" ou NULL para as duas.
#' @return Data frame com slug, camada, linhas, colunas e MB.
mape_tabelas_publicadas <- function(camada = NULL) {
  linhas <- list()
  for (cm in c("dimensao", "fonte")) {
    if (!is.null(camada) && !cm %in% camada) next
    raiz <- mape_caminho("dados", cm)
    if (!dir.exists(raiz)) next
    arqs <- list.files(raiz, pattern = "[.]parquet$", recursive = TRUE,
                       full.names = TRUE)
    for (a in arqs) {
      slug <- sub("[.]parquet$", "", sub(paste0("^", raiz, "/"), "", a))
      linhas[[length(linhas) + 1]] <- data.frame(
        slug = slug, camada = cm, mb = round(mape_mb(a), 2),
        stringsAsFactors = FALSE)
    }
  }
  res <- if (length(linhas)) do.call(rbind, linhas) else
    data.frame(slug = character(), camada = character(), mb = numeric())
  res[order(res$slug), ]
}

#' Junta tabelas do MAPEmunicipios com as cardinalidades conferidas
#'
#' Esta é a função que precisa ser cuidadosa, porque é onde as granularidades
#' incompatíveis se encontram. Ela **recusa** três combinações que produziriam
#' resultado enganoso, em vez de produzi-lo em silêncio:
#'
#' Uma tabela sem `ano` (a dimensão histórica) juntada por município replicaria
#' os valores em todos os anos. A função exige `permitir_replicacao = TRUE`
#' para fazer isso, e avisa quantas vezes cada valor será repetido.
#'
#' Uma tabela com chave duplicada multiplicaria linhas. A função para e nomeia
#' a tabela responsável — é o que as Finanças e os Dados Históricos fazem hoje,
#' por defeito herdado da fonte.
#'
#' Uma tabela de cobertura baixa geraria uma coluna quase toda vazia. A função
#' avisa com o número antes de juntar; a Corrupção cobre 0,8% do painel.
#'
#' @param tabelas Vetor de nomes ou lista de data frames nomeada.
#' @param by Chaves da junção.
#' @param tipo "left", "full" ou "inner".
#' @param permitir_replicacao Autoriza juntar tabela sem `ano` por município.
#' @param territorio Se TRUE, começa pelo bloco territorial do diretório.
#' @return Data frame, com o atributo `mape_relatorio` descrevendo cada junção.
#' @examples
#' \dontrun{
#' mape_juntar(c("saude", "populacao"), territorio = TRUE)
#' }
mape_juntar <- function(tabelas, by = c("id_municipio", "ano"), tipo = "full",
                        permitir_replicacao = FALSE, territorio = FALSE) {
  if (is.character(tabelas)) {
    slugs <- vapply(tabelas, mape_resolver_tabela, character(1), USE.NAMES = FALSE)
    partes <- lapply(slugs, function(s) {
      mape_ler_tabela(s, camada = if (grepl("/", s)) "fonte" else "dimensao")
    })
    names(partes) <- slugs
  } else {
    partes <- tabelas
    if (is.null(names(partes))) names(partes) <- paste0("tabela_", seq_along(partes))
  }
  if (length(partes) < 1) stop("Nada para juntar.", call. = FALSE)

  relatorio <- list()
  n_mun_total <- length(unique(mape_ler_tabela("00_diretorios/municipios")$id_municipio))

  # Diagnóstico ANTES de juntar. Descobrir que uma chave é duplicada depois de
  # a junção ter multiplicado as linhas é descobrir tarde demais: o legado faz
  # isso e apaga a evidência com um distinct() cego no fim.
  bloqueios <- character()
  for (nm in names(partes)) {
    p <- partes[[nm]]
    chaves_p <- intersect(by, names(p))
    if (!length(chaves_p)) {
      bloqueios <- c(bloqueios, sprintf(
        "%s: não tem nenhuma das chaves pedidas (%s)", nm, paste(by, collapse = ", ")))
      next
    }
    k <- do.call(paste, p[, chaves_p, drop = FALSE])
    if (anyDuplicated(k)) {
      bloqueios <- c(bloqueios, sprintf(
        "%s: %d chave(s) duplicada(s) em %s, %d linha(s) excedente(s)",
        nm, length(unique(k[duplicated(k)])), paste(chaves_p, collapse = "+"),
        sum(duplicated(k))))
    }
    if (!"ano" %in% names(p) && "ano" %in% by) {
      n_anos <- length(mape_anos_painel())
      if (!permitir_replicacao) {
        bloqueios <- c(bloqueios, sprintf(
          paste0("%s: não tem coluna `ano`. Juntá-la a um painel replicaria ",
                 "cada valor em até %d anos. Passe permitir_replicacao = TRUE ",
                 "se for isso mesmo que você quer."), nm, n_anos))
      } else {
        message("[", nm, "] sem `ano`: cada valor será replicado em até ",
                n_anos, " anos.")
      }
    }
    cob <- round(100 * length(unique(p$id_municipio)) / n_mun_total, 1)
    if (cob < 50) {
      message("[", nm, "] cobre ", cob, "% dos municípios; a junção vai gerar ",
              "coluna majoritariamente vazia.")
    }
  }
  if (length(bloqueios)) {
    stop("Não dá para juntar assim:\n", paste0("  - ", bloqueios, collapse = "\n"),
         "\n\nJuntar mesmo assim multiplicaria linhas ou replicaria valores sem ",
         "registro, que é o defeito estrutural do pipeline antigo.", call. = FALSE)
  }

  resultado <- partes[[1]]
  relatorio[[1]] <- data.frame(passo = 0, tabela = names(partes)[1],
                               linhas = nrow(resultado), colunas = ncol(resultado),
                               stringsAsFactors = FALSE)

  if (length(partes) > 1) {
    for (i in 2:length(partes)) {
      chaves_i <- intersect(by, intersect(names(resultado), names(partes[[i]])))
      rel <- if (length(chaves_i) < length(by)) "many-to-one" else "one-to-one"
      resultado <- mape_join(resultado, partes[[i]], by = chaves_i, tipo = tipo,
                             relationship = rel,
                             nome = paste0("juntar + ", names(partes)[i]))
      relatorio[[i]] <- data.frame(
        passo = i - 1, tabela = names(partes)[i], linhas = nrow(resultado),
        colunas = ncol(resultado), stringsAsFactors = FALSE)
    }
  }

  # O bloco territorial entra por ÚLTIMO, e não como primeira parte. A ordem
  # importa porque a cardinalidade não é simétrica: o diretório tem uma linha
  # por município e o painel tem uma por município-ano, então o diretório é
  # sempre o lado "one" da junção. Pô-lo primeiro invertia isso e fazia
  # mape_join() recusar corretamente uma junção que estava mal montada por mim.
  if (territorio) {
    dir_mun <- mape_ler_tabela("00_diretorios/municipios")
    cols <- intersect(c("id_municipio", "nome_municipio", "sigla_uf", "nome_uf",
                        "nome_regiao"), names(dir_mun))
    resultado <- mape_join(resultado, dir_mun[, cols, drop = FALSE],
                           by = "id_municipio", tipo = "left",
                           relationship = "many-to-one", nome = "juntar + territorio")
    resultado <- resultado[, c(intersect(cols, names(resultado)),
                               setdiff(names(resultado), cols)), drop = FALSE]
    relatorio[[length(relatorio) + 1]] <- data.frame(
      passo = length(partes), tabela = "00_diretorios/municipios",
      linhas = nrow(resultado), colunas = ncol(resultado), stringsAsFactors = FALSE)
  }

  attr(resultado, "mape_relatorio") <- do.call(rbind, relatorio)
  rownames(resultado) <- NULL
  resultado
}

#' Cobertura real de cada tabela por ano
#'
#' Substitui as dezessete colunas `dimensao_<nome>` da base publicada, que eram
#' codificadas como 1 e NA (nunca zero), tinham um erro de digitação no nome
#' (`dimensao_identificao`) e não eram usadas por nenhum consumidor.
#'
#' A diferença que importa: aquelas colunas eram atribuídas na etapa de junção e
#' portanto diziam "esta dimensão foi juntada", não "esta dimensão tem dado
#' aqui". Esta função conta presença real de valor não vazio.
#'
#' @param tabelas Slugs a medir. NULL usa todas as publicadas.
#' @param por_ano Se FALSE, agrega a cobertura da tabela inteira.
#' @return Data frame com tabela, ano, municípios cobertos e percentual.
#' @examples
#' \dontrun{
#' cob <- mape_cobertura()
#' subset(cob, tabela == "14_corrupcao")
#' }
mape_cobertura <- function(tabelas = NULL, por_ano = TRUE) {
  disponiveis <- mape_tabelas_publicadas()
  if (is.null(tabelas)) {
    tabelas <- disponiveis$slug
  } else {
    tabelas <- vapply(tabelas, mape_resolver_tabela, character(1), USE.NAMES = FALSE)
  }
  n_mun <- length(unique(mape_ler_tabela("00_diretorios/municipios")$id_municipio))

  linhas <- list()
  for (t in tabelas) {
    camada <- disponiveis$camada[match(t, disponiveis$slug)]
    x <- mape_ler_tabela(t, camada = camada)
    chaves <- intersect(c("id_municipio", "ano"), names(x))
    dados <- setdiff(names(x), chaves)
    if (!length(dados)) next

    # "Coberto" é ter pelo menos um valor não vazio, e não estar presente na
    # tabela. A distinção é o que separa cobertura de preenchimento.
    tem <- rowSums(!is.na(x[, dados, drop = FALSE])) > 0

    if (por_ano && "ano" %in% names(x)) {
      agg <- tapply(x$id_municipio[tem], x$ano[tem], function(v) length(unique(v)))
      linhas[[length(linhas) + 1]] <- data.frame(
        tabela = t, ano = as.integer(names(agg)), municipios = as.integer(agg),
        stringsAsFactors = FALSE)
    } else {
      linhas[[length(linhas) + 1]] <- data.frame(
        tabela = t, ano = NA_integer_,
        municipios = length(unique(x$id_municipio[tem])),
        stringsAsFactors = FALSE)
    }
  }

  res <- do.call(rbind, linhas)
  res$cobertura_pct <- round(100 * res$municipios / n_mun, 1)
  res[order(res$tabela, res$ano), ]
}

# Catálogo de indicadores derivados -------------------------------------------
#
# Um indicador derivado é uma conta entre colunas que a base não guarda pronta.
# O caso que justifica o catálogo é o PIB per capita: ele existe na base
# publicada e NÃO é reproduzível a partir dela, porque o denominador usado foi
# uma segunda extração da população, descartada logo depois de dividir.
#
# Aqui cada indicador declara de que colunas depende. Se uma delas faltar, a
# função nomeia a coluna ausente e para, em vez de devolver NA em silêncio.

.mape_indicadores <- list(

  pib_per_capita_brl2023 = list(
    rotulo = "PIB per capita",
    unidade = "BRL de dezembro de 2023",
    precisa = c("pib_brl2023", "populacao_residente_i"),
    tabelas = c("04_economia", "02_populacao"),
    calcular = function(d) d$pib_brl2023 / d$populacao_residente_i,
    nota = paste(
      "A base publicada traz uma coluna de PIB per capita que não é",
      "reproduzível a partir dela: o denominador veio de uma segunda extração",
      "da população, feita junto com o PIB e descartada logo depois de dividir.",
      "As duas séries de população são idênticas nas 127.786 linhas",
      "comparáveis, então o número bate — mas quem quisesse conferir não",
      "conseguiria. Aqui o denominador é explícito e vem da tabela dona."
    )
  ),

  receita_propria_per_capita_brl2023 = list(
    rotulo = "Receita própria per capita",
    unidade = "BRL de dezembro de 2023",
    precisa = c("siconfi_receitas_proprias_brl2023", "populacao_residente_i"),
    tabelas = c("06_financas", "02_populacao"),
    calcular = function(d) d$siconfi_receitas_proprias_brl2023 / d$populacao_residente_i,
    nota = paste(
      "Mede quanto o município arrecada por conta própria, por habitante.",
      "É o indicador que separa município que se sustenta de município que",
      "depende de transferência."
    )
  ),

  taxa_homicidios_p100k = list(
    rotulo = "Taxa de homicídios por 100 mil habitantes",
    unidade = "óbitos por 100 mil habitantes",
    precisa = c("sim_obitos_homicidio_i", "populacao_residente_i"),
    tabelas = c("13_seguranca", "02_populacao"),
    calcular = function(d) d$sim_obitos_homicidio_i / d$populacao_residente_i * 1e5,
    nota = paste(
      "Homicídios registrados no SIM sobre a população do mesmo ano. Usa o SIM",
      "e não o Anuário do FBSP porque o SIM cobre os 5.570 municípios e o",
      "Anuário cobre 27."
    )
  ),

  cobertura_esgoto_urbano_pct = list(
    rotulo = "Cobertura de esgoto na população urbana",
    unidade = "%",
    precisa = c("snis_populacao_urbana_atendida_esgoto_i", "snis_populacao_urbana_i"),
    tabelas = "03_meio_ambiente",
    calcular = function(d) {
      100 * d$snis_populacao_urbana_atendida_esgoto_i / d$snis_populacao_urbana_i
    },
    nota = paste(
      "Calculada em vez de lida porque a coluna pronta da base publicada tem",
      "erro de digitação no nome (`populacao_atentida_esgoto`) e mede",
      "população absoluta, não percentual."
    )
  ),

  prejuizo_desastre_per_capita_brl2023 = list(
    rotulo = "Prejuízo com desastres por habitante",
    unidade = "BRL de dezembro de 2023",
    precisa = c("s2id_prejuizos_publicos_brl2023", "s2id_prejuizos_privados_brl2023",
                "populacao_residente_i"),
    tabelas = c("03_meio_ambiente", "02_populacao"),
    calcular = function(d) {
      (d$s2id_prejuizos_publicos_brl2023 + d$s2id_prejuizos_privados_brl2023) /
        d$populacao_residente_i
    },
    nota = paste(
      "Soma prejuízo público e privado declarados no S2ID. Zero significa",
      "'nenhum desastre reconhecido no ano', e não 'desastre sem prejuízo'."
    )
  ),

  comparecimento_prefeitura_pct = list(
    rotulo = "Comparecimento na eleição para prefeito",
    unidade = "%",
    precisa = c("tse_comparecimento_prefeitura_i", "tse_eleitores_aptos_prefeitura_i"),
    tabelas = "16_eleicoes",
    calcular = function(d) {
      100 * d$tse_comparecimento_prefeitura_i / d$tse_eleitores_aptos_prefeitura_i
    },
    nota = "Só existe em ano de eleição municipal, e só de primeiro turno."
  ),

  esforco_proprio_saude_pct = list(
    rotulo = "Despesa em saúde com recursos próprios, sobre a despesa total",
    unidade = "%",
    precisa = c("ieps_despesa_saude_recursos_proprios_per_capita_brl2023",
                "ieps_despesa_saude_total_per_capita_brl2023"),
    tabelas = "10_saude",
    calcular = function(d) {
      100 * d$ieps_despesa_saude_recursos_proprios_per_capita_brl2023 /
        d$ieps_despesa_saude_total_per_capita_brl2023
    },
    nota = paste(
      "Quanto da saúde municipal sai do caixa do próprio município, e não de",
      "transferência federal ou estadual."
    )
  ),

  dependencia_emendas_prop = list(
    rotulo = "Emendas parlamentares sobre a receita própria",
    unidade = "razão",
    precisa = c("emendas_valor_total_brl2023", "siconfi_receitas_proprias_brl2023"),
    tabelas = "06_financas",
    calcular = function(d) {
      d$emendas_valor_total_brl2023 / d$siconfi_receitas_proprias_brl2023
    },
    nota = paste(
      "Mede o peso da emenda parlamentar diante do que o município arrecada.",
      "Atenção: a tabela de Finanças tem 222 chaves duplicadas herdadas da",
      "fonte das emendas, que associa o gasto ao município por nome e sem UF."
    )
  )
)

#' Catálogo de indicadores derivados
#'
#' @return Data frame com um indicador por linha.
#' @examples
#' mape_indicadores()
mape_indicadores <- function() {
  do.call(rbind, lapply(names(.mape_indicadores), function(nm) {
    ind <- .mape_indicadores[[nm]]
    data.frame(indicador = nm, rotulo = ind$rotulo, unidade = ind$unidade,
               precisa = paste(ind$precisa, collapse = ", "),
               tabelas = paste(ind$tabelas, collapse = ", "),
               nota = ind$nota, stringsAsFactors = FALSE)
  }))
}

#' Calcula indicadores derivados
#'
#' @param quais Nomes dos indicadores. NULL calcula todos os possíveis com os
#'   dados disponíveis.
#' @param dados Data frame já montado com as colunas necessárias. Se NULL, a
#'   função junta as tabelas de que os indicadores precisam.
#' @param manter_insumos Se TRUE, devolve também as colunas usadas no cálculo,
#'   para que a conta seja conferível.
#' @return Data frame com id_municipio, ano e uma coluna por indicador.
#' @examples
#' \dontrun{
#' d <- mape_derivadas(c("taxa_homicidios_p100k", "pib_per_capita_brl"))
#' }
mape_derivadas <- function(quais = NULL, dados = NULL, manter_insumos = FALSE) {
  if (is.null(quais)) quais <- names(.mape_indicadores)
  desconhecidos <- setdiff(quais, names(.mape_indicadores))
  if (length(desconhecidos)) {
    stop("Indicador desconhecido: ", paste(desconhecidos, collapse = ", "),
         "\nVeja mape_indicadores() para o catálogo.", call. = FALSE)
  }

  precisa <- unique(unlist(lapply(.mape_indicadores[quais], `[[`, "precisa")))

  if (is.null(dados)) {
    tabelas <- unique(unlist(lapply(.mape_indicadores[quais], `[[`, "tabelas")))
    tabelas <- tabelas[vapply(tabelas, function(t) {
      file.exists(mape_caminho_tabela(t, "parquet",
                                      camada = if (grepl("/", t)) "fonte" else "dimensao"))
    }, logical(1))]
    if (!length(tabelas)) {
      stop("Nenhuma das tabelas necessárias está publicada.", call. = FALSE)
    }
    dados <- mape_juntar(tabelas, by = c("id_municipio", "ano"), tipo = "full")
  }

  faltando <- setdiff(precisa, names(dados))
  if (length(faltando)) {
    culpados <- vapply(quais, function(q) {
      any(.mape_indicadores[[q]]$precisa %in% faltando)
    }, logical(1))
    stop("Faltam colunas para calcular ", paste(quais[culpados], collapse = ", "),
         ":\n  ", paste(faltando, collapse = "\n  "),
         "\n\nUma coluna que sumiu do dado é um indicador que mudou de ",
         "definição, não um NA. Confira dicionario/deprecacao.csv: ela pode ",
         "ter sido renomeada.", call. = FALSE)
  }

  chaves <- intersect(c("id_municipio", "ano"), names(dados))
  saida <- dados[, chaves, drop = FALSE]
  for (q in quais) {
    v <- .mape_indicadores[[q]]$calcular(dados)
    # Divisão por zero produz Inf, que atravessa qualquer média sem reclamar.
    v[is.infinite(v)] <- NA_real_
    saida[[q]] <- v
  }
  if (manter_insumos) {
    saida <- cbind(saida, dados[, setdiff(precisa, chaves), drop = FALSE])
  }
  rownames(saida) <- NULL
  saida
}
