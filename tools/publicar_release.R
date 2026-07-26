# Empacotamento do release ---------------------------------------------------
#
# Monta a pasta que vira um release do GitHub. É o único ponto de contato entre
# este repositório e o pacote MAPEmunicipios: o ETL escreve aqui, o pacote lê
# daqui, e nada mais atravessa a fronteira.
#
# O release leva três coisas, e a terceira é a que faz diferença:
#
#   - uma tabela por arquivo, em Parquet e em csv.gz;
#   - o dicionário inteiro, para que o pacote saiba tipo, unidade e domínio de
#     cada coluna sem precisar embutir uma cópia que envelhece;
#   - um SHA256SUMS.txt e um manifesto em JSON com contagens medidas.
#
# Sem o dicionário junto, uma variável nova só apareceria para quem usa o pacote
# depois de uma nova versão do pacote. Com ele, aparece no dia seguinte à
# publicação do release.
#
# Rodar com:
#   Rscript tools/publicar_release.R              # monta em dist/
#   Rscript tools/publicar_release.R v1.0.0       # monta e mostra o comando do gh

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) {
  source(f, encoding = "UTF-8")
}

args <- commandArgs(trailingOnly = TRUE)
versao <- if (length(args)) args[1] else
  paste0("v0.0.0-", format(Sys.Date(), "%Y%m%d"))

# PORTAO DE PUBLICACAO — achado 22, item 5 da auditoria de 26/07/2026.
#
# "Erro impede a publicacao, sem excecao" era falso em todos os caminhos de
# escrita, e tambem aqui: este script empacotava qualquer coisa que estivesse em
# dados/, sem olhar a validacao. Um release e a saida mais publica do
# repositorio; e o ultimo lugar onde faz sentido nao conferir.
#
# Erro reivindicado em qa/erros_aceitos.csv nao bloqueia — e para isso que o
# arquivo existe. Erro nao reivindicado bloqueia.
message("Conferindo a validacao das tabelas antes de empacotar...")
.tabs <- mape_tabelas_publicadas()
.bloqueios <- list()
for (.i in seq_len(nrow(.tabs))) {
  .x <- as.data.frame(mape_ler_tabela(.tabs$slug[.i], camada = .tabs$camada[.i]))
  .r <- tryCatch(
    suppressMessages(suppressWarnings(
      mape_validar_tabela(.x, .tabs$slug[.i], erro = FALSE, gravar = FALSE))),
    error = function(e) NULL)
  if (is.null(.r) || !nrow(.r)) next
  .e <- .r[.r$gravidade == "erro", , drop = FALSE]
  if (nrow(.e)) .bloqueios[[length(.bloqueios) + 1]] <- .e
}
if (length(.bloqueios)) {
  .b <- do.call(rbind, .bloqueios)
  stop("Release BARRADO: ", nrow(.b), " erro(s) de validacao nao reivindicado(s).\n",
       paste0("  - ", .b$tabela, " / ", .b$checagem, ": ",
              substr(.b$descricao, 1, 140), collapse = "\n"),
       "\n\nConserte o dado, ou reivindique o erro em qa/erros_aceitos.csv com ",
       "justificativa.\nRode `Rscript tools/validar_tudo.R` para o quadro completo.",
       call. = FALSE)
}
message("  ok: nenhum erro nao reivindicado nas ", nrow(.tabs), " tabelas.\n")

