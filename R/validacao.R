# Validação e controle de qualidade ------------------------------------------
#
# As checagens da seção 11.2 do plano. Cada uma nasceu de um defeito real
# encontrado no levantamento do legado, e por isso o comentário de cada bloco
# diz o que ela previne.
#
# Regra de bloqueio, e desta vez ela é EXECUTADA e não só declarada:
#
#   - um ERRO impede a publicação, a menos que esteja reivindicado de antemão em
#     qa/erros_aceitos.csv, com justificativa;
#   - um AVISO exige justificativa registrada — em qa/justificativas.csv, ou no
#     campo `problema` da variável que ele nomeia;
#   - um aviso SEM justificativa vira erro.
#
# A auditoria de 26/07/2026 mostrou que nada disso era executado: o achado 22
# mediu que nenhum caminho de escrita chamava esta função, e o achado 38 mediu
# que a cláusula "aviso sem justificativa vira erro" não existia em código
# nenhum. As duas frases estavam escritas em cinco arquivos e valiam zero.
#
# O número de checagens não é mais digitado. mape_validar_tabela() conta quantas
# de fato rodaram e o relatório imprime esse número — porque a checagem 3 e a 6
# desaparecem quando o diretório de municípios não pode ser lido (achado 83), e
# antes disso o relatório dizia "as doze checagens passaram" mesmo assim.

#' Lê o livro-caixa de justificativas de aviso
#'
#' @return Data frame com slug_tabela, checagem, coluna, justificativa.
mape_justificativas <- function() {
  caminho <- mape_caminho("qa", "justificativas.csv")
  vazio <- data.frame(slug_tabela = character(), checagem = character(),
                      coluna = character(), justificativa = character(),
                      stringsAsFactors = FALSE)
  if (!file.exists(caminho)) return(vazio)
  r <- utils::read.csv(caminho, stringsAsFactors = FALSE, encoding = "UTF-8")
  if (!nrow(r)) return(vazio)
  r
}

#' Lê o livro-caixa de erros reivindicados
#'
#' Um erro só deixa de bloquear se estiver aqui, nomeado por tabela e checagem,
#' com justificativa. É o análogo de qa/paridade_esperada.csv: reivindicar antes,
#' nunca depois de ver o resultado.
#'
#' @return Data frame com slug_tabela, checagem, justificativa.
mape_erros_aceitos <- function() {
  caminho <- mape_caminho("qa", "erros_aceitos.csv")
  vazio <- data.frame(slug_tabela = character(), checagem = character(),
                      justificativa = character(), stringsAsFactors = FALSE)
  if (!file.exists(caminho)) return(vazio)
  r <- utils::read.csv(caminho, stringsAsFactors = FALSE, encoding = "UTF-8")
  if (!nrow(r)) return(vazio)
  r
}

#' Anexa a justificativa de cada achado, e promove aviso sem justificativa a erro
#'
#' Três fontes de justificativa, nesta ordem:
#'   1. qa/justificativas.csv, casando tabela + checagem (+ coluna, se declarada);
#'   2. o campo `problema` da variável nomeada no achado, em variaveis.csv;
#'   3. qa/erros_aceitos.csv, que rebaixa um erro reivindicado a aviso justificado.
#'
#' O campo `observacoes` da tabela NÃO conta como justificativa de aviso, de
#' propósito: texto livre no nível da tabela não prova que *este* aviso foi
#' justificado, que é a crítica do achado 38. Ele continua valendo como contexto
#' e é impresso no relatório.
#'
#' @param res Data frame de achados.
#' @param tabela Identificador da tabela.
#' @return O mesmo data frame, com as colunas justificada e justificativa, e as
#'   gravidades já ajustadas.
mape_aplicar_justificativas <- function(res, tabela) {
  if (!nrow(res)) {
    res$justificada <- logical(0)
    res$justificativa <- character(0)
    return(res)
  }
  res$justificada <- FALSE
  res$justificativa <- NA_character_

  just <- mape_justificativas()
  aceitos <- mape_erros_aceitos()
  vars <- tryCatch(mape_dicionario("variaveis"), error = function(e) NULL)

  # A descrição de um achado de schema começa com "<coluna>: ...".
  coluna_do_achado <- function(desc) {
    m <- regmatches(desc, regexpr("^[a-z][a-z0-9_]*(?=:)", desc, perl = TRUE))
    if (length(m)) m else NA_character_
  }

  for (i in seq_len(nrow(res))) {
    col <- coluna_do_achado(res$descricao[i])

    # 1. livro-caixa de justificativas
    j <- just[just$slug_tabela == tabela & just$checagem == res$checagem[i], , drop = FALSE]
    if (nrow(j)) {
      j <- j[is.na(j$coluna) | j$coluna == "*" | j$coluna == "" |
               (!is.na(col) & j$coluna == col), , drop = FALSE]
    }
    if (nrow(j)) {
      res$justificada[i] <- TRUE
      res$justificativa[i] <- j$justificativa[1]
      next
    }

    # 2. campo `problema` da variável nomeada
    if (!is.na(col) && !is.null(vars)) {
      linha <- vars[vars$nome_canonico == col, , drop = FALSE]
      prob <- linha$problema[nzchar(trimws(as.character(linha$problema)))]
      prob <- prob[!is.na(prob)]
      if (length(prob)) {
        res$justificada[i] <- TRUE
        res$justificativa[i] <- paste0("problema da variável ", col, ": ", prob[1])
        next
      }
    }

    # 3. erro reivindicado
    if (res$gravidade[i] == "erro") {
      a <- aceitos[aceitos$slug_tabela == tabela & aceitos$checagem == res$checagem[i], ,
                   drop = FALSE]
      if (nrow(a)) {
        res$justificada[i] <- TRUE
        res$justificativa[i] <- a$justificativa[1]
        res$gravidade[i] <- "aviso"   # reivindicado: deixa de bloquear
      }
    }
  }

  # A cláusula que faltava: aviso sem justificativa vira erro. A gravidade
  # "informativo" fica de fora — ela não afirma defeito, só mede cobertura, e
  # exigir justificativa para ela transformaria informação em ruído.
  res$justificada[res$gravidade == "informativo"] <- TRUE
  promove <- res$gravidade == "aviso" & !res$justificada
  res$gravidade[promove] <- "erro"
  res$descricao[promove] <- paste0(res$descricao[promove],
                                   " [aviso sem justificativa registrada]")
  res
}

