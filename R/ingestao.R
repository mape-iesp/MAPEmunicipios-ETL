# Ingestão de fontes ---------------------------------------------------------
#
# Duas funções que existem para tornar a seção 8 do plano executável em vez de
# descritiva: baixar um arquivo com procedência registrada, e criar o esqueleto
# de uma fonte nova.
#
# A segunda é a que mais importa para o objetivo (c) do projeto — "atualização
# fácil por quem chega sem contexto". Um bolsista que precise acrescentar o
# MapBiomas ao Meio Ambiente roda um comando e recebe dois scripts com o
# encadeamento certo, um manifesto para preencher e um README. O que sobra para
# ele é a parte específica da fonte, que é a única que ele tem como saber.

#' Baixa um arquivo de fonte e registra a procedência
#'
#' O legado tem a data do download embutida no nome do arquivo
#' (`Emendas_CGU_8_10_2024.xlsx`, `BD_Atlas_1991_2023_v1.0_2024.04.29.xlsx`), o
#' que obriga a editar o código toda vez que a fonte é atualizada. Aqui a data e
#' a versão vivem no manifesto, o nome do arquivo é estável, e o `sha256`
#' registrado permite conferir depois que o arquivo na pasta é o arquivo certo —
#' sessenta e quatro bytes substituindo a confiança cega.
#'
#' @param url Endereço do arquivo.
#' @param fonte Slug da fonte, no formato `"<dimensao>/<fonte>"`.
#' @param arquivo Nome local, sem data nem versão. NULL usa o basename da URL.
#' @param versao_fonte Versão declarada pelo produtor.
#' @param forcar Se TRUE, rebaixa mesmo que o arquivo já exista.
#' @param modo "wb" para binário, "w" para texto.
#' @return Invisivelmente, o caminho do arquivo baixado.
mape_baixar <- function(url, fonte, arquivo = NULL, versao_fonte = NA_character_,
                        forcar = FALSE, modo = "wb") {
  stopifnot(is.character(url), length(url) == 1)
  if (!grepl("/", fonte)) {
    stop("O slug da fonte precisa ter o formato '<dimensao>/<fonte>'. ",
         "Recebi: '", fonte, "'.", call. = FALSE)
  }
  if (is.null(arquivo)) {
    arquivo <- basename(sub("[?].*$", "", url))
    if (!nzchar(arquivo)) {
      stop("Não consegui deduzir o nome do arquivo a partir da URL. ",
           "Passe `arquivo` explicitamente.", call. = FALSE)
    }
  }

  raiz <- mape_caminho("fontes", fonte, "raw")
  dir.create(raiz, recursive = TRUE, showWarnings = FALSE)
  destino <- file.path(raiz, arquivo)

  if (file.exists(destino) && !forcar) {
    message("[", fonte, "] já existe: ", arquivo,
            " (", round(mape_mb(destino), 2), " MB). Use forcar = TRUE para rebaixar.")
  } else {
    message("[", fonte, "] baixando ", url)
    utils::download.file(url, destino, mode = modo, quiet = FALSE)
  }

  sha <- mape_sha256(destino)
  mape_registrar_manifesto(
    fonte = fonte, url = url, arquivo_local = arquivo,
    versao_fonte = versao_fonte, sha256 = sha,
    tamanho_mb = round(mape_mb(destino), 3))

  message("[", fonte, "] sha256: ", substr(sha, 1, 16), "...")
  invisible(destino)
}

#' Soma sha256 de um arquivo
#'
#' @param caminho Caminho do arquivo.
#' @return A soma em hexadecimal, ou NA se o pacote digest não estiver instalado.
mape_sha256 <- function(caminho) {
  if (!requireNamespace("digest", quietly = TRUE)) {
    warning("O pacote digest não está instalado; a procedência fica sem hash. ",
            "Instale com install.packages('digest').", call. = FALSE)
    return(NA_character_)
  }
  digest::digest(caminho, algo = "sha256", file = TRUE)
}

#' Escreve ou atualiza o MANIFESTO.yml de uma fonte
#'
#' @param fonte Slug da fonte.
#' @param ... Campos do manifesto.
#' @return Invisivelmente, o caminho do manifesto.
mape_registrar_manifesto <- function(fonte, ...) {
  campos <- list(...)
  destino <- mape_caminho("fontes", fonte, "MANIFESTO.yml")
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)

  atual <- if (file.exists(destino)) {
    tryCatch(yaml::read_yaml(destino), error = function(e) list())
  } else list()

  atual$fonte <- basename(fonte)
  atual$dimensao <- dirname(fonte)
  for (nm in names(campos)) atual[[nm]] <- campos[[nm]]
  atual$data_download <- format(Sys.Date(), "%Y-%m-%d")

  yaml::write_yaml(atual, destino)
  invisible(destino)
}

