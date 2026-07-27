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
# O titulo dizia "executa sem erro" e o codigo so confere pertinencia ao grafo.
# Nada e executado aqui, e prometer execucao num criterio que nao executa e a
# mesma patologia que a auditoria encontrou no dado.
tentar(8, "todo alvo tar_make(...) citado na documentacao EXISTE no grafo", {
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
  # Duas formas, e a segunda existe porque a primeira sozinha deixou passar um
  # vazamento real: os quatro identificadores LEGADOS estao listados como "- `id`",
  # mas o identificador OFICIAL aparece so em prosa, como `MAPE_GCP_BILLING=<id>`.
  # Conferir apenas a lista dava OK enquanto o oficial estava em
  # dicionario/proveniencia.csv, versionado e empurrado para o remoto publico.
  ids <- unlist(regmatches(linhas, gregexpr("(?<=^- `)[^`]+(?=`)", linhas, perl = TRUE)))
  # O charset e o comprimento sao os que o GCP impoe a um project id (6 a 30,
  # minuscula/digito/hifen, comecando por letra). Sem isso o padrao captura o
  # lixo que vier depois do "=" e produz falso positivo em qualquer arquivo.
  ids <- c(ids, unlist(regmatches(
    linhas, gregexpr("(?<=MAPE_GCP_BILLING=)[a-z][a-z0-9-]{5,29}", linhas, perl = TRUE))))
  ids <- unique(ids[nzchar(ids)])
  if (!length(ids)) {
    return(list(ok = FALSE, detalhe = "a nota nao lista identificadores no formato esperado (- `id`)"))
  }
  versionados <- system2("git", c("-C", RAIZ, "ls-files"), stdout = TRUE)
  versionados <- versionados[!grepl("[.]local[.]md$", versionados)]
  # Lê BYTE A BYTE, e não por linha. `readLines()` sobre arquivo binário emite
  # warning e o tratador o convertia em character(), pulando o arquivo em
  # silêncio — 52 dos arquivos versionados são .parquet, .gz ou .xlsx, e um
  # portão que pula o que não sabe ler não é portão.
  achados <- character()
  padroes <- lapply(ids, charToRaw)
  contem <- function(bruto, padrao) {
    n <- length(padrao)
    if (!n || length(bruto) < n) return(FALSE)
    inicio <- which(bruto == padrao[1])
    for (i in inicio) {
      if (i + n - 1L <= length(bruto) && all(bruto[i:(i + n - 1L)] == padrao)) return(TRUE)
    }
    FALSE
  }
  for (arq in versionados) {
    caminho <- file.path(RAIZ, arq)
    if (!file.exists(caminho)) next
    bruto <- tryCatch(readBin(caminho, "raw", n = file.size(caminho)),
                      error = function(e) raw())
    if (!length(bruto)) next
    for (k in seq_along(ids)) {
      if (contem(bruto, padroes[[k]])) {
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
  # Este criterio conferia PRESENCA: bastava o numero certo aparecer em algum
  # lugar do arquivo para o numero errado ao lado ficar invisivel. Foi assim que
  # "413 expectativas" sobreviveu na linha 104 enquanto a linha 70 ja dizia 564,
  # com o portao passando. Agora confere AUSENCIA DE CONTRADICAO: nenhum OUTRO
  # numero pode aparecer no mesmo contexto.
  exigir <- function(rotulo, valor, padrao) {
    ocorrencias <- unlist(regmatches(txt, gregexpr(padrao, txt, perl = TRUE)))
    numeros <- unique(gsub("[^0-9]", "", ocorrencias))
    numeros <- numeros[nzchar(numeros)]
    if (!length(numeros)) {
      problemas <<- c(problemas, paste0(rotulo, ": nao citado (esperava ", valor, ")"))
    } else if (!all(numeros == as.character(valor))) {
      problemas <<- c(problemas, sprintf("%s: o arquivo diz %s e a medicao da %s",
                                         rotulo, paste(setdiff(numeros, as.character(valor)),
                                                       collapse = "/"), valor))
    }
  }
  # Os padroes sao ancorados no CONTEXTO, e nao no substantivo solto: o
  # CLAUDE.md fala legitimamente de "110 variaveis" (as que tem campo calculado
  # medido na fonte) e de "15 tabelas" (as sem caminho de reconstrucao), que sao
  # outras medidas e nao contradicao.
  exigir("pacotes",      lock,  "\\*{0,2}[0-9]+\\*{0,2} pacotes no lockfile")
  exigir("variaveis",    n_var, "\\*{0,2}[0-9]+\\*{0,2} vari[áa]veis (documentadas|no dicion[áa]rio)")
  exigir("tabelas",      n_tab, "\\*{0,2}[0-9]+\\*{0,2} tabelas publicadas")
  exigir("expectativas", n_exp, "\\*{0,2}[0-9]+\\*{0,2} expectativas")
  # Contradicao interna sobre validacao: o numero de avisos tem de ser um so.
  avisos <- unique(unlist(regmatches(txt, gregexpr("[0-9]+ avisos", txt))))
  if (length(avisos) > 1) {
    problemas <- c(problemas, paste("avisos citados de formas diferentes:",
                                    paste(avisos, collapse = ", ")))
  }
  # E nao pode continuar afirmando que nenhum achado foi corrigido.
  if (grepl("nenhum foi corrigido", txt, fixed = TRUE))
    problemas <- c(problemas, "ainda diz 'nenhum foi corrigido'")

  list(ok = !length(problemas),
       detalhe = if (length(problemas)) paste("desatualizado em:", paste(problemas, collapse = ", "))
                 else sprintf("%d pacotes, %d variaveis, %d tabelas, %d expectativas",
                              lock, n_var, n_tab, n_exp))
})

# -- 13 ---------------------------------------------------------------------
# Os criterios 13 a 16 nasceram da reverificacao de 26/07/2026, que reexecutou
# os 105 grupos e derrubou cinco deles. Todos os cinco passavam pelos doze
# criterios anteriores, e passavam porque nenhum deles olhava o ARTEFATO: o
# codigo era corrigido e o .md publicado continuava com o texto velho.
tentar(13, "a documentacao gerada esta em dia com o dicionario e com o dado", {
  gerados <- c(list.files(file.path(RAIZ, "dados", "dimensao"), pattern = "[.]md$",
                          full.names = TRUE),
               list.files(file.path(RAIZ, "fontes"), pattern = "README[.]md$",
                          recursive = TRUE, full.names = TRUE))
  gerados <- gerados[file.exists(gerados)]
  # Sem `return()` aqui de proposito: `tentar()` recebe a expressao como
  # promessa e a avalia no ambiente do chamador, que e o topo do script — um
  # `return()` ali morre com "no function to return from".
  if (!length(gerados)) {
    list(ok = FALSE, detalhe = "nenhum documento gerado encontrado")
  } else {
    # Regera para um espelho temporario e compara: se der diferenca, o .md
    # publicado nao corresponde ao dicionario atual.
    raiz_velha <- getOption("mape.raiz")
    espelho <- file.path(tempdir(), "fechamento_doc")
    unlink(espelho, recursive = TRUE)
    dir.create(espelho, recursive = TRUE, showWarnings = FALSE)
    # file.copy("a/b", dest, recursive = TRUE) cria dest/b, e nao dest/a/b:
    # por isso copiamos as pastas de PRIMEIRO nivel.
    for (d in c("dados", "dicionario", "config", "qa", "fontes")) {
      if (dir.exists(file.path(RAIZ, d))) {
        file.copy(file.path(RAIZ, d), espelho, recursive = TRUE)
      }
    }
    options(mape.raiz = espelho)
    ok_geracao <- tryCatch({
      suppressWarnings(suppressMessages(mape_gerar_documentacao_completa())); TRUE
    }, error = function(e) conditionMessage(e))
    options(mape.raiz = raiz_velha)

    if (!isTRUE(ok_geracao)) {
      list(ok = FALSE, detalhe = paste("a geracao falhou:", ok_geracao))
    } else {
      # A linha de data muda a cada execucao; compara ignorando ela.
      # O carimbo aparece em duas formas: "Gerado em ..." no cabeçalho e
      # "_Gerado em ... por `...`._" no rodapé. Ignorar só a primeira faria
      # todo documento parecer fora de sincronia.
      sem_data <- function(p) paste(grep("^_?Gerado em ", readLines(p, warn = FALSE),
                                         invert = TRUE, value = TRUE), collapse = "\n")
      desatualizados <- character()
      comparados <- 0L
      for (f in gerados) {
        rel <- sub(paste0("^", RAIZ, "/?"), "", f)
        novo <- file.path(espelho, rel)
        if (!file.exists(novo)) next
        comparados <- comparados + 1L
        if (!identical(sem_data(f), sem_data(novo))) desatualizados <- c(desatualizados, rel)
      }
      list(ok = !length(desatualizados) && comparados > 0L,
           detalhe = if (length(desatualizados))
             sprintf("%d de %d documento(s) fora de sincronia: %s", length(desatualizados),
                     comparados, paste(utils::head(desatualizados, 6), collapse = ", "))
           else if (!comparados) "nenhum documento pode ser comparado no espelho"
           else sprintf("%d documento(s) gerado(s) comparados, todos em dia", comparados))
    }
  }
})

# -- 14 ---------------------------------------------------------------------
tentar(14, "a paridade nao tem diferenca nao explicada nem reivindicacao morta", {
  arqs <- list.files(file.path(RAIZ, "qa"), pattern = "^paridade_.*[.]md$", full.names = TRUE)
  if (!length(arqs)) return(list(ok = FALSE, detalhe = "nenhum relatorio de paridade"))
  com_pendencia <- character()
  for (a in arqs) {
    l <- readLines(a, warn = FALSE)
    m <- regmatches(l, regexpr("(?<=Diferenças não explicadas: )[0-9]+", l, perl = TRUE))
    m <- unlist(m)
    if (!length(m) || as.integer(m[1]) > 0) com_pendencia <- c(com_pendencia, basename(a))
    if (!any(grepl("sha256", l))) com_pendencia <- c(com_pendencia, paste0(basename(a), " (sem sha256)"))
  }
  # Achado 25: o relatorio publicado era ANTERIOR as reivindicacoes, entao ele
  # mostrava um estado que o arquivo de reivindicacoes ja tinha mudado.
  esp <- file.path(RAIZ, "qa", "paridade_esperada.csv")
  velhos <- if (file.exists(esp)) {
    basename(arqs[file.mtime(arqs) < file.mtime(esp)])
  } else character()
  list(ok = !length(com_pendencia) && !length(velhos),
       detalhe = paste(c(
         if (length(com_pendencia)) paste("com pendencia:", paste(unique(com_pendencia), collapse = ", ")),
         if (length(velhos)) paste("gerados ANTES de paridade_esperada.csv:", paste(velhos, collapse = ", ")),
         if (!length(com_pendencia) && !length(velhos))
           sprintf("%d relatorio(s), 0 nao explicadas, todos com sha256 e mais novos que as reivindicacoes",
                   length(arqs))), collapse = "; "))
})

# -- 15 ---------------------------------------------------------------------
tentar(15, "todo renomeio de deprecacao.csv resolve numa coluna publicada", {
  dep <- mape_dicionario("deprecacao")
  pub <- mape_dicionario("variaveis")$nome_canonico
  prox <- split(dep$nome_novo, dep$nome_antigo)
  resolve <- function(n) {
    visto <- character(); fila <- n
    while (length(fila)) {
      c1 <- fila[1]; fila <- fila[-1]
      if (c1 %in% pub) return(TRUE)
      if (c1 %in% visto) next
      visto <- c(visto, c1)
      fila <- c(fila, prox[[c1]])
    }
    FALSE
  }
  ren <- dep[!is.na(dep$acao) & dep$acao == "renomear", , drop = FALSE]
  destinos <- unique(ren$nome_novo)
  mortos <- destinos[!vapply(destinos, resolve, logical(1))]
  list(ok = !length(mortos),
       detalhe = if (length(mortos))
         sprintf("%d destino(s) que nao resolvem: %s", length(mortos),
                 paste(utils::head(mortos, 8), collapse = ", "))
       else sprintf("%d renomeio(s), %d destino(s) distinto(s), todos resolvem",
                    nrow(ren), length(destinos)))
})

# -- 16 ---------------------------------------------------------------------
tentar(16, "nenhum documento gerado repete afirmacao que o dado desmente", {
  # Uma errata que introduz afirmacao falsa e pior que a omissao que ela
  # conserta. Estas quatro foram medidas e falsificadas em 26/07/2026.
  proibidas <- list(
    list(arq = "dados/dimensao/12_habitacao.md",
         padrao = "dois jeitos contraditorios: zero nas linhas fabricadas e NA",
         motivo = "a tabela nao tem uma unica celula NA (achado 15)"),
    list(arq = "dados/dimensao/13_seguranca.md",
         padrao = "que a junção descarta",
         motivo = "os pseudo-codigos ESTAO publicados (achado 13)"),
    list(arq = "dados/dimensao/09_educacao.md",
         padrao = "media_saeb_\\* NÃO vêm do SAEB",
         motivo = "nome legado, e a afirmacao contradiz a descricao das colunas (achado 63)"),
    list(arq = "dados/dimensao/04_economia.md",
         padrao = "não é reprodutível",
         motivo = "pib_per_capita reproduz em 127.786 de 127.786 linhas (achado 62)")
  )
  achadas <- character()
  for (p in proibidas) {
    caminho <- file.path(RAIZ, p$arq)
    if (!file.exists(caminho)) next
    if (any(grepl(p$padrao, readLines(caminho, warn = FALSE)))) {
      achadas <- c(achadas, paste0(p$arq, ": ", p$motivo))
    }
  }
  list(ok = !length(achadas),
       detalhe = if (length(achadas)) paste(achadas, collapse = "; ")
                 else sprintf("%d afirmacao(oes) falsificada(s) conferida(s); nenhuma sobreviveu",
                              length(proibidas)))
})

# -- 17 ---------------------------------------------------------------------
# A reverificacao achou o dist/ uma geracao atras da arvore: os 26 qa/*.md
# embarcados diziam "Checagens executadas: 18" contra 19, e nao levavam a
# checagem de exclusividade territorial. Quem consome o release nao veria o
# aviso. dist/ nao e versionado, entao este criterio so vale quando ele existe.
tentar(17, "o release montado em dist/ nao esta atras da arvore", {
  raiz_dist <- list.dirs(file.path(RAIZ, "dist"), recursive = FALSE)
  if (!length(raiz_dist)) {
    list(ok = TRUE, detalhe = "dist/ nao existe nesta copia: nada a conferir")
  } else {
    divergentes <- character(); conferidos <- 0L
    sem_data <- function(p) paste(grep("^_?Gerado em ", readLines(p, warn = FALSE),
                                       invert = TRUE, value = TRUE), collapse = "\n")
    # O bundle achata `dados/dimensao/x.parquet` em `dados/x.parquet` e
    # `dados/fonte/<dim>/y.parquet` em `dados/y.parquet`. Comparar pelo caminho
    # literal fazia `file.exists()` dar FALSE e o laco pular os 52 arquivos de
    # dado em silencio — o payload do release nunca era conferido.
    localizar <- function(rel) {
      direto <- file.path(RAIZ, rel)
      if (file.exists(direto)) return(direto)
      if (!grepl("^dados/", rel)) return(NA_character_)
      cand <- list.files(file.path(RAIZ, "dados"), pattern = paste0("^", basename(rel), "$"),
                         recursive = TRUE, full.names = TRUE)
      if (length(cand) == 1L) cand else NA_character_
    }
    for (d in raiz_dist) {
      embarcados <- list.files(d, recursive = TRUE, full.names = TRUE)
      embarcados <- embarcados[!grepl("(SHA256SUMS[.]txt|documentacao[.]tar[.]gz)$", embarcados)]
      for (f in embarcados) {
        rel <- sub(paste0("^", d, "/?"), "", f)
        na_arvore <- localizar(rel)
        if (is.na(na_arvore)) next
        conferidos <- conferidos + 1L
        igual <- if (grepl("[.](md|csv)$", f)) {
          identical(sem_data(f), sem_data(na_arvore))
        } else {
          # Dado e binario: compara por hash, e nao por linha.
          identical(digest::digest(f, algo = "sha256", file = TRUE),
                    digest::digest(na_arvore, algo = "sha256", file = TRUE))
        }
        if (!igual) divergentes <- c(divergentes, rel)
      }
      # E as somas do proprio bundle tem de fechar. `system2` roda no diretorio
      # do processo R, e nao em `d` — sem o setwd o shasum nao achava o arquivo,
      # devolvia "No such file or directory", zero linhas FAILED, e o criterio
      # passava sempre. Era metade do portao morta.
      if (file.exists(file.path(d, "SHA256SUMS.txt"))) {
        antes <- setwd(d)
        r <- suppressWarnings(system2("shasum", c("-a", "256", "-c", "SHA256SUMS.txt"),
                                      stdout = TRUE, stderr = TRUE))
        setwd(antes)
        falhas <- grep("FAILED|No such file", r, value = TRUE)
        if (length(falhas)) {
          divergentes <- c(divergentes, sprintf("%s: SHA256SUMS nao fecha (%d linha[s])",
                                                basename(d), length(falhas)))
        }
      }
    }
    list(ok = !length(divergentes),
         detalhe = if (length(divergentes))
           sprintf("%d artefato(s) do release atras da arvore: %s", length(divergentes),
                   paste(utils::head(divergentes, 6), collapse = ", "))
         else sprintf("%d artefato(s) embarcado(s) conferido(s), todos em dia", conferidos))
  }
})

# -- 18 ---------------------------------------------------------------------
registrar(18, "este script existe, cobre os dezessete acima e sai com codigo nao zero", TRUE,
          "17 criterios verificados acima")

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
