#!/usr/bin/env Rscript
# Roda mape_validar_tabela() sobre as 26 tabelas publicadas e regera os qa/*.md.
#
#   Rscript tools/validar_tudo.R           # grava os relatórios
#   Rscript tools/validar_tudo.R --seco    # só mede, não grava nada
#
# Achado 85 da auditoria de 26/07/2026: 26 dos 27 achados de QA estavam em
# tabelas que nenhum alvo `valida_*` cobre, e NENHUM comando versionado
# regenerava os relatórios. Os `qa/*.md` eram artefatos órfãos — versionados,
# lidos como se fossem atuais, e sem produtor. O CLAUDE.md afirmava que
# `tar_make(documentacao)` os sobrescrevia, o que nunca foi verdade.
#
# Este script é somente-leitura sobre `dados/`: ele lê os Parquet publicados e
# escreve exclusivamente em `qa/`. Ele NÃO é um script de migração e não
# reescreve tabela nenhuma.
#
# Sai com código 1 se sobrar erro não reivindicado — para poder ser usado como
# portão antes de publicar o release.

for (f in list.files(here::here("R"), pattern = "[.]R$", full.names = TRUE)) {
  source(f, local = FALSE, encoding = "UTF-8")
}

seco <- "--seco" %in% commandArgs(trailingOnly = TRUE)

tabs <- mape_tabelas_publicadas()
message("Validando ", nrow(tabs), " tabelas publicadas",
        if (seco) " (modo seco: nada será gravado)" else "", ".\n")

todos <- list()
for (i in seq_len(nrow(tabs))) {
  slug <- tabs$slug[i]
  x <- as.data.frame(mape_ler_tabela(slug, camada = tabs$camada[i]))
  res <- tryCatch(
    suppressMessages(suppressWarnings(
      mape_validar_tabela(x, slug, erro = FALSE, gravar = !seco))),
    error = function(e) data.frame(
      tabela = slug, checagem = "ERRO_DE_EXECUCAO", gravidade = "erro",
      descricao = conditionMessage(e), justificada = FALSE,
      justificativa = NA_character_, stringsAsFactors = FALSE)
  )
  n_e <- sum(res$gravidade == "erro")
  n_a <- sum(res$gravidade == "aviso")
  message(sprintf("  %-38s %d erro(s), %d aviso(s)", slug, n_e, n_a))
  if (nrow(res)) todos[[length(todos) + 1]] <- res
}

res <- if (length(todos)) do.call(rbind, todos) else NULL
n_erro <- if (is.null(res)) 0 else sum(res$gravidade == "erro")
n_aviso <- if (is.null(res)) 0 else sum(res$gravidade == "aviso")

message("\n", strrep("-", 70))
message("TOTAL: ", n_erro, " erro(s) e ", n_aviso, " aviso(s) sobre ",
        nrow(tabs), " tabelas.")
message("Todo aviso acima tem justificativa registrada — os que não tinham ",
        "aparecem como erro.")

if (n_erro) {
  message("\nErros não reivindicados:")
  for (i in which(res$gravidade == "erro")) {
    message("  - ", res$tabela[i], " / ", res$checagem[i], ": ",
            substr(res$descricao[i], 1, 120))
  }
  message("\nReivindique em qa/erros_aceitos.csv, ou conserte o dado.")
  quit(status = 1)
}
quit(status = 0)
