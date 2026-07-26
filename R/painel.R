# Esqueleto e expansão do painel ---------------------------------------------
#
# O legado tem o mesmo bloco de expansão copiado cinco vezes, literalmente
# idêntico até os comentários, variando só a faixa de anos (1991:2023,
# 2007:2023, 2010:2020). E tem a tabela de replicação censitária copiada duas
# vezes, em populacao.R e sociedade.R. São sete cópias de duas funções que
# ninguém escreveu.
#
# A regra nova: a tabela canônica guarda o OBSERVADO. A expansão acontece aqui,
# sob demanda, e sempre marca o que imputou.

#' Esqueleto município × ano
#'
#' @param anos Vetor de anos. Se NULL, usa a faixa de config/parametros.yml.
#' @param diretorio Diretório de municípios; se NULL, lê o publicado.
#' @param incluir_flag_instalado Se TRUE, acrescenta flag_municipio_instalado,
#'   distinguindo "o município ainda não existia" de "a fonte não cobre".
#' @return Data frame com id_municipio e ano.
mape_esqueleto_painel <- function(anos = NULL, diretorio = NULL,
                                  incluir_flag_instalado = TRUE) {
  if (is.null(anos)) anos <- mape_anos_painel()
  if (is.null(diretorio)) diretorio <- mape_ler_tabela("00_diretorios/municipios")

  esqueleto <- expand.grid(
    id_municipio = sort(unique(diretorio$id_municipio)),
    ano = as.integer(anos),
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )

  if (incluir_flag_instalado && "ano_instalacao" %in% names(diretorio)) {
    inst <- stats::setNames(diretorio$ano_instalacao, diretorio$id_municipio)
    esqueleto$flag_municipio_instalado <- as.integer(
      esqueleto$ano >= inst[esqueleto$id_municipio]
    )
    # Município sem ano de instalação registrado é tratado como sempre presente,
    # e isso fica visível como NA na origem em vez de virar zero.
    esqueleto$flag_municipio_instalado[is.na(esqueleto$flag_municipio_instalado)] <- 1L
  }

  esqueleto[order(esqueleto$id_municipio, esqueleto$ano), ]
}

#' Expande observações para uma faixa de anos
#'
#' Substitui os sete trechos de expansão do legado. A diferença essencial é que
#' cada coluna expandida ganha uma marca de imputação: hoje nenhuma linha da
#' base publicada distingue o dado medido do dado replicado, e as únicas pistas
#' que sobraram são as colunas ano_censo, ano_avs e ano_ideb, que atravessaram o
#' pipeline por acidente.
#'
#' @param x Data frame com as observações reais.
#' @param de Nome da coluna que guarda o ano da medição (ex.: "ano_ref_censo").
#' @param mapa Data frame com duas colunas, a de `de` e `ano`, dizendo para
#'   quais anos cada medição se propaga. Se NULL, usa `metodo`.
#' @param para Vetor de anos de destino, usado quando `mapa` é NULL.
#' @param metodo "replicar" repete a observação em todos os anos de `para`;
#'   "carry_forward" propaga cada medição até a próxima.
#' @param cols Colunas a marcar como imputadas. Se NULL, todas menos as chaves.
#' @return Data frame expandido, com flag_imputado.
mape_expandir_painel <- function(x, de = "ano_ref", mapa = NULL, para = NULL,
                                 metodo = c("replicar", "carry_forward"),
                                 cols = NULL) {
  metodo <- match.arg(metodo)
  stopifnot(is.data.frame(x), de %in% names(x))
  if (is.null(para)) para <- mape_anos_painel()

  if (is.null(mapa)) {
    anos_medidos <- sort(unique(x[[de]]))
    if (metodo == "replicar") {
      mapa <- expand.grid(m = anos_medidos, ano = as.integer(para),
                          KEEP.OUT.ATTRS = FALSE)
    } else {
      # Cada ano de destino recebe a última medição igual ou anterior a ele.
      idx <- findInterval(as.integer(para), anos_medidos)
      valido <- idx > 0
      mapa <- data.frame(m = anos_medidos[idx[valido]],
                         ano = as.integer(para)[valido])
    }
    names(mapa)[1] <- de
  }

  expandido <- merge(x, mapa, by = de, all.x = FALSE, all.y = FALSE)

  # A marca de imputação: a linha é observada quando o ano de destino coincide
  # com o ano da medição.
  expandido$flag_imputado <- as.integer(expandido$ano != expandido[[de]])

  chaves <- intersect(c("id_municipio", "ano", de, "flag_imputado"), names(expandido))
  if (is.null(cols)) cols <- setdiff(names(expandido), chaves)
  expandido <- expandido[, c(chaves, cols), drop = FALSE]
  expandido[order(expandido$id_municipio, expandido$ano), ]
}

#' Tabela de replicação censitária usada no legado
#'
#' Reproduz exatamente o mapeamento copiado em populacao.R:23-27 e
#' sociedade.R:17-21, que replica o censo de 2000 sobre 1996-2005 e o de 2010
#' sobre 2006-2015. Existe para o teste de paridade: é preciso conseguir
#' reproduzir o comportamento antigo antes de trocá-lo.
#'
#' @param col Nome da coluna de ano de referência no resultado.
#' @return Data frame com o mapeamento.
mape_mapa_censitario_legado <- function(col = "ano_ref_censo") {
  mapa <- data.frame(
    ref = c(rep(2000L, length(1996:2005)), rep(2010L, length(2006:2015))),
    ano = c(1996:2005, 2006:2015)
  )
  names(mapa)[1] <- col
  mapa
}
