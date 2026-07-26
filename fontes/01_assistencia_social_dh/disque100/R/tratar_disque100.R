# Tratamento: Disque 100 — denúncias de violações de direitos humanos --------
#
# Contagem anual de violações denunciadas ao Disque Direitos Humanos, por
# município e por grupo vulnerável.
#
# O prefixo `total_` das colunas do legado é banido pela convenção nova: ele é
# usado em sete dimensões diferentes para coisas sem relação entre si — contagem
# de desastres, valores em reais, número de instituições, óbitos, eleitores
# aptos. Aqui as colunas passam a `disque100_violacoes_<grupo>_i`, que diz a
# fonte, o conceito e o tipo.
#
# A coluna `grupo` do bruto é um caso de colisão exata com a dimensão Segurança,
# onde `grupo` é a classificação de municípios do FBSP. São conceitos
# incompatíveis com o mesmo nome, e o prefixo de fonte resolve.

tratar_disque100 <- function(origem = NULL) {
  if (is.null(origem)) {
    origem <- file.path(
      mape_caminho("mape_municipios", "1 Dimensões Individuais",
                   "8 Assistência Social e Direitos Humanos - Códigos e Dados"),
      "Disque 100", "disque100.xlsx"
    )
  }
  bruto <- as.data.frame(openxlsx::read.xlsx(origem))
  message("bruto: ", nrow(bruto), " linhas x ", ncol(bruto), " colunas")

  x <- janitor::clean_names(bruto)

  renomeacoes <- c(
    total_violacoes = "disque100_violacoes_i",
    total_violacoes_crianca_adolescente = "disque100_violacoes_crianca_adolescente_i",
    total_violacoes_lgbtq = "disque100_violacoes_lgbtq_i",
    total_violacoes_pcd = "disque100_violacoes_pcd_i",
    total_violacoes_pessoa_idosa = "disque100_violacoes_pessoa_idosa_i",
    total_violacoes_religiao = "disque100_violacoes_religiao_i"
  )
  for (de in names(renomeacoes)) {
    if (de %in% names(x)) names(x)[names(x) == de] <- renomeacoes[[de]]
  }

  x <- mape_tratar_sentinelas(x, converter_numerico = FALSE)
  x <- mape_normalizar_chaves(x)

  for (nm in grep("_i$", names(x), value = TRUE)) {
    x[[nm]] <- mape_como_inteiro(x[[nm]])
  }

  mape_validar_chave(x)
  x[order(x$id_municipio, x$ano), ]
}
