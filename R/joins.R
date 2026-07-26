# Junções com cardinalidade declarada ----------------------------------------
#
# A cadeia de dezesseis junções do legado não declara relationship em nenhuma
# delas, não tem um único stopifnot, e não conta linhas antes e depois. Quando
# uma junção multiplica a série inteira de um município — como acontece na
# dimensão histórica, que é juntada sem ano contra uma tabela com 54 chaves
# duplicadas —, o efeito só aparece 2.122 linhas depois, no distinct() final,
# que apaga a evidência.
#
# Aqui a cardinalidade é declarada antes e conferida depois.

#' Junta duas tabelas conferindo a cardinalidade
#'
#' @param x,y Data frames.
#' @param by Chave da junção, como em dplyr::left_join.
#' @param tipo "left", "full", "inner" ou "anti".
#' @param relationship Cardinalidade esperada: "one-to-one", "one-to-many",
#'   "many-to-one" ou "many-to-many". A última exige justificativa e emite
#'   aviso, porque é quase sempre um defeito disfarçado.
#' @param esperado_linhas Número de linhas esperado no resultado. Se informado
#'   e não bater, a função falha.
#' @param nome Rótulo da junção, usado nas mensagens.
#' @return O data frame juntado, com o atributo "mape_relatorio".
mape_join <- function(x, y, by, tipo = c("left", "full", "inner", "anti"),
                      relationship = "one-to-one",
                      esperado_linhas = NULL, nome = NULL) {
  tipo <- match.arg(tipo)
  stopifnot(is.data.frame(x), is.data.frame(y))
  rotulo <- if (is.null(nome)) paste0(tipo, "_join") else nome

  chaves_x <- if (is.null(names(by))) by else ifelse(names(by) == "", by, names(by))
  chaves_y <- unname(by)

  faltando_x <- setdiff(chaves_x, names(x))
  faltando_y <- setdiff(chaves_y, names(y))
  if (length(faltando_x) || length(faltando_y)) {
    stop("[", rotulo, "] chave ausente. Em x: ",
         paste(faltando_x, collapse = ", "), ". Em y: ",
         paste(faltando_y, collapse = ", "), ".", call. = FALSE)
  }

  # Tipos incompatíveis na chave produzem junção vazia sem erro. É a causa mais
  # comum de defeito silencioso no legado, onde ano alterna entre character,
  # numeric, integer e integer64 conforme a dimensão.
  for (i in seq_along(chaves_x)) {
    tx <- mape_tipo_de(x[[chaves_x[i]]])
    ty <- mape_tipo_de(y[[chaves_y[i]]])
    if (tx != ty) {
      stop("[", rotulo, "] tipo incompatível na chave '", chaves_x[i],
           "': x é ", tx, " e y é ", ty,
           ".\nNormalize com mape_normalizar_chaves() antes de juntar.",
           call. = FALSE)
    }
  }

  # Chave nula casa com chave nula por padrão no dplyr, o que funde linhas de
  # origens diferentes. No legado é assim que uma linha sem município da
  # população se encontra com uma do RH.
  na_x <- sum(!stats::complete.cases(x[, chaves_x, drop = FALSE]))
  na_y <- sum(!stats::complete.cases(y[, chaves_y, drop = FALSE]))
  if (na_x || na_y) {
    warning("[", rotulo, "] chave nula em ", na_x, " linha(s) de x e ", na_y,
            " de y. Elas vão casar entre si. Elimine na origem.", call. = FALSE)
  }

  n_x <- nrow(x); n_y <- nrow(y)
  fn <- switch(tipo,
               left  = dplyr::left_join,
               full  = dplyr::full_join,
               inner = dplyr::inner_join,
               anti  = dplyr::anti_join)

  res <- if (tipo == "anti") {
    fn(x, y, by = by)
  } else {
    fn(x, y, by = by, relationship = relationship, na_matches = "never")
  }

  # Órfãos dos dois lados, contados e não descartados.
  orfaos_x <- nrow(dplyr::anti_join(x, y, by = by))
  orfaos_y <- nrow(dplyr::anti_join(y, x, by = stats::setNames(chaves_x, chaves_y)))

  relatorio <- list(
    nome = rotulo, tipo = tipo, by = by, relationship = relationship,
    linhas_x = n_x, linhas_y = n_y, linhas_resultado = nrow(res),
    orfaos_x = orfaos_x, orfaos_y = orfaos_y,
    chave_na_x = na_x, chave_na_y = na_y
  )

  if (!is.null(esperado_linhas) && nrow(res) != esperado_linhas) {
    stop("[", rotulo, "] esperava ", esperado_linhas, " linha(s) e obtive ",
         nrow(res), ". x tinha ", n_x, ", y tinha ", n_y, ".", call. = FALSE)
  }
  if (tipo == "left" && nrow(res) > n_x) {
    stop("[", rotulo, "] o left_join multiplicou linhas: ", n_x, " -> ",
         nrow(res), ". A chave não é única em y.", call. = FALSE)
  }

  message(sprintf("[%s] %s: %d x %d -> %d linhas (órfãos: %d em x, %d em y)",
                  rotulo, tipo, n_x, n_y, nrow(res), orfaos_x, orfaos_y))

  attr(res, "mape_relatorio") <- relatorio
  res
}

#' Confere se uma chave é única
#'
#' Usa o vocabulário do plano: chaves duplicadas é o número de valores de chave
#' que aparecem mais de uma vez; linhas excedentes é quantas linhas seriam
#' removidas por uma deduplicação. São números diferentes e o legado os confunde.
#'
#' @param x Data frame.
#' @param chaves Vetor de nomes de coluna.
#' @param erro Se TRUE, falha quando houver duplicata.
#' @return Invisivelmente, uma lista com o diagnóstico.
mape_validar_chave <- function(x, chaves = c("id_municipio", "ano"), erro = TRUE) {
  faltando <- setdiff(chaves, names(x))
  if (length(faltando)) {
    stop("Chave ausente: ", paste(faltando, collapse = ", "), call. = FALSE)
  }

  k <- do.call(paste, c(x[, chaves, drop = FALSE], sep = "\r"))
  dup <- duplicated(k)
  n_chaves_dup <- length(unique(k[dup]))
  n_linhas_exc <- sum(dup)
  n_na <- sum(!stats::complete.cases(x[, chaves, drop = FALSE]))

  diag <- list(chaves = chaves, n_linhas = nrow(x),
               n_chaves_duplicadas = n_chaves_dup,
               n_linhas_excedentes = n_linhas_exc,
               n_chave_na = n_na)

  if (n_na > 0) {
    msg <- paste0(n_na, " linha(s) com chave nula em (",
                  paste(chaves, collapse = ", "), ").")
    if (erro) stop(msg, call. = FALSE) else warning(msg, call. = FALSE)
  }
  if (n_chaves_dup > 0) {
    exemplos <- utils::head(unique(k[dup]), 3)
    msg <- paste0(n_chaves_dup, " chave(s) duplicada(s) e ", n_linhas_exc,
                  " linha(s) excedente(s). Exemplos: ",
                  paste(gsub("\r", " / ", exemplos), collapse = "; "))
    if (erro) stop(msg, call. = FALSE) else warning(msg, call. = FALSE)
  }
  invisible(diag)
}
