# Leitura e escrita de tabelas -----------------------------------------------
#
# O formato canônico é Parquet, e a exportação é CSV comprimido. O .xlsx está
# fora do pipeline: além de não preservar tipos, o legado depende de um
# acidente de serialização dele para funcionar (a coluna ano do PIB vira texto
# ao passar pelo xlsx, e é isso que faz uma das junções não quebrar).
#
# Toda escrita passa por aqui, o que garante três coisas que o legado não
# garantia: row.names = FALSE, schema conferido contra o dicionário, e o
# registro do que foi gravado.

#' Caminho de uma tabela publicada
#'
#' @param tabela Identificador. "00_diretorios/municipios" para uma tabela de
#'   fonte, ou "03_meio_ambiente" para uma tabela de dimensão.
#' @param formato Extensão desejada.
#' @param camada "fonte", "dimensao" ou "derivado".
#' @return Caminho absoluto.
mape_caminho_tabela <- function(tabela, formato = "parquet", camada = NULL) {
  if (is.null(camada)) camada <- if (grepl("/", tabela)) "fonte" else "dimensao"
  mape_caminho("dados", camada, paste0(tabela, ".", formato))
}

#' Mede as quatro grandezas que uma sobrescrita não pode reduzir
#'
#' Linhas, colunas, chaves distintas e municípios distintos. É o vetor que
#' mape_conferir_perda() compara antes de deixar gravar por cima.
#'
#' @param x Data frame.
#' @return Lista com n_linhas, n_colunas, n_chaves, n_municipios e colunas.
mape_medir_tabela <- function(x) {
  chaves <- intersect(c("id_municipio", "ano"), names(x))
  list(
    n_linhas = nrow(x),
    n_colunas = ncol(x),
    n_chaves = if (length(chaves)) nrow(unique(x[, chaves, drop = FALSE])) else NA_integer_,
    n_municipios = if ("id_municipio" %in% names(x)) length(unique(x$id_municipio)) else NA_integer_,
    colunas = names(x)
  )
}

#' Impede que uma sobrescrita destrua dado publicado
#'
#' Antes de gravar por cima de uma tabela que já existe, compara as quatro
#' grandezas de mape_medir_tabela(). Se a nova perder qualquer uma delas, para
#' com erro e mostra o diff.
#'
#' Isto é o achado crítico nº 6 da auditoria de 26/07/2026:
#' tar_make(dim_11_transportes) trocava 183.814 linhas e 5.570 municípios por
#' 929 linhas e 133 municípios, sem que nada barrasse a gravação. A perda era
#' possível porque ninguém comparava antes de sobrescrever.
#'
#' A perda continua sendo possível — há casos legítimos, como remover uma coluna
#' que o dicionário mandou remover. Mas passa a exigir declaração explícita e
#' motivo registrado, que é a diferença entre uma decisão e um acidente.
#'
#' @param x A tabela nova.
#' @param tabela Identificador da tabela.
#' @param camada "fonte", "dimensao" ou "derivado".
#' @param permitir_perda Se TRUE, autoriza a perda. Exige motivo.
#' @param motivo_perda Texto que justifica a perda. Registrado em
#'   qa/perdas_autorizadas.csv.
#' @return Invisivelmente, TRUE se pode gravar.
mape_conferir_perda <- function(x, tabela, camada = NULL,
                                permitir_perda = FALSE, motivo_perda = NULL) {
  canonico <- mape_caminho_tabela(tabela, mape_param("formatos.canonico"), camada)
  if (!file.exists(canonico)) return(invisible(TRUE))

  antes <- mape_medir_tabela(as.data.frame(arrow::read_parquet(canonico)))
  depois <- mape_medir_tabela(x)

  perdas <- character()
  for (m in c("n_linhas", "n_colunas", "n_chaves", "n_municipios")) {
    a <- antes[[m]]; d <- depois[[m]]
    if (is.na(a) || is.na(d)) next
    if (d < a) {
      fmt <- function(v) formatC(v, format = "d", big.mark = ".", decimal.mark = ",")
      perdas <- c(perdas, sprintf("  %-13s %s -> %s  (perde %s, %.2f%%)",
                                  m, fmt(a), fmt(d), fmt(a - d), 100 * (a - d) / a))
    }
  }
  sumidas <- setdiff(antes$colunas, depois$colunas)
  if (length(sumidas)) {
    perdas <- c(perdas, paste0("  colunas que somem: ", paste(sumidas, collapse = ", ")))
  }

  if (!length(perdas)) return(invisible(TRUE))

  if (!permitir_perda) {
    stop("Gravar '", tabela, "' destruiria dado publicado. A gravação foi barrada.\n\n",
         paste(perdas, collapse = "\n"), "\n\n",
         "Se a tabela nova está certa e a publicada é que estava errada, ",
         "grave com permitir_perda = TRUE e um motivo_perda.\n",
         "Se não está, a entrada que falta é o que precisa ser consertado — ",
         "não a tabela publicada.", call. = FALSE)
  }
  if (is.null(motivo_perda) || !nzchar(trimws(motivo_perda))) {
    stop("permitir_perda = TRUE exige motivo_perda: a perda fica registrada em ",
         "qa/perdas_autorizadas.csv e sem motivo o registro não serve para nada.",
         call. = FALSE)
  }

  registro <- data.frame(
    data = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    tabela = tabela,
    n_linhas_antes = antes$n_linhas, n_linhas_depois = depois$n_linhas,
    n_colunas_antes = antes$n_colunas, n_colunas_depois = depois$n_colunas,
    n_chaves_antes = antes$n_chaves, n_chaves_depois = depois$n_chaves,
    n_municipios_antes = antes$n_municipios, n_municipios_depois = depois$n_municipios,
    colunas_removidas = paste(sumidas, collapse = " "),
    motivo = motivo_perda,
    stringsAsFactors = FALSE
  )
  destino <- mape_caminho("qa", "perdas_autorizadas.csv")
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  utils::write.table(registro, destino, sep = ",", row.names = FALSE,
                     col.names = !file.exists(destino), append = file.exists(destino),
                     qmethod = "double", fileEncoding = "UTF-8")
  message("[perda autorizada] ", tabela, ": ", motivo_perda)
  invisible(TRUE)
}

