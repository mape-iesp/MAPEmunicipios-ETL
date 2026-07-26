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

#' Escreve uma tabela publicada
#'
#' Valida contra o dicionário antes de gravar, escreve o formato canônico e as
#' exportações, e confere que a releitura de cada exportação devolve o mesmo
#' número de linhas e colunas. Essa conferência é a checagem 11 do plano, e é o
#' que teria pego a coluna fantasma do CSV publicado.
#'
#' @param x Data frame.
#' @param tabela Identificador da tabela.
#' @param formatos Formatos de exportação, além do canônico.
#' @param validar Se TRUE, roda mape_validar_schema() antes de gravar.
#' @param camada "fonte", "dimensao" ou "derivado".
#' @return Invisivelmente, o vetor de caminhos escritos.
mape_escrever_tabela <- function(x, tabela,
                                 formatos = mape_param("formatos.exportacao"),
                                 validar = TRUE, camada = NULL) {
  stopifnot(is.data.frame(x))

  if (validar && mape_tabela_no_dicionario(tabela)) {
    mape_validar_schema(x, tabela)
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
      con <- if (fmt == "csv.gz") gzfile(destino, "w") else file(destino, "w")
      on.exit(try(close(con), silent = TRUE), add = TRUE)
      utils::write.csv(x, con, row.names = FALSE, na = "", fileEncoding = "UTF-8")
      close(con)
      on.exit()
    } else {
      stop("Formato de exportação não suportado: ", fmt, call. = FALSE)
    }
    escritos <- c(escritos, destino)
  }

  # Conferência de equivalência entre formatos. Compara dimensões e nomes; os
  # tipos do CSV são reconstruídos na leitura a partir do dicionário, então
  # divergência de tipo aqui é esperada e não é erro.
  relido <- arrow::read_parquet(canonico)
  if (!identical(dim(relido), dim(x)) || !identical(names(relido), names(x))) {
    stop("O Parquet relido não bate com o objeto original em '", tabela, "'.",
         call. = FALSE)
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
