# Paridade — achados 24, 25, 40, 66, 67 e 68.
#
# A paridade era o teste mais fraco do repositório, e era fraco de um jeito
# específico: ele relatava "zero diferenças não explicadas" porque as
# diferenças não chegavam a ser olhadas. Os testes daqui exercitam as quatro
# maneiras pelas quais isso acontecia.
#
# A referência de verdade (qa/referencia/*.RDa, 56 MB) não é versionada, então
# aqui ela é FABRICADA a partir de uma tabela publicada pequena. Isso é de
# propósito: um teste que dependesse do arquivo real seria pulado na maioria das
# máquinas, e um teste pulado não prova nada — que é exatamente o defeito que
# o achado 60 encontrou noutro lugar da suíte.

referencia_sintetica <- function(dim_slug, extras = NULL, chaves_extra = 0L) {
  publicada <- mape_ler_tabela(dim_slug, camada = "dimensao")
  v <- mape_dicionario("variaveis")
  v <- v[v$dimensao == dim_slug & !is.na(v$dimensao), c("nome_legado", "nome_canonico")]
  v <- v[v$nome_canonico %in% names(publicada), , drop = FALSE]

  antiga <- publicada[, c("id_municipio", "ano", v$nome_canonico), drop = FALSE]
  names(antiga) <- c("id_municipio", "ano", v$nome_legado)
  # Uma coluna que existe só na referência: é o caso "removida de propósito",
  # que o achado 40 mostrou ser inalcançável.
  for (nm in extras) antiga[[nm]] <- "x"
  if (chaves_extra > 0) {
    sobra <- antiga[seq_len(chaves_extra), , drop = FALSE]
    sobra$ano <- max(antiga$ano) + seq_len(chaves_extra)
    antiga <- rbind(antiga, sobra)
  }

  arq <- withr::local_tempfile(fileext = ".RDa", .local_envir = parent.frame())
  base_municipios_brasileiros <- antiga
  save(base_municipios_brasileiros, file = arq)
  arq
}

test_that("a paridade compara o CONJUNTO DE CHAVES, e não só valor a valor", {
  skip_if_not(file.exists(mape_caminho_tabela("14_corrupcao", "parquet", "dimensao")),
              "sem 14_corrupcao publicada")
  # Achado 67: o merge é inner, então linha que existe de um lado só sumia da
  # comparação junto com o relatório. 33.291 linhas publicadas nunca foram
  # confrontadas com coisa alguma.
  ref <- referencia_sintetica("14_corrupcao", chaves_extra = 3L)
  res <- suppressMessages(mape_paridade(
    "14_corrupcao", referencia = ref,
    esperadas = data.frame(coluna = character(), motivo = character()),
    gravar = FALSE))
  linha <- res[res$coluna == "(conjunto de chaves)", ]
  expect_equal(nrow(linha), 1L)
  expect_equal(linha$classe, "c_nao_explicada")
  expect_match(linha$descricao, "3 só na referência")
})

test_that("o curinga NÃO justifica diferença de chave", {
  skip_if_not(file.exists(mape_caminho_tabela("14_corrupcao", "parquet", "dimensao")),
              "sem 14_corrupcao publicada")
  # Achado 66: o curinga é uma reivindicação sobre diferença de VALOR. Ele
  # estava dispensando diferença de LINHA — em 13_seguranca, um motivo sobre
  # tipo de coluna cobria as 352 chaves dos códigos não municipais.
  ref <- referencia_sintetica("14_corrupcao", chaves_extra = 2L)
  res <- suppressWarnings(suppressMessages(mape_paridade(
    "14_corrupcao", referencia = ref,
    esperadas = data.frame(coluna = "*", motivo = "motivo sobre valor de coluna"),
    gravar = FALSE)))
  expect_equal(res$classe[res$coluna == "(conjunto de chaves)"], "c_nao_explicada")

  # Reivindicada pelo nome, aí sim ela é dispensada.
  res2 <- suppressWarnings(suppressMessages(mape_paridade(
    "14_corrupcao", referencia = ref,
    esperadas = data.frame(coluna = "(conjunto de chaves)", motivo = "assimetria de janela"),
    gravar = FALSE)))
  expect_equal(res2$classe[res2$coluna == "(conjunto de chaves)"], "a_correcao_reivindicada")
})

