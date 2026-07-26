# Estes testes usam a tabela do diretório, que é a primeira publicada e serve
# de caso concreto para todo o resto.

tabela_existe <- function() {
  file.exists(here::here("dados", "fonte", "00_diretorios", "municipios.parquet"))
}

# ---- Entrada e saída --------------------------------------------------------

test_that("a escrita e a releitura preservam dimensões e nomes", {
  skip_if_not(tabela_existe(), "tabela do diretório ainda não publicada")
  x <- mape_ler_tabela("00_diretorios/municipios")
  expect_equal(nrow(x), 5570)
  expect_equal(ncol(x), 27)
})

test_that("o Parquet preserva os tipos, ao contrário do xlsx e do CSV", {
  skip_if_not(tabela_existe())
  x <- mape_ler_tabela("00_diretorios/municipios")
  # O contrato: código é texto, flag é inteiro. É justamente o que se perde ao
  # passar por xlsx — e o pipeline legado depende desse acidente para funcionar.
  expect_type(x$id_municipio, "character")
  expect_type(x$flag_capital_uf, "integer")
})

test_that("o CSV exportado não ganha a coluna fantasma", {
  skip_if_not(tabela_existe())
  csv <- here::here("dados", "fonte", "00_diretorios", "municipios.csv.gz")
  skip_if_not(file.exists(csv))
  cabecalho <- names(utils::read.csv(csv, nrows = 1, check.names = FALSE))
  # A base publicada hoje tem 452 campos no header para 451 colunas, porque o
  # write.csv foi feito sem row.names = FALSE.
  expect_false(any(cabecalho == "" | grepl("^X$|^X\\.", cabecalho)))
  expect_length(cabecalho, 27)
})

test_that("mape_ler_tabela falha com mensagem útil quando a tabela não existe", {
  expect_error(mape_ler_tabela("99_inexistente/nada"), "não encontrada")
})

# ---- Dicionário -------------------------------------------------------------

test_that("o dicionário tem as tabelas registradas", {
  skip_if_not(file.exists(here::here("dicionario", "tabelas.csv")))
  expect_true(mape_tabela_no_dicionario("00_diretorios/municipios"))
  expect_false(mape_tabela_no_dicionario("99_inexistente/nada"))
})

test_that("mape_tipo_de usa o vocabulário fechado", {
  expect_equal(mape_tipo_de("a"), "character")
  expect_equal(mape_tipo_de(1L), "integer")
  expect_equal(mape_tipo_de(1.5), "double")
  expect_equal(mape_tipo_de(TRUE), "logical")
  expect_equal(mape_tipo_de(Sys.Date()), "date")
})

test_that("mape_validar_schema separa escala errada de valor fora da faixa", {
  skip_if_not(file.exists(here::here("dicionario", "variaveis.csv")))

  # Como o projeto é um conjunto de scripts e não um pacote, o
  # local_mocked_bindings do testthat não se aplica: a substituição é feita
  # direto no ambiente global, com restauração garantida no fim do teste.
  usar_vars <- function(vars) {
    original <- mape_variaveis_de
    assign("mape_variaveis_de", function(tabela) vars, envir = globalenv())
    withr::defer(assign("mape_variaveis_de", original, envir = globalenv()),
                 envir = parent.frame())
  }
  fazer_vars <- function(nome) data.frame(
    tabela = "teste", nome_canonico = nome, nome_na_fonte = nome,
    tipo = "double", dominio_valido = NA, obrigatoria = FALSE,
    stringsAsFactors = FALSE
  )

  # ESCALA ERRADA é erro: uma coluna _pct cujos valores não passam de 1 é, na
  # verdade, uma proporção com o sufixo trocado. É o caso que produz hoje, na
  # base publicada, proporcao_* em escala 0-100 e pct_* em escala 0-1.
  usar_vars(fazer_vars("cobertura_teste_pct"))
  x_prop <- data.frame(id_municipio = "1100015",
                       cobertura_teste_pct = c(0.2, 0.9),
                       stringsAsFactors = FALSE)
  expect_error(mape_validar_schema(x_prop, "teste"), "é proporção, use _prop")

  # Ordem de grandeza incompatível também é erro.
  x_absurdo <- data.frame(id_municipio = "1100015",
                          cobertura_teste_pct = c(50, 13050),
                          stringsAsFactors = FALSE)
  expect_error(mape_validar_schema(x_absurdo, "teste"), "incompatível com a faixa")

  # VALOR FORA DA FAIXA é só aviso: uma taxa que chega a 128% continua sendo um
  # percentual. É o caso real da Taxa de Atualização Cadastral em 2016.
  x_fora <- data.frame(id_municipio = "1100015",
                       cobertura_teste_pct = c(80, 128.8),
                       stringsAsFactors = FALSE)
  expect_warning(mape_validar_schema(x_fora, "teste"), "fora de \\[0,100\\]")
})

