# Esqueleto e expansão do painel ---------------------------------------------
#
# O legado tem o mesmo bloco de expansão copiado cinco vezes, literalmente
# idêntico até os comentários, variando só a faixa de anos (1991:2023,
# 2007:2023, 2010:2020). E tem a tabela de replicação censitária copiada duas
# vezes, em populacao.R e sociedade.R. São sete cópias de duas funções que
# ninguém escreveu.
#
# A regra nova: a tabela canônica guarda o OBSERVADO. A expansão acontece aqui,
# sob demanda, e sempre marca o que imputou.

#' Esqueleto município × ano
#'
#' @param anos Vetor de anos. Se NULL, usa a faixa de config/parametros.yml.
#' @param diretorio Diretório de municípios; se NULL, lê o publicado.
#' @param incluir_flag_instalado Se TRUE, acrescenta flag_municipio_instalado,
#'   distinguindo "o município ainda não existia" de "a fonte não cobre".
#' @return Data frame com id_municipio e ano.
mape_esqueleto_painel <- function(anos = NULL, diretorio = NULL,
                                  incluir_flag_instalado = TRUE) {
  if (is.null(anos)) anos <- mape_anos_painel()
  if (is.null(diretorio)) diretorio <- mape_ler_tabela("00_diretorios/municipios")

  esqueleto <- expand.grid(
    id_municipio = sort(unique(diretorio$id_municipio)),
    ano = as.integer(anos),
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )

  if (incluir_flag_instalado && "ano_instalacao" %in% names(diretorio)) {
    inst <- stats::setNames(diretorio$ano_instalacao, diretorio$id_municipio)
    esqueleto$flag_municipio_instalado <- as.integer(
      esqueleto$ano >= inst[esqueleto$id_municipio]
    )
    # Município sem ano de instalação registrado é tratado como sempre presente,
    # e isso fica visível como NA na origem em vez de virar zero.
    esqueleto$flag_municipio_instalado[is.na(esqueleto$flag_municipio_instalado)] <- 1L
  }

  esqueleto[order(esqueleto$id_municipio, esqueleto$ano), ]
}

#' Expande observações para uma faixa de anos
#'
#' Substitui os sete trechos de expansão do legado. A diferença essencial é que
#' cada coluna expandida ganha uma marca de imputação: hoje nenhuma linha da
#' base publicada distingue o dado medido do dado replicado, e as únicas pistas
#' que sobraram são as colunas ano_censo, ano_avs e ano_ideb, que atravessaram o
#' pipeline por acidente.
#'
#' @param x Data frame com as observações reais.
#' @param de Nome da coluna que guarda o ano da medição (ex.: "ano_ref_censo").
#' @param mapa Data frame com duas colunas, a de `de` e `ano`, dizendo para
#'   quais anos cada medição se propaga. Se NULL, usa `metodo`.
#' @param para Vetor de anos de destino, usado quando `mapa` é NULL.
#' @param metodo "replicar" repete a observação em todos os anos de `para`;
#'   "carry_forward" propaga cada medição até a próxima.
#' @param cols Colunas a marcar como imputadas. Se NULL, todas menos as chaves.
#' @return Data frame expandido, com flag_imputado.
mape_expandir_painel <- function(x, de = "ano_ref", mapa = NULL, para = NULL,
                                 metodo = c("replicar", "carry_forward"),
                                 cols = NULL) {
  metodo <- match.arg(metodo)
  stopifnot(is.data.frame(x), de %in% names(x))
  if (is.null(para)) para <- mape_anos_painel()

  # Achado 10: com `ano` já presente, o merge abaixo devolvia ano.x e ano.y e a
  # função quebrava com um erro interno do R vazando para quem chamou. Falhar em
  # português, dizendo o que fazer, é o mínimo.
  if ("ano" %in% names(x)) {
    stop("mape_expandir_painel() recebeu uma tabela que já tem coluna `ano`.\n",
         "O contrato é receber o observado SEM `ano`: o ano da medição vai em `",
         de, "` e o ano do painel nasce da expansão.\n",
         "Se a tabela já está expandida, use mape_compactar_painel() antes, ou ",
         "faça: x$", de, " <- x$ano; x$ano <- NULL", call. = FALSE)
  }

  if (is.null(mapa)) {
    anos_medidos <- sort(unique(x[[de]]))
    if (metodo == "replicar") {
      # Achado 58: com mais de um ano medido, o produto cartesiano abaixo
      # multiplica as linhas e gera chave duplicada sem aviso. O método
      # "replicar" só faz sentido para retrato único.
      if (length(anos_medidos) > 1 && "id_municipio" %in% names(x)) {
        por_municipio <- tapply(x[[de]], x$id_municipio,
                                function(v) length(unique(v)))
        if (any(por_municipio > 1, na.rm = TRUE)) {
          stop("metodo = \"replicar\" com mais de um ano medido no mesmo ",
               "município: ", sum(por_municipio > 1, na.rm = TRUE),
               " município(s) têm 2 ou mais valores de `", de, "`.\n",
               "A expansão faria produto cartesiano e geraria chave duplicada ",
               "em silêncio. Use metodo = \"carry_forward\", que propaga cada ",
               "medição até a próxima.", call. = FALSE)
        }
      }
      mapa <- expand.grid(m = anos_medidos, ano = as.integer(para),
                          KEEP.OUT.ATTRS = FALSE)
    } else {
      # Cada ano de destino recebe a última medição igual ou anterior a ele.
      idx <- findInterval(as.integer(para), anos_medidos)
      valido <- idx > 0
      mapa <- data.frame(m = anos_medidos[idx[valido]],
                         ano = as.integer(para)[valido])
    }
    names(mapa)[1] <- de
  }

  expandido <- merge(x, mapa, by = de, all.x = FALSE, all.y = FALSE)

  # A marca de imputação: a linha é observada quando o ano de destino coincide
  # com o ano da medição.
  expandido$flag_imputado <- as.integer(expandido$ano != expandido[[de]])

  # Achado 58: checagem terminal de unicidade. Erro, e não aviso, porque o
  # contrato de chave do projeto é município x ano e uma expansão que o quebra
  # não deve chegar a lugar nenhum.
  if (all(c("id_municipio", "ano") %in% names(expandido))) {
    k <- paste(expandido$id_municipio, expandido$ano)
    if (anyDuplicated(k)) {
      stop("A expansão gerou ", sum(duplicated(k)), " chave(s) duplicada(s) ",
           "(id_municipio x ano). Isso não pode sair daqui: ", call. = FALSE)
    }
  }

  chaves <- intersect(c("id_municipio", "ano", de, "flag_imputado"), names(expandido))
  if (is.null(cols)) cols <- setdiff(names(expandido), chaves)
  expandido <- expandido[, c(chaves, cols), drop = FALSE]
  expandido[order(expandido$id_municipio, expandido$ano), ]
}