#' Anos em que uma coluna monetária salta de nível para quase todos os municípios
#'
#' Achado 1. Um erro de escala move a série toda pelo mesmo fator num ano só; o
#' crescimento econômico não faz isso. A assinatura não está na dispersão — a
#' razão ano a ano do PIB municipal tem IQR relativo de ~0,11 tanto nos anos de
#' quebra quanto nos normais — e sim na MEDIANA da razão comparada com a mediana
#' típica da própria série.
#'
#' No PIB publicado: 0,84 em 2001, 0,73 em 2004 e 0,57 em 2011, contra 1,10 de
#' crescimento nominal típico. Uma queda de 43% no PIB nominal somado de todos os
#' municípios do país, num ano em que a economia cresceu, é aritmética e não
#' economia.
#'
#' @param x Data frame com id_municipio, ano e a coluna.
#' @param coluna Nome da coluna monetária.
#' @param min_salto Desvio mínimo em relação à mediana típica da série, como
#'   fator (0,3 = 30%).
#' @return Data frame com ano, mediana da razão e o desvio contra o típico.
mape_quebras_de_nivel <- function(x, coluna, min_salto = 0.3) {
  v <- suppressWarnings(as.numeric(as.character(x[[coluna]])))
  d <- data.frame(id = as.character(x$id_municipio),
                  ano = as.integer(as.character(x$ano)), v = v,
                  stringsAsFactors = FALSE)
  d <- d[!is.na(d$v) & d$v > 0 & !is.na(d$ano) & !is.na(d$id), , drop = FALSE]
  if (!nrow(d)) return(NULL)

  anos <- sort(unique(d$ano))
  if (length(anos) < 5) return(NULL)

  medianas <- list()
  for (k in seq_along(anos)[-1]) {
    a <- anos[k]; b <- anos[k - 1]
    if (a - b != 1) next
    m <- merge(d[d$ano == a, c("id", "v")], d[d$ano == b, c("id", "v")],
               by = "id", suffixes = c("_a", "_b"))
    # Exige massa: numa serie esparsa — dano de desastre, emenda parlamentar —
    # a mediana da razao e instavel e o teste vira gerador de ruido. Meia
    # cobertura do pais nos DOIS anos e o piso para a mediana significar algo.
    if (nrow(m) < 2500) next
    med <- stats::median(m$v_a / m$v_b, na.rm = TRUE)
    if (is.finite(med) && med > 0) {
      medianas[[length(medianas) + 1]] <- data.frame(ano = a, mediana = med)
    }
  }
  if (length(medianas) < 4) return(NULL)
  med <- do.call(rbind, medianas)

  # A referência é a própria série: a mediana das medianas é o crescimento
  # típico, robusta aos anos de quebra justamente porque eles são minoria.
  tipico <- stats::median(med$mediana)
  med$desvio <- med$mediana / tipico
  fora <- med[abs(log(med$desvio)) > log(1 + min_salto), , drop = FALSE]
  if (nrow(fora)) fora else NULL
}

#' Colunas que não variam entre os anos medidos, num painel em que as irmãs variam
#'
#' Achado 14. Devolve, por coluna, a proporção de municípios em que o valor é
#' idêntico em todos os anos em que a coluna tem valor. Só reporta quando a
#' tabela tem colunas que VARIAM — numa tabela transversal replicada por desenho
#' a invariância é esperada e não diz nada.
#'
#' @param x Data frame com id_municipio e ano.
#' @param limiar Proporção mínima de municípios invariantes para reportar.
#' @return Lista nomeada coluna -> proporção.
mape_colunas_invariantes <- function(x, limiar = 0.95) {
  anos <- unique(x$ano)
  if (length(anos) < 2) return(list())

  candidatas <- names(x)[vapply(x, is.numeric, logical(1))]
  candidatas <- setdiff(candidatas, c("id_municipio", "ano"))
  candidatas <- grep("^(flag_|ano_ref_)", candidatas, value = TRUE, invert = TRUE)
  if (!length(candidatas)) return(list())

  prop_invariante <- function(nm) {
    v <- x[[nm]]
    # Só entram municípios com mais de uma observação NÃO NULA E NÃO ZERO.
    #
    # Sem o "não zero", a checagem vira gerador de ruído: uma coluna esparsa é
    # trivialmente invariante em todo município que só tem zero, e o zero
    # constante não é evidência de replicação — é evidência de ausência. O caso
    # que a checagem existe para pegar (o retrato do AdaptaBrasil repetido de
    # 2010 a 2020) tem valores reais, não zeros.
    ok <- !is.na(v) & v != 0
    if (!any(ok)) return(NA_real_)
    n_obs <- tapply(v[ok], x$id_municipio[ok], length)
    mult <- unlist(n_obs) > 1
    if (sum(mult) < 100) return(NA_real_)   # poucos municípios: não conclui
    iguais <- tapply(v[ok], x$id_municipio[ok],
                     function(z) length(unique(z)) == 1)
    mean(unlist(iguais)[mult])
  }

  props <- vapply(candidatas, prop_invariante, numeric(1))
  props <- props[!is.na(props)]
  if (!length(props)) return(list())

  # A comparação com as irmãs: se TODAS são invariantes, a tabela é transversal
  # replicada por desenho e não há o que reportar.
  if (all(props >= limiar)) return(list())

  as.list(props[props >= limiar])
}

