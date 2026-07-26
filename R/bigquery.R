# Acesso ao BigQuery e registro de proveniência ------------------------------
#
# O legado tem QUATRO projetos de faturamento diferentes escritos dentro do
# código, em cerca de 28 chamadas. Três deles são aparentemente pessoais, o que
# significa que o custo de reconstruir a base está espalhado por quatro contas,
# e que ninguém consegue dizer quanto a base custou. É isto que mape_billing_id()
# existe para resolver: um projeto só, resolvido fora do código.
#
# Os quatro identificadores não são reproduzidos aqui de propósito. Este
# repositório é público, e o diagnóstico não depende dos nomes.
#
# Além de resolver a configuração, estas funções registram QUEM gerou cada
# extração. Hoje nenhuma data de extração existe em lugar nenhum do projeto, e
# as tabelas da Base dos Dados mudam sem aviso.
#
# ATENÇÃO: durante a migração nada disto roda. O princípio da seção 12.2 do
# plano é que esta etapa reestrutura o código e não atualiza os dados; os
# scripts de extração são escritos e só executados na etapa seguinte.

#' Resolve o projeto de faturamento do Google Cloud
#'
#' A ordem é: variável de ambiente MAPE_GCP_BILLING, depois
#' config/parametros.yml, depois basedosdados::get_billing_id(). Falha com uma
#' mensagem que diz o que fazer.
#'
#' @return O identificador do projeto, como character.
mape_billing_id <- function() {
  # Um identificador válido é texto não vazio. A conferência de tipo não é
  # zelo excessivo: basedosdados::get_billing_id() devolve FALSE quando não há
  # projeto configurado, em vez de erro, e sem esta checagem o pipeline sairia
  # daqui com o literal "FALSE" no lugar do projeto.
  valido <- function(v) is.character(v) && length(v) == 1 && nzchar(v)

  do_ambiente <- Sys.getenv("MAPE_GCP_BILLING", unset = "")
  if (valido(do_ambiente)) return(do_ambiente)

  do_arquivo <- tryCatch(mape_param("gcp_billing"), error = function(e) NULL)
  if (valido(do_arquivo)) return(do_arquivo)

  do_pacote <- tryCatch(
    suppressMessages(basedosdados::get_billing_id()),
    error = function(e) NULL
  )
  if (valido(do_pacote)) return(do_pacote)

  stop(
    "Não consegui resolver o projeto de faturamento do Google Cloud.\n",
    "Faça uma destas coisas:\n",
    "  1. Acrescente ao .Renviron da raiz do repositório:\n",
    "       MAPE_GCP_BILLING=<seu-projeto-gcp>\n",
    "  2. Ou ajuste gcp_billing em config/parametros.yml.\n\n",
    "Se você só quer CONSUMIR as tabelas publicadas, não precisa de nada disso ",
    "— use mape_ler_tabela().",
    call. = FALSE
  )
}

#' Teto de bytes do BigQuery, lido em GiB de config/parametros.yml
#'
#' O YAML é declarado em GiB porque o leitor de YAML do R converte inteiros
#' acima de 2^31 para NA em silêncio — foi o primeiro modo de falha que este
#' freio encontrou, e ele teria desligado o teto sem dizer nada.
#'
#' @param qual "consulta" ou "sessao".
#' @return Bytes, como numeric.
mape_teto_bq <- function(qual = c("consulta", "sessao")) {
  qual <- match.arg(qual)
  gib <- mape_param(paste0("bq.teto_gib_", qual))
  stopifnot(is.numeric(gib), length(gib) == 1, !is.na(gib), gib > 0)
  as.numeric(gib) * 1024^3
}

#' Bytes já escaneados nesta sessão, segundo qa/custo_bigquery.csv
#'
#' @return Numeric com o total acumulado de bytes cobrados.
mape_custo_bigquery <- function() {
  caminho <- mape_caminho("qa", "custo_bigquery.csv")
  if (!file.exists(caminho)) return(0)
  reg <- utils::read.csv(caminho, stringsAsFactors = FALSE)
  if (!nrow(reg)) return(0)
  sum(as.numeric(reg$bytes_cobrados), na.rm = TRUE)
}

#' Formata bytes de um jeito legível
#' @param b Bytes.
#' @return Texto.
mape_formatar_bytes <- function(b) {
  u <- c("B", "KiB", "MiB", "GiB", "TiB")
  i <- if (b <= 0) 1 else min(length(u), floor(log(b, 1024)) + 1)
  sprintf("%.2f %s", b / 1024^(i - 1), u[i])
}

