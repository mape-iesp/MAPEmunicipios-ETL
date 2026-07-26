# O dicionário como entrada do pipeline --------------------------------------
#
# No legado o dicionário é produzido DEPOIS da base e se alinha a ela por
# posição: a linha 27 descreve a coluna 27, sem nenhuma chave de junção. Aqui o
# papel se inverte. O dicionário passa a ser lido pelo código para renomear
# colunas, validar tipos e domínios, e gerar a documentação publicada.
#
# Consequência prática: uma tabela sem linha no dicionário não passa na
# validação. É essa mecânica que impede a documentação de ficar para depois.

.mape_cache_dic <- new.env(parent = emptyenv())

#' Lê um dos arquivos do dicionário
#'
#' @param qual "variaveis", "tabelas", "dimensoes", "conceitos" ou "deprecacao".
#' @param .recarregar Ignora o cache da sessão.
#' @return Data frame.
mape_dicionario <- function(qual = "variaveis", .recarregar = FALSE) {
  chave <- paste0("dic_", qual)
  if (.recarregar || is.null(.mape_cache_dic[[chave]])) {
    caminho <- mape_caminho("dicionario", paste0(qual, ".csv"))
    if (!file.exists(caminho)) {
      stop("Arquivo do dicionário não encontrado: ", caminho, "\n",
           "Rode targets::tar_make(dicionario) para gerá-lo.", call. = FALSE)
    }
    .mape_cache_dic[[chave]] <- utils::read.csv(
      caminho, stringsAsFactors = FALSE, encoding = "UTF-8", na.strings = c("", "NA")
    )
  }
  .mape_cache_dic[[chave]]
}

#' Linhas do dicionário de variáveis de uma tabela
#'
#' @param tabela Identificador da tabela.
#' @return Data frame com as variáveis daquela tabela.
mape_variaveis_de <- function(tabela) {
  dic <- mape_dicionario("variaveis")
  dic[!is.na(dic$tabela) & dic$tabela == tabela, , drop = FALSE]
}

#' A tabela tem entrada no dicionário?
#'
#' @param tabela Identificador da tabela.
#' @return TRUE ou FALSE.
mape_tabela_no_dicionario <- function(tabela) {
  dic <- tryCatch(mape_dicionario("tabelas"), error = function(e) NULL)
  !is.null(dic) && tabela %in% dic$slug_tabela
}

#' Renomeia as colunas de uma tabela a partir do dicionário
#'
#' Usa o par (nome_na_fonte -> nome_canonico). É esta função que substitui o
#' vetor posicional de 451 nomes do legado, cujo defeito estrutural é que
#' names(x) <- v só falha quando o comprimento difere: se uma dimensão ganha uma
#' coluna e outra perde, o comprimento continua igual e todos os nomes deslizam
#' sem erro.
#'
#' @param x Data frame recém-lido da fonte.
#' @param tabela Identificador da tabela.
#' @param estrito Se TRUE, falha quando a tabela tiver colunas que o dicionário
#'   não conhece.
#' @return O data frame renomeado, com as colunas na ordem do dicionário.
mape_aplicar_renomeacao <- function(x, tabela, estrito = TRUE) {
  vars <- mape_variaveis_de(tabela)
  if (!nrow(vars)) {
    stop("Nenhuma variável registrada em dicionario/variaveis.csv para a ",
         "tabela '", tabela, "'. Registre-as antes de tratar a fonte.",
         call. = FALSE)
  }

  mapa <- stats::setNames(vars$nome_canonico, vars$nome_na_fonte)
  mapa <- mapa[!is.na(names(mapa)) & !is.na(mapa)]

  desconhecidas <- setdiff(names(x), c(names(mapa), unname(mapa)))
  if (length(desconhecidas)) {
    msg <- paste0(
      "Colunas presentes na fonte e ausentes do dicionário de '", tabela, "': ",
      paste(desconhecidas, collapse = ", "),
      "\nAcrescente-as a dicionario/variaveis.csv ou remova-as no script."
    )
    if (estrito) stop(msg, call. = FALSE) else warning(msg, call. = FALSE)
  }

  renomear <- intersect(names(x), names(mapa))
  names(x)[match(renomear, names(x))] <- unname(mapa[renomear])

  # Ordem canônica: as colunas conhecidas na ordem do dicionário, o resto ao fim.
  ordem <- c(intersect(vars$nome_canonico, names(x)),
             setdiff(names(x), vars$nome_canonico))
  x[, ordem, drop = FALSE]
}

