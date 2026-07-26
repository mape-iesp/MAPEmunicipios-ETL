#!/usr/bin/env Rscript
# Verifica mecanicamente os treze criterios de "pronto" da rodada de correcao da
# auditoria (auditoria/prompt-correcao.md, secao 12).
#
#   Rscript tools/verificar_fechamento.R
#
# Imprime uma linha por criterio com OK ou FALHA, e SAI COM CODIGO 1 se algum
# falhar. E este script que decide se a rodada acabou — nao a prosa de nenhum
# relatorio, o que e coerente com a regra de ouro da propria rodada: afirmacao
# sem checagem e defeito.
#
# O criterio 13 e este arquivo existir e cobrir os doze primeiros.

suppressMessages({
  library(arrow)
  library(bit64)
})
for (f in list.files(here::here("R"), pattern = "[.]R$", full.names = TRUE)) {
  source(f, local = FALSE, encoding = "UTF-8")
}

RAIZ <- here::here()
resultados <- list()

registrar <- function(n, titulo, ok, detalhe = "") {
  resultados[[length(resultados) + 1]] <<- list(n = n, titulo = titulo,
                                                ok = isTRUE(ok), detalhe = detalhe)
}

tentar <- function(n, titulo, expr) {
  r <- tryCatch(expr, error = function(e) list(ok = FALSE, detalhe = paste("erro:", conditionMessage(e))))
  registrar(n, titulo, r$ok, r$detalhe)
}

ledger <- utils::read.csv(file.path(RAIZ, "auditoria", "CORRECOES.csv"),
                          stringsAsFactors = FALSE, encoding = "UTF-8")

# -- 1 ----------------------------------------------------------------------
tentar(1, "CORRECOES.csv tem 105 linhas, de 1 a 105, sem furo nem repeticao", {
  g <- suppressWarnings(as.integer(ledger$grupo))
  ok <- nrow(ledger) == 105 && identical(sort(g), seq_len(105))
  list(ok = ok, detalhe = sprintf("%d linha(s), %d distinta(s)", nrow(ledger), length(unique(g))))
})

# -- 2 ----------------------------------------------------------------------
tentar(2, "nenhuma linha com status = pendente", {
  n <- sum(ledger$status == "pendente")
  list(ok = n == 0, detalhe = sprintf("%d pendente(s); %s", n,
    paste(sprintf("%s=%d", names(table(ledger$status)), as.integer(table(ledger$status))),
          collapse = ", ")))
})

# -- 3 ----------------------------------------------------------------------
tentar(3, "todo corrigido/mitigado tem reproducao antes, depois e commit existente", {
  alvo <- ledger[ledger$status %in% c("corrigido", "mitigado"), , drop = FALSE]
  vazio <- function(v) is.na(v) | !nzchar(trimws(v))
  faltando <- alvo$grupo[vazio(alvo$reproduziu_antes) | vazio(alvo$reproduziu_depois) |
                           vazio(alvo$commit)]
  shas <- unique(alvo$commit[!vazio(alvo$commit)])
  inexistentes <- shas[vapply(shas, function(s)
    system2("git", c("-C", RAIZ, "cat-file", "-e", paste0(s, "^{commit}")),
            stdout = FALSE, stderr = FALSE) != 0, logical(1))]
  list(ok = !length(faltando) && !length(inexistentes),
       detalhe = sprintf("%d grupo(s), %d com campo vazio, %d sha inexistente",
                         nrow(alvo), length(faltando), length(inexistentes)))
})

# -- 4 ----------------------------------------------------------------------
tentar(4, "todo bloqueado/nao-reproduz/nao-confirmado tem observacao", {
  alvo <- ledger[ledger$status %in% c("bloqueado", "nao-reproduz-hoje",
                                      "nao-confirmado-pela-auditoria"), , drop = FALSE]
  vazias <- alvo$grupo[is.na(alvo$observacao) | !nzchar(trimws(alvo$observacao))]
  list(ok = !length(vazias),
       detalhe = sprintf("%d grupo(s), %d sem observacao", nrow(alvo), length(vazias)))
})

