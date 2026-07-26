# O esqueleto do painel e a base larga -----------------------------------------
#
# Grupo 26 da auditoria: mape_esqueleto_painel() e mape_montar_base_larga()
# podiam virar `function(...) NULL` sem que nenhum teste reclamasse. As duas
# ficavam entre as 26 funções que a suíte fingia cobrir — e a base larga é o
# produto que os consumidores de fora leem, então uma regressão ali sai daqui
# direto para quem usa.
#
# Os testes de fixture montam uma árvore descartável (raiz_de_teste(), em
# setup.R) e nunca tocam em dado publicado. Os dois últimos medem o publicado
# de propósito, porque é sobre ele que a documentação faz afirmação numérica.

# Diretório mínimo, com ano de instalação, para o esqueleto.
diretorio_fixture <- function() {
  data.frame(
    id_municipio   = c("1100015", "3304557", "3550308", "1700400"),
    nome_municipio = c("Alta Floresta D'Oeste", "Rio de Janeiro",
                       "São Paulo", "Abreulândia"),
    sigla_uf       = c("RO", "RJ", "SP", "TO"),
    ano_instalacao = c(1977L, 1565L, 1554L, NA_integer_),
    stringsAsFactors = FALSE
  )
}

# Painel município x ano com uma coluna de conteúdo determinística.
painel_fixture <- function(municipios, anos, nome_col, valor = NULL) {
  x <- expand.grid(id_municipio = municipios, ano = as.integer(anos),
                   KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  x <- x[order(x$id_municipio, x$ano), ]
  x[[nome_col]] <- if (is.null(valor)) seq_len(nrow(x)) else valor(x)
  rownames(x) <- NULL
  x
}


# -- mape_esqueleto_painel() ---------------------------------------------------

test_that("o esqueleto é o produto cartesiano de município por ano", {
  e <- mape_esqueleto_painel(anos = 2020:2022, diretorio = diretorio_teste,
                             incluir_flag_instalado = FALSE)

  expect_equal(nrow(e), 4 * 3)
  expect_equal(names(e), c("id_municipio", "ano"))
  expect_equal(sort(unique(e$id_municipio)), sort(diretorio_teste$id_municipio))
  expect_equal(sort(unique(e$ano)), 2020:2022)
  # Chave única: um esqueleto com chave repetida multiplicaria toda junção
  # feita sobre ele.
  expect_equal(anyDuplicated(paste(e$id_municipio, e$ano)), 0L)
  # `ano` é inteiro por contrato de chave, não double nem texto.
  expect_type(e$ano, "integer")
  expect_type(e$id_municipio, "character")
  # E vem ordenado por município, depois ano.
  expect_identical(e, e[order(e$id_municipio, e$ano), ])
})

test_that("sem `anos`, o esqueleto usa a janela de config/parametros.yml", {
  e <- mape_esqueleto_painel(diretorio = diretorio_teste,
                             incluir_flag_instalado = FALSE)
  faixa <- mape_param("anos_painel")
  expect_equal(range(e$ano), c(as.integer(faixa[1]), as.integer(faixa[2])))
  expect_equal(nrow(e), 4 * length(mape_anos_painel()))
})

test_that("flag_municipio_instalado separa 'não existia' de 'sem cobertura'", {
  e <- mape_esqueleto_painel(anos = 1975:1978, diretorio = diretorio_fixture())

  expect_true("flag_municipio_instalado" %in% names(e))
  expect_type(e$flag_municipio_instalado, "integer")

  # Alta Floresta D'Oeste foi instalada em 1977: 0 antes, 1 a partir dali.
  af <- e[e$id_municipio == "1100015", ]
  expect_equal(af$flag_municipio_instalado[af$ano == 1976], 0L)
  expect_equal(af$flag_municipio_instalado[af$ano == 1977], 1L)
  expect_equal(af$flag_municipio_instalado[af$ano == 1978], 1L)

  # Sem ano de instalação registrado, o município é tratado como sempre
  # presente — e nunca como NA, que contaminaria qualquer soma.
  ab <- e[e$id_municipio == "1700400", ]
  expect_equal(unique(ab$flag_municipio_instalado), 1L)
  expect_false(anyNA(e$flag_municipio_instalado))
})

test_that("o esqueleto sobre o diretório publicado é o painel inteiro", {
  # 5.570 municípios x 36 anos = 200.520 linhas. É o retângulo em que toda
  # dimensão é encaixada, e o número que a base larga tem de reproduzir.
  e <- mape_esqueleto_painel(incluir_flag_instalado = FALSE)
  expect_equal(length(unique(e$id_municipio)), 5570)
  expect_equal(length(unique(e$ano)), length(mape_anos_painel()))
  expect_equal(nrow(e), 5570 * length(mape_anos_painel()))
  expect_equal(anyDuplicated(paste(e$id_municipio, e$ano)), 0L)
})


# -- mape_montar_base_larga() --------------------------------------------------

test_that("a base larga junta as dimensões pelo par município x ano", {
  raiz <- raiz_de_teste()
  withr::local_options(mape.raiz = raiz)
  withr::defer(limpar_caches_mape())

  mun <- c("1100015", "3304557", "3550308", "1700400")
  gravar_fixture(raiz, diretorio_fixture(), "00_diretorios/municipios", "fonte")
  aa <- painel_fixture(mun, 2020:2022, "aa_i")
  gravar_fixture(raiz, aa, "aa_um")
  # bb cobre só dois municípios: o que falta tem de virar NA, e não sumir.
  gravar_fixture(raiz, painel_fixture(mun[1:2], 2020:2022, "bb_pct",
                                      valor = function(d) rep(50, nrow(d))),
                 "bb_dois")

  b <- suppressMessages(mape_montar_base_larga(
    dimensoes = c("aa_um", "bb_dois"), anos = 2020:2022))

  expect_equal(nrow(b), 12)
  expect_true(all(c("id_municipio", "ano", "aa_i", "bb_pct") %in% names(b)))
  # O bloco territorial entra uma vez só, vindo do diretório.
  expect_true(all(c("nome_municipio", "sigla_uf") %in% names(b)))
  expect_equal(anyDuplicated(paste(b$id_municipio, b$ano)), 0L)

  # O valor tem de chegar na linha certa. A fixture é numerada em ordem de
  # município e depois de ano, então 3550308/2021 (4º município, 2º ano) é a
  # 11ª linha — e é 11 que tem de aparecer na base larga, não o vizinho.
  esperado <- aa$aa_i[aa$id_municipio == "3550308" & aa$ano == 2021]
  expect_equal(esperado, 11L)
  expect_equal(b$aa_i[b$id_municipio == "3550308" & b$ano == 2021], esperado)
  # E o município fora da cobertura de bb fica NA, sem perder a linha.
  expect_equal(b$bb_pct[b$id_municipio == "1100015" & b$ano == 2020], 50)
  expect_true(is.na(b$bb_pct[b$id_municipio == "3550308" & b$ano == 2021]))
})

test_that("flags = TRUE marca 0/1 a presença real de cada dimensão", {
  raiz <- raiz_de_teste()
  withr::local_options(mape.raiz = raiz)
  withr::defer(limpar_caches_mape())

  mun <- c("1100015", "3304557", "3550308", "1700400")
  gravar_fixture(raiz, diretorio_fixture(), "00_diretorios/municipios", "fonte")
  gravar_fixture(raiz, painel_fixture(mun, 2020:2022, "aa_i"), "aa_um")
  gravar_fixture(raiz, painel_fixture(mun[1:2], 2020:2022, "bb_pct",
                                      valor = function(d) rep(50, nrow(d))),
                 "bb_dois")

  b <- suppressMessages(mape_montar_base_larga(
    dimensoes = c("aa_um", "bb_dois"), anos = 2020:2022, flags = TRUE))

  expect_true(all(c("dimensao_aa_um", "dimensao_bb_dois") %in% names(b)))
  expect_equal(unique(b$dimensao_aa_um), 1L)
  # A flag descreve a presença OBSERVADA, e não o desejo: 6 pares em bb.
  expect_equal(sum(b$dimensao_bb_dois == 1L), 6L)
  expect_equal(sum(b$dimensao_bb_dois == 0L), 6L)
  expect_false(anyNA(b$dimensao_bb_dois))
  expect_true(all(b$dimensao_bb_dois[b$id_municipio %in% mun[1:2]] == 1L))
})

test_that("dimensão sem coluna `ano` fica fora, e a função diz por quê", {
  raiz <- raiz_de_teste()
  withr::local_options(mape.raiz = raiz)
  withr::defer(limpar_caches_mape())

  mun <- c("1100015", "3304557", "3550308", "1700400")
  gravar_fixture(raiz, diretorio_fixture(), "00_diretorios/municipios", "fonte")
  gravar_fixture(raiz, painel_fixture(mun, 2020:2022, "aa_i"), "aa_um")
  # Transversal: só município. Juntá-la replicaria o valor em todos os anos,
  # que é o defeito que a base larga existe para não ter.
  gravar_fixture(raiz, data.frame(id_municipio = mun, cc_idx = 1:4,
                                  stringsAsFactors = FALSE), "cc_transversal")

  msgs <- capture_messages(
    b <- mape_montar_base_larga(dimensoes = c("aa_um", "cc_transversal"),
                                anos = 2020:2022))

  expect_true(any(grepl("cc_transversal", msgs, fixed = TRUE)))
  expect_true(any(grepl("FORA da base larga", msgs, fixed = TRUE)))
  # O descarte é silencioso no dado, não no log: a coluna não entra.
  expect_false("cc_idx" %in% names(b))
  expect_equal(nrow(b), 12)
})

test_that("chave duplicada numa dimensão para a montagem e nomeia a culpada", {
  raiz <- raiz_de_teste()
  withr::local_options(mape.raiz = raiz)
  withr::defer(limpar_caches_mape())

  mun <- c("1100015", "3304557", "3550308", "1700400")
  gravar_fixture(raiz, diretorio_fixture(), "00_diretorios/municipios", "fonte")
  gravar_fixture(raiz, painel_fixture(mun, 2020:2022, "aa_i"), "aa_um")

  dup <- painel_fixture(mun, 2020:2022, "dd_i")
  dup <- rbind(dup, dup[dup$id_municipio == "3304557" & dup$ano == 2021, ])
  dup$dd_i[nrow(dup)] <- 999
  gravar_fixture(raiz, dup, "dd_duplicada")

  # Sem deduplicar, a junção multiplicaria linhas — que é o defeito do legado.
  expect_error(
    suppressMessages(mape_montar_base_larga(dimensoes = c("aa_um", "dd_duplicada"),
                                            anos = 2020:2022)),
    "dd_duplicada"
  )

  # Com deduplicar = TRUE, passa, mantém a PRIMEIRA ocorrência e registra a
  # escolha no log — ela é arbitrária e não pode ser invisível.
  msgs <- capture_messages(
    b <- mape_montar_base_larga(dimensoes = c("aa_um", "dd_duplicada"),
                                anos = 2020:2022, deduplicar = TRUE))
  expect_equal(nrow(b), 12)
  expect_true(any(grepl("deduplicando", msgs, fixed = TRUE)))
  # A primeira ocorrência de 3304557/2021 é a 8ª linha da fixture; a segunda,
  # acrescentada no fim, vale 999. Ficar com 999 seria ficar com a última.
  expect_equal(b$dd_i[b$id_municipio == "3304557" & b$ano == 2021], 8L)
})

test_that("a base larga do dado publicado tem as dimensões que a documentação afirma", {
  # Este é o teste sobre o publicado, e o único caro (~5 s). Ele existe porque
  # os números da base larga circulam em prosa — 440 colunas e 16 dimensões, na
  # documentação antiga — e a regra do repositório é medir.
  #
  # deduplicar = TRUE é obrigatório aqui: 06_financas tem 222 chaves duplicadas
  # herdadas da fonte, e sem isso a montagem para (o que os testes de fixture
  # acima cobrem).
  msgs <- capture_messages(
    b <- suppressWarnings(mape_montar_base_larga(flags = TRUE, deduplicar = TRUE)))

  expect_equal(nrow(b), 200520)
  expect_equal(length(unique(b$id_municipio)), 5570)
  expect_equal(length(unique(b$ano)), 36)
  expect_equal(anyDuplicated(paste(b$id_municipio, b$ano)), 0L)

  # 15 dimensões, uma coluna de flag por dimensão, e 424 colunas de conteúdo.
  flags <- grep("^dimensao_", names(b), value = TRUE)
  expect_equal(length(flags), 15)
  expect_equal(ncol(b), 439)
  expect_equal(ncol(b) - length(flags), 424)

  # 15_dados_historicos é transversal e sai — mas sai avisando. Ficar de fora
  # em silêncio foi o achado; o aviso é a correção.
  expect_false("dimensao_15_dados_historicos" %in% flags)
  expect_true(any(grepl("15_dados_historicos", msgs, fixed = TRUE)))
  expect_true(any(grepl("FORA da base larga", msgs, fixed = TRUE)))
})
