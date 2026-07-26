# Normalização e validação das chaves ----------------------------------------
#
# O contrato é: id_municipio é texto de 7 dígitos, ano é inteiro. Estas funções
# são aplicadas na SAÍDA de cada fonte, não na entrada de cada junção — a
# diferença entre uma regra e as doze coerções as.character(ano) espalhadas
# pelo arquivo de junção do legado.

#' Converte um vetor para inteiro de forma segura
#'
#' O motivo desta função existir é o integer64. O pacote bit64 registra uma
#' classe cujo armazenamento interno é um double reinterpretado; chamar
#' as.numeric() sobre ele devolve lixo silenciosamente. No legado,
#' as.numeric(ano) sobre populacao.RData devolve 9.83e-321, e sort() sobre a
#' coluna ano de instituicoes.RData devolve resultado absurdo sem erro.
#'
#' @param x Vetor a converter.
#' @return Vetor de inteiros.
mape_como_inteiro <- function(x) {
  if (inherits(x, "integer64")) {
    # bit64::as.integer.integer64 faz a leitura correta dos bits. Se o pacote
    # não estiver carregado, passar por character é o caminho seguro.
    if (requireNamespace("bit64", quietly = TRUE)) {
      return(as.integer(bit64::as.character.integer64(x)))
    }
    return(as.integer(as.character(x)))
  }
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) {
    x <- trimws(x)
    x[x == ""] <- NA_character_
  }
  suppressWarnings(as.integer(x))
}

#' Converte um código de município para texto com zeros à esquerda
#'
#' Aceita numérico, inteiro, integer64, fator ou texto. Preserva NA. Um código
#' que, depois de limpo, não tiver exatamente o número de dígitos esperado é
#' devolvido como NA e contabilizado no aviso — devolver um código truncado
#' seria pior que devolver nada.
#'
#' @param x Vetor de códigos.
#' @param digitos Número de dígitos esperado (7 para id_municipio, 6 para o
#'   código sem dígito verificador).
#' @param avisar Se TRUE, emite aviso quando algum valor não puder ser
#'   convertido.
#' @return Vetor de texto.
mape_como_codigo <- function(x, digitos = 7L, avisar = TRUE) {
  if (inherits(x, "integer64")) x <- as.character(x)
  if (is.factor(x)) x <- as.character(x)
  if (is.numeric(x)) {
    # format() com scipen alto evita que 1.1e+06 vire "1.1e+06".
    x <- withr::with_options(
      list(scipen = 999),
      ifelse(is.na(x), NA_character_, format(x, trim = TRUE, scientific = FALSE))
    )
  }
  x <- trimws(as.character(x))
  # Remove separadores de milhar que aparecem em fontes lidas de planilha: o
  # MCMV traz o código como "110.020".
  x <- gsub("[.,[:space:]]", "", x)
  x[x %in% c("", "NA", "NULL")] <- NA_character_

  # Zeros à esquerda para códigos que perderam o primeiro dígito ao passar por
  # numérico em algum ponto da cadeia.
  #
  # O preenchimento é feito à mão de propósito: formatC(..., flag = "0") sobre
  # um vetor de TEXTO preenche com espaço, não com zero, e o código sairia daqui
  # com um espaço à esquerda para ser rejeitado como inválido logo abaixo.
  curto <- !is.na(x) & nchar(x) < digitos
  x[curto] <- paste0(strrep("0", digitos - nchar(x[curto])), x[curto])

  invalido <- !is.na(x) & (nchar(x) != digitos | grepl("\\D", x))
  if (any(invalido)) {
    if (avisar) {
      exemplos <- utils::head(unique(x[invalido]), 5)
      warning(
        sum(invalido), " código(s) de município não têm ", digitos,
        " dígitos e viraram NA. Exemplos: ",
        paste(exemplos, collapse = ", "),
        call. = FALSE
      )
    }
    x[invalido] <- NA_character_
  }
  x
}

#' Normaliza as chaves de uma tabela
#'
#' Aplica o contrato de tipos e reordena as colunas de chave para o começo.
#' Deve ser a última coisa que um script de fonte faz antes de gravar.
#'
#' @param x Data frame.
#' @param id Nome da coluna de código do município, ou NULL para pular.
#' @param ano Nome da coluna de ano, ou NULL para pular.
#' @param digitos Dígitos esperados no código.
#' @return O data frame com as chaves normalizadas e à esquerda.
mape_normalizar_chaves <- function(x, id = "id_municipio", ano = "ano",
                                   digitos = 7L) {
  stopifnot(is.data.frame(x))

  if (!is.null(id)) {
    if (!id %in% names(x)) {
      stop("Coluna de chave '", id, "' não existe na tabela. Colunas: ",
           paste(utils::head(names(x), 20), collapse = ", "), call. = FALSE)
    }
    x[[id]] <- mape_como_codigo(x[[id]], digitos = digitos)
  }

  if (!is.null(ano)) {
    if (!ano %in% names(x)) {
      stop("Coluna de ano '", ano, "' não existe na tabela. Colunas: ",
           paste(utils::head(names(x), 20), collapse = ", "), call. = FALSE)
    }
    x[[ano]] <- mape_como_inteiro(x[[ano]])
  }

  chaves <- c(id, ano)
  chaves <- chaves[!is.null(chaves) & chaves %in% names(x)]
  x[, c(chaves, setdiff(names(x), chaves)), drop = FALSE]
}

