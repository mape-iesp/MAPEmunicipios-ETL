# Validação e controle de qualidade ------------------------------------------
#
# As checagens da seção 11.2 do plano. Cada uma nasceu de um defeito real
# encontrado no levantamento do legado, e por isso o comentário de cada bloco
# diz o que ela previne.
#
# Regra de bloqueio, e desta vez ela é EXECUTADA e não só declarada:
#
#   - um ERRO impede a publicação, a menos que esteja reivindicado de antemão em
#     qa/erros_aceitos.csv, com justificativa;
#   - um AVISO exige justificativa registrada — em qa/justificativas.csv, ou no
#     campo `problema` da variável que ele nomeia;
#   - um aviso SEM justificativa vira erro.
#
# A auditoria de 26/07/2026 mostrou que nada disso era executado: o achado 22
# mediu que nenhum caminho de escrita chamava esta função, e o achado 38 mediu
# que a cláusula "aviso sem justificativa vira erro" não existia em código
# nenhum. As duas frases estavam escritas em cinco arquivos e valiam zero.
#
# O número de checagens não é mais digitado. mape_validar_tabela() conta quantas
# de fato rodaram e o relatório imprime esse número — porque a checagem 3 e a 6
# desaparecem quando o diretório de municípios não pode ser lido (achado 83), e
# antes disso o relatório dizia "as doze checagens passaram" mesmo assim.

#' Lê o livro-caixa de justificativas de aviso
#'
#' @return Data frame com slug_tabela, checagem, coluna, justificativa.
mape_justificativas <- function() {
  caminho <- mape_caminho("qa", "justificativas.csv")
  vazio <- data.frame(slug_tabela = character(), checagem = character(),
                      coluna = character(), justificativa = character(),
                      stringsAsFactors = FALSE)
  if (!file.exists(caminho)) return(vazio)
  r <- utils::read.csv(caminho, stringsAsFactors = FALSE, encoding = "UTF-8")
  if (!nrow(r)) return(vazio)
  r
}

#' Lê o livro-caixa de erros reivindicados
#'
#' Um erro só deixa de bloquear se estiver aqui, nomeado por tabela e checagem,
#' com justificativa. É o análogo de qa/paridade_esperada.csv: reivindicar antes,
#' nunca depois de ver o resultado.
#'
#' @return Data frame com slug_tabela, checagem, justificativa.
mape_erros_aceitos <- function() {
  caminho <- mape_caminho("qa", "erros_aceitos.csv")
  vazio <- data.frame(slug_tabela = character(), checagem = character(),
                      justificativa = character(), stringsAsFactors = FALSE)
  if (!file.exists(caminho)) return(vazio)
  r <- utils::read.csv(caminho, stringsAsFactors = FALSE, encoding = "UTF-8")
  if (!nrow(r)) return(vazio)
  r
}

