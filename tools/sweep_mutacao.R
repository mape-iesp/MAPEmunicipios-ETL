#!/usr/bin/env Rscript
# Sweep de mutacao: troca cada funcao mape_* por function(...) NULL e roda a
# suite. Uma funcao que sobrevive a mutacao NAO e testada de verdade.
#
#   Rscript tools/sweep_mutacao.R                 # todas (lento: ~20s por funcao)
#   Rscript tools/sweep_mutacao.R mape_deflacionar mape_escrever_tabela
#
# Achado 26 da auditoria: 26 das 62 funcoes mape_* podiam virar
# function(...) NULL sem quebrar NENHUM teste — incluindo mape_deflacionar() e
# mape_marcar_nominal(). A suite dava a impressao de cobrir o que nao cobria.
#
# Este script e a meta-cobertura: ele mede a suite, nao o codigo.

alvos <- commandArgs(trailingOnly = TRUE)

for (f in list.files(here::here("R"), pattern = "[.]R$", full.names = TRUE)) {
  source(f, local = FALSE, encoding = "UTF-8")
}
todas <- ls(envir = globalenv())
todas <- todas[grepl("^mape_", todas)]
todas <- todas[vapply(todas, function(n) is.function(get(n)), logical(1))]
if (!length(alvos)) alvos <- todas
alvos <- intersect(alvos, todas)

message("Sweep sobre ", length(alvos), " funcao(oes).\n")

sobrevivem <- character()
for (fn in alvos) {
  # A mutacao precisa sobreviver ao setup.R da suite, que RE-CARREGA R/*.R e
  # desfaria um assign() feito antes. Como list.files() devolve em ordem
  # alfabetica, um arquivo `zzz_` e carregado por ultimo e vence.
  patch <- here::here("R", "zzz_mutacao_temporaria.R")
  writeLines(sprintf('%s <- function(...) NULL', fn), patch)
  on.exit(unlink(patch), add = TRUE)

  codigo <- sprintf('
    setwd("%s")
    r <- tryCatch(as.data.frame(testthat::test_dir("tests/testthat",
           reporter = "silent", stop_on_failure = FALSE)),
         error = function(e) NULL)
    cat(if (is.null(r)) -1 else sum(r$failed))
  ', here::here())
  saida <- suppressWarnings(system2("Rscript", c("-e", shQuote(codigo)),
                                    stdout = TRUE, stderr = FALSE))
  unlink(patch)
  falhas <- suppressWarnings(as.integer(tail(saida, 1)))
  vivo <- !is.na(falhas) && falhas == 0
  if (vivo) sobrevivem <- c(sobrevivem, fn)
  message(sprintf("  %-40s %s", fn,
                  if (vivo) "SOBREVIVE (nao testada)" else "morre (testada)"))
}

message("\n", strrep("-", 70))
message(length(sobrevivem), " de ", length(alvos), " funcoes sobrevivem a mutacao.")
if (length(sobrevivem)) {
  message("Nao sao exercitadas por nenhum teste:")
  for (s in sobrevivem) message("  - ", s)
}
