# Deflação -------------------------------------------------------------------
#
# No legado, oito scripts chamam ipca() com a base "12/2023" escrita dentro do
# código e gravam o resultado POR CIMA da coluna original, com o mesmo nome. As
# três consequências se somam: o valor nominal não existe mais em lugar nenhum
# do repositório, atualizar a base de deflação mudaria retroativamente números
# já publicados, e nada registra que a operação aconteceu — a palavra IPCA
# sequer aparece no documento de metadados.
#
# A regra nova: o canônico é o nominal, a deflação cria coluna NOVA, e a base
# vive em config/parametros.yml.

#' Deflaciona colunas monetárias, criando colunas novas
#'
#' @param x Data frame.
#' @param cols Colunas a deflacionar. Devem terminar em `_brl_nominal`; o
#'   sufixo é trocado pelo de deflação no resultado.
#' @param data_ref Nome da coluna que dá a data de referência de cada valor, ou
#'   um vetor de datas. Aceita uma coluna de ano, que vira 31 de dezembro.
#'   Passar isto explicitamente é o que corrige o defeito da dimensão Corrupção,
#'   onde o deflator usa o ano da fiscalização quando deveria usar o ano do
#'   repasse — a coluna certa existe no bruto e é ignorada.
#' @param base Mês-base no formato "MM/AAAA". Se NULL, usa o parâmetro.
#' @param sufixo Sufixo das colunas criadas. Se NULL, usa o parâmetro.
#' @param indice Série de índices a usar, como data frame com as colunas `data`
#'   e `indice`. Se NULL, lê a cópia fixada em `config/ipca.csv`. Passar a série
#'   explicitamente é o que torna a função testável sem rede.
#' @return O data frame com as colunas deflacionadas acrescentadas.
mape_deflacionar <- function(x, cols, data_ref = "ano", base = NULL,
                             sufixo = NULL, indice = NULL) {
  stopifnot(is.data.frame(x))
  if (is.null(base))   base   <- mape_param("deflator_base")
  if (is.null(sufixo)) sufixo <- mape_param("deflator_sufixo")

  faltando <- setdiff(cols, names(x))
  if (length(faltando)) {
    stop("Colunas a deflacionar ausentes: ", paste(faltando, collapse = ", "),
         call. = FALSE)
  }

  # Data de referência: uma coluna de ano vira 31/12 daquele ano, que é a
  # convenção que o legado usa.
  if (is.character(data_ref) && length(data_ref) == 1 && data_ref %in% names(x)) {
    v <- x[[data_ref]]
    datas <- if (inherits(v, "Date")) v else
      as.Date(paste0(mape_como_inteiro(v), "-12-31"))
  } else {
    datas <- as.Date(data_ref)
  }
  if (all(is.na(datas))) {
    stop("Todas as datas de referência são nulas; não dá para deflacionar.",
         call. = FALSE)
  }

  # Achado 37: aqui o deflator era `deflateBR::ipca()`, chamado DENTRO do laço.
  # Cada coluna disparava um download novo da API do IPEA, o resultado não era
  # reprodutível (a série é revisada), nada registrava qual série foi usada, e a
  # função dependia de rede para rodar.
  #
  # Agora a série é lida uma vez, de uma cópia fixada e versionada, e o vetor de
  # fatores é calculado uma vez para todas as colunas.
  serie <- if (is.null(indice)) mape_serie_ipca() else indice
  fator <- mape_fator_deflacao(datas, base, serie)

  for (col in cols) {
    novo <- if (grepl("_brl_nominal$", col)) {
      sub("_brl_nominal$", paste0("_", sufixo), col)
    } else {
      paste0(col, "_", sufixo)
    }
    if (novo %in% names(x)) {
      warning("Coluna '", novo, "' já existe e será sobrescrita.", call. = FALSE)
    }
    x[[novo]] <- as.numeric(x[[col]]) * fator
  }
  attr(x, "mape_deflacao") <- list(base = base, sufixo = sufixo,
                                   colunas = cols, n_indice = nrow(serie))
  x
}

#' Lê a cópia fixada da série do IPCA
#'
#' Achado 37: a série vinha da API do IPEA a cada chamada. Uma série de índice de
#' preços é revisada, então o mesmo código rodando em dois dias podia devolver
#' números diferentes — e nada registrava qual série tinha sido usada. A cópia
#' fixada é o que torna a deflação reprodutível.
#'
#' Para atualizar a cópia, rode `tools/atualizar_ipca.R`, que registra a
#' proveniência.
#'
#' @return Data frame com `data` (Date, primeiro dia do mês) e `indice`.
mape_serie_ipca <- function() {
  caminho <- mape_caminho("config", "ipca.csv")
  if (!file.exists(caminho)) {
    stop("A série do IPCA não está fixada em config/ipca.csv.\n",
         "Rode: Rscript tools/atualizar_ipca.R\n",
         "A deflação NÃO busca a série na rede: ela seria irreprodutível e não ",
         "ficaria registrada (achado 37 da auditoria).", call. = FALSE)
  }
  s <- utils::read.csv(caminho, stringsAsFactors = FALSE)
  s$data <- as.Date(s$data)
  s[order(s$data), ]
}

#' Fator de deflação de cada data até o mês-base
#'
#' @param datas Vetor de datas.
#' @param base Mês-base "MM/AAAA".
#' @param serie Data frame com `data` e `indice`.
#' @return Vetor numérico de fatores.
mape_fator_deflacao <- function(datas, base, serie) {
  # A série é normalizada com o índice do mês-base igual a 100, e o mês-base
  # fica gravado no próprio arquivo. Recalculá-lo aqui a partir da string
  # "MM/AAAA" daria resultado diferente: deflateBR resolve "12/2023" um mês à
  # frente, e o fator de dezembro de 2023 vale 1,0056 e não 1,0000. Confiar no
  # arquivo é o que faz a cópia fixada reproduzir o pipeline antigo dígito a
  # dígito, em vez de "quase".
  if ("base" %in% names(serie) && !identical(serie$base[1], base)) {
    stop("A série fixada em config/ipca.csv foi gerada para a base '",
         serie$base[1], "' e a deflação pediu '", base, "'.\n",
         "Regenere com: Rscript tools/atualizar_ipca.R", call. = FALSE)
  }
  mes <- as.Date(format(datas, "%Y-%m-01"))
  i_ref <- serie$indice[match(mes, serie$data)]
  faltando <- sum(is.na(i_ref) & !is.na(mes))
  if (faltando) {
    warning(faltando, " data(s) fora da série do IPCA fixada (",
            format(min(serie$data)), " a ", format(max(serie$data)),
            "): o valor deflacionado sai NA.", call. = FALSE)
  }
  100 / i_ref
}

#' Marca colunas monetárias como nominais
#'
#' Conveniência para o script de fonte: renomeia as colunas acrescentando o
#' sufixo `_brl_nominal`, deixando explícito no nome que o valor é corrente.
#'
#' @param x Data frame.
#' @param cols Colunas monetárias.
#' @return O data frame com as colunas renomeadas.
mape_marcar_nominal <- function(x, cols) {
  for (col in intersect(cols, names(x))) {
    if (!grepl("_brl_nominal$", col)) {
      names(x)[names(x) == col] <- paste0(col, "_brl_nominal")
    }
  }
  x
}