#' Anexa a justificativa de cada achado, e promove aviso sem justificativa a erro
#'
#' Três fontes de justificativa, nesta ordem:
#'   1. qa/justificativas.csv, casando tabela + checagem (+ coluna, se declarada);
#'   2. o campo `problema` da variável nomeada no achado, em variaveis.csv;
#'   3. qa/erros_aceitos.csv, que rebaixa um erro reivindicado a aviso justificado.
#'
#' O campo `observacoes` da tabela NÃO conta como justificativa de aviso, de
#' propósito: texto livre no nível da tabela não prova que *este* aviso foi
#' justificado, que é a crítica do achado 38. Ele continua valendo como contexto
#' e é impresso no relatório.
#'
#' @param res Data frame de achados.
#' @param tabela Identificador da tabela.
#' @return O mesmo data frame, com as colunas justificada e justificativa, e as
#'   gravidades já ajustadas.
mape_aplicar_justificativas <- function(res, tabela) {
  if (!nrow(res)) {
    res$justificada <- logical(0)
    res$justificativa <- character(0)
    return(res)
  }
  res$justificada <- FALSE
  res$justificativa <- NA_character_

  just <- mape_justificativas()
  aceitos <- mape_erros_aceitos()
  vars <- tryCatch(mape_dicionario("variaveis"), error = function(e) NULL)

  # A descrição de um achado de schema começa com "<coluna>: ...".
  coluna_do_achado <- function(desc) {
    m <- regmatches(desc, regexpr("^[a-z][a-z0-9_]*(?=:)", desc, perl = TRUE))
    if (length(m)) m else NA_character_
  }

  for (i in seq_len(nrow(res))) {
    col <- coluna_do_achado(res$descricao[i])

    # 1. livro-caixa de justificativas
    j <- just[just$slug_tabela == tabela & just$checagem == res$checagem[i], , drop = FALSE]
    if (nrow(j)) {
      j <- j[is.na(j$coluna) | j$coluna == "*" | j$coluna == "" |
               (!is.na(col) & j$coluna == col), , drop = FALSE]
    }
    if (nrow(j)) {
      res$justificada[i] <- TRUE
      res$justificativa[i] <- j$justificativa[1]
      next
    }

    # 2. campo `problema` da variável nomeada
    if (!is.na(col) && !is.null(vars)) {
      linha <- vars[vars$nome_canonico == col, , drop = FALSE]
      prob <- linha$problema[nzchar(trimws(as.character(linha$problema)))]
      prob <- prob[!is.na(prob)]
      if (length(prob)) {
        res$justificada[i] <- TRUE
        res$justificativa[i] <- paste0("problema da variável ", col, ": ", prob[1])
        next
      }
    }

    # 3. erro reivindicado
    if (res$gravidade[i] == "erro") {
      a <- aceitos[aceitos$slug_tabela == tabela & aceitos$checagem == res$checagem[i], ,
                   drop = FALSE]
      if (nrow(a)) {
        res$justificada[i] <- TRUE
        res$justificativa[i] <- a$justificativa[1]
        res$gravidade[i] <- "aviso"   # reivindicado: deixa de bloquear
      }
    }
  }

  # A cláusula que faltava: aviso sem justificativa vira erro. A gravidade
  # "informativo" fica de fora — ela não afirma defeito, só mede cobertura, e
  # exigir justificativa para ela transformaria informação em ruído.
  res$justificada[res$gravidade == "informativo"] <- TRUE
  promove <- res$gravidade == "aviso" & !res$justificada
  res$gravidade[promove] <- "erro"
  res$descricao[promove] <- paste0(res$descricao[promove],
                                   " [aviso sem justificativa registrada]")
  res
}

#' Descrições de uma tabela que se repetem noutra — a checagem 12
#'
#' Compara descrições normalizadas: minúsculas, sem acento, sem pontuação, sem
#' os sufixos de deflação que o projeto acrescenta mecanicamente. Isso é o que
#' pega o bloco deslizado de 06_financas, cujo caso mais grave escapa da
#' igualdade exata porque teve texto prefixado.
#'
#' Pares legítimos ficam de fora por uma lista de exceções declarada: há
#' conceitos que a mesma frase descreve com razão em tabelas diferentes.
#'
#' @param tabela Identificador da tabela.
#' @return Data frame com coluna, outra, tabela_outra.
mape_descricoes_repetidas <- function(tabela) {
  vars <- mape_dicionario("variaveis")
  normalizar <- function(s) {
    s <- tolower(iconv(as.character(s), to = "ASCII//TRANSLIT"))
    s <- gsub("\\(deflacionado[^)]*\\)", "", s)
    s <- gsub("[[:punct:]]", " ", s)
    trimws(gsub("[[:space:]]+", " ", s))
  }
  vars$.norm <- normalizar(vars$descricao)
  # Pares legítimos: a mesma frase descreve o mesmo conceito nas duas tabelas.
  excecoes <- c("nome do municipio", "sigla da unidade da federacao",
                "nome da unidade da federacao", "codigo ibge do municipio 7 digitos",
                "ano de referencia", "ano")

  minhas <- vars[!is.na(vars$tabela) & vars$tabela == tabela &
                   !is.na(vars$.norm) & nzchar(vars$.norm), , drop = FALSE]
  out <- list()
  for (i in seq_len(nrow(minhas))) {
    n <- minhas$.norm[i]
    if (n %in% excecoes || nchar(n) < 25) next
    outras <- vars[!is.na(vars$.norm) & vars$.norm == n &
                     !is.na(vars$tabela) & vars$tabela != tabela, , drop = FALSE]
    if (nrow(outras)) {
      out[[length(out) + 1]] <- data.frame(
        coluna = minhas$nome_canonico[i],
        outra = outras$nome_canonico[1],
        tabela_outra = outras$tabela[1],
        stringsAsFactors = FALSE)
    }
  }
  if (length(out)) do.call(rbind, out) else
    data.frame(coluna = character(), outra = character(),
               tabela_outra = character(), stringsAsFactors = FALSE)
}

