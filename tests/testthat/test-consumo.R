# A interface de consumo é a superfície que o pacote MAPEmunicipios reproduz
# para fora. Um erro aqui vira erro na mão de quem só quer os dados, então os
# testes cobrem tanto o caminho feliz quanto as recusas.

test_that("mape_resolver_tabela aceita as grafias que uma pessoa usaria", {
  skip_if_not(dir.exists(mape_caminho("dados", "dimensao")),
              "sem tabelas publicadas")
  expect_equal(mape_resolver_tabela("10_saude"), "10_saude")
  expect_equal(mape_resolver_tabela("saude"), "10_saude")
  expect_equal(mape_resolver_tabela("saúde"), "10_saude")
  expect_equal(mape_resolver_tabela("Meio Ambiente"), "03_meio_ambiente")
  expect_equal(mape_resolver_tabela("educacao/ideb"), "09_educacao/ideb")
})

test_that("mape_resolver_tabela falha com mensagem útil", {
  skip_if_not(dir.exists(mape_caminho("dados", "dimensao")),
              "sem tabelas publicadas")
  expect_error(mape_resolver_tabela("inexistente_qualquer"), "não encontrada")
  # A mensagem precisa dizer para onde ir, e não só que deu errado.
  expect_error(mape_resolver_tabela("inexistente_qualquer"),
               "mape_tabelas_publicadas")
})

test_that("mape_ler filtra por ano e por município", {
  skip_if_not(file.exists(mape_caminho_tabela("02_populacao", "parquet", "dimensao")),
              "sem 02_populacao publicada")
  x <- mape_ler("populacao", anos = 2010:2012,
                municipios = c("1100015", "3304557"))
  expect_true(all(x$ano %in% 2010:2012))
  expect_setequal(unique(x$id_municipio), c("1100015", "3304557"))
})

test_that("mape_ler traz o bloco territorial quando pedido", {
  skip_if_not(file.exists(mape_caminho_tabela("02_populacao", "parquet", "dimensao")),
              "sem 02_populacao publicada")
  x <- mape_ler("populacao", anos = 2010, territorio = TRUE)
  expect_true(all(c("nome_municipio", "sigla_uf") %in% names(x)))
  # O território não pode multiplicar linhas: o diretório é uma linha por
  # município.
  y <- mape_ler("populacao", anos = 2010)
  expect_equal(nrow(x), nrow(y))
})

test_that("mape_juntar recusa tabela com chave duplicada", {
  skip_if_not(file.exists(mape_caminho_tabela("06_financas", "parquet", "dimensao")),
              "sem 06_financas publicada")
  # As Finanças herdam 222 chaves duplicadas da fonte das emendas. Juntar assim
  # multiplicaria linhas, que é exatamente o que o pipeline antigo fazia antes
  # de apagar a evidência com um distinct() cego.
  expect_error(mape_juntar(c("06_financas", "02_populacao")),
               "chave\\(s\\) duplicada\\(s\\)")
})

test_that("mape_juntar recusa tabela sem ano sem autorização explícita", {
  skip_if_not(file.exists(mape_caminho_tabela("15_dados_historicos", "parquet", "dimensao")),
              "sem 15_dados_historicos publicada")
  expect_error(mape_juntar(c("02_populacao", "15_dados_historicos")),
               "não tem coluna")
})

test_that("mape_juntar preserva a chave e registra o relatório", {
  skip_if_not(file.exists(mape_caminho_tabela("13_seguranca", "parquet", "dimensao")),
              "sem 13_seguranca publicada")
  b <- mape_juntar(c("13_seguranca", "02_populacao"), territorio = TRUE)
  k <- paste(b$id_municipio, b$ano)
  expect_false(anyDuplicated(k) > 0)

  rel <- attr(b, "mape_relatorio")
  expect_s3_class(rel, "data.frame")
  expect_true(nrow(rel) >= 2)
  expect_true(all(c("tabela", "linhas", "colunas") %in% names(rel)))
})

test_that("mape_cobertura mede presença de valor, não presença de linha", {
  skip_if_not(file.exists(mape_caminho_tabela("14_corrupcao", "parquet", "dimensao")),
              "sem 14_corrupcao publicada")
  cb <- mape_cobertura("14_corrupcao")
  expect_true(all(c("tabela", "ano", "municipios", "cobertura_pct") %in% names(cb)))
  # A Corrupção cobre uma fração pequena do painel; se a cobertura desse 100%,
  # a função estaria contando linha em vez de dado.
  expect_true(max(cb$cobertura_pct) < 50)
})

test_that("mape_indicadores devolve o catálogo com as dependências declaradas", {
  cat_ind <- mape_indicadores()
  expect_s3_class(cat_ind, "data.frame")
  expect_true(nrow(cat_ind) > 0)
  expect_true(all(c("indicador", "rotulo", "unidade", "precisa") %in% names(cat_ind)))
  expect_false(any(is.na(cat_ind$precisa) | cat_ind$precisa == ""))
})

test_that("mape_derivadas nomeia a coluna que falta em vez de devolver NA", {
  # O comportamento que se quer evitar é o silêncio: um indicador que devolve
  # NA porque a coluna mudou de nome parece dado ausente e é código quebrado.
  vazio <- data.frame(id_municipio = "1100015", ano = 2020L)
  expect_error(mape_derivadas("taxa_homicidios_p100k", dados = vazio),
               "Faltam colunas")
  expect_error(mape_derivadas("taxa_homicidios_p100k", dados = vazio),
               "deprecacao")
})

test_that("mape_derivadas recusa indicador desconhecido", {
  expect_error(mape_derivadas("indicador_que_nao_existe"), "desconhecido")
})

test_that("mape_derivadas calcula certo e não deixa infinito passar", {
  d <- data.frame(
    id_municipio = c("1100015", "3304557"), ano = c(2020L, 2020L),
    sim_obitos_homicidio_i = c(10, 5),
    populacao_residente_i = c(100000, 0),
    stringsAsFactors = FALSE
  )
  r <- mape_derivadas("taxa_homicidios_p100k", dados = d)
  expect_equal(r$taxa_homicidios_p100k[1], 10)
  # Divisão por zero vira NA, e não Inf: um Inf atravessa qualquer média sem
  # reclamar e contamina o resultado em silêncio.
  expect_true(is.na(r$taxa_homicidios_p100k[2]))
})

test_that("mape_derivadas devolve os insumos quando pedido", {
  d <- data.frame(
    id_municipio = "1100015", ano = 2020L,
    sim_obitos_homicidio_i = 10, populacao_residente_i = 100000,
    stringsAsFactors = FALSE
  )
  r <- mape_derivadas("taxa_homicidios_p100k", dados = d, manter_insumos = TRUE)
  expect_true(all(c("sim_obitos_homicidio_i", "populacao_residente_i") %in% names(r)))
})
