# Documentação gerada a partir do dicionário ---------------------------------
#
# A promessa da seção 7.7 do plano: cada pasta de fonte ganha um README que
# nunca é escrito à mão, e por isso nunca fica desatualizado por esquecimento.
#
# O que torna isso mais do que conveniência é o que aconteceu com a
# documentação anterior. Ela tem `Total Variáveis` somando 533 contra 451
# reais, e cinco tabelas declarando cobertura até 2024 num painel que terminava
# em 2023. Nenhum desses números está errado por descuido: eles estão errados
# porque precisavam ser reescritos à mão toda vez que o dado mudava, e não
# foram. Um número que se mede não tem como divergir do que ele mede.

#' Gera a documentação publicada de uma tabela
#'
#' @param tabela Slug da tabela.
#' @param destino Caminho do arquivo. NULL usa a convenção
#'   `fontes/<dimensao>/<fonte>/README.md` para fonte e
#'   `dados/dimensao/<slug>.md` para dimensão.
#' @param recalcular Se TRUE, remede os campos calculados antes de escrever.
#' @return Invisivelmente, o caminho escrito.
mape_gerar_documentacao <- function(tabela, destino = NULL, recalcular = TRUE) {
  pub <- mape_tabelas_publicadas()
  if (!tabela %in% pub$slug) {
    stop("Tabela '", tabela, "' não está publicada em disco.", call. = FALSE)
  }
  camada <- pub$camada[match(tabela, pub$slug)]
  if (recalcular) mape_recalcular_campos(tabela)

  x <- mape_ler_tabela(tabela, camada = camada)
  meta <- mape_dicionario("tabelas")
  meta <- meta[meta$slug_tabela == tabela, , drop = FALSE]
  # Achados 43 e 55: com incluir_fontes = FALSE, a documentação de uma DIMENSÃO
  # não listava as colunas que vieram de uma fonte fatiada — 83 colunas
  # publicadas ficavam sem linha nenhuma no .md da tabela a que pertencem, e
  # 11_transportes.md e 12_habitacao.md não listavam nenhuma das suas.
  #
  # Para uma tabela de fonte o comportamento é o mesmo (não há fontes abaixo).
  vars <- mape_variaveis_de(tabela, incluir_fontes = TRUE)

  if (is.null(destino)) {
    destino <- if (camada == "fonte") {
      mape_caminho("fontes", tabela, "README.md")
    } else {
      mape_caminho("dados", "dimensao", paste0(tabela, ".md"))
    }
  }
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)

  campo <- function(nm, padrao = "não informado") {
    if (!nrow(meta) || !nm %in% names(meta) || is.na(meta[[nm]][1]) ||
        !nzchar(meta[[nm]][1])) padrao else meta[[nm]][1]
  }
  fmt <- function(n) formatC(n, format = "d", big.mark = ".", decimal.mark = ",")

  # --- Os campos calculados, medidos agora ---------------------------------
  n_mun <- length(unique(x$id_municipio))
  n_mun_br <- length(unique(mape_ler_tabela("00_diretorios/municipios")$id_municipio))
  chaves <- intersect(c("id_municipio", "ano"), names(x))
  dados <- setdiff(names(x), chaves)
  cobertura_tabela <- if ("ano" %in% names(x)) {
    paste0(min(x$ano, na.rm = TRUE), "-", max(x$ano, na.rm = TRUE))
  } else "sem dimensão temporal"
  # Achado 64: este número e o de qa/<slug>.md tinham o MESMO rótulo, "células
  # vazias", e valores diferentes — porque este exclui as colunas de chave e
  # aquele não. Dois documentos gerados no mesmo minuto discordavam sobre a
  # mesma tabela. Os dois números são úteis; o que faltava era o rótulo dizer
  # qual é qual, e as casas decimais baterem.
  pct_na <- round(100 * mean(is.na(as.matrix(x[, dados, drop = FALSE]))), 2)

  cab <- c(
    paste0("# ", campo("nome_publicado", tabela)), "",
    paste0("**Slug:** `", tabela, "`  "),
    paste0("**Camada:** ", camada, "  "),
    paste0("**Dimensão:** ", campo("dimensao")), "",
    "<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:",
    "     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e",
    "     da medição do próprio arquivo publicado. -->", "",
    campo("descricao", ""), ""
  )

  proc <- c(
    "## Procedência", "",
    "| | |", "|---|---|",
    paste0("| Fonte original | ", campo("fonte_original"), " |"),
    paste0("| Fonte da extração | ", campo("fonte_extracao"), " |"),
    paste0("| Link | ", if (campo("link", "") == "") "não informado" else
      paste0("<", campo("link"), ">"), " |"),
    paste0("| Método de acesso | `", campo("metodo_acesso"), "` |"),
    paste0("| Licença | ", campo("licenca", "a verificar"), " |"),
    paste0("| Periodicidade da fonte | ", campo("periodicidade_fonte"), " |"),
    paste0("| Script de ingestão | ", if (campo("script_ingestao", "") == "")
      "não informado" else paste0("`", campo("script_ingestao"), "`"), " |"),
    ""
  )

  # A cobertura aparece em duas linhas de propósito. Uma é o que a fonte
  # declara publicar e alguém digitou; a outra é o que a tabela entrega e é
  # medido. Separá-las resolve dois casos reais em que os dois números
  # divergiam sem que ninguém percebesse: o Censo da Educação Superior,
  # declarado como 1995-2023 e entregando 2009-2023, e o Anuário do FBSP,
  # declarado sem ressalva e cobrindo 27 municípios.
  cont <- c(
    "## O que a tabela contém", "",
    "| | |", "|---|---|",
    paste0("| Linhas | ", fmt(nrow(x)), " |"),
    paste0("| Colunas | ", ncol(x), " |"),
    paste0("| Municípios distintos | ", fmt(n_mun), " de ", fmt(n_mun_br),
           " (", round(100 * n_mun / n_mun_br, 1), "%) |"),
    paste0("| Chave primária | `", campo("chave_primaria", paste(chaves, collapse = ", ")), "` |"),
    paste0("| Granularidade | ", campo("granularidade"), " |"),
    paste0("| Cobertura declarada pela fonte | ", campo("cobertura_temporal_da_fonte"), " |"),
    paste0("| **Cobertura observada na tabela** | **", cobertura_tabela, "** |"),
    paste0("| Células vazias (colunas de conteúdo, sem as chaves) | ", pct_na, "% |"),
    paste0("| Regra de preenchimento temporal | `",
           campo("regra_preenchimento_temporal", "nenhuma"), "` |"),
    ""
  )

  # --- Variáveis ------------------------------------------------------------
  linhas_var <- character()
  if (nrow(vars)) {
    vars <- vars[order(match(vars$nome_canonico, names(x))), ]
    # Achado 55: `pct_na`, `minimo` e `maximo` do dicionário são medidos na
    # tabela declarada em `vars$tabela`, e para 110 variáveis essa tabela é a
    # FONTE, não a dimensão. Imprimir aquele número aqui fazia o documento da
    # DIMENSÃO afirmar dela uma medida da fonte: `ano_ref_inicio_tarifa_zero`
    # aparecia com 81,7% de vazios quando na dimensão ela é 99,94% vazia.
    #
    # A coluna `vazios` passa a ser medida em `x`, que é a tabela que ESTE
    # documento descreve. Onde os campos guardados vierem de outra tabela, a
    # nota abaixo diz de qual — em vez de calar.
    medida_alhures <- character()
    linhas_var <- c(
      "## Variáveis", "",
      "| variável | tipo | unidade | descrição | vazios |",
      "|---|---|---|---|---|",
      vapply(seq_len(nrow(vars)), function(i) {
        limpa <- function(s) {
          if (is.na(s) || !nzchar(s)) "—" else gsub("[|\n]", " ", s)
        }
        col <- vars$nome_canonico[i]
        na_txt <- if (col %in% names(x)) {
          paste0(format(round(100 * mean(is.na(x[[col]])), 1), nsmall = 1), "%")
        } else if (is.na(vars$pct_na[i])) "—" else {
          paste0(format(round(vars$pct_na[i], 1), nsmall = 1), "%")
        }
        decl <- vars$tabela[i]
        if (!is.na(decl) && nzchar(decl) && !identical(decl, tabela)) {
          medida_alhures <<- c(medida_alhures, paste0("`", col, "` (", decl, ")"))
        }
        paste0("| `", col, "` | ", limpa(vars$tipo[i]), " | ",
               limpa(vars$unidade[i]), " | ", limpa(vars$descricao[i]), " | ",
               na_txt, " |")
      }, character(1)),
      ""
    )
    if (length(medida_alhures)) {
      linhas_var <- c(linhas_var,
        paste0("A coluna `vazios` acima é medida **nesta** tabela. Já os campos ",
               "calculados do dicionário (`pct_na`, `minimo`, `maximo`, ",
               "`n_distintos`) são medidos na tabela em que a variável é ",
               "observada, que para ", length(medida_alhures),
               " destas colunas é outra: ",
               paste(medida_alhures, collapse = ", "),
               ". Os dois números podem divergir muito, e divergem por desenho: ",
               "a fonte guarda o observado e a dimensão o painel expandido."),
        "")
    }
  }

  # --- Ressalvas ------------------------------------------------------------
  # Tudo que a validação chama de aviso e que a tabela justifica. Publicar a
  # ressalva junto do dado é o que impede que ela vire folclore oral.
  ress <- character()
  problemas <- vars[!is.na(vars$problema) & nzchar(vars$problema), , drop = FALSE]
  obs <- campo("observacoes", "")
  if (nrow(problemas) || nzchar(obs)) {
    ress <- c("## Ressalvas", "")
    if (nzchar(obs)) ress <- c(ress, obs, "")
    if (nrow(problemas)) {
      for (i in seq_len(nrow(problemas))) {
        ress <- c(ress, paste0("**`", problemas$nome_canonico[i], "`** — ",
                               gsub("\n", " ", problemas$problema[i])), "")
      }
    }
  }

  # --- Como usar ------------------------------------------------------------
  uso <- c(
    "## Como ler esta tabela", "", "```r",
    'for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")',
    "",
    paste0('x <- mape_ler("', tabela, '")'),
    paste0('x <- mape_ler("', tabela, '", territorio = TRUE)   # com nome do município e UF'),
    "```", "",
    paste0("_Gerado em ", format(Sys.time(), "%Y-%m-%d %H:%M"),
           " por `mape_gerar_documentacao()`._"), ""
  )

  writeLines(c(cab, proc, cont, linhas_var, ress, uso), destino, useBytes = TRUE)
  invisible(destino)
}