#' Roda todas as checagens sobre uma tabela
#'
#' @param x Data frame.
#' @param tabela Identificador da tabela.
#' @param chaves Chave primária. Se NULL, lê do dicionário de tabelas.
#' @param diretorio Diretório de municípios. Se NULL, lê o publicado, exceto
#'   quando a própria tabela for o diretório.
#' @param erro Se TRUE, falha ao encontrar problema bloqueante.
#' @param gravar Se TRUE, escreve qa/<slug>.md. Passe FALSE para validar sem
#'   sujar a árvore versionada (achado 59).
#' @return Invisivelmente, um data frame com uma linha por problema.
mape_validar_tabela <- function(x, tabela, chaves = NULL, diretorio = NULL,
                                erro = TRUE, gravar = TRUE) {
  achados <- list()
  reg <- function(checagem, gravidade, descricao) {
    achados[[length(achados) + 1]] <<- data.frame(
      tabela = tabela, checagem = checagem, gravidade = gravidade,
      descricao = descricao, stringsAsFactors = FALSE
    )
  }
  # Quantas checagens de fato rodaram. O relatório imprime este número em vez
  # de afirmar doze — ver o cabeçalho e o achado 83.
  executadas <- character()
  rodou <- function(...) executadas <<- unique(c(executadas, c(...)))

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
    rodou("chave_unica", "chave_sem_na")
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
      rodou("dominio_chave", "cobertura_municipios")
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
    } else {
      # Achado 83: sem esta linha, as checagens 3 e 6 sumiam sem deixar rastro e
      # o relatório continuava dizendo que tudo passou.
      reg("dominio_chave", "aviso",
          "diretório de municípios indisponível: as checagens de domínio de chave e de cobertura de municípios NÃO rodaram")
    }
  }

  # -- 4, 9, 10. Tipos, domínio de valor e coerência sufixo/escala ----------
  if (mape_tabela_no_dicionario(tabela)) {
    rodou("tipos", "dominio_valor", "sufixo_escala")
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
    rodou("faixa_anos")
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
  rodou("nomes_colunas")
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
  # -- 12. Descrições repetidas entre tabelas -------------------------------
  # A checagem 12 do plano, que NUNCA foi implementada — e o defeito que ela
  # previne está publicado: sete variáveis de 06_financas carregam a descrição
  # dos componentes do PIB de 04_economia, deslizadas em bloco (achados 18, 23).
  #
  # A regra é de SIMILARIDADE e não de igualdade exata, porque o caso mais grave
  # do bloco (siconfi_deducao_fundeb_brl2023) escapa da igualdade: a descrição
  # foi montada prefixando texto à descrição alheia.
  if (mape_tabela_no_dicionario(tabela)) {
    rodou("descricao_repetida")
    d <- tryCatch(mape_descricoes_repetidas(tabela), error = function(e) NULL)
    if (!is.null(d) && nrow(d)) {
      for (i in seq_len(nrow(d))) {
        reg("descricao_repetida", "aviso",
            paste0(d$coluna[i], ": descrição igual à de `", d$outra[i],
                   "` (tabela ", d$tabela_outra[i], ")"))
      }
    }
  }

  rodou("sentinelas")
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
  rodou("valores_infinitos")
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

  # É aqui que a regra declarada passa a valer: aviso justificado continua
  # aviso, erro reivindicado vira aviso, e aviso sem justificativa vira erro.
  res <- mape_aplicar_justificativas(res, tabela)

  if (gravar) mape_gravar_relatorio_qa(res, tabela, x, length(executadas))

  n_erro  <- sum(res$gravidade == "erro")
  n_aviso <- sum(res$gravidade == "aviso")
  message(sprintf("[QA] %s: %d erro(s), %d aviso(s), %d checagem(ns) executada(s)",
                  tabela, n_erro, n_aviso, length(executadas)))
  if (n_aviso) {
    for (i in which(res$gravidade == "aviso")) {
      message("      aviso  ", res$checagem[i], ": ", res$descricao[i])
    }
  }
  if (n_erro && erro) {
    stop("Validação bloqueou a publicação de '", tabela, "':\n",
         paste0("  - ", res$checagem[res$gravidade == "erro"], ": ",
                res$descricao[res$gravidade == "erro"], collapse = "\n"),
         "\n\nUm aviso sem justificativa aparece aqui como erro. Registre a ",
         "justificativa em qa/justificativas.csv (ou no campo `problema` da ",
         "variável), ou reivindique o erro em qa/erros_aceitos.csv.",
         call. = FALSE)
  }
  invisible(res)
}