#' Descrições de uma tabela que se repetem noutra — a checagem 12
#'
#' Compara descrições normalizadas: minúsculas, sem acento, sem pontuação, sem
#' os sufixos de deflação que o projeto acrescenta mecanicamente. Isso é o que
#' pega o bloco deslizado de 06_financas, cujo caso mais grave escapa da
#' igualdade exata porque teve texto prefixado.
#'
#' Pares legítimos ficam de fora por uma lista de exceções declarada: há
#' conceitos que a mesma frase descreve com razão em tabelas diferentes.
#'
#' @param tabela Identificador da tabela.
#' @return Data frame com coluna, outra, tabela_outra.
mape_descricoes_repetidas <- function(tabela) {
  vars <- mape_dicionario("variaveis")
  normalizar <- function(s) {
    s <- tolower(iconv(as.character(s), to = "ASCII//TRANSLIT"))
    s <- gsub("\\(deflacionado[^)]*\\)", "", s)
    s <- gsub("[[:punct:]]", " ", s)
    trimws(gsub("[[:space:]]+", " ", s))
  }
  vars$.norm <- normalizar(vars$descricao)
  # Pares legítimos: a mesma frase descreve o mesmo conceito nas duas tabelas.
  excecoes <- c("nome do municipio", "sigla da unidade da federacao",
                "nome da unidade da federacao", "codigo ibge do municipio 7 digitos",
                "ano de referencia", "ano")

  minhas <- vars[!is.na(vars$tabela) & vars$tabela == tabela &
                   !is.na(vars$.norm) & nzchar(vars$.norm), , drop = FALSE]
  out <- list()
  for (i in seq_len(nrow(minhas))) {
    n <- minhas$.norm[i]
    if (n %in% excecoes || nchar(n) < 25) next
    outras <- vars[!is.na(vars$.norm) & vars$.norm == n &
                     !is.na(vars$tabela) & vars$tabela != tabela, , drop = FALSE]
    if (nrow(outras)) {
      out[[length(out) + 1]] <- data.frame(
        coluna = minhas$nome_canonico[i],
        outra = outras$nome_canonico[1],
        tabela_outra = outras$tabela[1],
        stringsAsFactors = FALSE)
    }
  }
  if (length(out)) do.call(rbind, out) else
    data.frame(coluna = character(), outra = character(),
               tabela_outra = character(), stringsAsFactors = FALSE)
}