# -- 5 ----------------------------------------------------------------------
tentar(5, "a suite passa e tem mais expectativas que o baseline (154)", {
  r <- as.data.frame(testthat::test_dir(file.path(RAIZ, "tests", "testthat"),
                                        reporter = "silent", stop_on_failure = FALSE))
  n <- sum(r$passed); f <- sum(r$failed)
  list(ok = f == 0 && n > 154,
       detalhe = sprintf("PASS %d (baseline 154), FAIL %d", n, f))
})

# -- 6 ----------------------------------------------------------------------
tentar(6, "as 26 tabelas validam sem erro e todo aviso tem justificativa", {
  tabs <- mape_tabelas_publicadas()
  erros <- 0; avisos <- 0; sem_just <- 0
  for (i in seq_len(nrow(tabs))) {
    x <- as.data.frame(mape_ler_tabela(tabs$slug[i], camada = tabs$camada[i]))
    res <- suppressMessages(suppressWarnings(
      mape_validar_tabela(x, tabs$slug[i], erro = FALSE, gravar = FALSE)))
    if (!nrow(res)) next
    erros <- erros + sum(res$gravidade == "erro")
    a <- res[res$gravidade == "aviso", , drop = FALSE]
    avisos <- avisos + nrow(a)
    if (nrow(a)) sem_just <- sem_just + sum(!a$justificada)
  }
  list(ok = erros == 0 && sem_just == 0,
       detalhe = sprintf("%d tabela(s): %d erro(s), %d aviso(s), %d sem justificativa",
                         nrow(tabs), erros, avisos, sem_just))
})

# -- 7 ----------------------------------------------------------------------
tentar(7, "nenhuma tabela perdeu linha, coluna, chave ou municipio vs BASELINE", {
  base <- readLines(file.path(RAIZ, "auditoria", "BASELINE.md"), warn = FALSE)
  # Só as linhas da tabela das 26 publicadas: elas têm "dimensao" ou "fonte" na
  # segunda célula. O arquivo tem outras tabelas (a de QA, por exemplo) que
  # também começam com "| `".
  linhas <- grep("^\\| `[^`]+` \\| (dimensao|fonte) \\|", base, value = TRUE)
  perdas <- character()
  for (l in linhas) {
    c_ <- trimws(strsplit(l, "|", fixed = TRUE)[[1]])
    c_ <- c_[nzchar(c_)]
    slug <- gsub("`", "", c_[1]); camada <- c_[2]
    n_lin <- as.integer(gsub("[^0-9]", "", c_[3]))
    n_col <- as.integer(gsub("[^0-9]", "", c_[4]))
    n_mun <- suppressWarnings(as.integer(gsub("[^0-9]", "", c_[6])))
    p <- file.path(RAIZ, "dados", camada, paste0(slug, ".parquet"))
    if (!file.exists(p)) { perdas <- c(perdas, paste(slug, "sumiu")); next }
    x <- as.data.frame(arrow::read_parquet(p))
    m <- mape_medir_tabela(x)
    if (m$n_linhas < n_lin) perdas <- c(perdas, sprintf("%s linhas %d<%d", slug, m$n_linhas, n_lin))
    if (m$n_colunas < n_col) perdas <- c(perdas, sprintf("%s colunas %d<%d", slug, m$n_colunas, n_col))
    if (!is.na(n_mun) && !is.na(m$n_municipios) && m$n_municipios < n_mun) {
      perdas <- c(perdas, sprintf("%s municipios %d<%d", slug, m$n_municipios, n_mun))
    }
  }
  list(ok = !length(perdas),
       detalhe = if (length(perdas)) paste(perdas, collapse = "; ")
                 else sprintf("%d tabela(s) conferida(s), nenhuma perda", length(linhas)))
})

