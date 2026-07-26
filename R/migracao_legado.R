# Migração genérica a partir dos artefatos do legado -------------------------
#
# As dezessete dimensões passam pela mesma transformação, e escrever dezessete
# scripts quase idênticos seria repetir o erro que produziu o legado. O que
# muda entre elas cabe em argumentos.
#
# A entrada é sempre o artefato que já existe (`<dimensao>.RData`), e não uma
# extração fresca: é o princípio da seção 12.2 do plano, e é o que torna o
# teste de paridade conclusivo.
#
# O que a função faz, na ordem:
#
#   1. normaliza a caixa dos cabeçalhos
#   2. descarta o bloco territorial que a dimensão replica (no legado ele é
#      removido por índice numérico na etapa de junção, com três intervalos
#      diferentes: [,-c(3:28)], [,-c(13:38)] e [,-c(3:28)] de novo)
#   3. renomeia pelo dicionário, que é a especificação
#   4. normaliza as chaves para o contrato (texto de 7 dígitos, ano inteiro)
#   5. converte sentinelas em NA
#   6. valida a chave e publica

#' Migra uma dimensão a partir do artefato do legado
#'
#' @param dimensao Slug da dimensão.
#' @param arquivo Caminho do .RData, relativo à pasta de dimensões do legado.
#' @param chaves Chave primária.
#' @param descartar Colunas a descartar além do bloco territorial, tipicamente
#'   sobras de identificação que vazaram de uma fonte.
#' @param renomear Vetor nomeado com renomeações que o dicionário não cobre.
#' @param inteiras Colunas a forçar para inteiro.
#' @param publicar Se TRUE, grava a tabela.
#' @return A tabela tratada.
mape_migrar_do_legado <- function(dimensao, arquivo,
                                  chaves = c("id_municipio", "ano"),
                                  descartar = NULL, renomear = NULL,
                                  inteiras = NULL, publicar = TRUE) {
  caminho <- mape_caminho("mape_municipios", "1 Dimensões Individuais", arquivo)
  if (!file.exists(caminho)) stop("Artefato não encontrado: ", caminho, call. = FALSE)

  amb <- new.env()
  nome_obj <- load(caminho, envir = amb)
  x <- as.data.frame(get(nome_obj[1], envir = amb))
  message("legado: ", nrow(x), " linhas x ", ncol(x), " colunas")

  x <- janitor::clean_names(x)

  vars <- mape_dicionario("variaveis")
  # `clean_names` já passou tudo para minúsculo; o dicionário guarda o nome
  # como está na base publicada, que às vezes tem maiúscula.
  vars$chave_busca <- janitor::make_clean_names(vars$nome_legado)

  # -- 2. O bloco territorial ------------------------------------------------
  do_diretorio <- vars$chave_busca[vars$dimensao == "00_diretorios" &
                                     !is.na(vars$dimensao)]
  do_diretorio <- setdiff(do_diretorio, chaves)
  a_remover <- intersect(names(x), c(do_diretorio, descartar))
  if (length(a_remover)) {
    message("descartando ", length(a_remover), " coluna(s) do bloco territorial ",
            "ou de identificação duplicada: ",
            paste(utils::head(a_remover, 8), collapse = ", "),
            if (length(a_remover) > 8) " ..." else "")
    x <- x[, setdiff(names(x), a_remover), drop = FALSE]
  }

  # -- 3. Renomeação pelo dicionário ----------------------------------------
  desta <- vars[vars$dimensao == dimensao & !is.na(vars$dimensao), ]
  mapa <- stats::setNames(desta$nome_canonico, desta$chave_busca)
  mapa <- mapa[!is.na(names(mapa)) & !is.na(mapa) & names(mapa) != mapa]
  if (!is.null(renomear)) {
    mapa <- c(mapa, stats::setNames(unname(renomear), janitor::make_clean_names(names(renomear))))
  }
  alvo <- intersect(names(x), names(mapa))
  if (length(alvo)) {
    names(x)[match(alvo, names(x))] <- unname(mapa[alvo])
    message("renomeadas ", length(alvo), " coluna(s) pelo dicionário")
  }

  # Colunas que o dicionário não conhece ficam registradas, não descartadas em
  # silêncio: é essa a diferença em relação ao legado.
  conhecidas <- c(chaves, desta$nome_canonico, unname(mapa))
  orfas <- setdiff(names(x), conhecidas)
  if (length(orfas)) {
    warning("[", dimensao, "] ", length(orfas),
            " coluna(s) sem entrada no dicionário: ",
            paste(orfas, collapse = ", "), call. = FALSE)
  }

  # -- 4 e 5. Chaves e sentinelas -------------------------------------------
  x <- mape_tratar_sentinelas(x, converter_numerico = FALSE)
  x <- mape_normalizar_chaves(
    x,
    id  = if ("id_municipio" %in% chaves) "id_municipio" else NULL,
    ano = if ("ano" %in% chaves) "ano" else NULL
  )

  # Colunas que ficaram como texto por causa de coerção posicional no legado.
  # O caso testemunha é a Segurança, onde seguranca.R converte para numérico as
  # colunas 3 a 38 de um objeto que tem 68, deixando 27 colunas quantidade_*
  # como texto na base publicada.
  for (nm in intersect(inteiras, names(x))) x[[nm]] <- mape_como_inteiro(x[[nm]])

  recuperadas <- 0
  for (nm in setdiff(names(x), chaves)) {
    if (is.character(x[[nm]])) {
      tentativa <- suppressWarnings(as.numeric(gsub(",", ".", x[[nm]], fixed = TRUE)))
      if (all(is.na(tentativa) == is.na(x[[nm]])) && any(!is.na(tentativa))) {
        x[[nm]] <- tentativa
        recuperadas <- recuperadas + 1
      }
    }
  }
  if (recuperadas) {
    message("recuperado o tipo numérico de ", recuperadas,
            " coluna(s) que estavam como texto")
  }

  # -- 6. Validação e publicação --------------------------------------------
  chaves_reais <- intersect(chaves, names(x))
  n_na <- sum(!stats::complete.cases(x[, chaves_reais, drop = FALSE]))
  if (n_na > 0) {
    message("eliminando ", n_na, " linha(s) com chave nula (defeito de origem)")
    x <- x[stats::complete.cases(x[, chaves_reais, drop = FALSE]), ]
  }

  suppressWarnings(mape_validar_chave(x, chaves_reais, erro = FALSE))
  x <- x[do.call(order, x[, chaves_reais, drop = FALSE]), ]

  if (publicar) {
    mape_escrever_tabela(x, dimensao, validar = FALSE, camada = "dimensao")
    mape_sincronizar_tipos(x, dimensao)
  }
  x
}

