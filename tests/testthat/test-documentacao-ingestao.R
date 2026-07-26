# A garantia que a documentação gerada oferece é mecânica: se ela pode ser
# regerada, ela não pode divergir do dado. Estes testes conferem que a
# regeneração de fato mede, e não copia um número guardado.

test_that("mape_recalcular_campos mede o arquivo e não confia no declarado", {
  skip_if_not(file.exists(mape_caminho_tabela("02_populacao", "parquet", "dimensao")),
              "sem 02_populacao publicada")

  vars <- mape_recalcular_campos("02_populacao", gravar = FALSE)
  x <- mape_ler_tabela("02_populacao", camada = "dimensao")

  # Achado 60: aqui havia skip_if(length(j) != 1), condicionado ao RESULTADO da
  # função sob teste. Se mape_recalcular_campos() devolvesse lixo, o teste
  # pulava em silêncio em vez de falhar. Uma variável publicada que sumiu do
  # dicionário é regressão, não motivo de pular.
  j <- which(vars$nome_canonico == "populacao_residente_i")
  expect_equal(length(j), 1)

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

  # Achado 87: este teste setava MAPE_RAIZ, que NÃO era lido por lugar nenhum do
  # código, e por isso criava fontes/00_diretorios/fonte_de_teste_tmp/ dentro do
  # repositório real. O isolamento era só aparente — pior que nenhum, porque um
  # leitor futuro confiaria nele. Agora mape_caminho() tem âncora de verdade.
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

  pasta <- mape_caminho("fontes", d, "fonte_de_teste_tmp")
  # A pasta tem de nascer DENTRO do tempdir. Se a âncora deixar de funcionar,
  # este teste falha em vez de sujar a árvore de novo.
  expect_true(startsWith(pasta, raiz))

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

# mape_sha256() — a procedência do dado bruto ---------------------------------
#
# Grupo 26 da auditoria: a função sobrevivia a `function(...) NULL`. Ela é o
# que amarra o arquivo em raw/ ao MANIFESTO.yml da fonte, e um hash que virou
# NULL em silêncio destrói a única prova de que o bruto não mudou desde a
# extração — sem que nada pare de funcionar.
#
# Os valores de referência foram calculados fora do R (`shasum -a 256`), de
# propósito: comparar digest com digest provaria só que digest é consistente
# consigo mesmo.

test_that("mape_sha256 devolve o sha256 do CONTEÚDO do arquivo", {
  f <- withr::local_tempfile()
  writeBin(charToRaw("MAPEmunicipios\n"), f)
  expect_identical(
    mape_sha256(f),
    "0b466f18b094fab7bf592e3fb512ef2a5ad221a4c4458c06a678c1b8860c1f57")

  # Arquivo vazio tem o hash canônico do vazio — e não NA nem erro.
  vazio <- withr::local_tempfile()
  file.create(vazio)
  expect_identical(
    mape_sha256(vazio),
    "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
})

test_that("mape_sha256 é do conteúdo, não do nome, e um byte muda tudo", {
  a <- withr::local_tempfile(fileext = ".csv")
  b <- withr::local_tempfile(fileext = ".parquet")
  c1 <- withr::local_tempfile()
  writeBin(charToRaw("id_municipio,valor\n3550308,1\n"), a)
  writeBin(charToRaw("id_municipio,valor\n3550308,1\n"), b)
  # Um único byte diferente: 1 -> 2.
  writeBin(charToRaw("id_municipio,valor\n3550308,2\n"), c1)

  # Mesmo conteúdo, nomes e extensões diferentes: mesmo hash.
  expect_identical(mape_sha256(a), mape_sha256(b))
  # Um byte de diferença: hash diferente. É esta propriedade que faz o
  # manifesto detectar que o bruto mudou.
  expect_false(identical(mape_sha256(a), mape_sha256(c1)))
  # E é sempre hexadecimal de 64 caracteres.
  expect_match(mape_sha256(a), "^[0-9a-f]{64}$")
})