#' Executa uma consulta no BigQuery, com dry-run, teto e registro de custo
#'
#' O freio tem quatro partes, e nenhuma é opcional:
#'
#' 1. **Dry-run sempre primeiro.** `bq_perform_query_dry_run()` mede exatamente
#'    quantos bytes a consulta escaneia e não custa nada. Sem ele, o custo só
#'    aparece na fatura.
#' 2. **Teto por consulta.** Acima de `bq.teto_gib_consulta`, a consulta é
#'    recusada aqui, antes de sair da máquina.
#' 3. **`maximum_bytes_billed`.** É o que faz o servidor do Google matar a
#'    consulta em vez de cobrá-la, caso o dry-run tenha subestimado.
#' 4. **Acumulado da sessão.** Cada execução soma uma linha em
#'    `qa/custo_bigquery.csv`, e o total é confrontado com
#'    `bq.teto_gib_sessao`.
#'
#' O modelo on-demand cobra por byte escaneado, não por byte devolvido: um
#' `LIMIT 10` sobre uma tabela grande custa o mesmo que a consulta sem `LIMIT`.
#' Por isso a agregação tem de ser feita no servidor, com `GROUP BY`, e nunca
#' num laço por município ou por ano.
#'
#' @param sql Consulta.
#' @param fonte Identificador da fonte, usado no registro.
#' @param billing Projeto de faturamento; se NULL, resolve sozinho.
#' @param registrar Se TRUE, grava uma linha em dicionario/proveniencia.csv.
#' @param so_estimar Se TRUE, roda apenas o dry-run e devolve os bytes, sem
#'   executar. Use para dimensionar uma consulta nova.
#' @return Data frame com o resultado, ou os bytes estimados se so_estimar.
mape_query <- function(sql, fonte, billing = NULL, registrar = TRUE,
                       so_estimar = FALSE) {
  if (is.null(billing)) billing <- mape_billing_id()

  teto_consulta <- mape_teto_bq("consulta")
  teto_sessao <- mape_teto_bq("sessao")

  # -- 1. Dry-run, sempre ----------------------------------------------------
  bytes <- tryCatch(
    as.numeric(bigrquery::bq_perform_query_dry_run(sql, billing = billing)),
    error = function(e) {
      stop("O dry-run falhou, então a consulta não roda.\n",
           "Sem a medição prévia não há como saber quanto ela custaria.\n\n",
           conditionMessage(e), call. = FALSE)
    }
  )
  message("[bq] dry-run de ", fonte, ": ", mape_formatar_bytes(bytes))
  if (so_estimar) return(bytes)

  # -- 2. Teto por consulta --------------------------------------------------
  if (bytes > teto_consulta) {
    stop("Consulta recusada: escanearia ", mape_formatar_bytes(bytes),
         ", acima do teto de ", mape_formatar_bytes(teto_consulta),
         " por consulta (bq.teto_gib_consulta).\n",
         "Reduza o escopo — selecione menos colunas, filtre no servidor, ",
         "agregue com GROUP BY — ou suba o teto de propósito em ",
         "config/parametros.yml.", call. = FALSE)
  }

  # -- 4a. Teto acumulado da sessão -----------------------------------------
  gasto <- mape_custo_bigquery()
  if (gasto + bytes > teto_sessao) {
    stop("Consulta recusada pelo teto acumulado: já foram escaneados ",
         mape_formatar_bytes(gasto), " e esta somaria ",
         mape_formatar_bytes(bytes), ", passando de ",
         mape_formatar_bytes(teto_sessao), " (bq.teto_gib_sessao).\n",
         "O acumulado está em qa/custo_bigquery.csv.", call. = FALSE)
  }

  # -- 3. Executa com maximum_bytes_billed ----------------------------------
  # É este argumento que transforma o teto de intenção em garantia: o servidor
  # mata a consulta em vez de cobrá-la.
  inicio <- Sys.time()
  tarefa <- bigrquery::bq_project_query(
    billing, sql,
    quiet = TRUE,
    maximum_bytes_billed = format(teto_consulta, scientific = FALSE)
  )
  resultado <- as.data.frame(bigrquery::bq_table_download(tarefa, quiet = TRUE))
  fim <- Sys.time()

  cobrados <- tryCatch({
    meta <- bigrquery::bq_job_meta(tarefa)
    as.numeric(meta$statistics$query$totalBytesBilled)
  }, error = function(e) bytes)
  if (!length(cobrados) || is.na(cobrados)) cobrados <- bytes

  # -- 4b. Registro do custo -------------------------------------------------
  destino <- mape_caminho("qa", "custo_bigquery.csv")
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  linha <- data.frame(
    data = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    fonte = fonte,
    sql_resumo = substr(gsub("[[:space:]]+", " ", sql), 1, 160),
    hash_consulta = substr(digest::digest(sql, algo = "sha256"), 1, 16),
    bytes_dry_run = format(bytes, scientific = FALSE),
    bytes_cobrados = format(cobrados, scientific = FALSE),
    n_linhas = nrow(resultado),
    segundos = round(as.numeric(difftime(fim, inicio, units = "secs")), 1),
    stringsAsFactors = FALSE
  )
  utils::write.table(linha, destino, sep = ",", row.names = FALSE,
                     col.names = !file.exists(destino), append = file.exists(destino),
                     qmethod = "double", fileEncoding = "UTF-8")
  message("[bq] ", fonte, ": ", nrow(resultado), " linhas, cobrados ",
          mape_formatar_bytes(cobrados), " (acumulado: ",
          mape_formatar_bytes(gasto + cobrados), ")")

  if (registrar) {
    mape_registrar_proveniencia(
      fonte = fonte,
      metodo = "bigquery",
      # O identificador do projeto GCP NÃO entra aqui: `dicionario/proveniencia.csv`
      # é versionado e vai no release, e o repositório é público. O identificador
      # vive só em MAPE_GCP_BILLING, no .Renviron, que o .gitignore cobre. Ele
      # também não é proveniência do dado: quem paga a consulta não diz nada
      # sobre o que a consulta devolveu — isso é o hash e o número de linhas.
      detalhe = paste0("bytes=", format(cobrados, scientific = FALSE)),
      hash_consulta = substr(digest::digest(sql, algo = "sha256"), 1, 16),
      n_linhas = nrow(resultado),
      segundos = round(as.numeric(difftime(fim, inicio, units = "secs")), 1)
    )
  }
  resultado
}

