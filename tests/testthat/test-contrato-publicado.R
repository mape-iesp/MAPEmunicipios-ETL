# Contrato de dados, afirmado sobre o ARTEFATO PUBLICADO — achado 44.
#
# A suíte validava 1 das 26 tabelas publicadas e lia 6, e nada nela ancorava o
# contrato de chave nem o domínio de sufixo sobre o dado que sai daqui. O
# contrato estava escrito no CLAUDE.md, no plano e em config/parametros.yml, e
# nenhum teste o exercia.
#
# Estes testes leem os 26 Parquet. É a leitura sequencial mais cara da suíte —
# poucos segundos, porque o formato é colunar — e é o que transforma o contrato
# de convenção em asserção.

publicadas <- function() {
  skip_if_not(file.exists(here::here("dados", "dimensao", "04_economia.parquet")),
              "sem tabelas publicadas")
  mape_tabelas_publicadas()
}

test_that("as 26 tabelas publicadas estão todas no dicionário", {
  tabs <- publicadas()
  expect_equal(nrow(tabs), 26)
  for (s in tabs$slug) expect_true(mape_tabela_no_dicionario(s))
})

test_that("id_municipio é texto de 7 dígitos em toda tabela publicada", {
  tabs <- publicadas()
  contrato <- mape_param("chaves")
  expect_equal(contrato$id_municipio$tipo, "character")
  expect_equal(contrato$id_municipio$digitos, 7)

  for (i in seq_len(nrow(tabs))) {
    x <- as.data.frame(mape_ler_tabela(tabs$slug[i], camada = tabs$camada[i]))
    if (!"id_municipio" %in% names(x)) next
    expect_true(is.character(x$id_municipio),
                info = paste(tabs$slug[i], "id_municipio não é character"))
    larguras <- unique(nchar(x$id_municipio[!is.na(x$id_municipio)]))
    expect_equal(larguras, 7,
                 info = paste(tabs$slug[i], "id_municipio com largura",
                              paste(larguras, collapse = "/")))
  }
})

test_that("ano é integer e nunca integer64 nas tabelas publicadas", {
  # integer64 é a armadilha silenciosa do repositório: as.numeric(ano) devolve
  # 9.83e-321 e sort()/range() devolvem lixo sem erro.
  tabs <- publicadas()
  for (i in seq_len(nrow(tabs))) {
    x <- as.data.frame(mape_ler_tabela(tabs$slug[i], camada = tabs$camada[i]))
    if (!"ano" %in% names(x)) next
    expect_false(inherits(x$ano, "integer64"),
                 info = paste(tabs$slug[i], "ano é integer64"))
    expect_equal(mape_tipo_de(x$ano), "integer",
                 info = paste(tabs$slug[i], "ano é", mape_tipo_de(x$ano)))
  }
})

test_that("o conjunto de colunas _pct fora de [0,100] é exatamente o baseline", {
  # Baseline congelado em 26/07/2026: 18 colunas, todas com o defeito declarado
  # e justificado. Uma 19ª quebra este teste — que é o ponto. Se uma coluna sair
  # da lista porque foi corrigida, o teste também quebra, e a lista é atualizada
  # no mesmo commit da correção, de propósito.
  esperado <- c(
    "01_assistencia_social_dh::cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_pct",
    "01_assistencia_social_dh/cadunico::cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_pct",
    "10_saude::pni_cobertura_bcg_pct",
    "10_saude::pni_cobertura_dtp_pct",
    "10_saude::pni_cobertura_dtpa_gestante_pct",
    "10_saude::pni_cobertura_febre_amarela_pct",
    "10_saude::pni_cobertura_haemophilus_influenzae_b_pct",
    "10_saude::pni_cobertura_hepatite_a_pct",
    "10_saude::pni_cobertura_hepatite_b_pct",
    "10_saude::pni_cobertura_penta_pct",
    "10_saude::pni_cobertura_poliomielite_pct",
    "10_saude::pni_cobertura_poliomielite_reforco_4a_pct",
    "10_saude::pni_cobertura_sarampo_pct",
    "10_saude::pni_cobertura_tetra_viral_pct",
    "10_saude::pni_cobertura_triplice_bacteriana_pct",
    "10_saude::pni_cobertura_triplice_viral_d2_pct",
    "10_saude::pni_cobertura_triplice_viral_dose1_pct",
    "10_saude::pni_cobertura_vacinal_agregada_pct"
  )

  tabs <- publicadas()
  observado <- character()
  for (i in seq_len(nrow(tabs))) {
    x <- as.data.frame(mape_ler_tabela(tabs$slug[i], camada = tabs$camada[i]))
    for (nm in grep("_pct$", names(x), value = TRUE)) {
      v <- x[[nm]]
      if (is.numeric(v) && any(!is.na(v)) &&
          (min(v, na.rm = TRUE) < 0 || max(v, na.rm = TRUE) > 100)) {
        observado <- c(observado, paste0(tabs$slug[i], "::", nm))
      }
    }
  }
  expect_setequal(observado, esperado)
})