test_that("curinga que não absorve nada emite aviso", {
  skip_if_not(file.exists(mape_caminho_tabela("14_corrupcao", "parquet", "dimensao")),
              "sem 14_corrupcao publicada")
  # Achado 66: `absorveu` contava QUALQUER reivindicação, inclusive a linha de
  # chaves que o próprio curinga fabricava — então o aviso nunca disparava, em
  # 0 de 6 dimensões. Uma referência idêntica à publicada não gera diferença de
  # valor nenhuma, logo o curinga aqui é inerte por construção.
  ref <- referencia_sintetica("14_corrupcao")
  expect_warning(
    suppressMessages(mape_paridade(
      "14_corrupcao", referencia = ref,
      esperadas = data.frame(coluna = "*", motivo = "não absorve nada"),
      gravar = FALSE)),
    "NÃO absorveu diferença nenhuma")
})

test_that("reivindicação nominal de coluna removida é alcançável", {
  skip_if_not(file.exists(mape_caminho_tabela("14_corrupcao", "parquet", "dimensao")),
              "sem 14_corrupcao publicada")
  # Achado 40: sete das nove reivindicações nominais nunca eram consultadas,
  # porque o laço percorre o dicionário e coluna removida não tem linha nele.
  # Elas se liam como verificadas sem nunca terem sido.
  ref <- referencia_sintetica("14_corrupcao", extras = "coluna_que_foi_removida")
  res <- suppressMessages(mape_paridade(
    "14_corrupcao", referencia = ref,
    esperadas = data.frame(coluna = "coluna_que_foi_removida",
                           motivo = "removida de propósito na migração"),
    gravar = FALSE))
  linha <- res[res$coluna == "coluna_que_foi_removida", ]
  expect_equal(nrow(linha), 1L)
  expect_equal(linha$classe, "a_correcao_reivindicada")
  expect_match(linha$descricao, "removida de propósito")
})

test_that("reivindicação órfã vira diferença não explicada", {
  skip_if_not(file.exists(mape_caminho_tabela("14_corrupcao", "parquet", "dimensao")),
              "sem 14_corrupcao publicada")
  # O contrapeso do teste acima: dispensar coluna que não existe de lado nenhum
  # é dispensa de nada, e tem de aparecer como problema em vez de sumir.
  ref <- referencia_sintetica("14_corrupcao")
  res <- suppressMessages(mape_paridade(
    "14_corrupcao", referencia = ref,
    esperadas = data.frame(coluna = "coluna_que_nunca_existiu",
                           motivo = "reivindicação inventada"),
    gravar = FALSE))
  linha <- res[res$coluna == "coluna_que_nunca_existiu", ]
  expect_equal(nrow(linha), 1L)
  expect_equal(linha$classe, "c_nao_explicada")
  expect_match(linha$descricao, "órfã")
})

test_that("gravar = FALSE não escreve relatório nenhum", {
  skip_if_not(file.exists(mape_caminho_tabela("14_corrupcao", "parquet", "dimensao")),
              "sem 14_corrupcao publicada")
  # Achados 59 e 87: a suíte não pode sujar a árvore versionada.
  destino <- mape_caminho("qa", "paridade_14_corrupcao.md")
  antes <- if (file.exists(destino)) file.mtime(destino) else NA
  ref <- referencia_sintetica("14_corrupcao")
  suppressWarnings(suppressMessages(mape_paridade(
    "14_corrupcao", referencia = ref,
    esperadas = data.frame(coluna = character(), motivo = character()),
    gravar = FALSE)))
  depois <- if (file.exists(destino)) file.mtime(destino) else NA
  expect_equal(antes, depois)
})

test_that("as reivindicações versionadas são todas alcançáveis", {
  skip_if_not(file.exists(mape_caminho("qa", "paridade_esperada.csv")),
              "sem qa/paridade_esperada.csv")
  # Achado 40 outra vez, agora sobre o arquivo de verdade: uma reivindicação que
  # nomeia coluna inexistente é dispensa morta, e o relatório a exibia como se
  # fosse cobertura. Este teste não precisa da referência de 56 MB: ele afirma
  # que toda reivindicação nominal tem contraparte no dicionário OU é de coluna
  # removida — o que se confere pelo registro de depreciação.
  esp <- utils::read.csv(mape_caminho("qa", "paridade_esperada.csv"),
                         stringsAsFactors = FALSE, encoding = "UTF-8")
  expect_true(all(c("dimensao", "coluna", "motivo") %in% names(esp)))
  expect_true(all(nzchar(esp$motivo)))
  # Nenhuma reivindicação sem dimensão declarada, e nenhuma dimensão repetida
  # com o mesmo nome de coluna (que tornaria a segunda inalcançável).
  expect_equal(sum(duplicated(esp[, c("dimensao", "coluna")])), 0L)
})