test_that("mape_campos_calculados devolve uma linha por coluna", {
  x <- data.frame(a = c(1, NA, 3), b = c("x", "y", NA), stringsAsFactors = FALSE)
  res <- mape_campos_calculados(x, "teste")
  expect_equal(nrow(res), 2)
  expect_equal(res$pct_na, c(33.3333, 33.3333), tolerance = 1e-3)
  expect_equal(res$tipo_real, c("double", "character"))
})

# ---- Validação --------------------------------------------------------------

test_that("a tabela do diretório passa em todas as checagens executadas", {
  skip_if_not(tabela_existe())
  x <- mape_ler_tabela("00_diretorios/municipios")
  # gravar = FALSE: sem isto, a suíte reescrevia qa/00_diretorios__municipios.md,
  # que é versionado, a cada execução (achado 59). O nome do teste também dizia
  # "doze checagens", número que o código nunca executou.
  res <- suppressMessages(
    mape_validar_tabela(x, "00_diretorios/municipios", erro = FALSE, gravar = FALSE))
  expect_equal(sum(res$gravidade == "erro"), 0)
})

test_that("a validação bloqueia nome de coluna fora do padrão", {
  x <- data.frame(id_municipio = "1100015", `ln.pc.receita1920.sd` = 1,
                  check.names = FALSE, stringsAsFactors = FALSE)
  res <- suppressWarnings(
    mape_validar_tabela(x, "teste/sintetico", chaves = "id_municipio",
                        erro = FALSE, gravar = FALSE)
  )
  expect_true(any(res$checagem == "nomes_colunas" & res$gravidade == "erro"))
})

test_that("a validação sinaliza os prefixos genéricos banidos, e sem justificativa isso bloqueia", {
  x <- data.frame(id_municipio = "1100015", total_desastres = 1,
                  quantidade_estupro = 2, stringsAsFactors = FALSE)
  res <- suppressWarnings(suppressMessages(
    mape_validar_tabela(x, "teste/sintetico", chaves = "id_municipio",
                        erro = FALSE, gravar = FALSE)
  ))
  expect_true(any(res$checagem == "nomes_colunas"))

  # Achado 38: a regra "aviso sem justificativa vira erro" estava escrita em
  # cinco arquivos e não existia em código. Agora existe: este aviso não tem
  # linha em qa/justificativas.csv, então ele sobe para erro e bloqueia.
  i <- which(res$checagem == "nomes_colunas")
  expect_equal(res$gravidade[i], "erro")
  expect_false(res$justificada[i])
  expect_match(res$descricao[i], "sem justificativa registrada")
})