#' Escreve uma tabela publicada
#'
#' Valida contra o dicionário antes de gravar, confere que a gravação não
#' destrói dado publicado, escreve o formato canônico e as exportações, e
#' confere que a releitura de cada exportação devolve o mesmo número de linhas e
#' colunas. Essa conferência é a checagem 11 do plano, e é o que teria pego a
#' coluna fantasma do CSV publicado.
#'
#' @param x Data frame.
#' @param tabela Identificador da tabela.
#' @param formatos Formatos de exportação, além do canônico.
#' @param validar Se TRUE, roda mape_validar_schema() antes de gravar.
#' @param camada "fonte", "dimensao" ou "derivado".
#' @param permitir_perda Se TRUE, autoriza sobrescrever perdendo linha, coluna,
#'   chave ou município. Exige motivo_perda.
#' @param motivo_perda Justificativa da perda, registrada em
#'   qa/perdas_autorizadas.csv.
#' @return Invisivelmente, o vetor de caminhos escritos.
mape_escrever_tabela <- function(x, tabela,
                                 formatos = mape_param("formatos.exportacao"),
                                 validar = TRUE, camada = NULL,
                                 permitir_perda = FALSE, motivo_perda = NULL) {
  stopifnot(is.data.frame(x))

  # A guarda de perda vem ANTES da validação de schema: uma tabela truncada pode
  # passar no schema (os tipos continuam certos) e ainda assim destruir o painel.
  mape_conferir_perda(x, tabela, camada, permitir_perda, motivo_perda)

  # Achado 22: "erro impede a publicação, sem exceção" era falso em todos os
  # caminhos de escrita, porque esta função chamava mape_validar_schema() — uma
  # checagem de tipos — e nunca mape_validar_tabela(), que é a bateria de
  # qualidade. As doze checagens existiam como função que ninguém invocava na
  # publicação. Agora o portão é de verdade: erro não reivindicado para a
  # gravação antes de qualquer write_parquet.
  if (validar) {
    if (mape_tabela_no_dicionario(tabela)) {
      mape_validar_tabela(x, tabela, erro = TRUE)
    } else {
      mape_validar_schema(x, tabela)
    }
  }

  canonico <- mape_caminho_tabela(tabela, mape_param("formatos.canonico"), camada)
  dir.create(dirname(canonico), recursive = TRUE, showWarnings = FALSE)
  arrow::write_parquet(x, canonico)
  escritos <- canonico

  for (fmt in formatos) {
    destino <- mape_caminho_tabela(tabela, fmt, camada)
    if (fmt %in% c("csv", "csv.gz")) {
      # row.names = FALSE não é opcional: é a ausência dele que produz a coluna
      # sem nome no CSV publicado hoje.
      # Achado 99: `fileEncoding` é IGNORADO pelo R quando o destino é uma
      # conexão já aberta — o argumento só vale quando write.csv() abre o
      # arquivo ele mesmo. O csv.gz saía na codificação nativa da sessão, e
      # numa sessão latin-1 os acentos dos nomes de município sairiam
      # corrompidos. A codificação vai na abertura da conexão, que é onde o R
      # de fato a lê.
      con <- if (fmt == "csv.gz") gzfile(destino, "w", encoding = "UTF-8")
             else file(destino, "w", encoding = "UTF-8")
      on.exit(try(close(con), silent = TRUE), add = TRUE)
      utils::write.csv(x, con, row.names = FALSE, na = "")
      close(con)
      on.exit()
    } else {
      stop("Formato de exportação não suportado: ", fmt, call. = FALSE)
    }
    escritos <- c(escritos, destino)
  }

  # Conferência de equivalência entre formatos — a checagem 11 do plano.
  #
  # Achado 39: ela existia só no nome. O código relia o Parquet contra si mesmo
  # e nunca abria nenhuma das exportações, então um csv.gz com coluna fantasma,
  # truncado ou com aspas quebradas passava direto. A demonstração do verificador
  # foi escrever o CSV sem row.names = FALSE: o CSV saiu com uma coluna "X" a
  # mais e a guarda continuou dizendo que estava tudo bem.
  #
  # Agora TODOS os caminhos acumulados em `escritos` são relidos. O CSV é lido
  # como texto (colClasses = "character") de propósito: os tipos do CSV são
  # reconstruídos a partir do dicionário na leitura normal, então exigir tipo
  # aqui seria exigir o impossível — mas número de linhas, nomes e ordem das
  # colunas têm de bater, e é isso que pega truncamento, coluna fantasma e
  # newline embutido.
  for (caminho in escritos) {
    relido <- if (grepl("[.]parquet$", caminho)) {
      as.data.frame(arrow::read_parquet(caminho))
    } else {
      utils::read.csv(caminho, stringsAsFactors = FALSE, colClasses = "character",
                      check.names = FALSE)
    }
    if (nrow(relido) != nrow(x)) {
      stop("A releitura de '", basename(caminho), "' devolveu ", nrow(relido),
           " linha(s), e o objeto tem ", nrow(x), ".", call. = FALSE)
    }
    if (!identical(names(relido), names(x))) {
      so_no_arquivo <- setdiff(names(relido), names(x))
      so_no_objeto <- setdiff(names(x), names(relido))
      stop("A releitura de '", basename(caminho), "' não bate nos nomes de coluna.\n",
           if (length(so_no_arquivo)) paste0("  só no arquivo: ",
                                             paste(so_no_arquivo, collapse = ", "), "\n") else "",
           if (length(so_no_objeto)) paste0("  só no objeto: ",
                                            paste(so_no_objeto, collapse = ", "), "\n") else "",
           if (!length(so_no_arquivo) && !length(so_no_objeto))
             "  mesmos nomes, ordem diferente\n" else "",
           call. = FALSE)
    }
  }

  message("gravado: ", tabela, " (", nrow(x), " linhas x ", ncol(x),
          " colunas) -> ", paste(basename(escritos), collapse = ", "))
  invisible(escritos)
}

