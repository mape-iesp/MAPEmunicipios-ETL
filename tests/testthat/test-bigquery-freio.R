# Freio de custo do BigQuery — § 6 da rodada de correção.
#
# Antes deste freio, mape_query() chamava basedosdados::read_sql() direto: sem
# dry-run, sem teto e sem registro de custo. O modelo on-demand cobra por byte
# escaneado, então uma consulta mal escrita custava dinheiro real e o custo só
# aparecia na fatura.
#
# Estes testes não tocam a rede. O que eles provam é a aritmética dos tetos e o
# fato de que o teto lido do YAML é um número utilizável — que foi exatamente
# onde o freio quase falhou em silêncio.

# Estas funções são carregadas em globalenv() por setup.R, não vêm de um
# pacote, então local_mocked_bindings(.env = globalenv()) não as alcança.
# Troca direta com restauração no fim do teste resolve.
trocar_global <- function(nome, valor, envir = parent.frame()) {
  antigo <- get(nome, envir = globalenv())
  assign(nome, valor, envir = globalenv())
  withr::defer(assign(nome, antigo, envir = globalenv()), envir = envir)
}

test_that("os tetos saem do YAML como bytes utilizáveis", {
  tc <- mape_teto_bq("consulta")
  ts <- mape_teto_bq("sessao")

  expect_true(is.numeric(tc) && !is.na(tc) && tc > 0)
  expect_true(is.numeric(ts) && !is.na(ts) && ts > 0)
  expect_equal(tc, 64 * 1024^3)
  expect_equal(ts, 512 * 1024^3)

  # O teto de sessão é metade da cota grátis mensal de 1 TiB, que é a decisão
  # registrada em config/parametros.yml.
  expect_equal(ts, 0.5 * 1024^4)
  # E o teto por consulta tem de ser menor que o de sessão, senão uma consulta
  # sozinha poderia estourar o acumulado.
  expect_lt(tc, ts)
})

test_that("o teto NÃO é lido em bytes diretos do YAML", {
  # Este teste existe por causa de um modo de falha real: declarar o teto em
  # bytes (68719476736) faz o leitor de YAML do R devolver NA em silêncio,
  # porque o valor estoura o int32. Um teto NA desligaria o freio inteiro sem
  # emitir nada. A declaração em GiB é o que evita isso, e mape_teto_bq() tem um
  # stopifnot que recusa NA.
  expect_error(mape_param("bq.teto_bytes_consulta"), "não encontrado")
  expect_type(mape_param("bq.teto_gib_consulta"), "integer")
  expect_false(is.na(mape_param("bq.teto_gib_consulta")))
})

test_that("mape_formatar_bytes escala a unidade", {
  expect_equal(mape_formatar_bytes(0), "0.00 B")
  expect_equal(mape_formatar_bytes(1023), "1023.00 B")
  expect_equal(mape_formatar_bytes(1024), "1.00 KiB")
  expect_equal(mape_formatar_bytes(3061650), "2.92 MiB")
  expect_equal(mape_formatar_bytes(64 * 1024^3), "64.00 GiB")
  expect_equal(mape_formatar_bytes(1024^4), "1.00 TiB")
})

test_that("o acumulado sai de qa/custo_bigquery.csv e começa em zero quando não há arquivo", {
  raiz <- file.path(tempdir(), paste0("mape-bq-", as.integer(runif(1, 1, 1e9))))
  dir.create(file.path(raiz, "qa"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(raiz, "config"), recursive = TRUE, showWarnings = FALSE)
  file.copy(here::here("config", "parametros.yml"), file.path(raiz, "config"))
  withr::local_options(mape.raiz = raiz)
  rm(list = ls(.mape_cache_param), envir = .mape_cache_param)

  expect_equal(mape_custo_bigquery(), 0)

  utils::write.csv(
    data.frame(data = "2026-07-26 12:00:00", fonte = "teste",
               sql_resumo = "SELECT 1", hash_consulta = "abc",
               bytes_dry_run = "1000", bytes_cobrados = "3061650",
               n_linhas = 1, segundos = 0.1, stringsAsFactors = FALSE),
    file.path(raiz, "qa", "custo_bigquery.csv"), row.names = FALSE)

  expect_equal(mape_custo_bigquery(), 3061650)
})

test_that("uma consulta acima do teto é recusada antes de sair da máquina", {
  # Substitui só o dry-run: se o teto funcionar, bq_project_query() nunca é
  # alcançado, e por isso este teste não precisa de rede nem de credencial.
  trocar_global("mape_billing_id", function() "projeto-de-teste")
  trocar_global("mape_teto_bq", function(qual = "consulta") if (qual == "consulta") 1000 else 1e12)
  testthat::local_mocked_bindings(
    bq_perform_query_dry_run = function(...) 5e9,
    .package = "bigrquery"
  )

  expect_error(
    suppressMessages(mape_query("SELECT * FROM tabela.enorme", fonte = "teste")),
    "Consulta recusada: escanearia"
  )
})

test_that("o teto acumulado da sessão também recusa", {
  raiz <- file.path(tempdir(), paste0("mape-bq-", as.integer(runif(1, 1, 1e9))))
  dir.create(file.path(raiz, "qa"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(raiz, "config"), recursive = TRUE, showWarnings = FALSE)
  file.copy(here::here("config", "parametros.yml"), file.path(raiz, "config"))
  withr::local_options(mape.raiz = raiz)
  rm(list = ls(.mape_cache_param), envir = .mape_cache_param)

  # Já gastou quase tudo: 500 GiB dos 512 GiB de teto.
  utils::write.csv(
    data.frame(data = "2026-07-26 12:00:00", fonte = "anterior",
               sql_resumo = "SELECT 1", hash_consulta = "abc",
               bytes_dry_run = "1", bytes_cobrados = format(500 * 1024^3, scientific = FALSE),
               n_linhas = 1, segundos = 0.1, stringsAsFactors = FALSE),
    file.path(raiz, "qa", "custo_bigquery.csv"), row.names = FALSE)

  trocar_global("mape_billing_id", function() "projeto-de-teste")
  testthat::local_mocked_bindings(
    # 20 GiB: passa no teto por consulta (64 GiB) e estoura o acumulado.
    bq_perform_query_dry_run = function(...) 20 * 1024^3,
    .package = "bigrquery"
  )

  expect_error(
    suppressMessages(mape_query("SELECT * FROM tabela", fonte = "teste")),
    "teto acumulado"
  )
})

test_that("so_estimar devolve os bytes e não executa nada", {
  trocar_global("mape_billing_id", function() "projeto-de-teste")
  testthat::local_mocked_bindings(
    bq_perform_query_dry_run = function(...) 3061650,
    # Se a execução for alcançada, o teste falha com esta mensagem em vez de
    # passar por acidente.
    bq_project_query = function(...) stop("so_estimar executou a consulta"),
    .package = "bigrquery"
  )

  b <- suppressMessages(mape_query("SELECT 1", fonte = "teste", so_estimar = TRUE))
  expect_equal(b, 3061650)
})

test_that("o dry-run que falha impede a consulta em vez de deixá-la passar", {
  trocar_global("mape_billing_id", function() "projeto-de-teste")
  testthat::local_mocked_bindings(
    bq_perform_query_dry_run = function(...) stop("sem credencial"),
    bq_project_query = function(...) stop("executou apesar do dry-run ter falhado"),
    .package = "bigrquery"
  )

  expect_error(
    suppressMessages(mape_query("SELECT 1", fonte = "teste")),
    "dry-run falhou"
  )
})