#' Sincroniza o tipo declarado no dicionário com o tipo corrigido
#'
#' O dicionário foi semeado a partir da base publicada, que carrega defeitos de
#' tipo: 27 colunas quantidade_* da Segurança estão como texto porque
#' seguranca.R converte só as colunas 3 a 38 de um objeto que tem 68. Depois de
#' a migração recuperar o tipo numérico, o dicionário precisa passar a declarar
#' o tipo CORRETO — senão a validação acusaria divergência para sempre.
#'
#' A troca é registrada, para que a correção fique visível e não pareça que o
#' dicionário sempre esteve certo.
#'
#' @param x A tabela migrada.
#' @param dimensao Slug.
#' @return Invisivelmente, os nomes das colunas cujo tipo mudou.
mape_sincronizar_tipos <- function(x, dimensao) {
  caminho <- mape_caminho("dicionario", "variaveis.csv")
  vars <- utils::read.csv(caminho, stringsAsFactors = FALSE, encoding = "UTF-8")

  mudaram <- character()
  for (nm in names(x)) {
    j <- which(vars$nome_canonico == nm & vars$tabela == dimensao)
    # As chaves aparecem em todas as tabelas mas o dicionário só as registra
    # uma vez; sincroniza pelo nome quando a busca por tabela não encontrar.
    if (!length(j) && nm %in% c("id_municipio", "ano")) {
      j <- which(vars$nome_canonico == nm)
    }
    if (!length(j)) next
    observado <- mape_tipo_de(x[[nm]])
    declarado <- vars$tipo[j][1]
    if (!is.na(declarado) && declarado != observado) {
      # Só sincroniza quando a migração RECUPEROU um tipo: texto que virou
      # número. O caminho inverso indicaria perda, e deve falhar em vez de ser
      # silenciosamente aceito.
      if (declarado == "character" && observado %in% c("double", "integer")) {
        vars$tipo[j] <- observado
        vars$motivo_revisao[j] <- paste0(
          "tipo recuperado na migração: estava como texto na base publicada, ",
          "por coerção posicional incompleta na origem")
        mudaram <- c(mudaram, nm)
      }
    }
  }

  if (length(mudaram)) {
    utils::write.csv(vars, caminho, row.names = FALSE, fileEncoding = "UTF-8", na = "")
    .mape_cache_dic$dic_variaveis <- NULL
    message("tipo recuperado em ", length(mudaram), " coluna(s): ",
            paste(utils::head(mudaram, 5), collapse = ", "),
            if (length(mudaram) > 5) " ..." else "")
  }
  invisible(mudaram)
}

#' Registra uma dimensão migrada do legado no dicionário
#'
#' Atalho para as dimensões cuja tabela publicada corresponde a uma única
#' unidade no legado. As variáveis já estão no dicionário semeado; o que falta
#' é atribuí-las à tabela.
#'
#' @param dimensao Slug.
#' @param ... Campos passados a mape_registrar_tabela().
#' @return Invisivelmente, o número de variáveis atribuídas.
mape_registrar_dimensao_legado <- function(dimensao, ...) {
  vars <- mape_dicionario("variaveis")
  nomes <- vars$nome_legado[vars$dimensao == dimensao & !is.na(vars$dimensao)]
  mape_registrar_tabela(slug = dimensao, dimensao = dimensao, ...)
  mape_atribuir_variaveis(slug = dimensao, nomes_legado = nomes)
}
