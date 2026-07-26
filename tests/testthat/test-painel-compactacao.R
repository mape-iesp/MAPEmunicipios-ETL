# A compactação é o caminho inverso da expansão, e é a metade que faltava para
# a decisão 3.3 do plano deixar de ser intenção. Ela apaga linhas, então precisa
# provar que só apaga as que são cópia.

test_that("compactar por ano_ref fica só com as linhas medidas", {
  # Duas medições (2000 e 2010) replicadas em quatro anos cada.
  x <- data.frame(
    id_municipio = rep("1100015", 8),
    ano = c(2000:2003, 2010:2013),
    ano_ref_ivs = c(rep(2000L, 4), rep(2010L, 4)),
    ivs_idx = c(rep(0.5, 4), rep(0.4, 4)),
    stringsAsFactors = FALSE
  )
  y <- mape_compactar_painel(x, metodo = "ano_ref", ano_ref = "ano_ref_ivs")

  expect_equal(nrow(y), 2)
  expect_equal(y$ano, c(2000L, 2010L))
  expect_equal(y$ivs_idx, c(0.5, 0.4))
  # A coluna de ano de referência sai: guardar as duas convidaria a filtrar
  # pela errada.
  expect_false("ano_ref_ivs" %in% names(y))
})

test_that("compactar por ano_ref exige a coluna de referência", {
  x <- data.frame(id_municipio = "1100015", ano = 2000L, v = 1)
  expect_error(mape_compactar_painel(x, metodo = "ano_ref", ano_ref = "nao_existe"),
               "exige uma coluna de ano de referência")
})

test_that("compactar por constante colapsa o retrato replicado", {
  x <- data.frame(
    id_municipio = rep(c("1100015", "3304557"), each = 3),
    ano = rep(2010:2012, 2),
    risco_idx = rep(c(0.7, 0.2), each = 3),
    stringsAsFactors = FALSE
  )
  y <- mape_compactar_painel(x, metodo = "constante", ano_medicao = 2015L)

  expect_equal(nrow(y), 2)
  expect_true(all(y$ano == 2015L))
  expect_equal(sort(y$risco_idx), c(0.2, 0.7))
})

test_that("compactar por constante recusa colapsar valor que varia", {
  # Se o valor muda ao longo dos anos, não é replicação de um retrato único, e
  # colapsar apagaria medição de verdade. Este é o teste que impede a
  # compactação de destruir dado por engano.
  x <- data.frame(
    id_municipio = rep("1100015", 3),
    ano = 2010:2012,
    risco_idx = c(0.7, 0.8, 0.9),
    stringsAsFactors = FALSE
  )
  expect_error(mape_compactar_painel(x, metodo = "constante"),
               "assume que o valor não muda")
})

test_that("compactar por preenchido descarta o zero-fill e mantém o zero medido", {
  x <- data.frame(
    id_municipio = rep("1100015", 4),
    ano = 2010:2013,
    contratos_i = c(0, 5, 0, 3),
    valor_brl2023 = c(0, 100, 0, 60),
    stringsAsFactors = FALSE
  )
  y <- mape_compactar_painel(x, metodo = "preenchido", vazio = c(0))
  expect_equal(nrow(y), 2)
  expect_equal(y$ano, c(2011L, 2012L + 1L))

  # Com vazio = numeric(0), só NA conta como ausência, e o zero é preservado.
  z <- mape_compactar_painel(x, metodo = "preenchido", vazio = numeric(0))
  expect_equal(nrow(z), 4)
})

test_that("compactar registra o que removeu", {
  x <- data.frame(id_municipio = rep("1100015", 10), ano = 2010:2019,
                  v = c(rep(0, 9), 1))
  y <- mape_compactar_painel(x, metodo = "preenchido")
  info <- attr(y, "mape_compactacao")
  expect_equal(info$linhas_antes, 10)
  expect_equal(info$linhas_depois, 1)
  expect_equal(info$reducao_pct, 90)
})

test_that("expandir e compactar são inversas quando há ano de referência", {
  # A ida e a volta precisam fechar: se não fecharem, uma das duas está
  # inventando ou perdendo linha.
  observado <- data.frame(
    id_municipio = c("1100015", "3304557"),
    ano_ref = c(2010L, 2010L),
    v = c(1.5, 2.5),
    stringsAsFactors = FALSE
  )
  expandido <- mape_expandir_painel(observado, de = "ano_ref", para = 2008:2012,
                                    metodo = "replicar")
  expect_equal(nrow(expandido), 10)

  expandido$ano_ref_v <- expandido$ano_ref
  voltou <- mape_compactar_painel(
    expandido[, c("id_municipio", "ano", "ano_ref_v", "v")],
    metodo = "ano_ref", ano_ref = "ano_ref_v")

  expect_equal(nrow(voltou), 2)
  expect_equal(sort(voltou$v), sort(observado$v))
})

# ---- Achado 78 --------------------------------------------------------------

test_that("mape_compactar_painel('constante') não descarta valor de coluna irmã", {
  # Achado 78: o colapso era por LINHA — ficava a primeira linha do município com
  # algum valor — e por isso perdia em silêncio o valor de uma coluna cujo não-NA
  # estivesse noutro ano. Aqui `a` só tem valor em 2001 e `b` só em 2002.
  x <- data.frame(
    id_municipio = rep("1100015", 3),
    ano = 2000:2002,
    a = c(NA, 10, NA),
    b = c(NA, NA, 20),
    stringsAsFactors = FALSE)

  y <- mape_compactar_painel(x, metodo = "constante", cols = c("a", "b"))
  expect_equal(nrow(y), 1)
  expect_equal(y$a, 10)
  expect_equal(y$b, 20)   # antes: NA, descartado em silêncio
})

test_that("mape_compactar_painel('constante') conserva as células preenchidas", {
  x <- data.frame(
    id_municipio = rep(c("1100015", "3304557"), each = 3),
    ano = rep(2000:2002, 2),
    a = c(NA, 1, NA, NA, NA, 3),
    b = c(2, NA, NA, 4, NA, NA),
    stringsAsFactors = FALSE)
  y <- mape_compactar_painel(x, metodo = "constante", cols = c("a", "b"))
  expect_equal(nrow(y), 2)
  expect_equal(sum(!is.na(y[, c("a", "b")])), sum(!is.na(x[, c("a", "b")])))
})