#' Roda todas as checagens sobre uma tabela
#'
#' @param x Data frame.
#' @param tabela Identificador da tabela.
#' @param chaves Chave primária. Se NULL, lê do dicionário de tabelas.
#' @param diretorio Diretório de municípios. Se NULL, lê o publicado, exceto
#'   quando a própria tabela for o diretório.
#' @param erro Se TRUE, falha ao encontrar problema bloqueante.
#' @param gravar Se TRUE, escreve qa/<slug>.md. Passe FALSE para validar sem
#'   sujar a árvore versionada (achado 59).
#' @return Invisivelmente, um data frame com uma linha por problema.
mape_validar_tabela <- function(x, tabela, chaves = NULL, diretorio = NULL,
                                erro = TRUE, gravar = TRUE) {
  achados <- list()
  reg <- function(checagem, gravidade, descricao) {
    achados[[length(achados) + 1]] <<- data.frame(
      tabela = tabela, checagem = checagem, gravidade = gravidade,
      descricao = descricao, stringsAsFactors = FALSE
    )
  }
  # Quantas checagens de fato rodaram. O relatório imprime este número em vez
  # de afirmar doze — ver o cabeçalho e o achado 83.
  executadas <- character()
  rodou <- function(...) executadas <<- unique(c(executadas, c(...)))

  # A chave primária vem do dicionário; digitar de novo aqui seria repetir a
  # fonte de verdade.
  if (is.null(chaves)) {
    tabs <- tryCatch(mape_dicionario("tabelas"), error = function(e) NULL)
    if (!is.null(tabs) && tabela %in% tabs$slug_tabela) {
      decl <- tabs$chave_primaria[tabs$slug_tabela == tabela][1]
      chaves <- trimws(strsplit(decl, ",")[[1]])
    } else {
      chaves <- intersect(c("id_municipio", "ano"), names(x))
    }
  }
  chaves <- intersect(chaves, names(x))

  # -- 1. Unicidade da chave primária ---------------------------------------
  # Previne: 222 chaves duplicadas em Finanças, 54 nos dados históricos.
  if (length(chaves)) {
    rodou("chave_unica", "chave_sem_na")
    d <- tryCatch(mape_validar_chave(x, chaves, erro = FALSE),
                  warning = function(w) suppressWarnings(
                    mape_validar_chave(x, chaves, erro = FALSE)))
    if (d$n_chaves_duplicadas > 0) {
      reg("chave_unica", "erro",
          paste0(d$n_chaves_duplicadas, " chave(s) duplicada(s), ",
                 d$n_linhas_excedentes, " linha(s) excedente(s)"))
    }
    # -- 2. Ausência de chave nula ------------------------------------------
    # Previne: as 122 linhas pré-deduplicação, 13 das quais sobrevivem hoje.
    if (d$n_chave_na > 0) {
      reg("chave_sem_na", "erro",
          paste0(d$n_chave_na, " linha(s) com chave nula"))
    }
  } else {
    reg("chave_unica", "aviso", "nenhuma coluna de chave encontrada")
  }

  # -- 3. Domínio da chave contra o diretório -------------------------------
  # Previne: 27 códigos de UF sumindo na Segurança e 27 muncode extintos na
  # dimensão histórica. Os órfãos são REPORTADOS, não descartados.
  if ("id_municipio" %in% names(x) && tabela != "00_diretorios/municipios") {
    dir_ok <- tryCatch({
      if (is.null(diretorio)) diretorio <- mape_ler_tabela("00_diretorios/municipios")
      TRUE
    }, error = function(e) FALSE)
    if (dir_ok) {
      rodou("dominio_chave", "cobertura_municipios")
      dd <- suppressWarnings(
        mape_validar_dominio_chave(x, diretorio = diretorio, erro_se_exceder = FALSE)
      )
      if (dd$n_codigos_orfaos > 0) {
        limiar <- mape_param("qa.max_prop_chave_orfa")
        reg("dominio_chave",
            if (dd$prop_linhas_orfas > limiar) "erro" else "aviso",
            paste0(dd$n_codigos_orfaos, " código(s) fora do diretório em ",
                   dd$n_linhas_orfas, " linha(s) (",
                   round(100 * dd$prop_linhas_orfas, 3), "%). Exemplos: ",
                   paste(utils::head(dd$codigos_orfaos, 5), collapse = ", ")))
      }
      # -- 6. Cobertura de municípios ---------------------------------------
      # Previne: o Anuário do FBSP cobrindo 27 municípios sem nenhum aviso.
      if (dd$cobertura_municipios < 0.5) {
        reg("cobertura_municipios", "aviso",
            paste0("a tabela cobre apenas ",
                   round(100 * dd$cobertura_municipios, 1),
                   "% dos municípios do diretório"))
      }
    } else {
      # Achado 83: sem esta linha, as checagens 3 e 6 sumiam sem deixar rastro e
      # o relatório continuava dizendo que tudo passou.
      reg("dominio_chave", "aviso",
          "diretório de municípios indisponível: as checagens de domínio de chave e de cobertura de municípios NÃO rodaram")
    }
  }

  # -- 4, 9, 10. Tipos, domínio de valor e coerência sufixo/escala ----------
  if (mape_tabela_no_dicionario(tabela)) {
    rodou("tipos", "dominio_valor", "sufixo_escala")
    prob <- tryCatch(
      suppressWarnings(mape_validar_schema(x, tabela, erro = FALSE)),
      error = function(e) NULL
    )
    if (!is.null(prob) && nrow(prob)) {
      for (i in seq_len(nrow(prob))) {
        reg("schema", prob$gravidade[i],
            paste0(prob$coluna[i], ": ", prob$descricao[i]))
      }
    }
  } else {
    reg("dicionario", "erro",
        "a tabela não tem entrada em dicionario/tabelas.csv")
  }

  # -- 5. Faixa de anos declarada contra observada --------------------------
  # Previne: cinco bases anunciando 2024 num painel que termina em 2023.
  if ("ano" %in% names(x) && any(!is.na(x$ano))) {
    rodou("faixa_anos")
    obs <- range(x$ano, na.rm = TRUE)
    painel <- mape_param("anos_painel")
    if (obs[1] < painel[1] || obs[2] > painel[2]) {
      reg("faixa_anos", "aviso",
          paste0("anos observados de ", obs[1], " a ", obs[2],
                 ", fora do painel declarado (", painel[1], " a ", painel[2], ")"))
    }
  }

  # -- 7. Linter de nomes de coluna -----------------------------------------
  # Previne: pontos (ln.pc.receita1920.sd), Title Case com acento
  # (Comércio.e.serviços), maiúsculas (NM_UF) e os prefixos genéricos total_ e
  # quantidade_, usados em sete dimensões para coisas sem relação entre si.
  rodou("nomes_colunas")
  ruins <- names(x)[!grepl("^[a-z][a-z0-9_]*$", names(x))]
  if (length(ruins)) {
    reg("nomes_colunas", "erro",
        paste0("nome(s) fora do padrão snake_case ASCII: ",
               paste(utils::head(ruins, 10), collapse = ", ")))
  }
  genericos <- grep("^(total_|quantidade_)", names(x), value = TRUE)
  if (length(genericos)) {
    reg("nomes_colunas", "aviso",
        paste0("prefixo genérico banido: ",
               paste(utils::head(genericos, 8), collapse = ", ")))
  }

  # -- 8. Sentinelas não convertidos ----------------------------------------
  # -- 12. Descrições repetidas entre tabelas -------------------------------
  # A checagem 12 do plano, que NUNCA foi implementada — e o defeito que ela
  # previne está publicado: sete variáveis de 06_financas carregam a descrição
  # dos componentes do PIB de 04_economia, deslizadas em bloco (achados 18, 23).
  #
  # A regra é de SIMILARIDADE e não de igualdade exata, porque o caso mais grave
  # do bloco (siconfi_deducao_fundeb_brl2023) escapa da igualdade: a descrição
  # foi montada prefixando texto à descrição alheia.
  if (mape_tabela_no_dicionario(tabela)) {
    rodou("descricao_repetida")
    d <- tryCatch(mape_descricoes_repetidas(tabela), error = function(e) NULL)
    if (!is.null(d) && nrow(d)) {
      for (i in seq_len(nrow(d))) {
        reg("descricao_repetida", "aviso",
            paste0(d$coluna[i], ": descrição igual à de `", d$outra[i],
                   "` (tabela ", d$tabela_outra[i], ")"))
      }
    }
  }

  # -- 13. Zero-inflação e janela efetiva por coluna -------------------------
  # Achados 4, 5, 15, 16 e 27. O `pct_na` dizia que
  # siconfi_receitas_realizadas_brl2023 estava 99,74% completa; ela é 96,95%
  # zero, e o zero ali significa "não medido" — o padrão de sum() sobre
  # subconjunto vazio, que devolve 0 e não NA.
  #
  # A checagem olha duas coisas que o pct_na não vê: quanto da coluna é zero, e
  # em que anos ela tem algum valor informativo.
  # O discriminante NÃO é a proporção de zeros: uma contagem de baixa incidência
  # é legitimamente quase toda zero, e um município com zero denúncias por
  # motivo religioso mediu zero. O que denuncia vazio-publicado-como-zero é o
  # zero em BLOCO DE ANO INTEIRO — anos em que a coluna é 100% zero para os
  # 5.570 municípios, ao lado de anos em que ela tem valor. Nenhum fenômeno
  # social desaparece do país inteiro num ano e volta no seguinte; um layout de
  # origem que deixa de publicar um estágio, sim.
  if ("ano" %in% names(x) && nrow(x) > 100) {
    rodou("zero_inflacao")
    anos <- sort(unique(x$ano))
    if (length(anos) >= 3) {
      for (nm in names(x)) {
        v <- x[[nm]]
        if (!is.numeric(v) || grepl("^(flag_|ano_ref_)", nm) || nm %in% chaves) next
        if (!any(!is.na(v))) next
        prop_por_ano <- vapply(anos, function(a) {
          vv <- v[x$ano == a]
          if (!any(!is.na(vv))) NA_real_ else mean(vv == 0, na.rm = TRUE)
        }, numeric(1))
        vazios <- anos[!is.na(prop_por_ano) & prop_por_ano >= 0.99]
        cheios <- anos[!is.na(prop_por_ano) & prop_por_ano < 0.90]
        if (length(vazios) && length(cheios)) {
          reg("zero_inflacao", "aviso",
              paste0(nm, ": ", length(vazios), " ano(s) com 99% ou mais de zeros exatos (",
                     paste(utils::head(vazios, 8), collapse = ", "),
                     if (length(vazios) > 8) ", ..." else "",
                     "), enquanto ", length(cheios), " ano(s) têm dado. ",
                     "Ano inteiro zerado costuma ser vazio publicado como zero, ",
                     "e o valor certo para 'não medido' é NA."))
        }
      }
    }
  }

  # -- 14. Quebra de nível em série monetária --------------------------------
  # Achado 1. A soma nacional do PIB caía 17,2% em 2001, 24,0% em 2004 e 43,7%
  # em 2011 — quedas que nenhum deflator explica, porque a série estava
  # multiplicada por um fator inteiro que muda por bloco de anos. Confirmado
  # contra a origem (basedosdados.br_ibge_pib.municipio) em 26/07/2026: o fator
  # é exatamente 3 em 2002-2003, 2 em 2004-2010 e 1 de 2011 em diante.
  #
  # A assinatura é uma razão ano a ano com IQR estreito e mediana longe de 1: se
  # TODOS os municípios saltam pelo mesmo fator, não é economia, é aritmética.
  if ("ano" %in% names(x) && "id_municipio" %in% names(x)) {
    rodou("quebra_de_nivel")
    monetarias <- grep("_brl", names(x), value = TRUE)
    monetarias <- monetarias[vapply(x[monetarias], is.numeric, logical(1))]
    for (nm in monetarias) {
      q <- tryCatch(mape_quebras_de_nivel(x, nm), error = function(e) NULL)
      if (!is.null(q) && nrow(q)) {
        reg("quebra_de_nivel", "aviso",
            paste0(nm, ": salto de nível em ",
                   paste(sprintf("%d (mediana x%.2f)", q$ano, q$mediana), collapse = ", "),
                   ". Razão ano a ano igual para quase todos os municípios não é ",
                   "economia, é fator aplicado à série."))
      }
    }
  }

  # -- 15. Licença declarada e proveniência da fonte -------------------------
  # Achado 90: o scaffold de mape_nova_fonte() promete que "sem `url` e
  # `licenca` a validação avisa", e NENHUMA checagem olhava licença, URL ou
  # manifesto. Achado 45: as 26 tabelas estão sob `licenca = "a verificar"` e o
  # release publica todas como CC BY 4.0.
  if (mape_tabela_no_dicionario(tabela)) {
    rodou("licenca")
    tabs <- mape_dicionario("tabelas")
    lin <- tabs[tabs$slug_tabela == tabela, , drop = FALSE]
    lic <- if ("licenca" %in% names(lin)) as.character(lin$licenca[1]) else NA_character_
    if (is.na(lic) || !nzchar(trimws(lic)) || grepl("verificar", lic, ignore.case = TRUE)) {
      reg("licenca", "aviso",
          paste0("licenca = '", if (is.na(lic)) "(vazio)" else lic,
                 "': a tabela não declara sob que licença é publicada, e o ",
                 "release a distribui como CC BY 4.0."))
    }
    # Fonte de download manual sem manifesto com URL não tem proveniência.
    if (grepl("/", tabela)) {
      metodo <- if ("metodo_acesso" %in% names(lin)) as.character(lin$metodo_acesso[1]) else NA
      if (!is.na(metodo) && metodo %in% c("download_manual", "arquivo_local")) {
        mani <- mape_caminho("fontes", tabela, "MANIFESTO.yml")
        if (!file.exists(mani)) {
          reg("proveniencia", "aviso",
              paste0("fonte de ", metodo, " sem MANIFESTO.yml: não há registro ",
                     "de onde o dado veio nem de qual arquivo o produziu."))
        } else {
          m <- tryCatch(yaml::read_yaml(mani), error = function(e) list())
          if (is.null(m$url) || !nzchar(as.character(m$url))) {
            reg("proveniencia", "aviso",
                "MANIFESTO.yml sem `url`: a origem do dado não está registrada.")
          }
        }
      }
    }
  }

  # -- 16. Invariância temporal ---------------------------------------------
  # Achado 14: `vulnerabilidade_socioeconomica_pct` é UMA medição publicada como
  # se fossem os censos de 2000 e 2010 — valor idêntico nos 5.565 municípios nos
  # dois anos. A variação entre censos é sempre exatamente zero, e ninguém tem
  # como saber disso olhando a tabela.
  #
  # O discriminante é a comparação com as colunas IRMÃS: numa tabela em que as
  # outras colunas variam entre os dois anos, uma que não varia em quase nenhum
  # município não está medindo duas vezes.
  if ("ano" %in% names(x) && "id_municipio" %in% names(x)) {
    rodou("invariancia_temporal")
    inv <- tryCatch(mape_colunas_invariantes(x), error = function(e) NULL)
    if (!is.null(inv) && length(inv)) {
      for (nm in names(inv)) {
        reg("invariancia_temporal", "aviso",
            paste0(nm, ": idêntica em ", round(100 * inv[[nm]], 1),
                   "% dos municípios entre os anos medidos, enquanto as colunas ",
                   "irmãs variam. Provavelmente é uma medição só, replicada — ",
                   "e a variação entre os anos é sempre zero por construção."))
      }
    }
  }

  # -- 17. Continuidade do painel -------------------------------------------
  # Achado 49: quatro dimensões têm o último ano truncado a uma fração dos
  # municípios, sem nenhuma marcação. Qualquer série temporal calculada sobre a
  # tabela quebra no último ponto, e o gráfico despenca.
  if ("ano" %in% names(x) && nrow(x) > 1000) {
    rodou("continuidade_painel")
    por_ano <- table(x$ano)
    if (length(por_ano) >= 3) {
      anos <- as.integer(names(por_ano))
      ultimo <- length(por_ano)
      mediana_anterior <- stats::median(as.numeric(por_ano[-ultimo]))
      razao <- as.numeric(por_ano[ultimo]) / mediana_anterior
      if (razao < 0.5) {
        reg("continuidade_painel", "aviso",
            paste0("o último ano (", anos[ultimo], ") tem ",
                   formatC(as.numeric(por_ano[ultimo]), format = "d", big.mark = ".",
                           decimal.mark = ","),
                   " linha(s), ", round(100 * razao, 1),
                   "% da mediana dos anos anteriores (",
                   formatC(mediana_anterior, format = "d", big.mark = ".",
                           decimal.mark = ","),
                   "). Série temporal calculada sobre a tabela quebra no último ponto."))
      }
    }
  }

  # -- 18. Cobertura temporal declarada contra observada ---------------------
  # Achado 54: a `cobertura_temporal_da_fonte` digitada contradizia a observada
  # em 12 das tabelas com coluna `ano`, e num caso os intervalos são DISJUNTOS:
  # `11_transportes/tarifas` declarava 2018-2024 e publica 2005-2017. Um campo
  # digitado apodrece; um campo digitado que ninguém confere apodrece em
  # silêncio.
  #
  # Intervalos disjuntos são erro — não há leitura em que o declarado descreva o
  # publicado. Divergência com regra de preenchimento declarada é silêncio, e o
  # resto é aviso.
  if ("ano" %in% names(x) && any(!is.na(x$ano)) && mape_tabela_no_dicionario(tabela)) {
    rodou("cobertura_temporal")
    tabs <- mape_dicionario("tabelas")
    lin <- tabs[tabs$slug_tabela == tabela, , drop = FALSE]
    dec <- as.character(lin$cobertura_temporal_da_fonte[1])
    regra <- as.character(lin$regra_preenchimento_temporal[1])
    anos_dec <- suppressWarnings(as.integer(regmatches(dec, gregexpr("[12][0-9]{3}", dec))[[1]]))
    obs <- range(as.integer(as.character(x$ano)), na.rm = TRUE)
    if (length(anos_dec)) {
      dec_lo <- min(anos_dec); dec_hi <- max(anos_dec)
      disjunto <- dec_hi < obs[1] || dec_lo > obs[2]
      diverge <- dec_lo != obs[1] || dec_hi != obs[2]
      tem_regra <- !is.na(regra) && nzchar(regra) && regra != "nenhuma"
      if (disjunto) {
        reg("cobertura_temporal", "erro",
            paste0("a cobertura declarada (", dec, ") e a observada (", obs[1],
                   "-", obs[2], ") são DISJUNTAS: não há um ano em comum."))
      } else if (diverge && !tem_regra) {
        reg("cobertura_temporal", "aviso",
            paste0("cobertura declarada '", dec, "' contra observada ", obs[1],
                   "-", obs[2], ", sem regra de preenchimento que explique."))
      }
    }
  }

  # -- 19. Exclusividade do bloco territorial --------------------------------
  # Achado 51. O contrato diz que `00_diretorios/municipios` é dono EXCLUSIVO do
  # bloco territorial e que nenhuma outra tabela deveria publicar nome de
  # município ou UF. A regra existia em cinco documentos e em código nenhum.
  #
  # A rodada anterior alegou que a checagem `descricao_repetida` pegava o caso
  # de `sigla_uf_nome` em 04_economia. Não pega, e não podia pegar: a descrição
  # daquela coluna era "Nome da Unidade da Federação", que está na lista de
  # exceções de `mape_descricoes_repetidas()`. Uma checagem que pula o caso
  # antes e depois da correção não prova correção nenhuma.
  #
  # O critério é o NOME da coluna, não a descrição — é o nome que diz quem é o
  # dono do dado.
  DONO_TERRITORIAL <- "00_diretorios/municipios"
  if (!identical(tabela, DONO_TERRITORIAL)) {
    rodou("exclusividade_territorial")
    # Não entram aqui `id_municipio` (a chave) nem `id_municipio_6` (o caminho
    # de conversão de 6 para 7 dígitos), que toda tabela pode ter.
    territoriais <- c(
      "nome_municipio", "municipio", "nome_uf", "sigla_uf", "sigla_uf_nome",
      "nome_regiao", "sigla_regiao", "nome_mesorregiao", "nome_microrregiao",
      "id_municipio_nome", "municipio_tarifa_zero", "localidade_gasto",
      "nome_regiao_imediata", "nome_regiao_intermediaria", "nome_regiao_saude")
    # Um achado POR COLUNA, e a descrição começa pelo nome dela: é assim que
    # mape_aplicar_justificativas() encontra a justificativa (ela lê o prefixo
    # "<coluna>:"). Um achado agregado seria injustificável e viraria erro.
    for (cl in intersect(names(x), territoriais)) {
      reg("exclusividade_territorial", "aviso",
          paste0(cl, ": coluna do bloco territorial publicada fora do ",
                 "diretório. O dono exclusivo desse bloco é `", DONO_TERRITORIAL,
                 "`; duplicá-lo faz duas tabelas discordarem sobre o nome do ",
                 "mesmo município. Use mape_ler(..., territorio = TRUE)."))
    }
  }

  rodou("sentinelas")
  sent <- mape_detectar_sentinelas(x)
  if (nrow(sent)) {
    reg("sentinelas", "erro",
        paste0(nrow(sent), " coluna(s) com sentinela não convertido: ",
               paste(utils::head(paste0(sent$coluna, "='", sent$sentinela, "'"), 5),
                     collapse = ", ")))
  }

  # -- Extra: valores infinitos ---------------------------------------------
  # Previne: log10() aplicado sem tratar zeros. No dado publicado hoje isso não
  # se manifesta, porque nenhum município-ano tem PIB igual a zero, mas o
  # defeito é latente e reapareceria numa reextração.
  rodou("valores_infinitos")
  for (nm in names(x)) {
    if (is.numeric(x[[nm]]) && any(is.infinite(x[[nm]]))) {
      reg("valores_infinitos", "erro",
          paste0(nm, ": ", sum(is.infinite(x[[nm]])), " valor(es) infinito(s)"))
    }
  }

  res <- if (length(achados)) do.call(rbind, achados) else
    data.frame(tabela = character(), checagem = character(),
               gravidade = character(), descricao = character(),
               stringsAsFactors = FALSE)

  # É aqui que a regra declarada passa a valer: aviso justificado continua
  # aviso, erro reivindicado vira aviso, e aviso sem justificativa vira erro.
  res <- mape_aplicar_justificativas(res, tabela)

  if (gravar) mape_gravar_relatorio_qa(res, tabela, x, length(executadas))

  n_erro  <- sum(res$gravidade == "erro")
  n_aviso <- sum(res$gravidade == "aviso")
  message(sprintf("[QA] %s: %d erro(s), %d aviso(s), %d checagem(ns) executada(s)",
                  tabela, n_erro, n_aviso, length(executadas)))
  if (n_aviso) {
    for (i in which(res$gravidade == "aviso")) {
      message("      aviso  ", res$checagem[i], ": ", res$descricao[i])
    }
  }
  if (n_erro && erro) {
    stop("Validação bloqueou a publicação de '", tabela, "':\n",
         paste0("  - ", res$checagem[res$gravidade == "erro"], ": ",
                res$descricao[res$gravidade == "erro"], collapse = "\n"),
         "\n\nUm aviso sem justificativa aparece aqui como erro. Registre a ",
         "justificativa em qa/justificativas.csv (ou no campo `problema` da ",
         "variável), ou reivindique o erro em qa/erros_aceitos.csv.",
         call. = FALSE)
  }
  invisible(res)
}

