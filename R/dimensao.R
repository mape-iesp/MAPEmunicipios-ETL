# Consolidação de dimensão e reconstrução da base larga ----------------------
#
# A camada canônica é a FONTE; a dimensão é derivada dela. Esta é a decisão 3.1
# do plano, e o argumento que a sustenta veio do levantamento: quatro das
# dezessete dimensões têm uma única fonte efetiva e nenhum consolidador, o SIM é
# extraído em duas dimensões diferentes e o IDEB aparece em três lugares. A
# dimensão é um agrupamento temático imposto sobre fontes com chaves,
# periodicidades e granularidades distintas.
#
# Aqui a derivação é explícita, determinística e conferida.

#' Consolida as tabelas de fonte de uma dimensão
#'
#' @param dimensao Slug da dimensão.
#' @param tipo Tipo de junção entre as fontes.
#' @param publicar Se TRUE, grava a tabela de dimensão. A gravação passa pela
#'   guarda de perda de mape_escrever_tabela(): se a consolidação das fontes
#'   presentes não reproduzir a dimensão publicada, ela falha em vez de gravar
#'   por cima (achado 6).
#' @param permitir_perda Repassado a mape_escrever_tabela().
#' @param motivo_perda Repassado a mape_escrever_tabela().
#' @return A tabela consolidada.
mape_consolidar_dimensao <- function(dimensao, tipo = "full", publicar = TRUE,
                                     permitir_perda = FALSE, motivo_perda = NULL) {
  tabs <- mape_dicionario("tabelas")
  fontes <- tabs$slug_tabela[tabs$dimensao == dimensao & grepl("/", tabs$slug_tabela)]
  fontes <- fontes[vapply(fontes, function(s) {
    file.exists(mape_caminho_tabela(s, "parquet"))
  }, logical(1))]

  if (!length(fontes)) {
    stop("Nenhuma tabela de fonte publicada para a dimensão '", dimensao, "'.",
         call. = FALSE)
  }
  message("consolidando ", dimensao, " a partir de ", length(fontes),
          " fonte(s): ", paste(basename(fontes), collapse = ", "))

  partes <- lapply(fontes, mape_ler_tabela)
  names(partes) <- fontes

  # A junção é feita pelas chaves comuns a todas as fontes. Fontes que não têm
  # `ano` (tabelas estáticas, como a dimensão histórica) são tratadas à parte:
  # juntá-las só por município replicaria os valores em todos os anos, que é
  # exatamente o defeito que multiplica a série no legado.
  tem_ano <- vapply(partes, function(p) "ano" %in% names(p), logical(1))
  if (any(tem_ano) && !all(tem_ano)) {
    warning("A dimensão '", dimensao, "' mistura fontes com e sem `ano`. ",
            "As sem ano ficam de fora da consolidação automática: juntá-las ",
            "só por município replicaria valores em todos os anos.",
            call. = FALSE)
    partes <- partes[tem_ano]
  }
  # Achado 79: `chaves` era calculado a partir do vetor `tem_ano` ANTIGO, de
  # antes da filtragem. Depois de descartar as fontes sem `ano`, todas as que
  # sobraram têm `ano` — mas `all(tem_ano)` continuava FALSE, e a consolidação
  # juntava só por município, perdendo a dimensão temporal em silêncio.
  tem_ano <- vapply(partes, function(p) "ano" %in% names(p), logical(1))
  chaves <- if (all(tem_ano)) c("id_municipio", "ano") else "id_municipio"

  resultado <- partes[[1]]
  if (length(partes) > 1) {
    for (i in 2:length(partes)) {
      resultado <- mape_join(
        resultado, partes[[i]], by = chaves, tipo = tipo,
        relationship = "one-to-one",
        nome = paste0(dimensao, " + ", basename(names(partes)[i]))
      )
    }
  }

  resultado <- resultado[do.call(order, resultado[, chaves, drop = FALSE]), ]
  mape_validar_chave(resultado, chaves)

  if (publicar) {
    # A guarda de perda pode barrar a gravação. Quando barra, o que falta é
    # sempre uma entrada — uma fonte não publicada, ou a expansão do painel que
    # esta função não faz —, e não a tabela publicada. A mensagem nomeia as
    # fontes usadas para que o diagnóstico comece no lugar certo.
    tryCatch(
      mape_escrever_tabela(resultado, dimensao, validar = TRUE,
                           camada = "dimensao",
                           permitir_perda = permitir_perda,
                           motivo_perda = motivo_perda),
      error = function(e) {
        stop("Não dá para publicar a dimensão '", dimensao, "'.\n\n",
             conditionMessage(e), "\n\n",
             "Consolidei a partir de ", length(fontes), " fonte(s): ",
             paste(basename(fontes), collapse = ", "), ".\n",
             "mape_consolidar_dimensao() junta as fontes e para aí — ela NÃO ",
             "expande o painel município x ano.\n",
             "Se a dimensão publicada tem o painel expandido e as fontes estão ",
             "compactadas, a consolidação não a reproduz, e é isso que a guarda ",
             "está dizendo.\n",
             "Para inspecionar sem gravar: mape_consolidar_dimensao(\"",
             dimensao, "\", publicar = FALSE).", call. = FALSE)
      }
    )
  }
  resultado
}

