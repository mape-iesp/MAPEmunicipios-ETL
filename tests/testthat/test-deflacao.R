# Deflação — achado 37.
#
# mape_deflacionar() chamava deflateBR::ipca() DENTRO do laço de colunas, então
# N colunas custavam N downloads da API do IPEA. Pior que o custo: o resultado
# não era reprodutível (uma série de índice de preços é revisada), nada
# registrava qual série tinha sido usada, e a função só rodava com rede.
#
# Nenhum destes testes toca a rede.

test_that("a série do IPCA está fixada e versionada", {
  s <- mape_serie_ipca()
  expect_true(nrow(s) > 300)
  expect_s3_class(s$data, "Date")
  expect_true(all(is.finite(s$indice)))
  expect_true(all(diff(s$data) > 0))
  # O mês-base fica gravado no arquivo, não só no YAML.
  expect_equal(s$base[1], mape_param("deflator_base"))
})

test_that("mape_deflacionar cria coluna nova e não toca na de entrada", {
  x <- data.frame(ano = c(2010L, 2020L), v_brl_nominal = c(1000, 1000))
  y <- mape_deflacionar(x, "v_brl_nominal")

  # A coluna de entrada sai byte a byte intacta: o canônico é o nominal.
  expect_equal(y$v_brl_nominal, x$v_brl_nominal)
  # E a nova recebe o sufixo do parâmetro.
  expect_true("v_brl2023" %in% names(y))
  expect_gt(y$v_brl2023[1], y$v_brl2023[2])   # 2010 vale mais que 2020
})

test_that("a deflação registra o que usou", {
  x <- data.frame(ano = 2010L, v_brl_nominal = 1000)
  y <- mape_deflacionar(x, "v_brl_nominal")
  a <- attr(y, "mape_deflacao")
  expect_equal(a$base, "12/2023")
  expect_equal(a$sufixo, "brl2023")
  expect_equal(a$colunas, "v_brl_nominal")
  expect_gt(a$n_indice, 300)
})

test_that("uma série injetada substitui a fixada, sem rede", {
  # É este parâmetro que torna a função testável: antes, testar a deflação
  # exigia a API do IPEA no ar.
  serie <- data.frame(data = as.Date(c("2010-12-01", "2023-12-01")),
                      indice = c(50, 100), base = "12/2023")
  x <- data.frame(ano = 2010L, v_brl_nominal = 1000)
  y <- mape_deflacionar(x, "v_brl_nominal", indice = serie)
  expect_equal(y$v_brl2023, 2000)   # índice dobrou, o valor dobra
})

test_that("série gerada para outra base é recusada", {
  serie <- data.frame(data = as.Date("2010-12-01"), indice = 50, base = "12/2021")
  x <- data.frame(ano = 2010L, v_brl_nominal = 1000)
  expect_error(mape_deflacionar(x, "v_brl_nominal", indice = serie),
               "foi gerada para a base")
})

test_that("data fora da série avisa em vez de devolver NA em silêncio", {
  serie <- data.frame(data = as.Date("2023-12-01"), indice = 100, base = "12/2023")
  x <- data.frame(ano = c(1950L, 2023L), v_brl_nominal = c(1000, 1000))
  expect_warning(mape_deflacionar(x, "v_brl_nominal", indice = serie),
                 "fora da série")
})

test_that("mape_marcar_nominal aplica o sufixo sem sobrescrever coluna existente", {
  x <- data.frame(receita = 100, despesa = 50)
  y <- mape_marcar_nominal(x, c("receita", "despesa"))
  expect_setequal(names(y), c("receita_brl_nominal", "despesa_brl_nominal"))
  expect_equal(y$receita_brl_nominal, 100)
  # Idempotente: chamar de novo não empilha sufixo.
  expect_setequal(names(mape_marcar_nominal(y, names(y))), names(y))
})
