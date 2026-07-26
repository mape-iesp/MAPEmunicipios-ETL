# Tratamento: CadÚnico — famílias com cadastro atualizado --------------------
#
# Indicadores municipais do Cadastro Único, publicados pelo MDS/SAGI. As
# contagens correspondem ao indicador IN004 (famílias com dados atualizados,
# por faixa de renda per capita) e as duas taxas são a Taxa de Atualização
# Cadastral, componente do Índice de Gestão Descentralizada do Bolsa Família.
#
# Duas notas de procedência que valem estar aqui e não só no manifesto:
#
#   A origem desta fonte esteve perdida. O inventário a registrava como
#   "arquivo local sem origem", e uma busca por 'cadun', 'anomes_s' e 'http' em
#   toda a árvore legada não retornava nada. Foi identificada durante o
#   planejamento.
#
#   A definição oficial de "família atualizada" é aquela cuja última
#   atualização de campos sensíveis tem menos de 24 meses. Isso muda a
#   interpretação da série e por isso está na descrição das variáveis.

tratar_cadunico <- function(origem = NULL) {
  if (is.null(origem)) {
    origem <- file.path(
      mape_caminho("mape_municipios", "1 Dimensões Individuais",
                   "8 Assistência Social e Direitos Humanos - Códigos e Dados"),
      "CadUnico", "2_output", "cadunico.csv"
    )
  }
  bruto <- utils::read.csv(origem, stringsAsFactors = FALSE, encoding = "UTF-8")
  message("bruto: ", nrow(bruto), " linhas x ", ncol(bruto), " colunas")

  x <- janitor::clean_names(bruto)

  # A coluna de código do município chega como codigo_ibge, com sete dígitos.
  # O nome vira id_municipio, que é o reservado do projeto.
  if ("codigo_ibge" %in% names(x)) {
    names(x)[names(x) == "codigo_ibge"] <- "id_municipio"
  }

  # As duas colunas de taxa terminam em _d no legado. O sufixo é ambíguo entre
  # proporção e percentual, e é justamente essa ambiguidade que produz, na base
  # publicada, colunas em escalas diferentes sob o mesmo prefixo. A Taxa de
  # Atualização Cadastral é razão entre cadastros atualizados e cadastros
  # totais, expressa em percentual — os valores observados (57,82 e 64,54 na
  # primeira linha) confirmam. Passam a _pct.
  renomeacoes <- c(
    cadun_taxa_atualizacao_cadastral_d = "cadun_taxa_atualizacao_cadastral_pct",
    cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_d =
      "cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_pct"
  )
  for (de in names(renomeacoes)) {
    if (de %in% names(x)) names(x)[names(x) == de] <- renomeacoes[[de]]
  }

  x <- mape_tratar_sentinelas(x, converter_numerico = FALSE)
  x <- mape_normalizar_chaves(x)

  # As contagens são inteiras por definição; o CSV às vezes as devolve como
  # double, o que faria o schema divergir do declarado.
  for (nm in grep("_i$", names(x), value = TRUE)) {
    x[[nm]] <- mape_como_inteiro(x[[nm]])
  }

  mape_validar_chave(x)
  x[order(x$id_municipio, x$ano), ]
}
