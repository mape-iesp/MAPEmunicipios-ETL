# Valores sentinela ----------------------------------------------------------
#
# Fontes brasileiras costumam codificar ausência de dado com strings ou números
# convencionados em vez de deixar o campo vazio. Quando isso não é tratado, a
# coluna inteira vira texto e o consumidor descobre sozinho.
#
# O caso testemunha está no AdaptaBrasil: indice_risco_seca é numérica e
# indice_risco_inundacoes_enxurradas é texto, vindas da mesma fonte e do mesmo
# bloco de código, porque a segunda tem "NaoDisponivel" em algumas linhas. O
# consumidor remenda isso à mão dentro do próprio script de análise.

#' Converte valores sentinela em NA
#'
#' @param x Data frame ou vetor.
#' @param cols Colunas a tratar. Se NULL, trata todas.
#' @param texto Vetor de strings sentinela. Se NULL, usa config/parametros.yml.
#' @param numerico Vetor de números sentinela. Se NULL, usa o arquivo de
#'   parâmetros.
#' @param converter_numerico Se TRUE, tenta converter para numérico as colunas
#'   de texto que, depois de removidos os sentinelas, só contêm números. É isso
#'   que recupera o tipo de indice_risco_inundacoes_enxurradas.
#' @return O objeto com os sentinelas trocados por NA.
mape_tratar_sentinelas <- function(x, cols = NULL, texto = NULL,
                                   numerico = NULL,
                                   converter_numerico = TRUE) {
  if (is.null(texto))    texto    <- mape_param("sentinelas.texto")
  if (is.null(numerico)) numerico <- mape_param("sentinelas.numerico")

  limpar_vetor <- function(v) {
    if (is.character(v) || is.factor(v)) {
      v <- as.character(v)
      # Compara sem espaços nas pontas e sem diferenciar caixa, porque as
      # mesmas convenções aparecem escritas de formas diferentes na mesma base.
      alvo <- tolower(trimws(v))
      v[alvo %in% tolower(texto)] <- NA_character_

      if (converter_numerico && any(!is.na(v))) {
        # Aceita vírgula decimal, que é como planilhas brasileiras exportam.
        tentativa <- suppressWarnings(as.numeric(gsub(",", ".", v, fixed = TRUE)))
        if (all(is.na(tentativa) == is.na(v))) v <- tentativa
      }
      return(v)
    }
    if (is.numeric(v)) {
      v[v %in% numerico] <- NA
      return(v)
    }
    v
  }

  if (!is.data.frame(x)) return(limpar_vetor(x))

  alvos <- if (is.null(cols)) names(x) else intersect(cols, names(x))
  for (nm in alvos) x[[nm]] <- limpar_vetor(x[[nm]])
  x
}

#' Relata quais sentinelas ainda existem numa tabela
#'
#' Usada pela validação (checagem 8). Devolve um data frame com uma linha por
#' coluna que ainda contém sentinela não convertido, para que o problema apareça
#' no relatório em vez de virar NA silencioso lá na frente.
#'
#' @param x Data frame.
#' @return Data frame com coluna, sentinela e contagem. Vazio se estiver limpo.
mape_detectar_sentinelas <- function(x) {
  texto    <- tolower(mape_param("sentinelas.texto"))
  numerico <- mape_param("sentinelas.numerico")
  achados  <- list()

  for (nm in names(x)) {
    v <- x[[nm]]
    if (is.character(v) || is.factor(v)) {
      alvo <- tolower(trimws(as.character(v)))
      encontrados <- intersect(unique(alvo), texto)
      for (s in encontrados) {
        achados[[length(achados) + 1]] <- data.frame(
          coluna = nm, sentinela = s, n = sum(alvo == s, na.rm = TRUE),
          stringsAsFactors = FALSE
        )
      }
    } else if (is.numeric(v)) {
      encontrados <- intersect(unique(v), numerico)
      for (s in encontrados) {
        achados[[length(achados) + 1]] <- data.frame(
          coluna = nm, sentinela = as.character(s), n = sum(v == s, na.rm = TRUE),
          stringsAsFactors = FALSE
        )
      }
    }
  }

  if (!length(achados)) {
    return(data.frame(coluna = character(), sentinela = character(),
                      n = integer(), stringsAsFactors = FALSE))
  }
  do.call(rbind, achados)
}
