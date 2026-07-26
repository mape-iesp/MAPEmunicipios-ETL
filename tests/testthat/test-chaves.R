test_that("mape_como_codigo normaliza sem fabricar código", {
  # Achado 57: este teste protegia o comportamento errado. Ele exigia que
  # mape_como_codigo(110015, 7L) devolvesse "0110015" — um código que não
  # existe, porque o primeiro dígito do código do IBGE é a região (1 a 5) e
  # nenhum município brasileiro tem zero à esquerda.
  expect_equal(mape_como_codigo("1100015"), "1100015")
  expect_equal(mape_como_codigo(1100015), "1100015")
  expect_true(is.na(mape_como_codigo(110015, 7L, avisar = FALSE)))
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

# ---- Achados 57 e 100 -------------------------------------------------------

test_that("mape_como_codigo não fabrica código a partir de entrada curta", {
  # Achado 57: o preenchimento com zero era feito ANTES da checagem de validade,
  # então "1" virava "0000001" — um código de 7 dígitos bem-formado, que passa em
  # todas as checagens e não existe. A documentação prometia NA.
  expect_true(is.na(suppressWarnings(mape_como_codigo("1"))))
  expect_true(is.na(suppressWarnings(mape_como_codigo("42"))))
  expect_true(is.na(suppressWarnings(mape_como_codigo("110"))))
  expect_warning(mape_como_codigo("1"), "não têm 7")

  # O caso que o preenchimento existe para reparar continua funcionando: um
  # código que perdeu UM zero à esquerda ao passar por numérico.
  # Um código de 6 dígitos não vira de 7 com zero: precisa do dígito
  # verificador, que só o diretório tem. Use mape_id7_de_id6().
  expect_true(is.na(mape_como_codigo("110001", digitos = 7L, avisar = FALSE)))
  expect_equal(suppressWarnings(mape_como_codigo(1100015)), "1100015")
  expect_equal(mape_como_codigo("110001", digitos = 6L), "110001")
})

test_that("mape_id7_de_id6 falha em diretório com código de 6 dígitos ambíguo", {
  # Achado 100: match() devolvia o primeiro casamento em silêncio, atribuindo o
  # município errado a metade das linhas. O teste antigo usava um diretório em
  # que a ambiguidade não podia ocorrer.
  ambiguo <- data.frame(
    id_municipio   = c("1100015", "1100023"),
    id_municipio_6 = c("110001",  "110001"),
    stringsAsFactors = FALSE)
  x <- data.frame(id_municipio_6 = "110001", v = 1, stringsAsFactors = FALSE)
  expect_error(mape_id7_de_id6(x, diretorio = ambiguo), "ambíguo")

  # Diretório sem ambiguidade continua funcionando.
  ok <- data.frame(id_municipio = c("1100015", "1100023"),
                   id_municipio_6 = c("110001", "110002"),
                   stringsAsFactors = FALSE)
  r <- mape_id7_de_id6(x, diretorio = ok)
  expect_equal(r$id_municipio, "1100015")
})

test_that("mape_id7_de_id6 avisa antes de sobrescrever id_municipio existente", {
  ok <- data.frame(id_municipio = "1100015", id_municipio_6 = "110001",
                   stringsAsFactors = FALSE)
  x <- data.frame(id_municipio_6 = "110001", id_municipio = "9999999",
                  stringsAsFactors = FALSE)
  expect_warning(mape_id7_de_id6(x, diretorio = ok), "SOBRESCRITA")
})