test_that("nenhuma coluna sob sufixo de contagem, taxa ou distância é negativa", {
  # Achado 73: a prova prometida pelo vocabulário fechado existia para 4 dos 15
  # tokens. Esta é a asserção mais barata do conjunto, e faltava inteira.
  tabs <- publicadas()
  negativas <- character()
  for (i in seq_len(nrow(tabs))) {
    x <- as.data.frame(mape_ler_tabela(tabs$slug[i], camada = tabs$camada[i]))
    for (nm in grep("(_i|_p100k|_p1k|_p100dom|_km|_km2)$", names(x), value = TRUE)) {
      v <- x[[nm]]
      if (is.numeric(v) && any(!is.na(v)) && min(v, na.rm = TRUE) < 0) {
        negativas <- c(negativas, paste0(tabs$slug[i], "::", nm))
      }
    }
  }
  expect_equal(negativas, character())
})

test_that("toda coluna flag_ publicada só tem 0, 1 ou NA", {
  tabs <- publicadas()
  ruins <- character()
  for (i in seq_len(nrow(tabs))) {
    x <- as.data.frame(mape_ler_tabela(tabs$slug[i], camada = tabs$camada[i]))
    for (nm in grep("^flag_", names(x), value = TRUE)) {
      if (!all(x[[nm]] %in% c(0, 1, NA, TRUE, FALSE))) {
        ruins <- c(ruins, paste0(tabs$slug[i], "::", nm))
      }
    }
  }
  expect_equal(ruins, character())
})

test_that("toda coluna publicada tem linha no dicionário, ou é chave declarada", {
  # Achado 80: o laço de validação iterava sobre as linhas do dicionário, então
  # coluna publicada fora dele não era olhada por checagem nenhuma.
  tabs <- publicadas()
  chaves <- names(mape_param("chaves"))
  orfas <- character()
  for (i in seq_len(nrow(tabs))) {
    x <- as.data.frame(mape_ler_tabela(tabs$slug[i], camada = tabs$camada[i]))
    vars <- mape_variaveis_de(tabs$slug[i])
    fora <- setdiff(names(x), c(vars$nome_canonico, chaves))
    if (length(fora)) orfas <- c(orfas, paste0(tabs$slug[i], "::", fora))
  }
  expect_equal(orfas, character())
})

test_that("nenhuma variável publicada fica sem descrição", {
  # Achado 56: eram 27.
  tabs <- publicadas()
  sem <- character()
  for (i in seq_len(nrow(tabs))) {
    x <- as.data.frame(mape_ler_tabela(tabs$slug[i], camada = tabs$camada[i]))
    vars <- mape_variaveis_de(tabs$slug[i])
    v <- vars[vars$nome_canonico %in% names(x), , drop = FALSE]
    vazias <- v$nome_canonico[is.na(v$descricao) | !nzchar(trimws(as.character(v$descricao)))]
    if (length(vazias)) sem <- c(sem, paste0(tabs$slug[i], "::", vazias))
  }
  expect_equal(unique(sem), character())
})

test_that("uma coluna monetária grande sobrevive à ida e volta pelo csv.gz", {
  # Achado 19: sete colunas de 04_economia estavam declaradas `integer` e
  # estouram o int32; 23.761 células viravam NA em silêncio na releitura do
  # csv.gz, porque mape_como_inteiro() tinha suppressWarnings.
  skip_if_not(file.exists(here::here("dados", "dimensao", "04_economia.csv.gz")))

  texto <- utils::read.csv(here::here("dados", "dimensao", "04_economia.csv.gz"),
                           stringsAsFactors = FALSE, colClasses = "character")
  tipado <- mape_aplicar_tipos(texto, "04_economia")

  monetarias <- grep("_brl2023$", names(texto), value = TRUE)
  perdidas <- sum(vapply(monetarias, function(k)
    sum(is.na(tipado[[k]]) & nzchar(texto[[k]])), integer(1)))
  expect_equal(perdidas, 0L)

  # E o maior PIB municipal continua maior que o teto do int32, o que é o que
  # torna este teste capaz de falhar.
  expect_gt(max(tipado$pib_brl2023, na.rm = TRUE), .Machine$integer.max)
})

test_that("mape_como_inteiro avisa quando a coerção perde valor", {
  expect_warning(mape_como_inteiro(c("1", "3000000000")),
                 "viraram NA na conversão")
  expect_silent(mape_como_inteiro(c("1", "2", NA)))
})