#' Defeitos declarados de uma tabela, lidos do dicionário
#'
#' Achado 31: nenhum dos defeitos que o próprio repositório declara era detectado
#' por checagem automática, e cinco das sete tabelas afetadas recebiam o atestado
#' "as doze checagens passaram". As checagens continuam não detectando o que não
#' sabem procurar — mas o relatório passa a dizer o que a tabela declara.
#'
#' @param tabela Identificador da tabela.
#' @return Vetor de textos, possivelmente vazio.
mape_defeitos_declarados <- function(tabela) {
  out <- character()

  tabs <- tryCatch(mape_dicionario("tabelas"), error = function(e) NULL)
  if (!is.null(tabs) && tabela %in% tabs$slug_tabela) {
    obs <- tabs$observacoes[tabs$slug_tabela == tabela][1]
    if (!is.na(obs) && nzchar(trimws(obs))) {
      # Os marcadores em aberto são os que não estão marcados CORRIGIDO.
      pedacos <- unlist(strsplit(obs, "(?<=[.])\\s+(?=[A-ZÀ-Ú])", perl = TRUE))
      abertos <- pedacos[grepl("DEFEITO|LIMITA|ATEN|RESSALVA|PROBLEMA", pedacos) &
                           !grepl("CORRIGIDO", pedacos)]
      if (length(abertos)) out <- c(out, paste0("(tabela) ", abertos))
    }
  }

  vars <- tryCatch(mape_dicionario("variaveis"), error = function(e) NULL)
  if (!is.null(vars)) {
    v <- vars[vars$tabela == tabela, , drop = FALSE]
    if (nrow(v)) {
      tem <- !is.na(v$problema) & nzchar(trimws(as.character(v$problema)))
      if (any(tem)) {
        out <- c(out, paste0("(", v$nome_canonico[tem], ") ", v$problema[tem]))
      }
    }
  }
  out
}