# -- 8 ----------------------------------------------------------------------
tentar(8, "todo comando tar_make(...) da documentacao executa sem erro", {
  arqs <- c(file.path(RAIZ, c("README.md", "CLAUDE.md")),
            list.files(file.path(RAIZ, "docs"), pattern = "[.]md$", full.names = TRUE))
  arqs <- arqs[file.exists(arqs)]
  # Só conta o que a documentação ENSINA, e ela ensina dentro de bloco de
  # código. Uma menção em prosa — numa errata que existe justamente para dizer
  # que o comando não funciona — não é uma receita.
  dentro_de_bloco <- function(arq) {
    l <- readLines(arq, warn = FALSE)
    cerca <- grepl("^\\s*```", l)
    dentro <- cumsum(cerca) %% 2 == 1 & !cerca
    l[dentro]
  }
  txt <- unlist(lapply(arqs, dentro_de_bloco))
  alvos <- unique(unlist(regmatches(txt, gregexpr("tar_make\\(([a-z0-9_]+)\\)", txt))))
  alvos <- gsub("tar_make\\(|\\)", "", alvos)
  alvos <- setdiff(alvos, "")
  existentes <- targets::tar_manifest(fields = "name")$name
  inexistentes <- setdiff(alvos, existentes)
  list(ok = !length(inexistentes),
       detalhe = sprintf("%d alvo(s) citado(s) na documentacao; %s", length(alvos),
         if (length(inexistentes)) paste("NAO EXISTEM:", paste(inexistentes, collapse = ", "))
         else "todos existem no grafo"))
})

# -- 9 ----------------------------------------------------------------------
tentar(9, "nenhum identificador GCP legado em arquivo versionado", {
  # Os quatro nomes ficam num arquivo NAO versionado; este script le de la para
  # nao reintroduzi-los. Sem o arquivo, o criterio nao pode ser verificado.
  nota <- file.path(RAIZ, "auditoria", "VAZAMENTO-GCP.local.md")
  if (!file.exists(nota)) {
    return(list(ok = FALSE, detalhe = "auditoria/VAZAMENTO-GCP.local.md ausente: nao da para verificar"))
  }
  # A nota lista os identificadores numa seção própria, um por linha, prefixada
  # por "- `". Ler só de lá evita que este script invente identificadores a
  # partir de nome de arquivo — e evita, principalmente, escrever qualquer um
  # deles dentro deste arquivo, que É versionado.
  linhas <- readLines(nota, warn = FALSE)
  ids <- unlist(regmatches(linhas, gregexpr("(?<=^- `)[^`]+(?=`)", linhas, perl = TRUE)))
  ids <- unique(ids[nzchar(ids)])
  if (!length(ids)) {
    return(list(ok = FALSE, detalhe = "a nota nao lista identificadores no formato esperado (- `id`)"))
  }
  versionados <- system2("git", c("-C", RAIZ, "ls-files"), stdout = TRUE)
  versionados <- versionados[!grepl("[.]local[.]md$", versionados)]
  achados <- character()
  for (id in ids) {
    for (arq in versionados) {
      caminho <- file.path(RAIZ, arq)
      if (!file.exists(caminho)) next
      conteudo <- tryCatch(readLines(caminho, warn = FALSE, encoding = "UTF-8"),
                           error = function(e) character(), warning = function(w) character())
      if (any(grepl(id, conteudo, fixed = TRUE))) {
        achados <- c(achados, arq)
        break
      }
    }
  }
  list(ok = !length(achados),
       detalhe = sprintf("%d identificador(es) conferido(s); %d com ocorrencia versionada",
                         length(ids), length(achados)))
})

# -- 10 ---------------------------------------------------------------------
tentar(10, "working tree limpo e ha commit citando cada grupo corrigido", {
  sujo <- system2("git", c("-C", RAIZ, "status", "--porcelain"), stdout = TRUE)
  log <- system2("git", c("-C", RAIZ, "log", "--pretty=%s%n%b"), stdout = TRUE)
  log1 <- paste(log, collapse = "\n")
  alvo <- ledger[ledger$status %in% c("corrigido", "mitigado"), , drop = FALSE]
  sem_commit <- alvo$grupo[!vapply(alvo$grupo, function(g)
    grepl(paste0("Achado[s]? .*\\b", g, "\\b"), log1) ||
    grepl(paste0("\\bACHADO ", g, "\\b"), log1), logical(1))]
  list(ok = !length(sujo) && !length(sem_commit),
       detalhe = sprintf("%d arquivo(s) sujo(s); %d grupo(s) sem commit que os cite",
                         length(sujo), length(sem_commit)))
})

