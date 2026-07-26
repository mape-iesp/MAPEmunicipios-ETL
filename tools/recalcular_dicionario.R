#!/usr/bin/env Rscript
# Recalcula os campos calculados de dicionario/variaveis.csv a partir do dado.
#
#   Rscript tools/recalcular_dicionario.R
#
# Achado 69: este passo vivia dentro de mape_gerar_documentacao_completa(), que
# e o corpo do alvo `documentacao` — e `documentacao` declara
# dicionario/variaveis.csv como dependencia. O alvo reescrevia a propria
# entrada, e o grafo ficava desatualizado no instante seguinte a rodar.
#
# Separado, ele e o que deve rodar A MONTANTE do grafo: primeiro os campos
# calculados, depois a documentacao que os le.
#
# Os campos reescritos sao: tipo_real, pct_na, pct_zero, n_distintos, minimo,
# maximo, n_infinito e janela_efetiva. Editar qualquer um deles a mao nao
# adianta.

for (f in list.files(here::here("R"), pattern = "[.]R$", full.names = TRUE)) {
  source(f, local = FALSE, encoding = "UTF-8")
}

antes <- tools::md5sum(here::here("dicionario", "variaveis.csv"))
invisible(mape_recalcular_campos(gravar = TRUE))
depois <- tools::md5sum(here::here("dicionario", "variaveis.csv"))

if (identical(unname(antes), unname(depois))) {
  message("dicionario/variaveis.csv ja estava atualizado.")
} else {
  message("dicionario/variaveis.csv atualizado.")
}
