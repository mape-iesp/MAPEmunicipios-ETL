# Registro de tabelas no dicionário ------------------------------------------
#
# Migrar uma fonte é sempre a mesma sequência: registrar a tabela, atribuir as
# variáveis a ela, tratar o bruto e publicar. Estas funções fazem as duas
# primeiras partes, para que o script de cada fonte contenha só o que é
# específico daquela fonte.
#
# Sem isso, cada uma das dezessete dimensões teria o seu próprio script de
# registro, e a convenção se dissolveria na terceira ou quarta cópia — que é
# exatamente como o legado acabou com o mesmo bloco de expansão de painel
# copiado cinco vezes.

#' Registra uma tabela em dicionario/tabelas.csv
#'
#' Os campos calculados (n_linhas, cobertura temporal observada, percentual de
#' vazios) não entram aqui: são preenchidos por mape_gerar_documentacao() a
#' partir do dado. Digitar um número que pode ser medido é a origem das
#' contagens que não fecham hoje.
#'
#' @param slug Identificador, no formato "<dimensao>/<fonte>".
#' @param dimensao Slug da dimensão.
#' @param nome_publicado Nome legível.
#' @param descricao O que a tabela contém.
#' @param chave_primaria Colunas da chave, separadas por vírgula.
#' @param granularidade Descrição da unidade de observação.
#' @param metodo_acesso Vocabulário fechado: bigquery, pacote_r,
#'   download_manual, api, arquivo_local.
#' @param fonte_original Órgão produtor.
#' @param fonte_extracao Onde o dado foi obtido.
#' @param link URL.
#' @param licenca Licença dos dados, ou "a verificar".
#' @param periodicidade_fonte anual, bienal, censitaria, mensal ou eventual.
#' @param regra_preenchimento_temporal nenhuma, carry_forward ou
#'   valor_unico_replicado.
#' @param script_ingestao Caminho do script.
#' @param observacoes Limitações conhecidas.
#' @param ... Campos adicionais.
#' @return Invisivelmente, a linha registrada.
mape_registrar_tabela <- function(slug, dimensao, nome_publicado, descricao,
                                  chave_primaria, granularidade, metodo_acesso,
                                  fonte_original, fonte_extracao, link = NA_character_,
                                  licenca = "a verificar",
                                  periodicidade_fonte = NA_character_,
                                  regra_preenchimento_temporal = "nenhuma",
                                  script_ingestao = NA_character_,
                                  cobertura_temporal_da_fonte = NA_character_,
                                  citacao_recomendada = NA_character_,
                                  observacoes = NA_character_, ...) {
  linha <- data.frame(
    slug_tabela = slug, dimensao = dimensao, nome_publicado = nome_publicado,
    descricao = descricao, responsavel = NA_character_,
    fonte_original = fonte_original, fonte_extracao = fonte_extracao,
    link = link, licenca = licenca, licenca_url = NA_character_,
    periodicidade_fonte = periodicidade_fonte,
    data_ultima_atualizacao_fonte = NA_character_,
    chave_primaria = chave_primaria, granularidade = granularidade,
    metodo_acesso = metodo_acesso, script_ingestao = script_ingestao,
    citacao_recomendada = citacao_recomendada,
    regra_preenchimento_temporal = regra_preenchimento_temporal,
    cobertura_temporal_da_fonte = cobertura_temporal_da_fonte,
    observacoes = observacoes,
    stringsAsFactors = FALSE
  )

  caminho <- mape_caminho("dicionario", "tabelas.csv")
  if (file.exists(caminho)) {
    tab <- utils::read.csv(caminho, stringsAsFactors = FALSE, encoding = "UTF-8")
    tab <- tab[tab$slug_tabela != slug, , drop = FALSE]
    for (nm in setdiff(names(linha), names(tab))) tab[[nm]] <- NA
    for (nm in setdiff(names(tab), names(linha))) linha[[nm]] <- NA
    tab <- rbind(tab[, names(linha)], linha)
  } else {
    tab <- linha
  }
  tab <- tab[order(tab$slug_tabela), ]
  utils::write.csv(tab, caminho, row.names = FALSE, fileEncoding = "UTF-8", na = "")
  .mape_cache_dic$dic_tabelas <- NULL
  invisible(linha)
}