#' Recupera o código de 7 dígitos a partir do de 6
#'
#' Várias fontes (CadÚnico, TSE, dados históricos, MCMV) trazem o código IBGE
#' sem o dígito verificador. O padrão é juntar com o diretório por
#' id_municipio_6. A diferença em relação ao legado é que os não-casados são
#' REPORTADOS, e não convertidos em NA em silêncio.
#'
#' @param x Data frame com a coluna de código de 6 dígitos.
#' @param col Nome dessa coluna.
#' @param diretorio Data frame com id_municipio e id_municipio_6. Se NULL, lê a
#'   tabela publicada do diretório.
#' @param remover Se TRUE, descarta a coluna de 6 dígitos depois de casar.
#' @return O data frame com id_municipio, mais o atributo "mape_orfaos".
mape_id7_de_id6 <- function(x, col = "id_municipio_6", diretorio = NULL,
                            remover = TRUE) {
  stopifnot(is.data.frame(x), col %in% names(x))

  if (is.null(diretorio)) diretorio <- mape_ler_tabela("00_diretorios/municipios")
  stopifnot(all(c("id_municipio", "id_municipio_6") %in% names(diretorio)))

  x[[col]] <- mape_como_codigo(x[[col]], digitos = 6L, avisar = FALSE)
  de_para <- unique(diretorio[, c("id_municipio", "id_municipio_6")])
  de_para$id_municipio_6 <- mape_como_codigo(de_para$id_municipio_6, 6L, FALSE)

  antes <- nrow(x)
  x$id_municipio <- de_para$id_municipio[match(x[[col]], de_para$id_municipio_6)]

  orfaos <- unique(x[[col]][is.na(x$id_municipio) & !is.na(x[[col]])])
  if (length(orfaos)) {
    warning(
      length(orfaos), " código(s) de 6 dígitos não existem no diretório e ",
      "ficaram sem id_municipio. Exemplos: ",
      paste(utils::head(orfaos, 5), collapse = ", "),
      call. = FALSE
    )
  }
  stopifnot(nrow(x) == antes)  # o match nunca deve multiplicar linhas

  if (remover) x[[col]] <- NULL
  x <- x[, c("id_municipio", setdiff(names(x), "id_municipio")), drop = FALSE]
  attr(x, "mape_orfaos") <- orfaos
  x
}

#' Valida o domínio da chave contra o diretório de municípios
#'
#' Faz o anti-join que o legado nunca fez. Os códigos que não existem no
#' diretório são REPORTADOS, e não descartados: é assim que os 27 códigos de UF
#' escondidos na Segurança e os 27 muncode extintos da dimensão histórica
#' deixam de sumir em silêncio.
#'
#' @param x Data frame a validar.
#' @param col Coluna de código do município.
#' @param diretorio Diretório de municípios; se NULL, lê o publicado.
#' @param erro_se_exceder Se TRUE, falha quando a proporção de órfãos passar do
#'   limiar de qa.max_prop_chave_orfa.
#' @return Uma lista com o diagnóstico, invisível.
mape_validar_dominio_chave <- function(x, col = "id_municipio",
                                       diretorio = NULL,
                                       erro_se_exceder = FALSE) {
  stopifnot(is.data.frame(x), col %in% names(x))
  if (is.null(diretorio)) diretorio <- mape_ler_tabela("00_diretorios/municipios")

  codigos <- x[[col]]
  validos <- diretorio$id_municipio

  n_na     <- sum(is.na(codigos))
  orfaos   <- setdiff(unique(codigos[!is.na(codigos)]), validos)
  n_linhas_orfas <- sum(codigos %in% orfaos)
  prop     <- if (nrow(x) > 0) n_linhas_orfas / nrow(x) else 0

  diag <- list(
    n_linhas          = nrow(x),
    n_chave_na        = n_na,
    codigos_orfaos    = orfaos,
    n_codigos_orfaos  = length(orfaos),
    n_linhas_orfas    = n_linhas_orfas,
    prop_linhas_orfas = prop,
    cobertura_municipios = length(intersect(unique(codigos), validos)) / length(validos)
  )

  if (n_na > 0) {
    warning(n_na, " linha(s) com ", col, " nulo. Elimine na origem antes de ",
            "qualquer deduplicação — ver plano/03-versionamento-qa.md, 11.4.",
            call. = FALSE)
  }
  if (length(orfaos)) {
    msg <- paste0(
      length(orfaos), " código(s) fora do diretório, em ", n_linhas_orfas,
      " linha(s) (", round(100 * prop, 3), "%). Exemplos: ",
      paste(utils::head(orfaos, 8), collapse = ", ")
    )
    if (erro_se_exceder && prop > mape_param("qa.max_prop_chave_orfa")) {
      stop(msg, call. = FALSE)
    }
    warning(msg, call. = FALSE)
  }
  invisible(diag)
}

#' Prepara a tabela para o join externo com o geobr
#'
#' Os consumidores fazem left_join(muni_sf, by = c("id_municipio" = "code_muni")).
#' Isso funciona hoje por coincidência: o CSV publicado entrega o código como
#' inteiro e o geobr também usa inteiro, mas o .RDa entrega texto. Em vez de
#' deixar o tipo ambíguo, a conversão fica explícita e documentada aqui.
#'
#' @param x Data frame com id_municipio como texto.
#' @param col Nome da coluna.
#' @return O data frame com a coluna como inteiro.
mape_para_geobr <- function(x, col = "id_municipio") {
  stopifnot(is.data.frame(x), col %in% names(x))
  x[[col]] <- as.integer(x[[col]])
  x
}