#' Grava o relatório de qualidade de uma tabela
#'
#' @param res Data frame de problemas.
#' @param tabela Identificador da tabela.
#' @param x A tabela validada, usada para o resumo quantitativo.
#' @param n_checagens Quantas checagens de fato rodaram. O relatório imprime
#'   este número; antes ele afirmava doze mesmo quando duas não tinham rodado.
#' @return Invisivelmente, o caminho do relatório.
mape_gravar_relatorio_qa <- function(res, tabela, x = NULL, n_checagens = NA_integer_) {
  destino <- mape_caminho("qa", paste0(gsub("/", "__", tabela), ".md"))
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)

  linhas <- c(
    paste0("# QA — ", tabela), "",
    paste0("Gerado em ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "."), ""
  )
  if (!is.null(x)) {
    linhas <- c(linhas,
      "## Resumo", "",
      paste0("- linhas: ", formatC(nrow(x), format = "d", big.mark = ".", decimal.mark = ",")),
      paste0("- colunas: ", ncol(x)),
      # Achado 64: o rótulo diz agora QUAL das duas medidas de vazio é esta. A
      # outra, sobre colunas de conteúdo, fica no .md da dimensão.
      paste0("- células vazias (todas as colunas): ",
             round(100 * mean(is.na(x)), 2), "%"),
      "")
  }

  linhas <- c(linhas, "## Checagens", "")
  quantas <- if (is.na(n_checagens)) "as" else paste("as", n_checagens)
  if (!nrow(res)) {
    linhas <- c(linhas,
                paste0("Nenhum problema automático: ", quantas,
                       " checagens executadas passaram."), "")
  } else {
    tem_just <- "justificativa" %in% names(res)
    linhas <- c(linhas,
      paste0("Checagens executadas: ", if (is.na(n_checagens)) "?" else n_checagens, "."), "",
      if (tem_just) "| checagem | gravidade | descrição | justificativa |" else
        "| checagem | gravidade | descrição |",
      if (tem_just) "|---|---|---|---|" else "|---|---|---|",
      paste0("| ", res$checagem, " | ", res$gravidade, " | ",
             gsub("[|]", "/", res$descricao),
             if (tem_just) paste0(" | ", gsub("[|]", "/", ifelse(is.na(res$justificativa),
                                                                 "— sem justificativa —",
                                                                 res$justificativa))) else "",
             " |"), "")
  }

  # Achado 31: o que a tabela declara sobre si mesma, ao lado do que as
  # checagens acharam. Sem esta seção, uma tabela com defeito conhecido e
  # declarado recebia um relatório que só dizia "passou".
  declarados <- tryCatch(mape_defeitos_declarados(tabela), error = function(e) character())
  linhas <- c(linhas, "## Defeitos declarados no dicionário", "")
  if (!length(declarados)) {
    linhas <- c(linhas, "Nenhum.", "")
  } else {
    linhas <- c(linhas,
      paste0("Estes ", length(declarados), " defeito(s) estão declarados no ",
             "dicionário e **não** são detectados pelas checagens automáticas ",
             "acima. Um relatório limpo não significa uma tabela sem defeito."),
      "",
      paste0("- ", gsub("\n", " ", declarados)), "")
  }

  writeLines(linhas, destino, useBytes = TRUE)
  invisible(destino)
}
