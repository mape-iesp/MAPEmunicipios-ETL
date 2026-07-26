# ---- Sentinelas -------------------------------------------------------------

test_that("mape_tratar_sentinelas recupera o tipo de coluna contaminada", {
  # O caso real: indice_risco_inundacoes_enxurradas é texto porque tem
  # "NaoDisponivel" em algumas linhas, enquanto a coluna irmã é numérica.
  x <- data.frame(risco = c("0.75", "NaoDisponivel", "0.31"),
                  stringsAsFactors = FALSE)
  res <- mape_tratar_sentinelas(x)
  expect_type(res$risco, "double")
  expect_equal(res$risco, c(0.75, NA, 0.31))
})

test_that("mape_tratar_sentinelas aceita vírgula decimal", {
  x <- data.frame(v = c("1,5", "2,25", "-"), stringsAsFactors = FALSE)
  expect_equal(mape_tratar_sentinelas(x)$v, c(1.5, 2.25, NA))
})

test_that("mape_tratar_sentinelas não converte coluna genuinamente textual", {
  x <- data.frame(nome = c("São Paulo", "Rio de Janeiro"), stringsAsFactors = FALSE)
  expect_type(mape_tratar_sentinelas(x)$nome, "character")
})

test_that("mape_tratar_sentinelas trata sentinela numérico", {
  x <- data.frame(v = c(10, -999, 20))
  expect_equal(mape_tratar_sentinelas(x)$v, c(10, NA, 20))
})

test_that("mape_detectar_sentinelas encontra o que sobrou", {
  x <- data.frame(a = c("Ignorado", "1"), b = c(1, -999), stringsAsFactors = FALSE)
  res <- mape_detectar_sentinelas(x)
  expect_equal(nrow(res), 2)
  expect_true("a" %in% res$coluna && "b" %in% res$coluna)
})

# ---- Junções ----------------------------------------------------------------

test_that("mape_join recusa tipos incompatíveis na chave", {
  x <- data.frame(id_municipio = "1100015", a = 1, stringsAsFactors = FALSE)
  y <- data.frame(id_municipio = 1100015, b = 2)
  # É a causa mais comum de junção silenciosamente vazia no legado.
  expect_error(mape_join(x, y, by = "id_municipio"), "tipo incompatível")
})

test_that("mape_join detecta multiplicação de linhas no left join", {
  x <- data.frame(id = "a", v = 1, stringsAsFactors = FALSE)
  y <- data.frame(id = c("a", "a"), w = 1:2, stringsAsFactors = FALSE)
  # É exatamente o que a dimensão histórica faz: junta sem ano contra uma
  # tabela com chave duplicada e multiplica a série inteira.
  expect_error(
    suppressMessages(mape_join(x, y, by = "id", relationship = "many-to-many")),
    "multiplicou linhas"
  )
})

test_that("mape_join falha quando o número de linhas não bate com o esperado", {
  x <- data.frame(id = c("a", "b"), stringsAsFactors = FALSE)
  y <- data.frame(id = "a", v = 1, stringsAsFactors = FALSE)
  expect_error(suppressMessages(mape_join(x, y, by = "id", esperado_linhas = 99)),
               "esperava 99")
})

test_that("mape_join avisa sobre chave nula dos dois lados", {
  x <- data.frame(id = c("a", NA), stringsAsFactors = FALSE)
  y <- data.frame(id = c("a", NA), v = 1:2, stringsAsFactors = FALSE)
  expect_warning(suppressMessages(mape_join(x, y, by = "id")), "chave nula")
})

test_that("mape_join relata órfãos dos dois lados", {
  x <- data.frame(id = c("a", "b"), stringsAsFactors = FALSE)
  y <- data.frame(id = c("a", "c"), v = 1:2, stringsAsFactors = FALSE)
  res <- suppressMessages(mape_join(x, y, by = "id"))
  rel <- attr(res, "mape_relatorio")
  expect_equal(rel$orfaos_x, 1)  # "b" não existe em y
  expect_equal(rel$orfaos_y, 1)  # "c" não existe em x
})

test_that("mape_validar_chave separa chaves duplicadas de linhas excedentes", {
  # O vocabulário importa: são números diferentes e o legado os confunde.
  x <- data.frame(id_municipio = c("a", "a", "a", "b"),
                  ano = c(1L, 1L, 1L, 1L), stringsAsFactors = FALSE)
  expect_error(mape_validar_chave(x), "1 chave")
  diag <- suppressWarnings(mape_validar_chave(x, erro = FALSE))
  expect_equal(diag$n_chaves_duplicadas, 1)  # só a chave (a, 1)
  expect_equal(diag$n_linhas_excedentes, 2)  # duas linhas a mais
})

test_that("mape_validar_chave aceita chave única", {
  x <- data.frame(id_municipio = c("a", "b"), ano = c(1L, 1L),
                  stringsAsFactors = FALSE)
  expect_silent(mape_validar_chave(x))
})

# ---- Painel -----------------------------------------------------------------