#' Baixa uma consulta uma vez e a guarda em raw/, com sha256 no manifesto
#'
#' O cache é o que garante que nenhuma consulta rode duas vezes. Se o arquivo
#' já existe, a função nem chama o BigQuery.
#'
#' @param sql Consulta.
#' @param fonte Caminho da fonte, relativo a fontes/ (ex.: "04_economia/ibge_pib").
#' @param arquivo Nome do arquivo em raw/.
#' @param billing Projeto de faturamento.
#' @param forcar Se TRUE, reconsulta mesmo com o cache presente.
#' @return Data frame.
mape_baixar_cache <- function(sql, fonte, arquivo, billing = NULL, forcar = FALSE) {
  destino <- mape_caminho("fontes", fonte, "raw", arquivo)
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)

  if (file.exists(destino) && !forcar) {
    message("[bq] cache: ", destino, " (nenhuma consulta)")
    return(as.data.frame(arrow::read_parquet(destino)))
  }

  resultado <- mape_query(sql, fonte = fonte, billing = billing)
  arrow::write_parquet(resultado, destino)

  # O sha256 vai para o MANIFESTO.yml, que é o que fica versionado — o raw/ não.
  sha <- digest::digest(destino, algo = "sha256", file = TRUE)
  manifesto_path <- mape_caminho("fontes", fonte, "MANIFESTO.yml")
  manifesto <- if (file.exists(manifesto_path)) yaml::read_yaml(manifesto_path) else list()
  manifesto$arquivo_local <- arquivo
  manifesto$sha256 <- sha
  manifesto$metodo_acesso <- "bigquery"
  manifesto$sql_hash <- substr(digest::digest(sql, algo = "sha256"), 1, 16)
  manifesto$data_download <- format(Sys.Date(), "%Y-%m-%d")
  dir.create(dirname(manifesto_path), recursive = TRUE, showWarnings = FALSE)
  yaml::write_yaml(manifesto, manifesto_path)
  message("[bq] cache gravado: ", destino, " (sha256 ", substr(sha, 1, 12), "...)")

  resultado
}

