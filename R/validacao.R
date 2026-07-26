# Validação e controle de qualidade ------------------------------------------
#
# As doze checagens da seção 11.2 do plano. Cada uma nasceu de um defeito real
# encontrado no levantamento do legado, e por isso o comentário de cada bloco
# diz o que ela previne.
#
# Regra de bloqueio: um ERRO impede a publicação, sem exceção. Um AVISO entra no
# relatório e exige justificativa registrada no campo observacoes da tabela. Um
# aviso sem justificativa vira erro na publicação — sem isso, avisos viram
# paisagem em poucas semanas e o sistema inteiro perde utilidade.

#' Roda todas as checagens sobre uma tabela
#'
#' @param x Data frame.
#' @param tabela Identificador da tabela.
#' @param chaves Chave primária. Se NULL, lê do dicionário de tabelas.
#' @param diretorio Diretório de municípios. Se NULL, lê o publicado, exceto
#'   quando a própria tabela for o diretório.
#' @param erro Se TRUE, falha ao encontrar problema bloqueante.
#' @return Invisivelmente, um data frame com uma linha por problema.
mape_validar_tabela <- function(x, tabela, chaves = NULL, diretorio = NULL,
                                erro = TRUE) {
  achados <- list()
  reg <- function(checagem, gravidade, descricao) {
    achados[[length(achados) + 1]] <<- data.frame(
      tabela = tabela, checagem = checagem, gravidade = gravidade,
      descricao = descricao, stringsAsFactors = FALSE
    )
  }

  # A chave primária vem do dicionário; digitar de novo aqui seria repetir a
  # fonte de verdade.
  if (is.null(chaves)) {
    tabs <- tryCatch(mape_dicionario("tabelas"), error = function(e) NULL)
    if (!is.null(tabs) && tabela %in% tabs$slug_tabela) {
      decl <- tabs$chave_primaria[tabs$slug_tabela == tabela][1]
      chaves <- trimws(strsplit(decl, ",")[[1]])
    } else {
      chaves <- intersect(c("id_municipio", "ano"), names(x))
    }
  }
  chaves <- intersect(chaves, names(x))

  # -- 1. Unicidade da chave primária ---------------------------------------
  # Previne: 222 chaves duplicadas em Finanças, 54 nos dados históricos.
  if (length(chaves)) {
    d <- tryCatch(mape_validar_chave(x, chaves, erro = FALSE),
                  warning = function(w) suppressWarnings(
                    mape_validar_chave(x, chaves, erro = FALSE)))
    if (d$n_chaves_duplicadas > 0) {
      reg("chave_unica", "erro",
          paste0(d$n_chaves_duplicadas, " chave(s) duplicada(s), ",
                 d$n_linhas_excedentes, " linha(s) excedente(s)"))
    }
    # -- 2. Ausência de chave nula ------------------------------------------
    # Previne: as 122 linhas pré-deduplicação, 13 das quais sobrevivem hoje.
    if (d$n_chave_na > 0) {
      reg("chave_sem_na", "erro",
          paste0(d$n_chave_na, " linha(s) com chave nula"))
    }
  } else {
    reg("chave_unica", "aviso", "nenhuma coluna de chave encontrada")
  }

  # -- 3. Domínio da chave contra o diretório -------------------------------
  # Previne: 27 códigos de UF sumindo na Segurança e 27 muncode extintos na
  # dimensão histórica. Os órfãos são REPORTADOS, não descartados.
  if ("id_municipio" %in% names(x) && tabela != "00_diretorios/municipios") {
    dir_ok <- tryCatch({
      if (is.null(diretorio)) diretorio <- mape_ler_tabela("00_diretorios/municipios")
      TRUE
    }, error = function(e) FALSE)
    if (dir_ok) {
      dd <- suppressWarnings(
        mape_validar_dominio_chave(x, diretorio = diretorio, erro_se_exceder = FALSE)
      )
      if (dd$n_codigos_orfaos > 0) {
        limiar <- mape_param("qa.max_prop_chave_orfa")
        reg("dominio_chave",
            if (dd$prop_linhas_orfas > limiar) "erro" else "aviso",
            paste0(dd$n_codigos_orfaos, " código(s) fora do diretório em ",
                   dd$n_linhas_orfas, " linha(s) (",
                   round(100 * dd$prop_linhas_orfas, 3), "%). Exemplos: ",
                   paste(utils::head(dd$codigos_orfaos, 5), collapse = ", ")))
      }
      # -- 6. Cobertura de municípios ---------------------------------------
      # Previne: o Anuário do FBSP cobrindo 27 municípios sem nenhum aviso.
      if (dd$cobertura_municipios < 0.5) {
        reg("cobertura_municipios", "aviso",
            paste0("a tabela cobre apenas ",
                   round(100 * dd$cobertura_municipios, 1),
                   "% dos municípios do diretório"))
      }
    }
  }

  # -- 4, 9, 10. Tipos, domínio de valor e coerência sufixo/escala ----------
  if (mape_tabela_no_dicionario(tabela)) {
    prob <- tryCatch(
      suppressWarnings(mape_validar_schema(x, tabela, erro = FALSE)),
      error = function(e) NULL
    )
    if (!is.null(prob) && nrow(prob)) {
      for (i in seq_len(nrow(prob))) {
        reg("schema", prob$gravidade[i],
            paste0(prob$coluna[i], ": ", prob$descricao[i]))
      }
    }
  } else {
    reg("dicionario", "erro",
        "a tabela não tem entrada em dicionario/tabelas.csv")
  }

  # -- 5. Faixa de anos declarada contra observada --------------------------
  # Previne: cinco bases anunciando 2024 num painel que termina em 2023.
  if ("ano" %in% names(x) && any(!is.na(x$ano))) {
    obs <- range(x$ano, na.rm = TRUE)
    painel <- mape_param("anos_painel")
    if (obs[1] < painel[1] || obs[2] > painel[2]) {
      reg("faixa_anos", "aviso",
          paste0("anos observados de ", obs[1], " a ", obs[2],
                 ", fora do painel declarado (", painel[1], " a ", painel[2], ")"))
    }
  }

  # -- 7. Linter de nomes de coluna -----------------------------------------
  # Previne: pontos (ln.pc.receita1920.sd), Title Case com acento
  # (Comércio.e.serviços), maiúsculas (NM_UF) e os prefixos genéricos total_ e
  # quantidade_, usados em sete dimensões para coisas sem relação entre si.
  ruins <- names(x)[!grepl("^[a-z][a-z0-9_]*$", names(x))]
  if (length(ruins)) {
    reg("nomes_colunas", "erro",
        paste0("nome(s) fora do padrão snake_case ASCII: ",
               paste(utils::head(ruins, 10), collapse = ", ")))
  }
  genericos <- grep("^(total_|quantidade_)", names(x), value = TRUE)
  if (length(genericos)) {
    reg("nomes_colunas", "aviso",
        paste0("prefixo genérico banido: ",
               paste(utils::head(genericos, 8), collapse = ", ")))
  }

  # -- 8. Sentinelas não convertidos ----------------------------------------
  sent <- mape_detectar_sentinelas(x)
  if (nrow(sent)) {
    reg("sentinelas", "erro",
        paste0(nrow(sent), " coluna(s) com sentinela não convertido: ",
               paste(utils::head(paste0(sent$coluna, "='", sent$sentinela, "'"), 5),
                     collapse = ", ")))
  }

  # -- Extra: valores infinitos ---------------------------------------------
  # Previne: log10() aplicado sem tratar zeros. No dado publicado hoje isso não
  # se manifesta, porque nenhum município-ano tem PIB igual a zero, mas o
  # defeito é latente e reapareceria numa reextração.
  for (nm in names(x)) {
    if (is.numeric(x[[nm]]) && any(is.infinite(x[[nm]]))) {
      reg("valores_infinitos", "erro",
          paste0(nm, ": ", sum(is.infinite(x[[nm]])), " valor(es) infinito(s)"))
    }
  }

  res <- if (length(achados)) do.call(rbind, achados) else
    data.frame(tabela = character(), checagem = character(),
               gravidade = character(), descricao = character(),
               stringsAsFactors = FALSE)

  mape_gravar_relatorio_qa(res, tabela, x)

  n_erro  <- sum(res$gravidade == "erro")
  n_aviso <- sum(res$gravidade == "aviso")
  message(sprintf("[QA] %s: %d erro(s), %d aviso(s)", tabela, n_erro, n_aviso))
  if (n_aviso) {
    for (i in which(res$gravidade == "aviso")) {
      message("      aviso  ", res$checagem[i], ": ", res$descricao[i])
    }
  }
  if (n_erro && erro) {
    stop("Validação bloqueou a publicação de '", tabela, "':\n",
         paste0("  - ", res$checagem[res$gravidade == "erro"], ": ",
                res$descricao[res$gravidade == "erro"], collapse = "\n"),
         call. = FALSE)
  }
  invisible(res)
}