#' Cria o esqueleto de uma fonte nova
#'
#' Gera a pasta, os dois scripts com o encadeamento padrão, o manifesto e o
#' README inicial. Nada aqui é opcional por acaso: cada arquivo criado
#' corresponde a um passo que, quando fica para depois, não é feito. As 51
#' descrições vazias do dicionário antigo são o que acontece quando o passo de
#' documentar não está no caminho de menor resistência.
#'
#' @param dimensao Slug da dimensão, já existente em `dicionario/dimensoes.csv`.
#' @param fonte Nome da fonte em snake_case, sem acento.
#' @param metodo_acesso `bigquery`, `pacote_r`, `download_manual`, `api` ou
#'   `arquivo_local`.
#' @param sobrescrever Se TRUE, reescreve arquivos que já existam.
#' @return Invisivelmente, o caminho da pasta criada.
#' @examples
#' \dontrun{
#' mape_nova_fonte("03_meio_ambiente", "mapbiomas_cobertura")
#' }
mape_nova_fonte <- function(dimensao, fonte,
                            metodo_acesso = c("bigquery", "download_manual",
                                              "pacote_r", "api", "arquivo_local"),
                            sobrescrever = FALSE) {
  metodo_acesso <- match.arg(metodo_acesso)

  dims <- mape_dicionario("dimensoes")
  col_slug <- intersect(c("slug", "slug_dimensao", "dimensao"), names(dims))[1]
  if (!is.na(col_slug) && !dimensao %in% dims[[col_slug]]) {
    stop("Dimensão '", dimensao, "' não está em dicionario/dimensoes.csv.\n",
         "Dimensões conhecidas: ", paste(dims[[col_slug]], collapse = ", "), "\n",
         "Para criar uma dimensão nova, acrescente a linha lá primeiro — a ",
         "numeração é só de acréscimo, nunca se renumera.", call. = FALSE)
  }
  if (!grepl("^[a-z][a-z0-9_]*$", fonte)) {
    stop("O nome da fonte deve ser snake_case sem acento e começar por letra. ",
         "Recebi: '", fonte, "'.", call. = FALSE)
  }

  slug <- paste0(dimensao, "/", fonte)
  pasta <- mape_caminho("fontes", slug)
  dir.create(file.path(pasta, "R"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(pasta, "raw"), recursive = TRUE, showWarnings = FALSE)

  escrever <- function(caminho, linhas) {
    if (file.exists(caminho) && !sobrescrever) {
      message("já existe, não toquei: ", sub(paste0("^", mape_caminho()), "", caminho))
      return(invisible(FALSE))
    }
    writeLines(linhas, caminho, useBytes = TRUE)
    message("criado: ", sub(paste0("^", mape_caminho(), "/"), "", caminho))
    invisible(TRUE)
  }

  # --- extrair_ -------------------------------------------------------------
  bloco_extracao <- switch(
    metodo_acesso,
    bigquery = c(
      "  # A consulta SEMPRE filtra. Uma varredura nacional sem filtro custa",
      "  # dinheiro de verdade: a do SICONFI no legado baixa 18,5 milhões de linhas.",
      "  bruto <- mape_query(\"",
      "    SELECT id_municipio, ano, /* ... */",
      "    FROM `basedosdados.br_orgao_tabela`",
      "    WHERE ano >= 2000",
      "  \")"),
    download_manual = c(
      "  # Download manual: o arquivo precisa estar em raw/, e o manifesto",
      "  # registra de onde ele veio. mape_verificar_raw() confere o sha256 e",
      "  # falha se o arquivo na pasta não for o arquivo declarado.",
      "  arquivo <- mape_verificar_raw(FONTE, \"ARQUIVO.xlsx\")",
      "  bruto <- readxl::read_excel(arquivo)"),
    pacote_r = c(
      "  bruto <- algum_pacote::alguma_funcao()"),
    api = c(
      "  resposta <- httr::GET(\"https://...\")",
      "  bruto <- jsonlite::fromJSON(httr::content(resposta, \"text\"))"),
    arquivo_local = c(
      "  arquivo <- mape_verificar_raw(FONTE, \"ARQUIVO.csv\")",
      "  bruto <- utils::read.csv(arquivo, stringsAsFactors = FALSE)")
  )

  escrever(file.path(pasta, "R", paste0("extrair_", fonte, ".R")), c(
    paste0("# Extração — ", slug),
    "#",
    "# Obtém o dado bruto e grava em raw/. Não limpa, não renomeia, não valida:",
    "# isso é trabalho do tratar_. Separar os dois é o que permite reprocessar",
    "# sem rebaixar, e rebaixar sem reprocessar.",
    "",
    paste0("FONTE <- \"", slug, "\""),
    "",
    paste0("extrair_", fonte, " <- function() {"),
    bloco_extracao,
    "",
    "  destino <- mape_caminho(\"fontes\", FONTE, \"raw\", \"bruto.parquet\")",
    "  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)",
    "  arrow::write_parquet(bruto, destino)",
    "  message(\"[\", FONTE, \"] extraído: \", nrow(bruto), \" linhas\")",
    "  invisible(destino)",
    "}",
    ""))

  # --- tratar_ --------------------------------------------------------------
  escrever(file.path(pasta, "R", paste0("tratar_", fonte, ".R")), c(
    paste0("# Tratamento — ", slug),
    "#",
    "# O encadeamento é sempre o mesmo, e a ordem importa:",
    "#",
    "#   limpar cabeçalho -> renomear pelo dicionário -> normalizar chaves ->",
    "#   converter sentinelas -> validar -> publicar",
    "#",
    "# Renomear antes de normalizar as chaves seria erro: a normalização procura",
    "# as colunas pelos nomes canônicos.",
    "",
    paste0("FONTE <- \"", slug, "\""),
    "",
    paste0("tratar_", fonte, " <- function() {"),
    "  bruto <- arrow::read_parquet(",
    "    mape_caminho(\"fontes\", FONTE, \"raw\", \"bruto.parquet\"))",
    "",
    "  x <- janitor::clean_names(as.data.frame(bruto))",
    "  x <- mape_aplicar_renomeacao(x, FONTE)",
    "  x <- mape_normalizar_chaves(x)",
    "  x <- mape_tratar_sentinelas(x)",
    "",
    "  # Linha de chave nula sai AQUI, na origem, antes de qualquer conferência",
    "  # de unicidade. Inverter a ordem foi o que fez o legado publicar linhas",
    "  # sem município.",
    "  x <- x[!is.na(x$id_municipio), , drop = FALSE]",
    "",
    "  mape_validar_chave(x, intersect(c(\"id_municipio\", \"ano\"), names(x)))",
    "  mape_validar_tabela(x, FONTE)",
    "  mape_escrever_tabela(x, FONTE, camada = \"fonte\")",
    "  mape_gerar_documentacao(FONTE)",
    "  invisible(x)",
    "}",
    ""))

  # --- MANIFESTO ------------------------------------------------------------
  manifesto <- file.path(pasta, "MANIFESTO.yml")
  if (!file.exists(manifesto) || sobrescrever) {
    writeLines(c(
      paste0("fonte: ", fonte),
      paste0("dimensao: ", dimensao),
      "orgao: PREENCHER",
      "url: PREENCHER            # obrigatorio; se nao houver, escreva 'indisponivel' e justifique",
      "arquivo_local: ~          # sem data no nome: a data vive aqui",
      "versao_fonte: ~",
      "data_download: ~",
      "baixado_por: ~",
      "sha256: ~",
      "licenca: a verificar",
      paste0("automatizavel: ",
             if (metodo_acesso %in% c("bigquery", "api", "pacote_r")) "sim" else "nao"),
      "nota: ~"
    ), manifesto, useBytes = TRUE)
    message("criado: ", sub(paste0("^", mape_caminho(), "/"), "", manifesto))
  }

  # --- README ---------------------------------------------------------------
  escrever(file.path(pasta, "README.md"), c(
    paste0("# ", slug), "",
    "> Este README é provisório. Depois que a tabela for publicada, ele passa a",
    "> ser **gerado** por `mape_gerar_documentacao()` a partir do dicionário, e",
    "> não deve mais ser editado à mão.", "",
    "## O que falta para publicar esta fonte", "",
    "1. Preencher `MANIFESTO.yml` — sem `url` e `licenca` a validação avisa.",
    paste0("2. Escrever a extração em `R/extrair_", fonte, ".R`."),
    paste0("3. Escrever o tratamento em `R/tratar_", fonte, ".R`."),
    "4. Registrar a tabela em `dicionario/tabelas.csv`:", "",
    "   ```r",
    "   mape_registrar_tabela(",
    paste0("     slug = \"", slug, "\","),
    paste0("     dimensao = \"", dimensao, "\","),
    "     nome_publicado = \"...\",",
    "     descricao = \"...\",",
    "     chave_primaria = \"id_municipio, ano\",",
    "     granularidade = \"municipio x ano\",",
    paste0("     metodo_acesso = \"", metodo_acesso, "\","),
    "     fonte_original = \"...\",",
    "     fonte_extracao = \"...\"",
    "   )",
    "   ```", "",
    "5. Registrar as variáveis em `dicionario/variaveis.csv`. **Sem isso o build",
    "   falha** — e é essa mecânica que impede a documentação de ficar para depois.",
    "",
    "   Cada variável precisa de `nome_canonico`, `nome_na_fonte`, `descricao`,",
    "   `unidade`, `escala` e `tipo`. O nome canônico segue",
    "   `[<prefixo_fonte>_]<conceito>[_<qualificador>]_<sufixo>`, com o sufixo",
    "   saindo do vocabulário fechado: `_i` contagem, `_pct` 0 a 100, `_prop`",
    "   0 a 1, `_razao` quociente que pode passar de 1, `_p100k` e `_p1k` taxas,",
    "   `_brl_nominal` e `_brl2023` dinheiro, `_km2`, `_idx`, `_cat`.",
    "",
    "6. Acrescentar a fonte à consolidação da dimensão e rodar:", "",
    "   ```bash",
    paste0("   Rscript -e 'targets::tar_make(fonte_", gsub("/", "_", slug), ")'"),
    "   ```", ""))

  message("\nfonte criada em fontes/", slug,
          "\nleia o README.md de lá: ele lista os seis passos que faltam.")
  invisible(pasta)
}
