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
#' Pedir uma dimensão devolve as variáveis dela e as de todas as suas fontes,
#' porque a dimensão é a união das fontes. Sem isso, fatiar uma fonte para fora
#' de uma dimensão esvaziaria a validação da dimensão em silêncio: as variáveis
#' continuariam no dicionário, mas com outro `tabela`, e a busca exata não as
#' encontraria mais.
#'
#' @param tabela Identificador da tabela. `"09_educacao"` traz também
#'   `"09_educacao/ideb"`; `"09_educacao/ideb"` traz só ela.
#' @param incluir_fontes Se FALSE, casa apenas o slug exato.
#' @return Data frame com as variáveis daquela tabela.
mape_variaveis_de <- function(tabela, incluir_fontes = TRUE) {
  dic <- mape_dicionario("variaveis")
  tem <- !is.na(dic$tabela)
  casa <- if (incluir_fontes && !grepl("/", tabela)) {
    tem & (dic$tabela == tabela | startsWith(dic$tabela, paste0(tabela, "/")))
  } else {
    tem & dic$tabela == tabela
  }
  dic[casa, , drop = FALSE]
}

#' Slugs das tabelas de fonte de uma dimensão
#'
#' @param dimensao Slug da dimensão.
#' @param apenas_publicadas Se TRUE, devolve só as que têm arquivo em disco.
#' @return Vetor de slugs, possivelmente vazio.
mape_fontes_de <- function(dimensao, apenas_publicadas = TRUE) {
  tabs <- mape_dicionario("tabelas")
  fontes <- tabs$slug_tabela[!is.na(tabs$dimensao) & tabs$dimensao == dimensao &
                               grepl("/", tabs$slug_tabela)]
  if (apenas_publicadas && length(fontes)) {
    fontes <- fontes[vapply(fontes, function(s) {
      file.exists(mape_caminho_tabela(s, "parquet", camada = "fonte"))
    }, logical(1))]
  }
  sort(fontes)
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

#' Recalcula os campos que são fato sobre o arquivo, não intenção de quem
#' escreve
#'
#' A seção 7.2 do plano separa campo **digitado** de campo **calculado**, e a
#' razão é empírica: é exatamente nos que deveriam ser calculados que os números
#' da documentação atual não fecham. A soma do campo `Total Variáveis` dá 533
#' contra 451 reais, e o artigo declara 182.407 observações contra 180.285 — esse
#' segundo número é a contagem antes da deduplicação, o que mostra que alguém
#' contou na etapa errada e nunca mais reconferiu.
#'
#' Nenhum dos dois é descuido. São o resultado inevitável de um número que
#' precisa ser reescrito à mão toda vez que o dado muda. Esta função elimina a
#' classe inteira de erro: os campos que ela preenche não são editáveis, porque
#' são medidos a cada execução.
#'
#' @param tabelas Slugs a medir. NULL usa todas as publicadas.
#' @param gravar Se TRUE, reescreve dicionario/variaveis.csv.
#' @return Invisivelmente, o data frame de variáveis atualizado.
mape_recalcular_campos <- function(tabelas = NULL, gravar = TRUE) {
  vars <- mape_dicionario("variaveis", .recarregar = TRUE)
  pub <- mape_tabelas_publicadas()
  if (is.null(tabelas)) tabelas <- pub$slug

  # pct_zero e janela_efetiva são campos calculados NOVOS, pedidos pelos achados
  # 4 e 21. O pct_na sozinho mentia: ele dizia que
  # siconfi_receitas_realizadas_brl2023 estava 99,74% completa, e ela é 97% zero
  # — zero que significa "não medido". Um campo mede ausência declarada; o outro,
  # ausência disfarçada de valor.
  calculados <- c("tipo_real", "pct_na", "pct_zero", "n_distintos", "minimo",
                  "maximo", "n_infinito", "janela_efetiva")
  for (cl in calculados) if (!cl %in% names(vars)) vars[[cl]] <- NA

  n_tocadas <- 0
  nao_medidas <- character()
  for (t in tabelas) {
    camada <- pub$camada[match(t, pub$slug)]
    if (is.na(camada)) next
    x <- mape_ler_tabela(t, camada = camada)

    for (nm in names(x)) {
      j <- which(vars$nome_canonico == nm & !is.na(vars$tabela) &
                   (vars$tabela == t | startsWith(t, paste0(vars$tabela, "/"))))
      # Uma variável pode aparecer na fonte e na dimensão que a contém. Medir
      # na fonte é o certo: é lá que ela é observada.
      #
      # Achado 36: aqui havia um fallback — se o casamento por (nome, tabela)
      # não achasse exatamente uma linha, o código caía para o casamento só por
      # nome e escrevia na PRIMEIRA linha encontrada, que é a de outra tabela.
      # Era assim que os campos calculados de `id_municipio` e `ano` acabavam
      # descrevendo 16_eleicoes: as duas colunas existem em quase toda tabela, e
      # a primeira linha do dicionário ganhava a medição de todas elas.
      #
      # Adivinhar a linha é pior que não medir. Agora pula, e registra.
      if (length(j) != 1) {
        if (length(j) > 1) {
          nao_medidas <- c(nao_medidas, paste0(t, "/", nm, " (", length(j),
                                                " linhas no dicionário)"))
        } else if (any(vars$nome_canonico == nm)) {
          nao_medidas <- c(nao_medidas, paste0(t, "/", nm,
                                                " (a linha existe, mas declara outra tabela)"))
        }
        next
      }
      v <- x[[nm]]
      vars$tipo_real[j] <- class(v)[1]
      vars$pct_na[j] <- round(100 * mean(is.na(v)), 4)
      vars$n_distintos[j] <- length(unique(v[!is.na(v)]))

      # Achado 4: pct_zero e janela_efetiva. O pct_na dizia que
      # siconfi_receitas_realizadas_brl2023 estava 99,74% completa; ela é 97%
      # zero, e o zero ali significa "não medido". Sem estas duas colunas, a
      # especificação afirmava completude onde havia buraco.
      if ("pct_zero" %in% names(vars)) {
        vars$pct_zero[j] <- if (is.numeric(v) && any(!is.na(v))) {
          round(100 * mean(v == 0, na.rm = TRUE), 4)
        } else NA_real_
      }
      if ("janela_efetiva" %in% names(vars) && "ano" %in% names(x)) {
        # Os anos em que a coluna tem ao menos um valor não nulo e não zero.
        informativo <- !is.na(v) & (!is.numeric(v) | v != 0)
        anos_com_dado <- sort(unique(suppressWarnings(
          as.integer(as.character(x$ano[informativo])))))
        anos_com_dado <- anos_com_dado[!is.na(anos_com_dado)]
        vars$janela_efetiva[j] <- if (length(anos_com_dado)) {
          paste0(min(anos_com_dado), "-", max(anos_com_dado))
        } else NA_character_
      }

      if (is.numeric(v) && any(!is.na(v))) {
        finito <- v[is.finite(v)]
        # Achado 35: min()/max() sobre integer64 devolvem o PADRÃO DE BITS, não
        # o valor — foi assim que o dicionário passou a declarar
        # minimo = 2,61e-317 para o PIB municipal. bit64 guarda um inteiro de 64
        # bits dentro de um double, e reduzir sem converter reinterpreta os bits
        # como ponto flutuante. A conversão por character é a que não perde
        # dígito no caminho.
        como_numero <- function(z) {
          if (inherits(z, "integer64")) as.numeric(as.character(z)) else as.numeric(z)
        }
        vars$minimo[j] <- if (length(finito)) min(como_numero(finito)) else NA_real_
        vars$maximo[j] <- if (length(finito)) max(como_numero(finito)) else NA_real_
        vars$n_infinito[j] <- sum(is.infinite(v))
      } else {
        vars$minimo[j] <- NA_real_
        vars$maximo[j] <- NA_real_
        vars$n_infinito[j] <- 0L
      }
      n_tocadas <- n_tocadas + 1
    }
  }

  if (length(nao_medidas)) {
    warning("Campos calculados NÃO atualizados em ", length(nao_medidas),
            " coluna(s), porque a linha do dicionário é ambígua:\n  ",
            paste(utils::head(nao_medidas, 12), collapse = "\n  "),
            if (length(nao_medidas) > 12) "\n  ..." else "",
            "\nCada coluna publicada precisa de exatamente uma linha que declare ",
            "a tabela dela.", call. = FALSE)
  }

  if (gravar) {
    utils::write.csv(vars, mape_caminho("dicionario", "variaveis.csv"),
                     row.names = FALSE, fileEncoding = "UTF-8", na = "")
    .mape_cache_dic$dic_variaveis <- NULL
  }
  message("campos calculados atualizados em ", n_tocadas, " variável(is) de ",
          length(tabelas), " tabela(s)")
  invisible(vars)
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
        } else if ((faixa[2] > 1000 || faixa[1] < -0.0001) &&
                   is.na(vars$dominio_valido[i])) {
          # Só é erro quando a coluna NÃO declara domínio. Se o dicionário
          # declara [0,100] e o dado chega a 51.175, isso é um defeito conhecido
          # da fonte, já reportado pela checagem de domínio — a cobertura do
          # SI-PNI não é truncada e o denominador da população-alvo é
          # subestimado. O dicionário é a especificação, e uma declaração
          # explícita é uma afirmação deliberada de quem a escreveu.
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
      # _razao é para quocientes cujo valor pode legitimamente passar de 1,
      # como a densidade de um município em relação à da capital. Usar _prop
      # nesses casos seria mentir sobre o domínio.
      if (grepl("_razao$", nm) && faixa[1] < 0) {
        registrar("aviso", nm, "razão com valor negativo")
      }

      # Achado 73: a prova prometida pelo vocabulário fechado existia para 4 dos
      # 15 tokens. Contagem, taxa por população e distância física não podem ser
      # negativas — é a asserção mais barata do conjunto e faltava inteira.
      if (grepl("(_i|_p100k|_p1k|_p100dom|_km|_km2)$", nm) && faixa[1] < 0) {
        registrar("erro", nm,
                  paste0("sufixo de contagem/taxa/distância exige valor não ",
                         "negativo, e o mínimo observado é ", signif(faixa[1], 5)))
      }

      # Achado 19: sete colunas de dinheiro declaradas `integer` estouram o
      # int32, e 23.761 células viravam NA em silêncio no caminho do csv.gz,
      # porque mape_como_inteiro() tem suppressWarnings. A checagem confronta a
      # magnitude observada com o limite do tipo declarado.
      if (!is.na(esperado) && esperado == "integer" &&
          max(abs(faixa), na.rm = TRUE) > .Machine$integer.max) {
        registrar("erro", nm,
                  paste0("declarada `integer` mas o máximo observado é ",
                         format(faixa[2], scientific = FALSE),
                         ", acima do teto do int32 (",
                         format(.Machine$integer.max, scientific = FALSE),
                         "): a releitura do csv.gz devolve NA em silêncio"))
      }
    }

    # Achado 80: as checagens de vocabulário estavam TODAS dentro do bloco
    # is.numeric(), então uma flag_ lógica ou textual escapava inteira, e um
    # sufixo numérico em coluna de texto passava sem nenhum registro.
    if (grepl("^flag_", nm)) {
      admissiveis <- if (is.logical(v)) c(TRUE, FALSE, NA) else c(0, 1, NA, "0", "1")
      if (!all(v %in% admissiveis)) {
        registrar("erro", nm,
                  paste0("prefixo flag_ exige 0/1 (ou TRUE/FALSE) e NA; ",
                         "observados: ",
                         paste(utils::head(setdiff(unique(as.character(v)),
                                                   as.character(admissiveis)), 5),
                               collapse = ", ")))
      }
    }
    if (grepl("(_pct|_prop|_razao|_p100k|_p1k|_p100dom|_km|_km2|_idx)$", nm) &&
        !is.numeric(v) && !all(is.na(v))) {
      registrar("erro", nm,
                paste0("sufixo numérico em coluna de tipo '", class(v)[1], "'"))
    }

    # Achado 56: 27 variáveis publicadas não têm descrição nenhuma. O dicionário
    # é a especificação; uma linha sem descrição não especifica nada.
    if ("descricao" %in% names(vars)) {
      desc <- as.character(vars$descricao[i])
      if (length(desc) == 1 && (is.na(desc) || !nzchar(trimws(desc)))) {
        registrar("aviso", nm, "variável publicada sem descrição no dicionário")
      }
    }
  }

  # As colunas de chave são estruturais e não pertencem a nenhuma tabela em
  # particular: elas são especificadas em config/parametros.yml, seção `chaves:`,
  # e não no dicionário de variáveis. Cobrá-las aqui seria exigir 26 linhas
  # idênticas no dicionário para dizer o que o YAML já diz uma vez.
  #
  # Achado 20, item (4): esse contrato estava declarado e NENHUMA função o lia.
  # Agora ele é verificado em toda tabela, o que é mais forte do que uma linha de
  # dicionário — pega o tipo, não só a presença.
  contrato <- tryCatch(mape_param("chaves"), error = function(e) NULL)
  chaves_declaradas <- names(contrato)
  for (k in intersect(chaves_declaradas, names(x))) {
    esperado_k <- contrato[[k]]$tipo
    real_k <- mape_tipo_de(x[[k]])
    if (!is.null(esperado_k) && !identical(real_k, esperado_k)) {
      registrar("erro", k,
                paste0("chave declarada '", esperado_k, "' em config/parametros.yml, ",
                       "observada '", real_k, "'"))
    }
    digitos <- contrato[[k]]$digitos
    if (!is.null(digitos) && is.character(x[[k]])) {
      errados <- sum(!is.na(x[[k]]) & nchar(x[[k]]) != digitos)
      if (errados > 0) {
        registrar("erro", k,
                  paste0(errados, " valor(es) de chave com número de dígitos ",
                         "diferente de ", digitos))
      }
    }
  }

  # Achado 80, o furo maior: o laço iterava sobre as linhas do DICIONÁRIO, então
  # uma coluna publicada que não constasse dele não era olhada por checagem
  # nenhuma. O dicionário é a especificação — coluna fora dele é coluna sem
  # especificação.
  fora_do_dicionario <- setdiff(names(x), c(vars$nome_canonico, chaves_declaradas))
  if (length(fora_do_dicionario)) {
    registrar("erro", paste(utils::head(fora_do_dicionario, 1), collapse = ""),
              paste0(length(fora_do_dicionario),
                     " coluna(s) publicada(s) sem linha no dicionário: ",
                     paste(utils::head(fora_do_dicionario, 8), collapse = ", ")))
  }

  # Achado 86: a checagem 9 só existe onde o dicionário quis, e 240 das 431
  # variáveis não têm faixa verificada. Não dá para inventar a faixa, mas dá
  # para dizer quanto do dado foi de fato olhado, em vez de deixar "as checagens
  # passaram" sugerir cobertura total.
  numericas <- names(x)[vapply(x, is.numeric, logical(1))]
  numericas <- intersect(numericas, vars$nome_canonico)
  if (length(numericas)) {
    sem_dominio <- sum(is.na(vars$dominio_valido[match(numericas, vars$nome_canonico)]))
    if (sem_dominio > 0) {
      registrar("informativo", "(tabela)",
                paste0(sem_dominio, " de ", length(numericas),
                       " coluna(s) numérica(s) sem `dominio_valido` declarado (",
                       round(100 * sem_dominio / length(numericas)),
                       "%): a checagem de faixa não olhou essas."))
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