#' Aplica ao data frame os tipos declarados no dicionário
#'
#' Necessária ao ler CSV, que não preserva tipo. O Parquet dispensa.
#'
#' @param x Data frame.
#' @param tabela Identificador da tabela.
#' @return O data frame tipado.
mape_aplicar_tipos <- function(x, tabela) {
  vars <- mape_variaveis_de(tabela)
  if (!nrow(vars)) return(x)

  for (i in seq_len(nrow(vars))) {
    nm <- vars$nome_canonico[i]
    tipo <- vars$tipo[i]
    if (is.na(nm) || is.na(tipo) || !nm %in% names(x)) next
    x[[nm]] <- switch(
      tipo,
      character = as.character(x[[nm]]),
      integer   = mape_como_inteiro(x[[nm]]),
      double    = suppressWarnings(as.numeric(x[[nm]])),
      logical   = as.logical(x[[nm]]),
      date      = as.Date(x[[nm]]),
      x[[nm]]
    )
  }
  x
}

#' Valida uma tabela contra o dicionário
#'
#' Confere presença das obrigatórias, tipo real contra tipo declarado, domínio
#' de valor, e a coerência entre o sufixo do nome e a escala observada. Essa
#' última checagem é o que torna o vocabulário de sufixos útil: dá para provar
#' que toda coluna terminada em _pct está entre 0 e 100.
#'
#' @param x Data frame.
#' @param tabela Identificador da tabela.
#' @param erro Se TRUE, falha ao encontrar problema bloqueante.
#' @return Invisivelmente, um data frame de problemas.
mape_validar_schema <- function(x, tabela, erro = TRUE) {
  vars <- mape_variaveis_de(tabela)
  if (!nrow(vars)) {
    stop("Sem entrada no dicionário para '", tabela, "'.", call. = FALSE)
  }
  problemas <- list()
  registrar <- function(gravidade, coluna, descricao) {
    problemas[[length(problemas) + 1]] <<- data.frame(
      tabela = tabela, gravidade = gravidade, coluna = coluna,
      descricao = descricao, stringsAsFactors = FALSE
    )
  }

  # Obrigatórias ausentes
  obrig <- vars$nome_canonico[!is.na(vars$obrigatoria) & vars$obrigatoria]
  for (nm in setdiff(obrig, names(x))) {
    registrar("erro", nm, "coluna obrigatória ausente")
  }

  for (i in seq_len(nrow(vars))) {
    nm <- vars$nome_canonico[i]
    if (is.na(nm) || !nm %in% names(x)) next
    v <- x[[nm]]

    # Tipo declarado contra tipo real
    esperado <- vars$tipo[i]
    if (!is.na(esperado)) {
      real <- mape_tipo_de(v)
      # integer declarado e double observado é aceito quando não há parte
      # fracionária: é como o Parquet costuma devolver contagens.
      compativel <- identical(real, esperado) ||
        (esperado == "integer" && real == "double" &&
           all(is.na(v) | v == round(v))) ||
        (esperado == "double" && real == "integer")
      if (!compativel) {
        registrar("erro", nm,
                  paste0("tipo declarado '", esperado, "', observado '", real, "'"))
      }
    }

    # Domínio de valor, no formato "[0,100]"
    dominio <- vars$dominio_valido[i]
    if (!is.na(dominio) && is.numeric(v)) {
      lim <- as.numeric(strsplit(gsub("[][ ]", "", dominio), ",")[[1]])
      if (length(lim) == 2) {
        fora <- sum(!is.na(v) & (v < lim[1] | v > lim[2]))
        if (fora > 0) {
          registrar("aviso", nm,
                    paste0(fora, " valor(es) fora do domínio ", dominio,
                           " (observado: ", signif(min(v, na.rm = TRUE), 5), " a ",
                           signif(max(v, na.rm = TRUE), 5), ")"))
        }
      }
    }

    # Coerência entre sufixo do nome e escala observada.
    #
    # A checagem distingue dois problemas que não são o mesmo:
    #
    #   ESCALA ERRADA é erro. Uma coluna _pct cujo máximo não passa de 1 é, na
    #   verdade, uma proporção com o sufixo trocado; uma cujo máximo passa de
    #   1.000 está noutra unidade. Nos dois casos o nome mente sobre o
    #   conteúdo, e é isso que o vocabulário de sufixos existe para impedir.
    #
    #   VALOR FORA DA FAIXA é aviso. Uma taxa de atualização cadastral que
    #   chega a 128% em 59 municípios de 2016 continua sendo um percentual: o
    #   numerador e o denominador foram medidos em momentos diferentes. O dado
    #   é publicável, desde que a limitação esteja registrada no campo
    #   observacoes da tabela — que é a regra de "aviso exige justificativa".
    if (is.numeric(v) && any(!is.na(v))) {
      faixa <- range(v, na.rm = TRUE)
      n_fora <- function(lo, hi) sum(!is.na(v) & (v < lo | v > hi))

      if (grepl("_pct$", nm)) {
        if (faixa[2] <= 1.0001 && faixa[1] >= 0) {
          registrar("erro", nm,
                    "sufixo _pct mas os valores não passam de 1: é proporção, use _prop")
        } else if (faixa[2] > 1000 || faixa[1] < -0.0001) {
          registrar("erro", nm,
                    paste0("sufixo _pct incompatível com a faixa observada (",
                           signif(faixa[1], 5), " a ", signif(faixa[2], 5), ")"))
        } else if (n_fora(0, 100) > 0 && is.na(vars$dominio_valido[i])) {
          # Só avisa se a coluna não declarar domínio próprio; quando declara,
          # a checagem de domínio acima já reportou, e repetir vira ruído.
          registrar("aviso", nm,
                    paste0(n_fora(0, 100), " valor(es) fora de [0,100], até ",
                           signif(faixa[2], 5),
                           ". Registre a justificativa em observacoes."))
        }
      }
      if (grepl("_prop$", nm)) {
        if (faixa[2] > 1.5) {
          registrar("erro", nm,
                    paste0("sufixo _prop mas o máximo é ", signif(faixa[2], 5),
                           ": provavelmente é percentual, use _pct"))
        } else if (n_fora(0, 1) > 0) {
          registrar("aviso", nm,
                    paste0(n_fora(0, 1), " valor(es) fora de [0,1]."))
        }
      }
      if (grepl("^flag_", nm) && !all(v %in% c(0, 1, NA))) {
        registrar("erro", nm, "prefixo flag_ exige valores 0, 1 ou NA")
      }
    }
  }

  res <- if (length(problemas)) do.call(rbind, problemas) else
    data.frame(tabela = character(), gravidade = character(),
               coluna = character(), descricao = character(),
               stringsAsFactors = FALSE)

  bloqueantes <- res[res$gravidade == "erro", , drop = FALSE]
  if (nrow(bloqueantes) && erro) {
    stop("Validação de schema falhou em '", tabela, "':\n",
         paste0("  - ", bloqueantes$coluna, ": ", bloqueantes$descricao,
                collapse = "\n"),
         call. = FALSE)
  }
  if (nrow(res) > nrow(bloqueantes)) {
    avisos <- res[res$gravidade == "aviso", , drop = FALSE]
    warning("Avisos em '", tabela, "':\n",
            paste0("  - ", avisos$coluna, ": ", avisos$descricao, collapse = "\n"),
            call. = FALSE)
  }
  invisible(res)
}

