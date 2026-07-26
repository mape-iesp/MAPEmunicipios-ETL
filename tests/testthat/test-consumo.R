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

test_that("mape_cobertura conta flag LIGADO como observação", {
  skip_if_not(file.exists(mape_caminho_tabela("11_transportes", "parquet", "dimensao")),
              "sem 11_transportes publicada")
  # Achado 21, e o erro que a primeira correção introduziu ao consertá-lo.
  # Reportar 100% sobre um painel com 0,5% de informação era o defeito; excluir
  # `flag_` inteiro trocou por reportar 27 municípios quando 133 têm dado. As
  # 578 linhas com `flag_adota_tarifa_zero == 1` são observação real, vinda
  # íntegra da fonte, cobrindo 106 municípios de 1992 a 2024.
  cb <- mape_cobertura("11_transportes", por_ano = FALSE)
  expect_equal(cb$municipios, 133L)

  # E a série anual tem de alcançar os anos em que só o flag existe: com o flag
  # fora, a tabela começava em 2005 e terminava em 2017.
  cb_ano <- mape_cobertura("11_transportes")
  expect_lte(min(cb_ano$ano), 1992L)
  expect_gte(max(cb_ano$ano), 2024L)

  # O contrapeso: `ano_ref_` continua fora. Numa tabela de carry_forward ele vem
  # preenchido em toda linha, e contá-lo ressuscitaria o 100% falso.
  x <- mape_ler_tabela("11_transportes", camada = "dimensao")
  expect_true("ano_ref_inicio_tarifa_zero" %in% names(x))
  expect_lt(max(cb_ano$cobertura_pct), 5)
})

test_that("flag em zero continua sendo preenchimento, e não dado", {
  # O critério é o VALOR, não o prefixo: um flag em 0 é linha de painel.
  x <- data.frame(
    id_municipio = c("1100015", "3304557", "3550308"),
    ano = c(2020L, 2020L, 2020L),
    flag_evento = c(1, 0, 0),
    medida_i = c(NA, NA, NA),
    stringsAsFactors = FALSE)
  flags <- grep("^flag_", names(x), value = TRUE)
  m <- vapply(x[flags], function(v) {
    z <- suppressWarnings(as.numeric(v)); !is.na(z) & z != 0
  }, logical(nrow(x)))
  ligado <- rowSums(matrix(m, nrow = nrow(x))) > 0
  expect_equal(sum(ligado), 1L)
  expect_true(ligado[1])
})

test_that("a regra do mapa censitário está LIGADA, e não só implementada", {
  # Achado 34. O defeito não era a falta do mecanismo: `mape_expandir_por_regra()`
  # já tinha o ramo `mapa_censitario_legado`, e nenhuma tabela o declarava. O
  # despacho caía em `carry_forward` e extrapolava o censo de 2010 até 2024.
  # Por isso este teste afirma a DECLARAÇÃO, e não só o comportamento da função:
  # é a célula do dicionário que estava errada.
  tabs <- mape_dicionario("tabelas")
  regra <- tabs$regra_preenchimento_temporal[tabs$slug_tabela == "05_sociedade/atlas_ivs"]
  expect_equal(regra, "mapa_censitario_legado")
})

test_that("expandir atlas_ivs ao painel reproduz a dimensão publicada", {
  skip_if_not(file.exists(mape_caminho_tabela("05_sociedade/atlas_ivs", "parquet", "fonte")) &&
              file.exists(mape_caminho_tabela("05_sociedade", "parquet", "dimensao")),
              "sem atlas_ivs ou 05_sociedade publicadas")
  x <- suppressMessages(mape_ler("05_sociedade/atlas_ivs", painel = TRUE))
  d <- mape_ler_tabela("05_sociedade", camada = "dimensao")

  # 111.300 linhas, 1996-2015. Com `carry_forward` dava 139.125 e ia até 2024,
  # inventando quatorze anos de censo que ninguém mediu.
  expect_equal(nrow(x), nrow(d))
  expect_equal(range(x$ano), range(d$ano))
  expect_equal(sum(duplicated(paste(x$id_municipio, x$ano))), 0L)

  # E os valores têm de bater célula a célula, não só a contagem de linhas.
  comum <- setdiff(intersect(names(x), names(d)), c("id_municipio", "ano"))
  i <- match(paste(d$id_municipio, d$ano), paste(x$id_municipio, x$ano))
  expect_equal(sum(is.na(i)), 0L)
  divergentes <- sum(vapply(comum, function(cl) {
    a <- d[[cl]]; b <- x[[cl]][i]
    sum(!((is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)))
  }, numeric(1)))
  expect_equal(divergentes, 0)
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