#' Registra uma extração em dicionario/proveniencia.csv
#'
#' Este arquivo é gerado, nunca digitado. É dele que sai o campo
#' data_ultima_extracao da documentação por tabela.
#'
#' @param fonte Identificador da fonte.
#' @param metodo "bigquery", "download_manual", "pacote_r", "api" ou
#'   "arquivo_local".
#' @param detalhe Texto livre com o que for relevante (projeto, URL, versão).
#' @param hash_consulta Hash do SQL ou do arquivo.
#' @param n_linhas Linhas obtidas.
#' @param segundos Duração.
#' @return Invisivelmente, a linha acrescentada.
mape_registrar_proveniencia <- function(fonte, metodo, detalhe = NA_character_,
                                        hash_consulta = NA_character_,
                                        n_linhas = NA_integer_,
                                        segundos = NA_real_) {
  caminho <- mape_caminho("dicionario", "proveniencia.csv")
  dir.create(dirname(caminho), recursive = TRUE, showWarnings = FALSE)

  linha <- data.frame(
    fonte = fonte,
    metodo = metodo,
    detalhe = detalhe,
    hash_consulta = hash_consulta,
    n_linhas = n_linhas,
    segundos = segundos,
    data_extracao = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    usuario = Sys.info()[["user"]],
    stringsAsFactors = FALSE
  )

  if (file.exists(caminho)) {
    antigo <- utils::read.csv(caminho, stringsAsFactors = FALSE, encoding = "UTF-8")
    linha <- rbind(antigo, linha)
  }
  utils::write.csv(linha, caminho, row.names = FALSE, fileEncoding = "UTF-8")
  invisible(linha)
}

#' Confere o checksum de um arquivo bruto contra o manifesto
#'
#' As fontes de download manual não têm o arquivo bruto versionado; o que é
#' versionado é o MANIFESTO.yml com o sha256. Sessenta e quatro bytes dão a
#' mesma garantia que versionar 194 MB de planilhas da MUNIC.
#'
#' @param fonte Caminho da pasta da fonte, relativo a fontes/.
#' @param arquivo Nome do arquivo em raw/. Se NULL, usa o do manifesto.
#' @return Invisivelmente, TRUE. Falha se o checksum divergir.
mape_verificar_raw <- function(fonte, arquivo = NULL) {
  manifesto_path <- mape_caminho("fontes", fonte, "MANIFESTO.yml")
  if (!file.exists(manifesto_path)) {
    stop("Sem MANIFESTO.yml em fontes/", fonte, ".\n",
         "Toda fonte de download manual precisa de um — ver ",
         "plano/migracao-etl/02-documentacao-e-atualizacao.md, seção 8.4.", call. = FALSE)
  }
  manifesto <- yaml::read_yaml(manifesto_path)
  if (is.null(arquivo)) arquivo <- manifesto$arquivo_local

  caminho <- mape_caminho("fontes", fonte, "raw", arquivo)
  if (!file.exists(caminho)) {
    # Achado 46: esta mensagem mandava o usuário à URL da origem sem avisar que,
    # em fonte marcada `derivado: true`, o que vem de lá NÃO é o que estava em
    # raw/. No CadÚnico a diferença é grande: a origem entrega a série MENSAL
    # com código de 6 dígitos, e o arquivo de raw/ é o snapshot de dezembro já
    # com 7 dígitos. Quem baixasse e seguisse em frente produziria outra tabela
    # em silêncio, e por isso `passos_ja_aplicados` entra aqui.
    stop("Arquivo bruto ausente: ", caminho, "\n",
         "Ele não é versionado. Obtenha-o assim:\n  ",
         manifesto$url %||% "(sem URL registrada)", "\n",
         if (isTRUE(manifesto$derivado)) {
           paste0("ATENÇÃO: esta fonte é DERIVADA — o que está em raw/ não é o ",
                  "bruto da origem.\n",
                  if (!is.null(manifesto$passos_ja_aplicados))
                    paste0("Passos já aplicados nele, que você terá de repetir:\n",
                           manifesto$passos_ja_aplicados, "\n") else "")
         } else "",
         if (!is.null(manifesto$nota)) paste0("Nota: ", manifesto$nota) else "",
         call. = FALSE)
  }

  observado <- digest::digest(caminho, algo = "sha256", file = TRUE)
  esperado <- manifesto$sha256
  if (!is.null(esperado) && !is.na(esperado) && nzchar(esperado) &&
      !identical(observado, esperado)) {
    stop("Checksum divergente em ", arquivo, ".\n",
         "  esperado: ", esperado, "\n  observado: ", observado, "\n",
         "O arquivo mudou desde que o manifesto foi escrito.", call. = FALSE)
  }
  # Devolve o CAMINHO, e não TRUE: assim o script de tratamento escreve
  #   origem <- mape_verificar_raw(FONTE, "arquivo.csv")
  # em vez de verificar e montar o caminho de novo, o que duplicaria a
  # convenção de onde o bruto vive.
  caminho
}

`%||%` <- function(a, b) if (is.null(a)) b else a
