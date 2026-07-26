# Guarda de perda na escrita — achado crítico nº 6 da auditoria de 26/07/2026.
#
# Antes desta guarda, tar_make(dim_11_transportes) trocava 183.814 linhas e
# 5.570 municípios de dados/dimensao/11_transportes.parquet por 929 linhas e
# 133 municípios, sem nenhum aviso. Nada comparava o novo com o publicado.
#
# Todos os testes daqui gravam num tempdir(), nunca na árvore real: a âncora de
# mape_caminho() é sobrescrita por getOption("mape.raiz").

raiz_falsa <- function() {
  r <- file.path(tempdir(), paste0("mape-teste-", as.integer(runif(1, 1, 1e9))))
  dir.create(file.path(r, "dados", "dimensao"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(r, "qa"), recursive = TRUE, showWarnings = FALSE)
  # A âncora redireciona TUDO, inclusive a leitura de config/parametros.yml.
  # Copiar o arquivo real mantém os testes falando dos mesmos parâmetros que a
  # produção, em vez de inventar um config de teste que poderia divergir.
  dir.create(file.path(r, "config"), recursive = TRUE, showWarnings = FALSE)
  file.copy(here::here("config", "parametros.yml"), file.path(r, "config"))
  # O cache de parâmetros é por sessão e guarda o conteúdo, não o caminho;
  # limpá-lo evita que a raiz falsa herde ou contamine a leitura da raiz real.
  rm(list = ls(.mape_cache_param), envir = .mape_cache_param)
  r
}

# Painel sintético de 4 municípios x 3 anos, com uma coluna de conteúdo.
painel_falso <- function(municipios = c("1100015", "3304557", "3550308", "1700400"),
                         anos = 2020:2022) {
  x <- expand.grid(id_municipio = municipios, ano = anos,
                   stringsAsFactors = FALSE)
  x$id_municipio <- as.character(x$id_municipio)
  x$ano <- as.integer(x$ano)
  x$valor_i <- seq_len(nrow(x))
  x$ano_ref_fonte <- 2019L
  x[order(x$id_municipio, x$ano), ]
}

test_that("mape_medir_tabela mede as quatro grandezas que não podem encolher", {
  m <- mape_medir_tabela(painel_falso())
  expect_equal(m$n_linhas, 12)
  expect_equal(m$n_colunas, 4)
  expect_equal(m$n_chaves, 12)
  expect_equal(m$n_municipios, 4)
})

test_that("sobrescrever SEM perda passa", {
  raiz <- raiz_falsa()
  withr::local_options(mape.raiz = raiz)

  x <- painel_falso()
  expect_silent(suppressMessages(
    mape_escrever_tabela(x, "99_teste", formatos = character(),
                         validar = FALSE, camada = "dimensao")))

  # Mesma tabela com uma coluna A MAIS: não perde nada, tem de passar.
  y <- x
  y$valor_novo_i <- 1L
  expect_silent(suppressMessages(
    mape_escrever_tabela(y, "99_teste", formatos = character(),
                         validar = FALSE, camada = "dimensao")))

  relido <- as.data.frame(arrow::read_parquet(
    file.path(raiz, "dados", "dimensao", "99_teste.parquet")))
  expect_equal(nrow(relido), 12)
  expect_true("valor_novo_i" %in% names(relido))
})

test_that("sobrescrever COM perda de linhas falha e não grava", {
  raiz <- raiz_falsa()
  withr::local_options(mape.raiz = raiz)
  destino <- file.path(raiz, "dados", "dimensao", "99_teste.parquet")

  x <- painel_falso()
  suppressMessages(mape_escrever_tabela(x, "99_teste", formatos = character(),
                                        validar = FALSE, camada = "dimensao"))

  # É este o caso do achado 6: a consolidação devolve um subconjunto.
  truncada <- x[x$ano == 2022, ]
  expect_error(
    suppressMessages(mape_escrever_tabela(truncada, "99_teste", formatos = character(),
                                          validar = FALSE, camada = "dimensao")),
    "destruiria dado publicado"
  )

  # E o arquivo continua sendo o de 12 linhas: a guarda barra ANTES de gravar.
  expect_equal(nrow(as.data.frame(arrow::read_parquet(destino))), 12)
})

test_that("sobrescrever COM perda de municípios falha, mesmo mantendo as linhas", {
  raiz <- raiz_falsa()
  withr::local_options(mape.raiz = raiz)

  x <- painel_falso()
  suppressMessages(mape_escrever_tabela(x, "99_teste", formatos = character(),
                                        validar = FALSE, camada = "dimensao"))

  # 12 linhas de novo, mas concentradas em 2 municípios: n_linhas não cai e
  # n_municipios sim. É a queda de 5.570 para 133 de 11_transportes, em
  # miniatura, e é por isso que a guarda olha as quatro grandezas e não só uma.
  y <- painel_falso(municipios = c("1100015", "3304557"), anos = 2020:2025)
  expect_equal(nrow(y), 12)
  expect_error(
    suppressMessages(mape_escrever_tabela(y, "99_teste", formatos = character(),
                                          validar = FALSE, camada = "dimensao")),
    "n_municipios"
  )
})

test_that("sobrescrever perdendo uma coluna declarada falha e nomeia a coluna", {
  raiz <- raiz_falsa()
  withr::local_options(mape.raiz = raiz)

  x <- painel_falso()
  suppressMessages(mape_escrever_tabela(x, "99_teste", formatos = character(),
                                        validar = FALSE, camada = "dimensao"))

  # A perda de ano_ref_ideb em 09_educacao, em miniatura.
  y <- x[, setdiff(names(x), "ano_ref_fonte")]
  expect_error(
    suppressMessages(mape_escrever_tabela(y, "99_teste", formatos = character(),
                                          validar = FALSE, camada = "dimensao")),
    "ano_ref_fonte"
  )
})

test_that("permitir_perda exige motivo, e o motivo fica registrado", {
  raiz <- raiz_falsa()
  withr::local_options(mape.raiz = raiz)

  x <- painel_falso()
  suppressMessages(mape_escrever_tabela(x, "99_teste", formatos = character(),
                                        validar = FALSE, camada = "dimensao"))
  truncada <- x[x$ano == 2022, ]

  # Autorizar sem motivo não vale: um registro sem motivo não serve para nada.
  expect_error(
    suppressMessages(mape_escrever_tabela(truncada, "99_teste", formatos = character(),
                                          validar = FALSE, camada = "dimensao",
                                          permitir_perda = TRUE)),
    "exige motivo_perda"
  )

  # Com motivo, grava e deixa rastro.
  suppressMessages(mape_escrever_tabela(truncada, "99_teste", formatos = character(),
                                        validar = FALSE, camada = "dimensao",
                                        permitir_perda = TRUE,
                                        motivo_perda = "teste: truncagem deliberada"))
  registro <- file.path(raiz, "qa", "perdas_autorizadas.csv")
  expect_true(file.exists(registro))
  reg <- utils::read.csv(registro, stringsAsFactors = FALSE)
  expect_equal(nrow(reg), 1)
  expect_equal(reg$n_linhas_antes, 12)
  expect_equal(reg$n_linhas_depois, 4)
  expect_match(reg$motivo, "truncagem deliberada")
})

test_that("tabela nova (que ainda não existe) grava sem barreira", {
  raiz <- raiz_falsa()
  withr::local_options(mape.raiz = raiz)
  expect_silent(suppressMessages(
    mape_escrever_tabela(painel_falso(), "99_inedita", formatos = character(),
                         validar = FALSE, camada = "dimensao")))
})

test_that("os três alvos dim_* se comportam como a auditoria mediu", {
  # Este é o teste de regressão do achado 6 sobre o dado real. Ele NÃO grava:
  # usa publicar = FALSE, que é o modo de inspeção documentado no CLAUDE.md.
  skip_if_not(file.exists(here::here("dados", "dimensao", "11_transportes.parquet")))

  medir <- function(slug) {
    pub <- as.data.frame(arrow::read_parquet(
      here::here("dados", "dimensao", paste0(slug, ".parquet"))))
    rec <- as.data.frame(suppressWarnings(suppressMessages(
      mape_consolidar_dimensao(slug, publicar = FALSE))))
    list(pub = mape_medir_tabela(pub), rec = mape_medir_tabela(rec))
  }

  # 01_assistencia_social_dh reproduz fielmente: é o controle.
  m <- medir("01_assistencia_social_dh")
  expect_equal(m$rec$n_linhas, m$pub$n_linhas)
  expect_equal(m$rec$n_municipios, m$pub$n_municipios)

  # 11_transportes não reproduz, e por isso a guarda tem de barrar.
  m <- medir("11_transportes")
  expect_lt(m$rec$n_municipios, m$pub$n_municipios)
  expect_error(
    suppressMessages(mape_conferir_perda(
      data.frame(id_municipio = "1100015", ano = 2020L),
      "11_transportes", camada = "dimensao")),
    "destruiria dado publicado"
  )
})
