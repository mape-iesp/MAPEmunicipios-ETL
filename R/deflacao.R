# Deflação -------------------------------------------------------------------
#
# No legado, oito scripts chamam ipca() com a base "12/2023" escrita dentro do
# código e gravam o resultado POR CIMA da coluna original, com o mesmo nome. As
# três consequências se somam: o valor nominal não existe mais em lugar nenhum
# do repositório, atualizar a base de deflação mudaria retroativamente números
# já publicados, e nada registra que a operação aconteceu — a palavra IPCA
# sequer aparece no documento de metadados.
#
# A regra nova: o canônico é o nominal, a deflação cria coluna NOVA, e a base
# vive em config/parametros.yml.

#' Deflaciona colunas monetárias, criando colunas novas
#'
#' @param x Data frame.
#' @param cols Colunas a deflacionar. Devem terminar em `_brl_nominal`; o
#'   sufixo é trocado pelo de deflação no resultado.
#' @param data_ref Nome da coluna que dá a data de referência de cada valor, ou
#'   um vetor de datas. Aceita uma coluna de ano, que vira 31 de dezembro.
#'   Passar isto explicitamente é o que corrige o defeito da dimensão Corrupção,
#'   onde o deflator usa o ano da fiscalização quando deveria usar o ano do
#'   repasse — a coluna certa existe no bruto e é ignorada.
#' @param base Mês-base no formato "MM/AAAA". Se NULL, usa o parâmetro.
#' @param sufixo Sufixo das colunas criadas. Se NULL, usa o parâmetro.
#' @return O data frame com as colunas deflacionadas acrescentadas.
mape_deflacionar <- function(x, cols, data_ref = "ano", base = NULL,
                             sufixo = NULL) {
  stopifnot(is.data.frame(x))
  if (is.null(base))   base   <- mape_param("deflator_base")
  if (is.null(sufixo)) sufixo <- mape_param("deflator_sufixo")

  faltando <- setdiff(cols, names(x))
  if (length(faltando)) {
    stop("Colunas a deflacionar ausentes: ", paste(faltando, collapse = ", "),
         call. = FALSE)
  }

  # Data de referência: uma coluna de ano vira 31/12 daquele ano, que é a
  # convenção que o legado usa.
  if (is.character(data_ref) && length(data_ref) == 1 && data_ref %in% names(x)) {
    v <- x[[data_ref]]
    datas <- if (inherits(v, "Date")) v else
      as.Date(paste0(mape_como_inteiro(v), "-12-31"))
  } else {
    datas <- as.Date(data_ref)
  }
  if (all(is.na(datas))) {
    stop("Todas as datas de referência são nulas; não dá para deflacionar.",
         call. = FALSE)
  }

  for (col in cols) {
    novo <- if (grepl("_brl_nominal$", col)) {
      sub("_brl_nominal$", paste0("_", sufixo), col)
    } else {
      paste0(col, "_", sufixo)
    }
    if (novo %in% names(x)) {
      warning("Coluna '", novo, "' já existe e será sobrescrita.", call. = FALSE)
    }
    x[[novo]] <- deflateBR::ipca(x[[col]], datas, base)
  }
  x
}

#' Marca colunas monetárias como nominais
#'
#' Conveniência para o script de fonte: renomeia as colunas acrescentando o
#' sufixo `_brl_nominal`, deixando explícito no nome que o valor é corrente.
#'
#' @param x Data frame.
#' @param cols Colunas monetárias.
#' @return O data frame com as colunas renomeadas.
mape_marcar_nominal <- function(x, cols) {
  for (col in intersect(cols, names(x))) {
    if (!grepl("_brl_nominal$", col)) {
      names(x)[names(x) == col] <- paste0(col, "_brl_nominal")
    }
  }
  x
}