#' Avisa que uma dimensão ficou de fora da base larga, e por quê
#'
#' Achado 11: aqui havia dois `next` nus. `15_dados_historicos` era descartada em
#' silêncio, e por isso a base larga tem 423 colunas e 15 dimensões enquanto o
#' README, o CLAUDE.md e o `docs/` anunciavam 440 e 16. Quem montava a base não
#' tinha como saber que faltava uma dimensão inteira.
#'
#' @param d Slug da dimensão.
#' @return Invisivelmente, NULL.
mape_avisar_fora_da_larga <- function(d) {
  n <- tryCatch({
    x <- mape_ler_tabela(d, camada = "dimensao")
    k <- x$id_municipio
    sum(duplicated(k))
  }, error = function(e) NA_integer_)

  message("[", d, "] FORA da base larga: é uma tabela transversal, sem coluna ",
          "`ano`. Juntá-la por município replicaria os valores em todos os anos ",
          "do painel, que é o defeito que a base larga existe para não ter.",
          if (!is.na(n) && n > 0)
            paste0(" Ela também tem ", n, " chave(s) duplicada(s) por município, ",
                   "que a guarda de chave desta função não vê justamente porque ",
                   "a dimensão sai antes.")
          else "",
          " Leia-a com mape_ler(\"", d, "\").")
  invisible(NULL)
}

#' Reconstrói a base larga a partir das tabelas modulares
#'
#' A base larga deixa de ser o produto principal e passa a ser gerada. Ela tem
#' três consumidores de código e um artigo, então eliminá-la agora quebraria
#' tudo isso em troca de nada; como artefato derivado, custa um comando.
#'
#' @param dimensoes Slugs a incluir. NULL usa todas as publicadas.
#' @param anos Faixa de anos. NULL usa a de config/parametros.yml.
#' @param flags Se TRUE, recria as colunas dimensao_<nome>, agora como 0/1 e
#'   derivadas da presença real na tabela de fonte.
#' @return A base larga.
mape_montar_base_larga <- function(dimensoes = NULL, anos = NULL, flags = FALSE,
                                   deduplicar = FALSE) {
  if (is.null(anos)) anos <- mape_anos_painel()
  disponiveis <- list.files(mape_caminho("dados", "dimensao"),
                            pattern = "[.]parquet$")
  disponiveis <- sub("[.]parquet$", "", disponiveis)
  if (is.null(dimensoes)) dimensoes <- disponiveis
  dimensoes <- intersect(dimensoes, disponiveis)
  if (!length(dimensoes)) stop("Nenhuma dimensão publicada.", call. = FALSE)

  base <- mape_esqueleto_painel(anos = anos, incluir_flag_instalado = FALSE)
  dir_mun <- mape_ler_tabela("00_diretorios/municipios")
  base <- mape_join(base, dir_mun, by = "id_municipio", tipo = "left",
                    relationship = "many-to-one", nome = "esqueleto + diretorio")

  # Antes de juntar qualquer coisa, confere a unicidade da chave em cada
  # dimensão. O legado não faz isso: ele junta, a chave duplicada multiplica as
  # linhas, e um distinct() cego no fim apaga a evidência. Aqui a montagem PARA
  # e diz qual dimensão é a responsável.
  problematicas <- character()
  if (deduplicar) problematicas <- character(0)
  for (d in if (deduplicar) character(0) else sort(dimensoes)) {
    parte <- mape_ler_tabela(d, camada = "dimensao")
    if (!"ano" %in% names(parte)) { mape_avisar_fora_da_larga(d); next }
    k <- paste(parte$id_municipio, parte$ano)
    if (anyDuplicated(k)) {
      problematicas <- c(problematicas, sprintf(
        "%s (%d chaves duplicadas, %d linhas excedentes)",
        d, length(unique(k[duplicated(k)])), sum(duplicated(k))))
    }
  }
  if (length(problematicas)) {
    stop("Não dá para montar a base larga: há dimensão com chave duplicada.\n",
         paste0("  - ", problematicas, collapse = "\n"),
         "\n\nJuntar assim multiplicaria linhas, que é o defeito do legado. ",
         "Resolva na origem, ou passe deduplicar = TRUE para aceitar a primeira ",
         "ocorrência de cada chave — o que é uma escolha arbitrária e fica ",
         "registrada no log da execução (achado 98: não existe relatório).",
         call. = FALSE)
  }

  for (d in sort(dimensoes)) {
    parte <- mape_ler_tabela(d, camada = "dimensao")
    if (!"ano" %in% names(parte)) { mape_avisar_fora_da_larga(d); next }
    if (deduplicar) {
      k <- paste(parte$id_municipio, parte$ano)
      if (anyDuplicated(k)) {
        message("[", d, "] deduplicando ", sum(duplicated(k)),
                " linha(s) excedente(s): fica a PRIMEIRA ocorrência de cada chave")
        parte <- parte[!duplicated(k), ]
      }
    }
    if (flags) parte[[paste0("dimensao_", d)]] <- 1L
    base <- mape_join(base, parte, by = c("id_municipio", "ano"), tipo = "left",
                      relationship = "one-to-one", nome = paste0("larga + ", d))
    if (flags) {
      col <- paste0("dimensao_", d)
      base[[col]][is.na(base[[col]])] <- 0L
    }
  }
  base
}