dist <- mape_caminho("dist", versao)
unlink(dist, recursive = TRUE)
dir.create(file.path(dist, "dados"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(dist, "dicionario"), recursive = TRUE, showWarnings = FALSE)

pub <- mape_tabelas_publicadas()
message("empacotando ", nrow(pub), " tabela(s) em ", dist)

# --- Tabelas ----------------------------------------------------------------
#
# O nome do arquivo no release achata a barra do slug em duplo sublinhado.
# Release do GitHub não tem pastas, e `03_meio_ambiente__adaptabrasil.parquet`
# permite reconstruir o slug sem ambiguidade.
inventario <- list()
for (i in seq_len(nrow(pub))) {
  slug <- pub$slug[i]
  plano <- gsub("/", "__", slug)
  x <- mape_ler_tabela(slug, camada = pub$camada[i])

  for (fmt in c("parquet", "csv.gz")) {
    origem <- mape_caminho_tabela(slug, fmt, pub$camada[i])
    if (!file.exists(origem)) next
    file.copy(origem, file.path(dist, "dados", paste0(plano, ".", fmt)),
              overwrite = TRUE)
  }

  inventario[[length(inventario) + 1]] <- data.frame(
    slug = slug, arquivo = paste0(plano, ".parquet"), camada = pub$camada[i],
    linhas = nrow(x), colunas = ncol(x),
    municipios = length(unique(x$id_municipio)),
    ano_min = if ("ano" %in% names(x)) min(x$ano, na.rm = TRUE) else NA_integer_,
    ano_max = if ("ano" %in% names(x)) max(x$ano, na.rm = TRUE) else NA_integer_,
    mb = round(mape_mb(mape_caminho_tabela(slug, "parquet", pub$camada[i])), 3),
    stringsAsFactors = FALSE)
}
inv <- do.call(rbind, inventario)

# --- Dicionário -------------------------------------------------------------
for (arq in list.files(mape_caminho("dicionario"), pattern = "[.](csv|md)$",
                       full.names = TRUE)) {
  file.copy(arq, file.path(dist, "dicionario", basename(arq)), overwrite = TRUE)
}
# Achado 45: o release publicava as 26 tabelas como CC BY 4.0 enquanto todas
# estavam sob `licenca = "a verificar"`, e o LICENSE-DADOS prometido nao existia.
# Ele embarca aqui, e traz as tres pendencias substantivas por escrito.
if (file.exists(mape_caminho("LICENSE-DADOS"))) {
  file.copy(mape_caminho("LICENSE-DADOS"), file.path(dist, "LICENSE-DADOS"),
            overwrite = TRUE)
  message("  LICENSE-DADOS embarcado")
}


# --- Inventário e manifesto -------------------------------------------------
utils::write.csv(inv, file.path(dist, "INVENTARIO.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")

manifesto <- list(
  versao = versao,
  gerado_em = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  painel = list(ano_inicio = mape_anos_painel()[1],
                ano_fim = utils::tail(mape_anos_painel(), 1),
                municipios = nrow(mape_ler_tabela("00_diretorios/municipios"))),
  tabelas = nrow(inv),
  tabelas_dimensao = sum(inv$camada == "dimensao"),
  tabelas_fonte = sum(inv$camada == "fonte"),
  variaveis = nrow(mape_dicionario("variaveis")),
  chave = list(id_municipio = "character de 7 digitos", ano = "integer"),
  licenca_dados = "CC BY 4.0, condicionada pelas licencas das fontes",
  repositorio_etl = "https://github.com/mape-iesp/MAPEmunicipios-ETL"
)
writeLines(jsonlite::toJSON(manifesto, auto_unbox = TRUE, pretty = TRUE),
           file.path(dist, "manifesto.json"), useBytes = TRUE)

# --- Somas de verificação ---------------------------------------------------
#
# O que o sha256 garante aqui não é integridade contra adversário: é conseguir
# provar, seis meses depois, que o arquivo que alguém baixou é o arquivo que
# foi publicado. É a mesma garantia que o manifesto de cada fonte dá para o
# dado bruto, pelo mesmo custo de 64 bytes.
arquivos <- list.files(dist, recursive = TRUE, full.names = TRUE)
arquivos <- arquivos[basename(arquivos) != "SHA256SUMS.txt"]
somas <- vapply(arquivos, function(a) {
  paste0(mape_sha256(a), "  ", sub(paste0("^", dist, "/"), "", a))
}, character(1))
writeLines(sort(unname(somas)), file.path(dist, "SHA256SUMS.txt"), useBytes = TRUE)

# --- Nota do release --------------------------------------------------------
fmt <- function(n) formatC(n, format = "d", big.mark = ".", decimal.mark = ",")
d <- inv[inv$camada == "dimensao", ]
f <- inv[inv$camada == "fonte", ]

writeLines(c(
  paste0("# MAPEmunicipios — dados ", versao), "",
  paste0("Painel de ", fmt(manifesto$painel$municipios), " municípios brasileiros, ",
         manifesto$painel$ano_inicio, "-", manifesto$painel$ano_fim, ", em ",
         nrow(inv), " tabelas."), "",
  "## Como usar", "", "```r",
  '# install.packages("remotes")',
  'remotes::install_github("mape-iesp/MAPEmunicipios")',
  "library(MAPEmunicipios)", "",
  'saude <- mape_ler("saude")',
  'mape_variaveis("homicidio")',
  "```", "",
  "Quem prefere baixar direto pode pegar qualquer `.parquet` ou `.csv.gz` desta",
  "página. O `SHA256SUMS.txt` confere a integridade do download.", "",
  "## Chave", "",
  "`id_municipio` é **texto de sete dígitos** e `ano` é inteiro. O código do",
  "IBGE é identificador, não quantidade: lê-lo como número perde o zero à",
  "esquerda de todo município do Acre, de Alagoas e do Amazonas.", "",
  "## Tabelas de dimensão", "",
  "O painel município × ano de cada tema.", "",
  "| tabela | linhas | colunas | municípios | anos |",
  "|---|---|---|---|---|",
  # Achado 97: aqui a linha de 15_dados_historicos saía como "NA-NA", porque a
  # tabela é transversal e não tem `ano`. A linha 144, para as fontes, já
  # tratava o caso; esta não.
  paste0("| `", d$slug, "` | ", fmt(d$linhas), " | ", d$colunas, " | ",
         fmt(d$municipios), " | ",
         ifelse(is.na(d$ano_min), "—", paste0(d$ano_min, "-", d$ano_max)), " |"), "",
  "## Tabelas de fonte", "",
  "O dado **como foi observado**, na granularidade nativa. Onde a dimensão",
  "repete a mesma medição em vários anos para preencher o painel, a fonte",
  "guarda a medição uma vez só.", "",
  "| tabela | linhas | colunas | municípios | anos |",
  "|---|---|---|---|---|",
  paste0("| `", f$slug, "` | ", fmt(f$linhas), " | ", f$colunas, " | ",
         fmt(f$municipios), " | ",
         ifelse(is.na(f$ano_min), "—", paste0(f$ano_min, "-", f$ano_max)), " |"), "",
  "## Ressalvas conhecidas", "",
  "Duas tabelas têm chave duplicada herdada da fonte, e as duas estão",
  "documentadas em `qa/`:", "",
  "- **`06_financas`** — 222 chaves duplicadas, porque as emendas parlamentares",
  "  são associadas ao município por nome e sem UF. Corrigir exige reprocessar a",
  "  fonte com junção por código.",
  "- **`15_dados_historicos`** — 54 municípios do Tocantins aparecem duas vezes,",
  "  com o registro anterior e o posterior a 1988. As duplicatas foram mantidas",
  "  de propósito, para que o problema fique visível.", "",
  "As coberturas vacinais do SI-PNI passam de 100% em vários municípios, uma",
  "delas chegando a 51.175%. A causa é o denominador da população-alvo,",
  "subestimado, e a ausência de truncamento na fonte. Os valores foram mantidos",
  "como a fonte publica.", "",
  "## Licença", "",
  "Dados sob CC BY 4.0, condicionada pelas licenças das fontes. Três precisam de",
  "verificação antes de qualquer uso comercial: IEPS Data, Anuário do FBSP e o",
  "pacote de replicação de Kustov & Pardelli.", "",
  paste0("_Gerado por `tools/publicar_release.R` em ",
         format(Sys.time(), "%Y-%m-%d %H:%M"), "._"), ""
), file.path(dist, "NOTA-DO-RELEASE.md"), useBytes = TRUE)

total_mb <- round(sum(vapply(list.files(dist, recursive = TRUE, full.names = TRUE),
                             mape_mb, numeric(1))), 1)

message("\n=========================================================")
message("release montado: ", dist)
message("  tabelas:  ", nrow(inv), " (", sum(inv$camada == "dimensao"),
        " dimensão, ", sum(inv$camada == "fonte"), " fonte)")
message("  arquivos: ", length(list.files(dist, recursive = TRUE)))
message("  tamanho:  ", total_mb, " MB")
message("=========================================================")
message("\nPara publicar:\n")
message("  gh release create ", versao, " \\")
message("    --title 'MAPEmunicipios — dados ", versao, "' \\")
message("    --notes-file ", file.path(dist, "NOTA-DO-RELEASE.md"), " \\")
message("    ", dist, "/dados/* \\")
message("    ", dist, "/dicionario/* \\")
message("    ", dist, "/INVENTARIO.csv ", dist, "/manifesto.json ",
        dist, "/SHA256SUMS.txt\n")
