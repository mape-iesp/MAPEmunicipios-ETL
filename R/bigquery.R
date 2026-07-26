# Acesso ao BigQuery e registro de proveniência ------------------------------
#
# O legado tem quatro projetos de faturamento diferentes escritos dentro do
# código, em cerca de 28 chamadas: dados-importacao, base-dos-dados-429117,
# municipality-carlos e dissertacao-de-mestrado-399114. Três deles são
# aparentemente pessoais, o que significa que o custo de reconstruir a base está
# espalhado por quatro contas.
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

#' Executa uma consulta no BigQuery e registra a proveniência
#'
#' @param sql Consulta.
#' @param fonte Identificador da fonte, usado no registro.
#' @param billing Projeto de faturamento; se NULL, resolve sozinho.
#' @param registrar Se TRUE, grava uma linha em dicionario/proveniencia.csv.
#' @return Data frame com o resultado.
mape_query <- function(sql, fonte, billing = NULL, registrar = TRUE) {
  if (is.null(billing)) billing <- mape_billing_id()

  inicio <- Sys.time()
  resultado <- basedosdados::read_sql(sql, billing_project_id = billing)
  fim <- Sys.time()

  if (registrar) {
    mape_registrar_proveniencia(
      fonte = fonte,
      metodo = "bigquery",
      detalhe = paste0("projeto=", billing),
      hash_consulta = substr(digest::digest(sql, algo = "sha256"), 1, 16),
      n_linhas = nrow(resultado),
      segundos = round(as.numeric(difftime(fim, inicio, units = "secs")), 1)
    )
  }
  as.data.frame(resultado)
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
         "plano/02-documentacao-e-atualizacao.md, seção 8.4.", call. = FALSE)
  }
  manifesto <- yaml::read_yaml(manifesto_path)
  if (is.null(arquivo)) arquivo <- manifesto$arquivo_local

  caminho <- mape_caminho("fontes", fonte, "raw", arquivo)
  if (!file.exists(caminho)) {
    stop("Arquivo bruto ausente: ", caminho, "\n",
         "Ele não é versionado. Obtenha-o assim:\n  ",
         manifesto$url %||% "(sem URL registrada)", "\n",
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