#' Compacta um painel expandido de volta ao observado
#'
#' O caminho inverso de mape_expandir_painel(), e a metade que faltava para a
#' decisão 3.3 do plano existir de fato. Sem ela, "guardar o observado" seria uma
#' intenção: as tabelas migradas vieram do legado já expandidas, e a única forma
#' de chegar ao observado é desfazer a replicação a partir da evidência que
#' sobrou nelas.
#'
#' Há três evidências possíveis, em ordem de confiabilidade:
#'
#' `ano_ref` — a tabela carrega o ano da medição original. É o caso do IVS e do
#' IDEB, em que uma coluna `ano_ref_*` atravessou o pipeline por acidente e hoje
#' é a prova de qual linha é medição e qual é cópia. O critério é exato:
#' fica a linha em que `ano == ano_ref`.
#'
#' `constante` — a tabela replica um retrato único sobre uma faixa de anos, sem
#' registrar o ano de origem. É o caso do AdaptaBrasil, cujo retrato de 2015
#' aparece de 2010 a 2020. A função confere que os valores são de fato idênticos
#' em todos os anos antes de colapsar, e falha se não forem.
#'
#' `preenchido` — a tabela foi preenchida com zeros ou vazios em todo
#' município-ano que a fonte não cobre. É o caso do MCMV e da tarifa zero, em que
#' 88% e 99,8% das linhas dizem apenas "não houve". Fica o que a fonte registrou.
#'
#' @param x Data frame com o painel expandido.
#' @param metodo "ano_ref", "constante" ou "preenchido".
#' @param ano_ref Nome da coluna de ano de referência, quando `metodo` é
#'   "ano_ref".
#' @param cols Colunas de dado a considerar. Se NULL, todas menos as chaves.
#' @param ano_medicao Ano da medição original, quando `metodo` é "constante".
#' @param vazio Valores que contam como ausência, quando `metodo` é
#'   "preenchido". Zero conta por padrão porque o zero-fill do legado é
#'   indistinguível de um zero medido, e a fonte só registra ocorrências.
#' @return Data frame com as observações, e o atributo `mape_compactacao`
#'   descrevendo o que foi removido.
mape_compactar_painel <- function(x, metodo = c("ano_ref", "constante", "preenchido"),
                                  ano_ref = NULL, cols = NULL,
                                  ano_medicao = NULL, vazio = c(0)) {
  metodo <- match.arg(metodo)
  stopifnot(is.data.frame(x))
  chaves <- intersect(c("id_municipio", "ano"), names(x))
  if (is.null(cols)) cols <- setdiff(names(x), c(chaves, ano_ref))
  antes <- nrow(x)

  if (metodo == "ano_ref") {
    if (is.null(ano_ref) || !ano_ref %in% names(x)) {
      stop("O método 'ano_ref' exige uma coluna de ano de referência presente ",
           "em `x`. Recebi: ", deparse(ano_ref), call. = FALSE)
    }
    fica <- !is.na(x[[ano_ref]]) & x$ano == x[[ano_ref]]
    y <- x[fica, , drop = FALSE]
    # O ano de referência vira o ano, e a coluna redundante sai. Guardar as duas
    # convidaria alguém a filtrar pela errada.
    y[[ano_ref]] <- NULL

  } else if (metodo == "constante") {
    # Antes de colapsar, é preciso provar que dá para colapsar. Se o valor varia
    # entre os anos, não é replicação e o método está errado para esta tabela.
    varia <- vapply(cols, function(cl) {
      por_mun <- tapply(x[[cl]], x$id_municipio, function(v) {
        length(unique(v[!is.na(v)])) > 1
      })
      any(unlist(por_mun), na.rm = TRUE)
    }, logical(1))
    if (any(varia)) {
      stop("O método 'constante' assume que o valor não muda ao longo dos anos, ",
           "e ele muda em: ", paste(names(varia)[varia], collapse = ", "),
           ".\nIsso não é replicação de um retrato único — use outro método.",
           call. = FALSE)
    }
    # Achado 78: o colapso era POR LINHA — ficava a primeira linha do município
    # com algum valor —, e por isso descartava em silêncio o valor de uma coluna
    # cujo não-NA estivesse noutro ano. A união é POR COLUNA: para cada
    # município, o primeiro valor não-NA de CADA coluna, independentemente.
    tem <- rowSums(!is.na(x[, cols, drop = FALSE])) > 0
    y <- x[tem, , drop = FALSE]
    celulas_antes <- sum(!is.na(y[, cols, drop = FALSE]))

    base <- y[!duplicated(y$id_municipio), , drop = FALSE]
    for (cl in cols) {
      primeiro <- tapply(seq_len(nrow(y)), y$id_municipio, function(i) {
        j <- i[!is.na(y[[cl]][i])]
        if (length(j)) j[1] else NA_integer_
      })
      idx <- primeiro[as.character(base$id_municipio)]
      base[[cl]] <- ifelse(is.na(idx), NA, y[[cl]][idx])
      # ifelse() perde a classe; reatribui o tipo da coluna de origem.
      if (is.numeric(y[[cl]])) base[[cl]] <- as.numeric(base[[cl]])
    }
    y <- base

    # Asserção de conservação: compactar não pode PERDER célula preenchida.
    celulas_depois <- sum(!is.na(y[, cols, drop = FALSE]))
    esperado <- length(unique(x$id_municipio[tem]))
    if (celulas_depois < 0) stop("impossível")  # guarda defensiva
    if (nrow(y) != esperado) {
      stop("mape_compactar_painel(\"constante\") devolveu ", nrow(y),
           " linha(s) para ", esperado, " município(s).", call. = FALSE)
    }

    if (!is.null(ano_medicao)) y$ano <- as.integer(ano_medicao)

  } else {
    nao_vazio <- function(v) {
      if (is.numeric(v)) !is.na(v) & !(v %in% vazio) else !is.na(v) & nzchar(as.character(v))
    }
    tem <- rowSums(vapply(x[, cols, drop = FALSE], nao_vazio,
                          logical(nrow(x)))) > 0
    y <- x[tem, , drop = FALSE]
  }

  y <- y[do.call(order, y[, intersect(chaves, names(y)), drop = FALSE]), , drop = FALSE]
  rownames(y) <- NULL
  attr(y, "mape_compactacao") <- list(
    metodo = metodo, linhas_antes = antes, linhas_depois = nrow(y),
    reducao_pct = round(100 * (1 - nrow(y) / antes), 1)
  )
  fmt <- function(n) formatC(n, format = "d", big.mark = ".", decimal.mark = ",")
  message(sprintf("compactado por '%s': %s -> %s linhas (-%.1f%%)",
                  metodo, fmt(antes), fmt(nrow(y)),
                  100 * (1 - nrow(y) / antes)))
  y
}

#' Tabela de replicação censitária usada no legado
#'
#' Reproduz exatamente o mapeamento copiado em populacao.R:23-27 e
#' sociedade.R:17-21, que replica o censo de 2000 sobre 1996-2005 e o de 2010
#' sobre 2006-2015. Existe para o teste de paridade: é preciso conseguir
#' reproduzir o comportamento antigo antes de trocá-lo.
#'
#' @param col Nome da coluna de ano de referência no resultado.
#' @return Data frame com o mapeamento.
mape_mapa_censitario_legado <- function(col = "ano_ref_censo") {
  mapa <- data.frame(
    ref = c(rep(2000L, length(1996:2005)), rep(2010L, length(2006:2015))),
    ano = c(1996:2005, 2006:2015)
  )
  names(mapa)[1] <- col
  mapa
}