#' Atribui variáveis a uma tabela e aplica renomeações
#'
#' @param slug Identificador da tabela.
#' @param nomes_legado Vetor com os nomes das colunas como estão na base
#'   publicada hoje. Serve para localizar as linhas no dicionário semeado.
#' @param renomear Vetor nomeado `c(nome_legado = "nome_canonico")` para as
#'   colunas que mudam de nome.
#' @param fixar Lista nomeada por nome canônico, cada elemento uma lista de
#'   campos a fixar (tipo, escala, unidade, dominio_valido, descricao...).
#'   O que for fixado deixa de estar pendente de revisão, porque passou a ser
#'   fato verificado e não inferência.
#' @param novas Data frame com variáveis que não existem na base publicada e
#'   portanto não estão no dicionário semeado.
#' @return Invisivelmente, o número de variáveis atribuídas.
mape_atribuir_variaveis <- function(slug, nomes_legado, renomear = NULL,
                                    fixar = NULL, novas = NULL) {
  caminho <- mape_caminho("dicionario", "variaveis.csv")
  vars <- utils::read.csv(caminho, stringsAsFactors = FALSE, encoding = "UTF-8")

  faltando <- setdiff(nomes_legado, vars$nome_legado)
  if (length(faltando)) {
    warning("Nomes ausentes do dicionário semeado (serão ignorados): ",
            paste(faltando, collapse = ", "), call. = FALSE)
    nomes_legado <- intersect(nomes_legado, vars$nome_legado)
  }

  idx <- match(nomes_legado, vars$nome_legado)
  vars$tabela[idx] <- slug

  if (!is.null(renomear)) {
    for (de in names(renomear)) {
      j <- which(vars$nome_legado == de)
      if (length(j)) vars$nome_canonico[j] <- unname(renomear[[de]])
    }
  }

  if (!is.null(fixar)) {
    for (nm in names(fixar)) {
      j <- which(vars$nome_canonico == nm & vars$tabela == slug)
      if (!length(j)) {
        warning("Variável '", nm, "' não encontrada em ", slug, call. = FALSE)
        next
      }
      for (campo in names(fixar[[nm]])) vars[[campo]][j] <- fixar[[nm]][[campo]]
      # O que foi fixado à mão deixa de ser inferência.
      vars$confianca_inferencia[j] <- "alta"
      vars$revisao_pendente[j] <- FALSE
      vars$motivo_revisao[j] <- NA_character_
    }
  }

  if (!is.null(novas) && nrow(novas)) {
    for (nm in setdiff(names(vars), names(novas))) novas[[nm]] <- NA
    novas$tabela <- slug
    vars <- rbind(vars, novas[, names(vars)])
  }

  utils::write.csv(vars, caminho, row.names = FALSE, fileEncoding = "UTF-8", na = "")
  .mape_cache_dic$dic_variaveis <- NULL

  n <- sum(vars$tabela == slug, na.rm = TRUE)
  message("dicionário: ", n, " variáveis atribuídas a ", slug,
          " (", sum(vars$revisao_pendente & vars$tabela == slug, na.rm = TRUE),
          " ainda pendentes de revisão)")
  invisible(n)
}

#' Registra uma pendência conhecida
#'
#' Fonte que existe mas não migra — porque não roda, porque não contribui com
#' nenhuma coluna publicada, ou porque a origem se perdeu. Fica registrada em
#' pendencias/ com diagnóstico, em vez de sumir sem explicação.
#'
#' @param slug Identificador da fonte.
#' @param titulo Resumo em uma linha.
#' @param diagnostico O que exatamente impede.
#' @param evidencia Caminho e linha no legado.
#' @param impacto O que se perde.
#' @param para_recuperar O que seria preciso fazer.
#' @return Invisivelmente, o caminho do arquivo.
mape_registrar_pendencia <- function(slug, titulo, diagnostico, evidencia,
                                     impacto, para_recuperar) {
  destino <- mape_caminho("pendencias", paste0(gsub("/", "__", slug), ".md"))
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  writeLines(c(
    paste0("# ", titulo), "",
    paste0("**Fonte:** `", slug, "`  "),
    paste0("**Registrado em:** ", format(Sys.Date(), "%Y-%m-%d")), "",
    "## O que impede", "", diagnostico, "",
    "## Evidência", "", evidencia, "",
    "## O que se perde", "", impacto, "",
    "## O que seria preciso para recuperar", "", para_recuperar, ""
  ), destino, useBytes = TRUE)
  message("pendência registrada: ", destino)
  invisible(destino)
}