#' Lê uma tabela publicada
#'
#' @param tabela Identificador da tabela.
#' @param aplicar_tipos Se TRUE, reaplica os tipos declarados no dicionário.
#'   Só faz diferença ao ler CSV; o Parquet já os preserva.
#' @param camada "fonte", "dimensao" ou "derivado".
#' @return Data frame.
mape_ler_tabela <- function(tabela, aplicar_tipos = TRUE, camada = NULL) {
  canonico <- mape_caminho_tabela(tabela, mape_param("formatos.canonico"), camada)

  if (file.exists(canonico)) {
    x <- as.data.frame(arrow::read_parquet(canonico))
  } else {
    alternativa <- mape_caminho_tabela(tabela, "csv.gz", camada)
    if (!file.exists(alternativa)) {
      stop("Tabela '", tabela, "' não encontrada.\n",
           "Procurei em:\n  ", canonico, "\n  ", alternativa, "\n",
           "Rode targets::tar_make() para gerá-la.", call. = FALSE)
    }
    x <- utils::read.csv(alternativa, stringsAsFactors = FALSE,
                         colClasses = "character", encoding = "UTF-8")
    if (aplicar_tipos) x <- mape_aplicar_tipos(x, tabela)
  }
  x
}

#' Tamanho de um arquivo em MB
#'
#' Usada pela política de versionamento: acima do limiar, o arquivo vai para
#' release do GitHub em vez do repositório.
#'
#' @param caminho Caminho do arquivo.
#' @return Tamanho em MB.
mape_mb <- function(caminho) {
  as.numeric(file.info(caminho)$size) / 1024^2
}

#' Verifica se um arquivo pode ser versionado
#'
#' @param caminho Caminho do arquivo.
#' @return TRUE se estiver abaixo do limiar de qa.max_mb_versionavel.
mape_versionavel <- function(caminho) {
  mape_mb(caminho) <= mape_param("qa.max_mb_versionavel")
}