#' Defeitos declarados de uma tabela, lidos do dicionário
#'
#' Achado 31: nenhum dos defeitos que o próprio repositório declara era detectado
#' por checagem automática, e cinco das sete tabelas afetadas recebiam o atestado
#' "as doze checagens passaram". As checagens continuam não detectando o que não
#' sabem procurar — mas o relatório passa a dizer o que a tabela declara.
#'
#' @param tabela Identificador da tabela.
#' @return Vetor de textos, possivelmente vazio.
mape_defeitos_declarados <- function(tabela) {
  out <- character()

  tabs <- tryCatch(mape_dicionario("tabelas"), error = function(e) NULL)
  if (!is.null(tabs) && tabela %in% tabs$slug_tabela) {
    obs <- tabs$observacoes[tabs$slug_tabela == tabela][1]
    if (!is.na(obs) && nzchar(trimws(obs))) {
      # Os marcadores em aberto são os que não estão marcados CORRIGIDO.
      pedacos <- unlist(strsplit(obs, "(?<=[.])\\s+(?=[A-ZÀ-Ú])", perl = TRUE))
      abertos <- pedacos[grepl("DEFEITO|LIMITA|ATEN|RESSALVA|PROBLEMA", pedacos) &
                           !grepl("CORRIGIDO", pedacos)]
      if (length(abertos)) out <- c(out, paste0("(tabela) ", abertos))
    }
  }

  vars <- tryCatch(mape_dicionario("variaveis"), error = function(e) NULL)
  if (!is.null(vars)) {
    v <- vars[vars$tabela == tabela, , drop = FALSE]
    if (nrow(v)) {
      tem <- !is.na(v$problema) & nzchar(trimws(as.character(v$problema)))
      if (any(tem)) {
        out <- c(out, paste0("(", v$nome_canonico[tem], ") ", v$problema[tem]))
      }
    }
  }
  out
}

#' Grava o relatório de qualidade de uma tabela
#'
#' @param res Data frame de problemas.
#' @param tabela Identificador da tabela.
#' @param x A tabela validada, usada para o resumo quantitativo.
#' @param n_checagens Quantas checagens de fato rodaram. O relatório imprime
#'   este número; antes ele afirmava doze mesmo quando duas não tinham rodado.
#' @return Invisivelmente, o caminho do relatório.
mape_gravar_relatorio_qa <- function(res, tabela, x = NULL, n_checagens = NA_integer_) {
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
      # Achado 64: o rótulo diz agora QUAL das duas medidas de vazio é esta. A
      # outra, sobre colunas de conteúdo, fica no .md da dimensão.
      paste0("- células vazias (todas as colunas): ",
             round(100 * mean(is.na(x)), 2), "%"),
      "")
  }

  linhas <- c(linhas, "## Checagens", "")
  quantas <- if (is.na(n_checagens)) "as" else paste("as", n_checagens)
  if (!nrow(res)) {
    linhas <- c(linhas,
                paste0("Nenhum problema automático: ", quantas,
                       " checagens executadas passaram."), "")
  } else {
    tem_just <- "justificativa" %in% names(res)
    linhas <- c(linhas,
      paste0("Checagens executadas: ", if (is.na(n_checagens)) "?" else n_checagens, "."), "",
      if (tem_just) "| checagem | gravidade | descrição | justificativa |" else
        "| checagem | gravidade | descrição |",
      if (tem_just) "|---|---|---|---|" else "|---|---|---|",
      paste0("| ", res$checagem, " | ", res$gravidade, " | ",
             gsub("[|]", "/", res$descricao),
             if (tem_just) paste0(" | ", gsub("[|]", "/", ifelse(is.na(res$justificativa),
                                                                 "— sem justificativa —",
                                                                 res$justificativa))) else "",
             " |"), "")
  }

  # Achado 31: o que a tabela declara sobre si mesma, ao lado do que as
  # checagens acharam. Sem esta seção, uma tabela com defeito conhecido e
  # declarado recebia um relatório que só dizia "passou".
  declarados <- tryCatch(mape_defeitos_declarados(tabela), error = function(e) character())
  linhas <- c(linhas, "## Defeitos declarados no dicionário", "")
  if (!length(declarados)) {
    linhas <- c(linhas, "Nenhum.", "")
  } else {
    linhas <- c(linhas,
      paste0("Estes ", length(declarados), " defeito(s) estão declarados no ",
             "dicionário e **não** são detectados pelas checagens automáticas ",
             "acima. Um relatório limpo não significa uma tabela sem defeito."),
      "",
      paste0("- ", gsub("\n", " ", declarados)), "")
  }

  writeLines(linhas, destino, useBytes = TRUE)
  invisible(destino)
}