#' Compara uma dimensão reconstruída com a base publicada
#'
#' O critério de aceitação global: nenhuma dimensão é promovida sem passar por
#' aqui. As diferenças são classificadas em três categorias, e só a terceira
#' bloqueia.
#'
#' O teste é conclusivo porque a migração parte dos artefatos existentes, sem
#' reextrair. Com o dado de entrada congelado, só o código muda, e toda
#' diferença é atribuível a ele.
#'
#' @param dimensao Slug da dimensão.
#' @param referencia Caminho do .RDa da base publicada.
#' @param esperadas Data frame com as diferenças reivindicadas a priori, com as
#'   colunas `coluna` e `motivo`. Reivindicar depois de ver o resultado
#'   invalidaria o teste.
#' @return Invisivelmente, o relatório de diferenças.
mape_paridade <- function(dimensao, referencia = NULL, esperadas = NULL) {
  if (is.null(referencia)) {
    # A referência vive em qa/referencia/, e não mais dentro da árvore legada.
    # São 56 MB contra os 18 GB do legado inteiro — a paridade nunca precisou
    # de mais que este arquivo, e enquanto ela apontava para lá dentro o
    # repositório ficava amarrado a uma pasta que ele existe para substituir.
    #
    # O caminho antigo continua sendo tentado, para que quem ainda tenha o
    # legado na máquina não precise fazer nada.
    candidatos <- c(
      mape_caminho("qa", "referencia", "base_municipios_brasileiros.RDa"),
      mape_caminho("mape_municipios", "4 Base completa",
                   "base_municipios_brasileiros.RDa")
    )
    referencia <- candidatos[file.exists(candidatos)][1]
    if (is.na(referencia)) {
      stop("Base de referência do teste de paridade não encontrada.\n",
           "Procurei em:\n  ", paste(candidatos, collapse = "\n  "), "\n\n",
           "Ela não é versionada (56 MB) e vive no Drive compartilhado do MAPE,\n",
           "em 'mape_municipios/4 Base completa/'. Copie-a para qa/referencia/.\n",
           "Sem ela, a validação continua funcionando; só a paridade contra o\n",
           "pipeline antigo fica indisponível.", call. = FALSE)
    }
  }
  if (!file.exists(referencia)) {
    stop("Base de referência não encontrada: ", referencia, call. = FALSE)
  }

  # As correções são reivindicadas ANTES de rodar, em qa/paridade_esperada.csv.
  # Um teste em que se pode justificar qualquer diferença depois de ver o
  # resultado não testa nada. A linha com coluna "*" vale para a dimensão
  # inteira, e serve para correções que afetam muitas colunas de uma vez, como
  # a recuperação de tipo na Segurança.
  if (is.null(esperadas)) {
    arq <- mape_caminho("qa", "paridade_esperada.csv")
    if (file.exists(arq)) {
      todas <- utils::read.csv(arq, stringsAsFactors = FALSE, encoding = "UTF-8")
      esperadas <- todas[todas$dimensao == dimensao, c("coluna", "motivo")]
    }
  }
  curinga <- if (!is.null(esperadas) && "*" %in% esperadas$coluna) {
    esperadas$motivo[esperadas$coluna == "*"][1]
  } else NA_character_

  amb <- new.env()
  nome <- load(referencia, envir = amb)
  antiga <- get(nome, envir = amb)

  # As colunas da dimensão na base publicada saem do dicionário, que registra
  # a que dimensão cada variável pertence.
  vars <- mape_dicionario("variaveis")
  cols_antigas <- vars$nome_legado[vars$dimensao == dimensao &
                                     !is.na(vars$dimensao) &
                                     vars$nome_legado %in% names(antiga)]
  mapa <- stats::setNames(vars$nome_canonico[match(cols_antigas, vars$nome_legado)],
                          cols_antigas)

  nova <- mape_ler_tabela(dimensao, camada = "dimensao")

  chave_antiga <- antiga[, c("id_municipio", "ano")]
  chave_antiga$id_municipio <- mape_como_codigo(chave_antiga$id_municipio, avisar = FALSE)
  chave_antiga$ano <- mape_como_inteiro(chave_antiga$ano)

  achados <- list()
  reg <- function(coluna, classe, descricao) {
    achados[[length(achados) + 1]] <<- data.frame(
      dimensao = dimensao, coluna = coluna, classe = classe,
      descricao = descricao, stringsAsFactors = FALSE)
  }

  # Achado 67: a paridade comparava valor a valor e NUNCA o conjunto de chaves,
  # então 33.291 linhas publicadas jamais foram confrontadas com coisa alguma. O
  # `merge` é inner: linha que só existe de um lado simplesmente não entra na
  # comparação, e some do relatório junto.
  k_ant <- paste(chave_antiga$id_municipio, chave_antiga$ano)
  k_nov <- paste(nova$id_municipio, nova$ano)
  so_no_novo <- length(setdiff(k_nov, k_ant))
  so_no_antigo <- length(setdiff(k_ant, k_nov))
  if (so_no_novo > 0 || so_no_antigo > 0) {
    reg("(conjunto de chaves)",
        if (is.na(curinga)) "c_nao_explicada" else "a_correcao_reivindicada",
        paste0(so_no_novo, " chave(s) só no publicado e ", so_no_antigo,
               " só na referência, de ", length(unique(k_nov)), " e ",
               length(unique(k_ant)), ". 'Zero diferenças não explicadas' não ",
               "cobre linha que não existe dos dois lados.",
               if (!is.na(curinga)) paste0(" ", curinga) else ""))
  }

  for (col_antiga in cols_antigas) {
    col_nova <- mapa[[col_antiga]]
    if (!col_nova %in% names(nova)) {
      motivo_aus <- if (!is.null(esperadas) && col_antiga %in% esperadas$coluna) {
        esperadas$motivo[esperadas$coluna == col_antiga][1]
      } else NA_character_
      reg(col_antiga,
          if (is.na(motivo_aus)) "c_nao_explicada" else "a_correcao_reivindicada",
          if (is.na(motivo_aus))
            paste0("coluna ausente na tabela nova (esperava '", col_nova, "')")
          else paste0("removida de propósito: ", motivo_aus))
      next
    }
    if (col_antiga != col_nova) {
      reg(col_antiga, "b_renomeacao", paste0("renomeada para '", col_nova, "'"))
    }

    # Compara pelos pares de chave presentes nos dois lados.
    va <- data.frame(chave_antiga, v = antiga[[col_antiga]], stringsAsFactors = FALSE)
    vn <- data.frame(nova[, c("id_municipio", "ano")], v = nova[[col_nova]],
                     stringsAsFactors = FALSE)
    m <- merge(va, vn, by = c("id_municipio", "ano"), suffixes = c("_a", "_n"))
    if (!nrow(m)) {
      reg(col_antiga, "c_nao_explicada", "nenhuma chave em comum")
      next
    }
    a <- m$v_a; n <- m$v_n
    if (is.numeric(a) || is.numeric(n)) {
      a <- suppressWarnings(as.numeric(a)); n <- suppressWarnings(as.numeric(n))
      tol <- mape_param("qa.tolerancia_paridade")
      difere <- !is.na(a) & !is.na(n) &
        abs(a - n) > tol * pmax(1, abs(a))
    } else {
      difere <- !is.na(a) & !is.na(n) & as.character(a) != as.character(n)
    }

    # Achado 24: a expressão acima exige que os DOIS lados tenham valor, então
    # uma coluna que virou NA inteira passava como "sem diferença". Ausência
    # tratada como igualdade é o modo mais silencioso de perder uma coluna.
    # Os dois sentidos são contados separadamente porque significam coisas
    # diferentes: valor -> NA é perda, NA -> valor é fabricação.
    n_valor_para_na <- sum(!is.na(a) & is.na(n))
    n_na_para_valor <- sum(is.na(a) & !is.na(n))
    if (n_valor_para_na > 0 || n_na_para_valor > 0) {
      motivo_na <- if (!is.null(esperadas) && col_antiga %in% esperadas$coluna) {
        esperadas$motivo[esperadas$coluna == col_antiga][1]
      } else curinga
      reg(col_antiga,
          if (is.na(motivo_na)) "c_nao_explicada" else "a_correcao_reivindicada",
          paste0(n_valor_para_na, " célula(s) tinham valor e viraram NA, ",
                 n_na_para_valor, " eram NA e ganharam valor, de ", nrow(m),
                 if (!is.na(motivo_na)) paste0(": ", motivo_na) else ""))
    }

    n_dif <- sum(difere)
    if (n_dif > 0) {
      motivo <- if (!is.null(esperadas) && col_antiga %in% esperadas$coluna) {
        esperadas$motivo[esperadas$coluna == col_antiga][1]
      } else curinga
      reg(col_antiga,
          if (is.na(motivo)) "c_nao_explicada" else "a_correcao_reivindicada",
          paste0(n_dif, " de ", nrow(m), " valores diferem",
                 if (!is.na(motivo)) paste0(": ", motivo) else ""))
    }
  }

  # Achado 66: o curinga `*` dava imunidade a 52,5% das colunas comparadas, e
  # cinco das seis linhas com `*` não absorviam diferença nenhuma. Dispensa
  # inerte é pior que dispensa nenhuma: ela parece cobertura.
  if (!is.na(curinga)) {
    absorveu <- length(achados) > 0 &&
      any(vapply(achados, function(a) a$classe == "a_correcao_reivindicada", logical(1)))
    if (!absorveu) {
      warning("A dimensão '", dimensao, "' tem uma linha curinga (coluna = \"*\") ",
              "em qa/paridade_esperada.csv que NÃO absorveu diferença nenhuma. ",
              "Ela dispensa tudo e não dispensa nada — apague-a, ou troque pelos ",
              "nomes explícitos das colunas que ela deveria cobrir.",
              call. = FALSE)
    }
  }

  res <- if (length(achados)) do.call(rbind, achados) else
    data.frame(dimensao = character(), coluna = character(),
               classe = character(), descricao = character(),
               stringsAsFactors = FALSE)

  destino <- mape_caminho("qa", paste0("paridade_", dimensao, ".md"))
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  n_c <- sum(res$classe == "c_nao_explicada")
  writeLines(c(
    paste0("# Paridade — ", dimensao), "",
    paste0("Gerado em ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "."),
    paste0("Referência: `", basename(referencia), "` (tag `dados-v1.0.0-legado`)."), "",
    paste0("Colunas comparadas: ", length(cols_antigas), ". ",
           "Diferenças não explicadas: ", n_c, "."), "",
    if (!nrow(res)) "Nenhuma diferença. A reconstrução é idêntica ao publicado." else
      c("| coluna | classe | descrição |", "|---|---|---|",
        paste0("| `", res$coluna, "` | ", res$classe, " | ",
               gsub("[|]", "/", res$descricao), " |")),
    ""), destino, useBytes = TRUE)

  message(sprintf("[paridade] %s: %d coluna(s) comparada(s), %d diferença(s) não explicada(s)",
                  dimensao, length(cols_antigas), n_c))
  if (n_c > 0) {
    for (i in which(res$classe == "c_nao_explicada")) {
      message("      NÃO EXPLICADA  ", res$coluna[i], ": ", res$descricao[i])
    }
  }
  invisible(res)
}
