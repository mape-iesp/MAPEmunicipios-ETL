# Duas checagens de qualidade que ninguém exercitava --------------------------
#
# Grupo 26 da auditoria: mape_colunas_invariantes() (a checagem 16, do achado
# 14) e mape_descricoes_repetidas() (a checagem 12) sobreviviam a
# `function(...) NULL`. As duas são chamadas de dentro de mape_validar_tabela()
# com tryCatch(..., error = function(e) NULL), então trocá-las por nada não
# quebrava nem o relatório de QA: ele simplesmente deixava de registrar o
# problema, que é a pior forma de falhar.

# Painel sintético com o número de municípios que a checagem exige para
# concluir (ela só reporta com 100 ou mais).
painel_invariancia <- function(n_mun = 150, anos = 2010:2012) {
  mun <- sprintf("%07d", seq(1100015, length.out = n_mun))
  x <- expand.grid(id_municipio = mun, ano = as.integer(anos),
                   KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  x <- x[order(x$id_municipio, x$ano), ]
  i <- match(x$id_municipio, mun)
  # Uma medição só, replicada nos anos: o retrato do AdaptaBrasil, em miniatura.
  x$replicada_pct <- 10 + i
  # Uma coluna que de fato varia entre os anos — é a comparação com ela que
  # torna a invariância da irmã informativa.
  x$variavel_i <- 100 * i + (x$ano - min(anos) + 1)
  rownames(x) <- NULL
  x
}


# -- mape_colunas_invariantes() -----------------------------------------------

test_that("isola a coluna replicada e deixa passar a que varia", {
  inv <- mape_colunas_invariantes(painel_invariancia())

  expect_true("replicada_pct" %in% names(inv))
  expect_equal(inv[["replicada_pct"]], 1)
  # A irmã que varia não pode ser reportada: seria ruído, e ruído é o que faz
  # um relatório de QA ser ignorado.
  expect_false("variavel_i" %in% names(inv))
  expect_length(inv, 1)
})

test_that("numa tabela em que TUDO é invariante, não reporta nada", {
  # Tabela transversal replicada por desenho: a invariância é esperada e não
  # diz nada. O discriminante da checagem é a comparação com as irmãs.
  x <- painel_invariancia()
  x$variavel_i <- x$replicada_pct * 2
  expect_length(mape_colunas_invariantes(x), 0)
})

test_that("coluna zerada não conta como replicada", {
  # Sem a regra do "não zero", uma coluna esparsa seria trivialmente invariante
  # em todo município que só tem zero — e o zero constante é evidência de
  # ausência, não de replicação.
  x <- painel_invariancia()
  x$zerada_i <- 0
  inv <- mape_colunas_invariantes(x)
  expect_false("zerada_i" %in% names(inv))
  expect_true("replicada_pct" %in% names(inv))
})

test_that("com poucos municípios ou um ano só, a checagem não conclui", {
  # 50 municípios: invariante em todos, e ainda assim não reporta — abaixo de
  # 100 a proporção não sustenta afirmação nenhuma.
  expect_length(mape_colunas_invariantes(painel_invariancia(n_mun = 50)), 0)
  # Um ano só: não há entre o que comparar.
  x <- painel_invariancia()
  expect_length(mape_colunas_invariantes(x[x$ano == 2010, ]), 0)
})

test_that("flag_ e ano_ref_ ficam fora: invariância ali é o esperado", {
  x <- painel_invariancia()
  x$flag_imputado <- 1L
  x$ano_ref_censo <- 2010L
  inv <- mape_colunas_invariantes(x)
  expect_false("flag_imputado" %in% names(inv))
  expect_false("ano_ref_censo" %in% names(inv))
})

test_that("no dado publicado, a checagem pega vulnerabilidade_socioeconomica_pct", {
  # Achado 14, sobre o dado real: uma medição publicada como se fossem os
  # censos de 2000 e 2010, com valor idêntico nos dois anos em todos os
  # municípios. Se a checagem deixar de pegá-la, a evidência do achado some.
  x <- mape_ler_tabela("05_sociedade", camada = "dimensao")
  inv <- mape_colunas_invariantes(x)

  expect_true("vulnerabilidade_socioeconomica_pct" %in% names(inv))
  expect_equal(inv[["vulnerabilidade_socioeconomica_pct"]], 1)
  # E a tabela tem colunas que variam — é isso que faz o achado ser um achado
  # e não uma propriedade de desenho.
  expect_lt(length(inv), sum(vapply(x, is.numeric, logical(1))))
})


# -- mape_descricoes_repetidas() ----------------------------------------------

# Dicionário fabricado. As descrições são escritas SEM acento de propósito: a
# normalização usa iconv(to = "ASCII//TRANSLIT"), cujo resultado para caractere
# acentuado depende da libiconv do sistema, e um teste não pode depender disso.
dicionario_fixture <- function(raiz) {
  vars <- data.frame(
    nome_canonico = c("receita_corrente_liquida_brl2023",
                      "receita_corrente_liquida_i",
                      "populacao_residente_i",
                      "id_municipio_a", "id_municipio_b",
                      "total_de_casos_a", "total_de_casos_b"),
    tabela = c("06_financas", "04_economia", "02_populacao",
               "06_financas", "04_economia",
               "06_financas", "04_economia"),
    descricao = c(
      # O par que a checagem existe para pegar: a mesma frase, separada por
      # maiuscula, pontuacao e o sufixo de deflacao que o projeto acrescenta.
      "Receita corrente liquida do municipio (deflacionado para 12/2023)",
      "RECEITA CORRENTE LIQUIDA DO MUNICIPIO!",
      "Populacao residente estimada pelo IBGE no meio do ano",
      # Par legitimo, na lista de excecoes: a mesma frase descreve o mesmo
      # conceito nas duas tabelas.
      "Codigo IBGE do municipio (7 digitos)",
      "Codigo IBGE do municipio (7 digitos)",
      # Descricao curta (menos de 25 caracteres normalizados): repeticao ali
      # nao e evidencia de bloco deslizado.
      "Total de casos", "Total de casos"
    ),
    stringsAsFactors = FALSE
  )
  dir.create(file.path(raiz, "dicionario"), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(vars, file.path(raiz, "dicionario", "variaveis.csv"),
                   row.names = FALSE, fileEncoding = "UTF-8")
  invisible(vars)
}

test_that("pega a descrição repetida apesar de caixa, pontuação e sufixo de deflação", {
  raiz <- raiz_de_teste()
  withr::local_options(mape.raiz = raiz)
  withr::defer(limpar_caches_mape())
  dicionario_fixture(raiz)

  r <- mape_descricoes_repetidas("06_financas")

  expect_s3_class(r, "data.frame")
  expect_equal(nrow(r), 1)
  expect_equal(r$coluna, "receita_corrente_liquida_brl2023")
  expect_equal(r$outra, "receita_corrente_liquida_i")
  expect_equal(r$tabela_outra, "04_economia")

  # A relação é simétrica: olhar do outro lado tem de achar o mesmo par.
  inverso <- mape_descricoes_repetidas("04_economia")
  expect_equal(nrow(inverso), 1)
  expect_equal(inverso$coluna, "receita_corrente_liquida_i")
  expect_equal(inverso$tabela_outra, "06_financas")
})

test_that("descrição única, exceção declarada e frase curta não viram achado", {
  raiz <- raiz_de_teste()
  withr::local_options(mape.raiz = raiz)
  withr::defer(limpar_caches_mape())
  dicionario_fixture(raiz)

  # 02_populacao só tem descrição única: nada a reportar, e o retorno é um data
  # frame vazio com as três colunas — não NULL, que quebraria quem itera.
  vazio <- mape_descricoes_repetidas("02_populacao")
  expect_s3_class(vazio, "data.frame")
  expect_identical(nrow(vazio), 0L)
  expect_named(vazio, c("coluna", "outra", "tabela_outra"))

  # As duas colunas restantes de 06_financas — id_municipio (exceção) e
  # total_de_casos (curta demais) — não aparecem no resultado.
  r <- mape_descricoes_repetidas("06_financas")
  expect_false("id_municipio_a" %in% r$coluna)
  expect_false("total_de_casos_a" %in% r$coluna)
})

test_that("o dicionário publicado não tem descrição repetida entre tabelas", {
  # Sobre o dicionário real: hoje as 26 tabelas dão zero. O bloco deslizado de
  # 06_financas foi corrigido, e este teste é o que impede que ele volte —
  # copiar a descrição da linha de cima é o erro mais fácil de cometer aqui.
  tabelas <- mape_dicionario("tabelas")$slug_tabela
  expect_length(tabelas, 26)

  repetidas <- lapply(tabelas, mape_descricoes_repetidas)
  n <- vapply(repetidas, nrow, integer(1))
  culpadas <- paste(tabelas[n > 0], collapse = ", ")
  expect_identical(sum(n), 0L, info = paste("tabelas com repetição:", culpadas))
})