#' Nome do tipo de um vetor, no vocabulário fechado do dicionário
#'
#' @param v Vetor.
#' @return "character", "integer", "double", "logical", "date" ou "outro".
mape_tipo_de <- function(v) {
  if (inherits(v, "Date"))     return("date")
  if (is.logical(v))           return("logical")
  if (inherits(v, "integer64")) return("integer")
  if (is.integer(v))           return("integer")
  if (is.numeric(v))           return("double")
  if (is.character(v) || is.factor(v)) return("character")
  "outro"
}

#' Calcula os campos que o dicionário não deve ter digitados
#'
#' Tipo real, faixa observada, percentual de vazios e contagens saem do dado.
#' A separação entre campo digitado e campo calculado é o que impede o problema
#' que existe hoje, em que a soma das variáveis declaradas dá 533 contra 451
#' reais e o artigo declara 182.407 observações contra 180.285.
#'
#' @param x Data frame.
#' @param tabela Identificador da tabela.
#' @return Data frame com uma linha por coluna de x.
mape_campos_calculados <- function(x, tabela) {
  do.call(rbind, lapply(names(x), function(nm) {
    v <- x[[nm]]
    num <- is.numeric(v)
    data.frame(
      tabela      = tabela,
      nome_canonico = nm,
      tipo_real   = mape_tipo_de(v),
      pct_na      = round(100 * mean(is.na(v)), 4),
      n_distintos = length(unique(v[!is.na(v)])),
      minimo      = if (num && any(!is.na(v))) min(v, na.rm = TRUE) else NA_real_,
      maximo      = if (num && any(!is.na(v))) max(v, na.rm = TRUE) else NA_real_,
      stringsAsFactors = FALSE
    )
  }))
}
