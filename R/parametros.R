# Acesso aos parâmetros do projeto -------------------------------------------
#
# Tudo que é constante do pipeline vive em config/parametros.yml e é lido por
# mape_param(). Nenhuma constante deve ser reescrita dentro de um script.

#' Caminho absoluto a partir da raiz do repositório
#'
#' Envelopa here::here() para que nenhum script precise saber onde está. A raiz
#' é ancorada pelo MAPEmunicipios.Rproj, não pelo diretório de trabalho.
#'
#' @param ... Componentes do caminho, como em here::here().
#' @return Caminho absoluto, como character.
mape_caminho <- function(...) {
  here::here(...)
}

# O YAML é lido uma vez por sessão e guardado aqui. Sem isso, uma função
# chamada dentro de um mutate() releria o arquivo a cada linha.
.mape_cache_param <- new.env(parent = emptyenv())

#' Lê um parâmetro de config/parametros.yml
#'
#' @param chave Nome do parâmetro. Aceita caminho aninhado separado por ponto,
#'   como "qa.max_prop_chave_orfa" ou "chaves.id_municipio.digitos".
#'   Se omitido, devolve a lista inteira.
#' @param .recarregar Força reler o arquivo, ignorando o cache da sessão. Útil
#'   depois de editar o YAML sem reiniciar o R.
#' @return O valor do parâmetro.
#'
#' @examples
#' mape_param("deflator_base")          # "12/2023"
#' mape_param("anos_painel")            # c(1991, 2023)
#' mape_param("qa.tolerancia_paridade") # 1e-09
mape_param <- function(chave = NULL, .recarregar = FALSE) {
  if (.recarregar || is.null(.mape_cache_param$valores)) {
    caminho <- mape_caminho("config", "parametros.yml")
    if (!file.exists(caminho)) {
      stop(
        "Não encontrei config/parametros.yml em ", caminho, ".\n",
        "Se você está rodando de fora do repositório, abra o ",
        "MAPEmunicipios.Rproj primeiro — o here() ancora nele.",
        call. = FALSE
      )
    }
    .mape_cache_param$valores <- yaml::read_yaml(caminho)
  }

  valores <- .mape_cache_param$valores
  if (is.null(chave)) {
    return(valores)
  }

  # Percorre o caminho aninhado, falhando com uma mensagem que diz onde parou
  # em vez de devolver NULL silenciosamente.
  partes <- strsplit(chave, ".", fixed = TRUE)[[1]]
  atual <- valores
  for (i in seq_along(partes)) {
    if (!is.list(atual) || !partes[i] %in% names(atual)) {
      stop(
        "Parâmetro não encontrado: '", chave, "'.\n",
        "Falhou em '", paste(partes[seq_len(i)], collapse = "."), "'. ",
        "Chaves disponíveis nesse nível: ",
        paste(names(atual), collapse = ", "),
        call. = FALSE
      )
    }
    atual <- atual[[partes[i]]]
  }

  # O yaml devolve listas para sequências homogêneas; simplifica para vetor
  # quando isso não perde informação.
  if (is.list(atual) && length(atual) > 0 &&
      all(vapply(atual, function(x) is.atomic(x) && length(x) == 1, logical(1)))) {
    atual <- unlist(atual, use.names = FALSE)
  }
  atual
}

#' Vetor de anos do painel
#'
#' Expande o par [inicio, fim] de anos_painel para a sequência completa.
#'
#' @return Vetor de inteiros.
mape_anos_painel <- function() {
  faixa <- mape_param("anos_painel")
  seq.int(from = as.integer(faixa[1]), to = as.integer(faixa[2]))
}