#' Gera a documentação de todas as tabelas e o índice geral
#'
#' @param tabelas Slugs. NULL usa todas as publicadas.
#' @return Invisivelmente, o vetor de caminhos escritos.
mape_gerar_documentacao_completa <- function(tabelas = NULL,
                                             gravar_dicionario = FALSE) {
  pub <- mape_tabelas_publicadas()
  if (is.null(tabelas)) tabelas <- pub$slug

  # Achado 69: aqui havia `mape_recalcular_campos(tabelas)`, que GRAVA
  # dicionario/variaveis.csv — declarado como dependência do próprio alvo
  # `documentacao` (`arquivo_dicionario`). O alvo reescrevia a sua entrada, e por
  # isso o grafo ficava desatualizado logo depois de rodar: ele nunca convergia.
  #
  # O recálculo continua acontecendo, porque a documentação tem de descrever o
  # dado de hoje — mas em memória. Para gravar o dicionário, use o comando
  # próprio: Rscript tools/recalcular_dicionario.R
  mape_recalcular_campos(tabelas, gravar = gravar_dicionario)
  escritos <- vapply(tabelas, function(t) {
    mape_gerar_documentacao(t, recalcular = FALSE)
  }, character(1))

  # --- O índice geral -------------------------------------------------------
  meta <- mape_dicionario("tabelas")
  vars <- mape_dicionario("variaveis")
  dims <- mape_dicionario("dimensoes")
  fmt <- function(n) formatC(n, format = "d", big.mark = ".", decimal.mark = ",")

  linhas <- list()
  for (t in tabelas) {
    camada <- pub$camada[match(t, pub$slug)]
    x <- mape_ler_tabela(t, camada = camada)
    linhas[[length(linhas) + 1]] <- data.frame(
      slug = t, camada = camada, linhas = nrow(x), colunas = ncol(x),
      municipios = length(unique(x$id_municipio)),
      anos = if ("ano" %in% names(x))
        paste0(min(x$ano, na.rm = TRUE), "-", max(x$ano, na.rm = TRUE)) else "—",
      mb = round(mape_mb(mape_caminho_tabela(t, "parquet", camada)), 2),
      stringsAsFactors = FALSE)
  }
  idx <- do.call(rbind, linhas)

  corpo <- c(
    "# Dicionário do MAPEmunicipios", "",
    "<!-- GERADO por mape_gerar_documentacao_completa(). Não edite à mão. -->", "",
    paste0("O painel cobre ", fmt(nrow(mape_ler_tabela("00_diretorios/municipios"))),
           " municípios brasileiros, de ", mape_anos_painel()[1], " a ",
           utils::tail(mape_anos_painel(), 1), "."), "",
    "| | |", "|---|---|",
    paste0("| Dimensões | ", nrow(dims), " |"),
    paste0("| Tabelas publicadas | ", nrow(idx), " (",
           sum(idx$camada == "dimensao"), " de dimensão, ",
           sum(idx$camada == "fonte"), " de fonte) |"),
    paste0("| Variáveis documentadas | ", fmt(nrow(vars)), " |"),
    paste0("| Variáveis pendentes de revisão | ",
           sum(vars$revisao_pendente %in% c(TRUE, "TRUE"), na.rm = TRUE), " |"),
    paste0("| Tamanho total em Parquet | ", round(sum(idx$mb), 1), " MB |"), "",
    "## Tabelas de dimensão", "",
    "A dimensão é o painel município × ano, e é o que a maior parte das pessoas",
    "quer. Cada uma junta as fontes do seu tema.", "",
    "| tabela | linhas | colunas | municípios | anos | MB |",
    "|---|---|---|---|---|---|"
  )
  d <- idx[idx$camada == "dimensao", ]
  corpo <- c(corpo, paste0(
    "| [`", d$slug, "`](../dados/dimensao/", d$slug, ".md) | ", fmt(d$linhas),
    " | ", d$colunas, " | ", fmt(d$municipios), " | ", d$anos, " | ", d$mb, " |"))

  f <- idx[idx$camada == "fonte", ]
  corpo <- c(corpo, "", "## Tabelas de fonte", "",
    "A fonte guarda o dado **como foi observado**, na granularidade nativa dela.",
    "Onde a dimensão repete a mesma medição em vários anos para preencher o",
    "painel, a fonte guarda a medição uma vez só. É a diferença entre as 183.814",
    "linhas de `11_transportes` e as 578 linhas de `11_transportes/tarifa_zero`.",
    "",
    "| tabela | linhas | colunas | municípios | anos | MB |",
    "|---|---|---|---|---|---|",
    paste0("| [`", f$slug, "`](../fontes/", f$slug, "/README.md) | ", fmt(f$linhas),
           " | ", f$colunas, " | ", fmt(f$municipios), " | ", f$anos, " | ", f$mb, " |"))

  corpo <- c(corpo, "", "## Arquivos do dicionário", "",
    "| arquivo | o que guarda |", "|---|---|",
    "| `dimensoes.csv` | o vocabulário de dimensões: slug, rótulo e número no legado |",
    "| `tabelas.csv` | uma linha por tabela, com procedência, licença e granularidade |",
    "| `variaveis.csv` | uma linha por variável, com tipo, unidade, escala e domínio |",
    "| `deprecacao.csv` | de-para dos nomes antigos, para quem tinha código escrito |",
    "",
    paste0("_Gerado em ", format(Sys.time(), "%Y-%m-%d %H:%M"), "._"), "")

  destino_idx <- mape_caminho("dicionario", "README.md")
  writeLines(corpo, destino_idx, useBytes = TRUE)

  message("documentação gerada: ", length(escritos), " tabela(s) + índice geral")
  invisible(c(escritos, destino_idx))
}