test_that("mape_expandir_painel marca o que foi imputado", {
  obs <- data.frame(id_municipio = c("1100015", "1100015"),
                    ano_ref_censo = c(2000L, 2010L), ivs = c(0.5, 0.4),
                    stringsAsFactors = FALSE)
  res <- mape_expandir_painel(obs, de = "ano_ref_censo",
                              mapa = mape_mapa_censitario_legado())
  expect_equal(nrow(res), 20)                    # 2 medições -> 20 anos
  expect_equal(sum(res$flag_imputado == 0), 2)   # só 2000 e 2010 são observados
  expect_equal(sum(res$flag_imputado == 1), 18)
})

test_that("mape_expandir_painel preserva o ano de referência", {
  obs <- data.frame(id_municipio = "1100015", ano_ref_censo = 2000L, v = 1,
                    stringsAsFactors = FALSE)
  res <- mape_expandir_painel(obs, de = "ano_ref_censo",
                              mapa = mape_mapa_censitario_legado())
  expect_true("ano_ref_censo" %in% names(res))
  expect_true(all(res$ano_ref_censo == 2000L))
})

test_that("mape_expandir_painel com carry_forward propaga até a próxima medição", {
  obs <- data.frame(id_municipio = "a", ano_ref = c(2005L, 2007L), v = c(1, 2),
                    stringsAsFactors = FALSE)
  res <- mape_expandir_painel(obs, de = "ano_ref", para = 2005:2008,
                              metodo = "carry_forward")
  expect_equal(res$v[res$ano == 2006], 1)  # herda 2005
  expect_equal(res$v[res$ano == 2008], 2)  # herda 2007
})

test_that("mape_mapa_censitario_legado reproduz o mapeamento do legado", {
  mapa <- mape_mapa_censitario_legado()
  expect_equal(nrow(mapa), 20)
  expect_equal(sort(unique(mapa$ano_ref_censo)), c(2000L, 2010L))
  expect_equal(range(mapa$ano), c(1996, 2015))
})

# ---- Interação chave × sentinela — achado 20 --------------------------------

test_that("mape_tratar_sentinelas não toca nas colunas de chave", {
  # Achado 20: a conversão numérica transformava id_municipio de texto em
  # double, e o scaffold oficial de mape_nova_fonte() produzia exatamente essa
  # chamada — o que espalhava o defeito para toda fonte nova. Os quatro testes
  # que já existiam usavam data frames SEM coluna de chave, e por isso nunca
  # exercitaram este caminho.
  x <- data.frame(id_municipio = c("1100015", "1200013"),
                  id_municipio_6 = c("110001", "120001"),
                  ano = c(2020L, 2021L),
                  indice = c("1,5", "NaoDisponivel"),
                  stringsAsFactors = FALSE)
  y <- mape_tratar_sentinelas(x)

  expect_type(y$id_municipio, "character")
  expect_equal(y$id_municipio, c("1100015", "1200013"))
  expect_type(y$id_municipio_6, "character")
  expect_type(y$ano, "integer")

  # E a coluna de conteúdo continua sendo tratada: o sentinela vira NA e o
  # tipo é recuperado.
  expect_type(y$indice, "double")
  expect_equal(y$indice, c(1.5, NA))
})

test_that("preservar_chaves = FALSE reproduz o comportamento antigo", {
  # O defeito continua alcançável de propósito, para quem souber o que quer.
  x <- data.frame(id_municipio = c("1100015", "1200013"), stringsAsFactors = FALSE)
  y <- mape_tratar_sentinelas(x, preservar_chaves = FALSE)
  expect_type(y$id_municipio, "double")
})

test_that("o scaffold gerado trata sentinelas ANTES de normalizar a chave", {
  raiz <- withr::local_tempdir()
  dir.create(file.path(raiz, "config"), recursive = TRUE, showWarnings = FALSE)
  file.copy(here::here("config", "parametros.yml"), file.path(raiz, "config"))
  dir.create(file.path(raiz, "dicionario"), recursive = TRUE, showWarnings = FALSE)
  for (f in list.files(here::here("dicionario"), pattern = "[.]csv$", full.names = TRUE)) {
    file.copy(f, file.path(raiz, "dicionario"))
  }
  withr::local_options(mape.raiz = raiz)
  rm(list = ls(.mape_cache_param), envir = .mape_cache_param)
  withr::defer(rm(list = ls(.mape_cache_param), envir = .mape_cache_param))

  dims <- mape_dicionario("dimensoes")
  col <- intersect(c("slug", "slug_dimensao", "dimensao"), names(dims))[1]
  d <- dims[[col]][1]
  suppressMessages(mape_nova_fonte(d, "fonte_ordem_tmp"))

  linhas <- readLines(mape_caminho("fontes", d, "fonte_ordem_tmp", "R",
                                   "tratar_fonte_ordem_tmp.R"))
  # Casa a CHAMADA, não o comentário que a explica.
  i_sent <- grep("^\\s+x <- mape_tratar_sentinelas", linhas)
  i_chave <- grep("^\\s+x <- mape_normalizar_chaves", linhas)
  expect_length(i_sent, 1)
  expect_length(i_chave, 1)
  expect_lt(i_sent, i_chave)
  # E com o argumento explícito, que é o que impede a conversão da chave.
  expect_match(linhas[i_sent], "converter_numerico = FALSE")
})