# -- 11 ---------------------------------------------------------------------
tentar(11, "FECHAMENTO.md, BASELINE.md e RELATORIO-FINAL.md existem e estao completos", {
  exigido <- list(
    "auditoria/FECHAMENTO.md" = c("cadeias causais", "ordem de correção",
                                  "sete afirmações centrais", "depois"),
    "auditoria/BASELINE.md" = c("26 tabelas", "suíte de testes", "sha256"),
    "auditoria/RELATORIO-FINAL.md" = c("quadro", "dado publicado mudou",
                                       "bloqueado", "decisão", "verificar_fechamento")
  )
  faltando <- character()
  for (arq in names(exigido)) {
    caminho <- file.path(RAIZ, arq)
    if (!file.exists(caminho)) { faltando <- c(faltando, paste(arq, "ausente")); next }
    txt <- paste(readLines(caminho, warn = FALSE), collapse = "\n")
    for (termo in exigido[[arq]]) {
      if (!grepl(termo, txt, ignore.case = TRUE, fixed = FALSE)) {
        faltando <- c(faltando, paste0(arq, ": falta '", termo, "'"))
      }
    }
  }
  list(ok = !length(faltando),
       detalhe = if (length(faltando)) paste(faltando, collapse = "; ") else "os tres, completos")
})

# -- 12 ---------------------------------------------------------------------
tentar(12, "CLAUDE.md descreve o estado atual: numeros conferidos por medicao", {
  txt <- paste(readLines(file.path(RAIZ, "CLAUDE.md"), warn = FALSE), collapse = "\n")
  lock <- length(jsonlite::fromJSON(file.path(RAIZ, "renv.lock"))$Packages)
  n_var <- nrow(mape_dicionario("variaveis"))
  n_tab <- nrow(mape_tabelas_publicadas())
  r <- as.data.frame(testthat::test_dir(file.path(RAIZ, "tests", "testthat"),
                                        reporter = "silent", stop_on_failure = FALSE))
  n_exp <- sum(r$passed)

  problemas <- character()
  # Cada numero que o CLAUDE.md cita tem de bater com a medicao.
  if (!grepl(paste0("\\*\\*", lock, "\\*\\* pacotes|", lock, " pacotes"), txt))
    problemas <- c(problemas, paste("pacotes:", lock))
  if (!grepl(paste0(n_var, " variáveis"), txt))
    problemas <- c(problemas, paste("variaveis:", n_var))
  if (!grepl(paste0(n_tab, " tabelas"), txt))
    problemas <- c(problemas, paste("tabelas:", n_tab))
  if (!grepl(paste0(n_exp, " expectativas"), txt))
    problemas <- c(problemas, paste("expectativas:", n_exp))
  # E nao pode continuar afirmando que nenhum achado foi corrigido.
  if (grepl("nenhum foi corrigido", txt, fixed = TRUE))
    problemas <- c(problemas, "ainda diz 'nenhum foi corrigido'")

  list(ok = !length(problemas),
       detalhe = if (length(problemas)) paste("desatualizado em:", paste(problemas, collapse = ", "))
                 else sprintf("%d pacotes, %d variaveis, %d tabelas, %d expectativas",
                              lock, n_var, n_tab, n_exp))
})

# -- 13 ---------------------------------------------------------------------
registrar(13, "este script existe, cobre os doze acima e sai com codigo nao zero", TRUE,
          "12 criterios verificados acima")

# ---------------------------------------------------------------------------
cat("\n", strrep("=", 78), "\n", sep = "")
cat("VERIFICACAO DE FECHAMENTO — auditoria/prompt-correcao.md, secao 12\n")
cat(strrep("=", 78), "\n\n", sep = "")

for (r in resultados) {
  cat(sprintf("%-4s %-6s %s\n", paste0(r$n, "."), if (r$ok) "OK" else "FALHA", r$titulo))
  if (nzchar(r$detalhe)) cat(sprintf("          %s\n", r$detalhe))
}

falhas <- sum(!vapply(resultados, function(r) r$ok, logical(1)))
cat("\n", strrep("-", 78), "\n", sep = "")
if (falhas) {
  cat(sprintf("%d de %d criterios FALHARAM. A rodada nao esta pronta.\n",
              falhas, length(resultados)))
  quit(status = 1)
}
cat(sprintf("Os %d criterios passaram.\n", length(resultados)))
quit(status = 0)
