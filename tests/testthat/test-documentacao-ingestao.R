# A garantia que a documentação gerada oferece é mecânica: se ela pode ser
# regerada, ela não pode divergir do dado. Estes testes conferem que a
# regeneração de fato mede, e não copia um número guardado.

test_that("mape_recalcular_campos mede o arquivo e não confia no declarado", {
  skip_if_not(file.exists(mape_caminho_tabela("02_populacao", "parquet", "dimensao")),
              "sem 02_populacao publicada")

  vars <- mape_recalcular_campos("02_populacao", gravar = FALSE)
  x <- mape_ler_tabela("02_populacao", camada = "dimensao")

  j <- which(vars$nome_canonico == "populacao_residente_i")
  skip_if(length(j) != 1, "variável não encontrada no dicionário")

  expect_equal(vars$tipo_real[j], class(x$populacao_residente_i)[1])
  expect_equal(vars$pct_na[j],
               round(100 * mean(is.na(x$populacao_residente_i)), 4))
  expect_equal(vars$maximo[j], max(x$populacao_residente_i, na.rm = TRUE))
})

test_that("a documentação gerada traz os números medidos, não os digitados", {
  skip_if_not(file.exists(mape_caminho_tabela("14_corrupcao", "parquet", "dimensao")),
              "sem 14_corrupcao publicada")

  destino <- withr::local_tempfile(fileext = ".md")
  mape_gerar_documentacao("14_corrupcao", destino = destino, recalcular = FALSE)
  texto <- paste(readLines(destino, warn = FALSE), collapse = "\n")

  x <- mape_ler_tabela("14_corrupcao", camada = "dimensao")
  fmt <- function(n) formatC(n, format = "d", big.mark = ".", decimal.mark = ",")

  expect_true(grepl(fmt(nrow(x)), texto, fixed = TRUE))
  expect_true(grepl(paste0("| Colunas | ", ncol(x), " |"), texto, fixed = TRUE))
  # A cobertura observada tem que ser a da tabela, e não a declarada. As duas
  # divergiam em cinco tabelas da documentação antiga sem que ninguém visse.
  expect_true(grepl(paste0(min(x$ano), "-", max(x$ano)), texto, fixed = TRUE))
  expect_true(grepl("GERADO", texto, fixed = TRUE))
})

test_that("a documentação avisa que é gerada e não deve ser editada", {
  skip_if_not(file.exists(mape_caminho_tabela("14_corrupcao", "parquet", "dimensao")),
              "sem 14_corrupcao publicada")
  destino <- withr::local_tempfile(fileext = ".md")
  mape_gerar_documentacao("14_corrupcao", destino = destino, recalcular = FALSE)
  texto <- paste(readLines(destino, warn = FALSE), collapse = "\n")
  expect_true(grepl("Não edite à mão", texto, fixed = TRUE))
})

test_that("mape_gerar_documentacao recusa tabela que não existe", {
  expect_error(mape_gerar_documentacao("99_inexistente"), "não está publicada")
})

test_that("mape_nova_fonte exige dimensão registrada", {
  expect_error(mape_nova_fonte("99_nao_existe", "qualquer"),
               "não está em dicionario/dimensoes.csv")
})

test_that("mape_nova_fonte exige nome em snake_case", {
  dims <- mape_dicionario("dimensoes")
  col <- intersect(c("slug", "slug_dimensao", "dimensao"), names(dims))[1]
  skip_if(is.na(col), "dicionário de dimensões sem coluna de slug")
  d <- dims[[col]][1]
  expect_error(mape_nova_fonte(d, "Nome Com Espaço"), "snake_case")
  expect_error(mape_nova_fonte(d, "2_comeca_com_numero"), "snake_case")
})

test_that("mape_nova_fonte cria o esqueleto completo", {
  dims <- mape_dicionario("dimensoes")
  col <- intersect(c("slug", "slug_dimensao", "dimensao"), names(dims))[1]
  skip_if(is.na(col), "dicionário de dimensões sem coluna de slug")
  d <- dims[[col]][1]

  raiz <- withr::local_tempdir()
  withr::local_envvar(MAPE_RAIZ = raiz)
  # mape_caminho() ancora na raiz do repositório; para não sujar a árvore real,
  # o teste cria e apaga a pasta no fim.
  pasta <- mape_caminho("fontes", d, "fonte_de_teste_tmp")
  withr::defer(unlink(pasta, recursive = TRUE))

  suppressMessages(mape_nova_fonte(d, "fonte_de_teste_tmp"))

  expect_true(dir.exists(pasta))
  expect_true(file.exists(file.path(pasta, "MANIFESTO.yml")))
  expect_true(file.exists(file.path(pasta, "README.md")))
  expect_true(file.exists(file.path(pasta, "R", "extrair_fonte_de_teste_tmp.R")))
  expect_true(file.exists(file.path(pasta, "R", "tratar_fonte_de_teste_tmp.R")))

  # Os scripts gerados precisam ser R válido: um esqueleto que não parseia é
  # pior que esqueleto nenhum.
  expect_silent(parse(file.path(pasta, "R", "extrair_fonte_de_teste_tmp.R")))
  expect_silent(parse(file.path(pasta, "R", "tratar_fonte_de_teste_tmp.R")))

  # E o tratamento precisa seguir a ordem certa: limpar a chave nula ANTES de
  # conferir unicidade. Inverter isso foi o erro mais caro do legado.
  linhas <- readLines(file.path(pasta, "R", "tratar_fonte_de_teste_tmp.R"))
  i_limpa <- grep("is.na\\(x\\$id_municipio\\)", linhas)
  i_valida <- grep("mape_validar_chave", linhas)
  expect_true(length(i_limpa) == 1 && length(i_valida) == 1)
  expect_lt(i_limpa, i_valida)
})

test_that("mape_baixar exige slug no formato dimensao/fonte", {
  expect_error(mape_baixar("http://exemplo.org/a.csv", "sem_barra"),
               "formato '<dimensao>/<fonte>'")
})

test_that("mape_variaveis_de de uma dimensão inclui as fontes dela", {
  skip_if_not(file.exists(mape_caminho_tabela("09_educacao/ideb", "parquet", "fonte")),
              "sem 09_educacao/ideb publicada")
  so_dim <- mape_variaveis_de("09_educacao", incluir_fontes = FALSE)
  com_fontes <- mape_variaveis_de("09_educacao", incluir_fontes = TRUE)
  expect_gt(nrow(com_fontes), nrow(so_dim))

  # Pedir a fonte explicitamente traz só ela.
  so_fonte <- mape_variaveis_de("09_educacao/ideb")
  expect_true(all(so_fonte$tabela == "09_educacao/ideb"))
})