test_that("o mesmo aviso, uma vez justificado, deixa de bloquear", {
  raiz <- withr::local_tempdir()
  dir.create(file.path(raiz, "config"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(raiz, "qa"), recursive = TRUE, showWarnings = FALSE)
  file.copy(here::here("config", "parametros.yml"), file.path(raiz, "config"))
  utils::write.csv(
    data.frame(slug_tabela = "teste/sintetico", checagem = "nomes_colunas",
               coluna = "*", justificativa = "nomes herdados da fonte, renomeio agendado",
               stringsAsFactors = FALSE),
    file.path(raiz, "qa", "justificativas.csv"), row.names = FALSE)
  withr::local_options(mape.raiz = raiz)
  rm(list = ls(.mape_cache_param), envir = .mape_cache_param)
  withr::defer(rm(list = ls(.mape_cache_param), envir = .mape_cache_param))

  x <- data.frame(id_municipio = "1100015", total_desastres = 1,
                  stringsAsFactors = FALSE)
  res <- suppressWarnings(suppressMessages(
    mape_validar_tabela(x, "teste/sintetico", chaves = "id_municipio",
                        erro = FALSE, gravar = FALSE)
  ))
  i <- which(res$checagem == "nomes_colunas")
  expect_equal(res$gravidade[i], "aviso")
  expect_true(res$justificada[i])
  expect_match(res$justificativa[i], "renomeio agendado")
})

test_that("um erro reivindicado em qa/erros_aceitos.csv deixa de bloquear", {
  raiz <- withr::local_tempdir()
  dir.create(file.path(raiz, "config"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(raiz, "qa"), recursive = TRUE, showWarnings = FALSE)
  file.copy(here::here("config", "parametros.yml"), file.path(raiz, "config"))
  withr::local_options(mape.raiz = raiz)
  rm(list = ls(.mape_cache_param), envir = .mape_cache_param)
  withr::defer(rm(list = ls(.mape_cache_param), envir = .mape_cache_param))

  x <- data.frame(id_municipio = c("1100015", "1100015"),
                  stringsAsFactors = FALSE)

  # Sem reivindicação: a chave duplicada bloqueia.
  res <- suppressWarnings(suppressMessages(
    mape_validar_tabela(x, "teste/sintetico", chaves = "id_municipio",
                        erro = FALSE, gravar = FALSE)))
  expect_equal(res$gravidade[res$checagem == "chave_unica"], "erro")

  # Com reivindicação: vira aviso justificado, e a justificativa aparece.
  utils::write.csv(
    data.frame(slug_tabela = "teste/sintetico", checagem = "chave_unica",
               justificativa = "duplicata herdada da fonte, mantida de proposito",
               stringsAsFactors = FALSE),
    file.path(raiz, "qa", "erros_aceitos.csv"), row.names = FALSE)
  res <- suppressWarnings(suppressMessages(
    mape_validar_tabela(x, "teste/sintetico", chaves = "id_municipio",
                        erro = FALSE, gravar = FALSE)))
  i <- which(res$checagem == "chave_unica")
  expect_equal(res$gravidade[i], "aviso")
  expect_match(res$justificativa[i], "mantida de proposito")
})

test_that("a validação detecta chave duplicada e chave nula", {
  x <- data.frame(id_municipio = c("1100015", "1100015", NA),
                  stringsAsFactors = FALSE)
  res <- suppressWarnings(
    mape_validar_tabela(x, "teste/sintetico", chaves = "id_municipio",
                        erro = FALSE, gravar = FALSE)
  )
  expect_true(any(res$checagem == "chave_unica" & res$gravidade == "erro"))
  expect_true(any(res$checagem == "chave_sem_na" & res$gravidade == "erro"))
})

test_that("a validação grava o relatório em qa/, e o conteúdo depende da tabela", {
  # Achado 60: este teste era vácuo — asserta file.exists() sobre um arquivo
  # VERSIONADO, então passava com a gravação inteiramente desligada.
  # Achado 59: e, ao rodar, reescrevia o relatório publicado do diretório com o
  # conteúdo de uma fixture, sujando a árvore a cada execução da suíte.
  # Agora grava num tempdir, sob um slug de teste, e confere o conteúdo.
  raiz <- withr::local_tempdir()
  dir.create(file.path(raiz, "config"), recursive = TRUE, showWarnings = FALSE)
  file.copy(here::here("config", "parametros.yml"), file.path(raiz, "config"))
  withr::local_options(mape.raiz = raiz)
  rm(list = ls(.mape_cache_param), envir = .mape_cache_param)
  withr::defer(rm(list = ls(.mape_cache_param), envir = .mape_cache_param))

  x <- data.frame(id_municipio = c("1100015", "3304557", "3550308"),
                  ano = c(2020L, 2020L, 2020L), valor_i = c(1L, 2L, 3L),
                  stringsAsFactors = FALSE)
  destino <- file.path(raiz, "qa", "teste__sintetico.md")
  expect_false(file.exists(destino))

  suppressWarnings(suppressMessages(
    mape_validar_tabela(x, "teste/sintetico", chaves = c("id_municipio", "ano"),
                        erro = FALSE)))

  expect_true(file.exists(destino))
  conteudo <- readLines(destino, warn = FALSE)
  # O relatório mede a tabela que recebeu: 3 linhas, 3 colunas.
  expect_true(any(grepl("linhas: 3", conteudo)))
  expect_true(any(grepl("colunas: 3", conteudo)))
})

test_that("gravar = FALSE valida sem escrever nada", {
  # Achado 59: mape_validar_tabela() gravava em qa/ incondicionalmente, então
  # não havia como rodar a validação sem sujar a árvore versionada.
  raiz <- withr::local_tempdir()
  dir.create(file.path(raiz, "config"), recursive = TRUE, showWarnings = FALSE)
  file.copy(here::here("config", "parametros.yml"), file.path(raiz, "config"))
  withr::local_options(mape.raiz = raiz)
  rm(list = ls(.mape_cache_param), envir = .mape_cache_param)
  withr::defer(rm(list = ls(.mape_cache_param), envir = .mape_cache_param))

  x <- data.frame(id_municipio = "1100015", ano = 2020L, valor_i = 1L,
                  stringsAsFactors = FALSE)
  suppressWarnings(suppressMessages(
    mape_validar_tabela(x, "teste/sintetico", chaves = c("id_municipio", "ano"),
                        erro = FALSE, gravar = FALSE)))
  expect_false(file.exists(file.path(raiz, "qa", "teste__sintetico.md")))
})

# ---- Parâmetros -------------------------------------------------------------

test_that("mape_param lê chave aninhada e falha com mensagem útil", {
  expect_equal(mape_param("deflator_base"), "12/2023")
  expect_type(mape_param("qa.tolerancia_paridade"), "double")
  expect_error(mape_param("nao.existe.isso"), "não encontrado")
})

test_that("mape_anos_painel expande a faixa declarada no config", {
  # A faixa vem de config/parametros.yml e não é fixada aqui de propósito. Este
  # teste já falhou uma vez por isso: quando a janela foi ampliada para
  # 1989-2024, para caber as 8.583 linhas de 1989-1990 das Finanças, ele
  # continuava exigindo 1991-2023 e acusava um problema que não existia.
  faixa <- mape_param("anos_painel")
  anos <- mape_anos_painel()
  expect_equal(range(anos), c(faixa[1], faixa[2]))
  expect_length(anos, faixa[2] - faixa[1] + 1)
  expect_type(anos, "integer")
})
