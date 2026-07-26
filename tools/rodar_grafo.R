#!/usr/bin/env Rscript
# Roda o grafo do targets e SAI COM CODIGO DIFERENTE DE ZERO se algum alvo falhar.
#
#   Rscript tools/rodar_grafo.R                 # o grafo inteiro
#   Rscript tools/rodar_grafo.R nome_do_alvo    # um alvo so
#
# Achado 41 da auditoria: `tar_make()` sai com codigo 0 mesmo quando um alvo
# falha. Um pipeline que falha em silencio e um pipeline que ninguem percebe que
# falhou — e o codigo de saida e exatamente o que a CI e qualquer script de
# automacao leem.
#
# ATENCAO (achado 6): rodar o grafo inteiro invoca os alvos dim_*. Desde a
# correcao do achado 6 eles nao destroem mais nada — a guarda de perda de
# mape_escrever_tabela() barra a gravacao —, mas dois deles FALHAM de proposito,
# porque as fontes fatiadas nao reproduzem a dimensao publicada. Este script vai
# reportar essa falha, que e o comportamento certo.

alvos <- commandArgs(trailingOnly = TRUE)

if (length(alvos)) {
  for (a in alvos) {
    message("== tar_make(", a, ")")
    targets::tar_make(names = tidyselect::all_of(a), callr_function = NULL)
  }
} else {
  targets::tar_make(callr_function = NULL)
}

# tar_make() nao propaga falha para o codigo de saida. tar_meta() sabe quem
# falhou, e e ela que decide o codigo aqui.
meta <- targets::tar_meta(fields = "error", targets_only = TRUE)
falhos <- meta[!is.na(meta$error), , drop = FALSE]

if (nrow(falhos)) {
  message("\n", strrep("-", 70))
  message(nrow(falhos), " alvo(s) falharam:")
  for (i in seq_len(nrow(falhos))) {
    message("  - ", falhos$name[i], ": ", substr(falhos$error[i], 1, 200))
  }
  quit(status = 1)
}

message("\nTodos os alvos concluidos sem erro.")
quit(status = 0)
