test_that("mape_como_codigo preserva zeros à esquerda", {
  # O caso que motiva a função: um código que passou por numérico em algum
  # ponto da cadeia e perdeu o zero inicial.
  expect_equal(mape_como_codigo(110015, 7L, avisar = FALSE), "0110015")
  expect_equal(mape_como_codigo("1100015"), "1100015")
  expect_equal(mape_como_codigo(1100015), "1100015")
})

test_that("mape_como_codigo remove separador de milhar de planilha", {
  # O MCMV traz o código como "110.020".
  expect_equal(mape_como_codigo("110.020", 6L, avisar = FALSE), "110020")
})

test_that("mape_como_codigo devolve NA em vez de código truncado", {
  expect_warning(res <- mape_como_codigo(c("1100015", "12345678", "abc")))
  expect_equal(res, c("1100015", NA, NA))
})

test_that("mape_como_codigo preserva NA", {
  expect_equal(mape_como_codigo(c("1100015", NA)), c("1100015", NA))
})

test_that("mape_como_codigo não usa notação científica", {
  # format() sem scipen transformaria 3550308 em 3.55e+06 dependendo do
  # contexto, e o código sairia corrompido.
  expect_equal(mape_como_codigo(3550308), "3550308")
})

test_that("mape_como_inteiro trata integer64 corretamente", {
  skip_if_not_installed("bit64")
  v <- bit64::as.integer64(c(2015, 2016, 2017))
  # as.numeric() sobre integer64 devolve lixo; é o defeito real do legado.
  expect_equal(mape_como_inteiro(v), c(2015L, 2016L, 2017L))
})

test_that("mape_como_inteiro converte texto e trata vazio", {
  expect_equal(mape_como_inteiro(c("2015", " 2016 ", "")), c(2015L, 2016L, NA))
})

test_that("mape_normalizar_chaves aplica o contrato e reordena", {
  x <- data.frame(valor = 1:2, ano = c("2015", "2016"),
                  id_municipio = c(1100015, 3304557), stringsAsFactors = FALSE)
  res <- mape_normalizar_chaves(x)
  expect_equal(names(res)[1:2], c("id_municipio", "ano"))
  expect_type(res$id_municipio, "character")
  expect_type(res$ano, "integer")
})

test_that("mape_normalizar_chaves falha com mensagem útil se a coluna não existe", {
  expect_error(mape_normalizar_chaves(data.frame(a = 1), id = "id_municipio"),
               "não existe na tabela")
})

test_that("mape_validar_dominio_chave reporta órfãos em vez de descartar", {
  x <- data.frame(
    # 1100000 é um dos 27 códigos de UF disfarçados de município na Segurança.
    id_municipio = c("1100015", "3304557", "1100000"),
    stringsAsFactors = FALSE
  )
  expect_warning(
    diag <- mape_validar_dominio_chave(x, diretorio = diretorio_teste),
    "fora do diretório"
  )
  expect_equal(diag$codigos_orfaos, "1100000")
  expect_equal(diag$n_linhas_orfas, 1)
})

test_that("mape_validar_dominio_chave avisa sobre chave nula", {
  x <- data.frame(id_municipio = c("1100015", NA), stringsAsFactors = FALSE)
  expect_warning(mape_validar_dominio_chave(x, diretorio = diretorio_teste),
                 "nulo")
})

test_that("mape_id7_de_id6 recupera o código e reporta não-casados", {
  x <- data.frame(id_municipio_6 = c("110001", "999999"), v = 1:2,
                  stringsAsFactors = FALSE)
  expect_warning(res <- mape_id7_de_id6(x, diretorio = diretorio_teste),
                 "não existem no diretório")
  expect_equal(res$id_municipio, c("1100015", NA))
  expect_false("id_municipio_6" %in% names(res))
  expect_equal(attr(res, "mape_orfaos"), "999999")
})

test_that("mape_id7_de_id6 nunca multiplica linhas", {
  x <- data.frame(id_municipio_6 = rep("110001", 5), stringsAsFactors = FALSE)
  res <- mape_id7_de_id6(x, diretorio = diretorio_teste)
  expect_equal(nrow(res), 5)
})

test_that("mape_para_geobr converte para inteiro", {
  x <- data.frame(id_municipio = "3550308", stringsAsFactors = FALSE)
  expect_type(mape_para_geobr(x)$id_municipio, "integer")
})