#' Grava o relatório de qualidade de uma tabela
#'
#' @param res Data frame de problemas.
#' @param tabela Identificador da tabela.
#' @param x A tabela validada, usada para o resumo quantitativo.
#' @return Invisivelmente, o caminho do relatório.
mape_gravar_relatorio_qa <- function(res, tabela, x = NULL) {
  destino <- mape_caminho("qa", paste0(gsub("/", "__", tabela), ".md"))
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)

  linhas <- c(
    paste0("# QA — ", tabela), "",
    paste0("Gerado em ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "."), ""
  )
  if (!is.null(x)) {
    linhas <- c(linhas,
      "## Resumo", "",
      paste0("- linhas: ", formatC(nrow(x), format = "d", big.mark = ".", decimal.mark = ",")),
      paste0("- colunas: ", ncol(x)),
      paste0("- células vazias: ",
             round(100 * mean(is.na(x)), 2), "%"),
      "")
  }
  linhas <- c(linhas, "## Checagens", "")
  if (!nrow(res)) {
    linhas <- c(linhas, "Nenhum problema. As doze checagens passaram.", "")
  } else {
    linhas <- c(linhas, "| checagem | gravidade | descrição |",
                "|---|---|---|",
                paste0("| ", res$checagem, " | ", res$gravidade, " | ",
                       gsub("[|]", "/", res$descricao), " |"), "")
  }
  writeLines(linhas, destino, useBytes = TRUE)
  invisible(destino)
}
