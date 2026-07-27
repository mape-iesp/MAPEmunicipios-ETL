# Empacotamento do release ---------------------------------------------------
#
# Monta a pasta que vira um release do GitHub. É o único ponto de contato entre
# este repositório e o pacote MAPEmunicipios: o ETL escreve aqui, o pacote lê
# daqui, e nada mais atravessa a fronteira.
#
# O que o release leva, medido em dist/v1.0.0 em 26/07/2026 — 116 arquivos e
# 138,1 MB, dos quais 137,3 MB são as tabelas e 0,6 MB é todo o resto:
#
#   - as 26 tabelas, uma por arquivo, em Parquet e em csv.gz (52 arquivos);
#   - o dicionário inteiro: as cinco planilhas (`variaveis`, `tabelas`,
#     `dimensoes`, `proveniencia`, `deprecacao`) e o `README.md` gerado, para
#     que o pacote saiba tipo, unidade e domínio de cada coluna sem precisar
#     embutir uma cópia que envelhece;
#   - a documentação gerada, 52 arquivos .md soltos, com o caminho preservado —
#     16 `dados/dimensao/<slug>.md`, 10 `fontes/<dim>/<fonte>/README.md` e 26
#     `qa/<slug>.md`, um por tabela publicada;
#   - um `documentacao.tar.gz` de 71 KB com esses 52 mais o
#     `dicionario/README.md`, 53 ao todo. Release do GitHub não tem pastas, e
#     cada anexo é um arquivo solto: subir os dez `fontes/*/*/README.md` sem o
#     tarball os achataria num só nome. É o tarball que vai como anexo;
#   - `LICENSE-DADOS`, `INVENTARIO.csv`, `NOTA-DO-RELEASE.md`, `SHA256SUMS.txt`
#     e um `manifesto.json` com as contagens medidas na hora.
#
# Sem o dicionário junto, uma variável nova só apareceria para quem usa o pacote
# depois de uma nova versão do pacote. Com ele, aparece no dia seguinte à
# publicação do release.
#
# E sem a documentação gerada junto (achado 32), o release levava a especificação
# e nenhum relatório: os 26 links relativos do `dicionario/README.md` embarcado
# apontavam todos para arquivo ausente, e a seção "Defeitos declarados no
# dicionário" de `qa/<slug>.md` — que é onde os defeitos conhecidos ficam
# reunidos por tabela — não saía do repositório.
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

# --- Documentação gerada ----------------------------------------------------
#
# Achado 32: o release levava o dicionário e nenhum relatório. Duas
# consequências, as duas medidas antes da correção.
#
# A primeira é que o `dicionario/README.md` embarcado tem 26 links relativos —
# 16 para `../dados/dimensao/*.md` e 10 para `../fontes/<dim>/<fonte>/README.md`
# — e todos os 26 apontavam para arquivo ausente dentro do `dist`.
#
# A segunda é mais séria: os defeitos que o repositório declara vivem no campo
# `observacoes` de `dicionario/tabelas.csv`, no campo `problema` de
# `dicionario/variaveis.csv` e na seção "Defeitos declarados no dicionário" de
# `qa/<slug>.md`. Os dois primeiros iam no release; o terceiro, que é o que
# reúne tudo por tabela, não ia.
#
# Os três conjuntos entram preservando o caminho que os links esperam.
copiar_doc <- function(origem, destino_rel) {
  destino <- file.path(dist, destino_rel)
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  isTRUE(file.copy(origem, destino, overwrite = TRUE))
}
docs <- 0L
for (arq in list.files(mape_caminho("dados", "dimensao"), pattern = "[.]md$",
                       full.names = TRUE)) {
  docs <- docs + copiar_doc(arq, file.path("dados", "dimensao", basename(arq)))
}
raiz_fontes <- mape_caminho("fontes")
for (arq in list.files(raiz_fontes, pattern = "^README[.]md$",
                       recursive = TRUE, full.names = TRUE)) {
  docs <- docs + copiar_doc(
    arq, file.path("fontes", sub(paste0("^", raiz_fontes, "/"), "", arq)))
}
for (slug in pub$slug) {
  arq <- mape_caminho("qa", paste0(gsub("/", "__", slug), ".md"))
  if (file.exists(arq)) docs <- docs + copiar_doc(arq, file.path("qa", basename(arq)))
}
message("  ", docs, " documento(s) .md embarcado(s)")

# Um release do GitHub não tem pastas: cada anexo é um arquivo solto, e subir a
# árvore acima achataria os dez `fontes/*/*/README.md` num só nome. O tarball
# preserva os caminhos, e é ele que vai como anexo.
local({
  antes <- setwd(dist)
  on.exit(setwd(antes), add = TRUE)
  alvos <- c(file.path("dados", "dimensao"), "fontes", "qa",
             file.path("dicionario", "README.md"))
  alvos <- alvos[file.exists(alvos)]
  utils::tar("documentacao.tar.gz", alvos, compression = "gzip", tar = "internal")
})
message("  documentacao.tar.gz montado")

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

# --- Nota do release --------------------------------------------------------
fmt <- function(n) formatC(n, format = "d", big.mark = ".", decimal.mark = ",")
d <- inv[inv$camada == "dimensao", ]
f <- inv[inv$camada == "fonte", ]

# Achado 32: quantas tabelas declaram defeito é medido no dicionário, na hora, e
# não escrito à mão aqui. Escrever à mão é como o número sete circulou pelo
# repositório sem que ninguém o tivesse contado.
com_defeito <- pub$slug[vapply(pub$slug, function(s) {
  length(tryCatch(mape_defeitos_declarados(s), error = function(e) character())) > 0
}, logical(1))]

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
  # Achado 103: esta seção afirmava que ler `id_municipio` como número "perde o
  # zero à esquerda de todo município do Acre, de Alagoas e do Amazonas". É
  # falso, e a auditoria falsificou: nenhum município brasileiro tem zero à
  # esquerda, porque o primeiro dígito do código do IBGE é a região, de 1 a 5 —
  # os códigos do AC começam em 12, os de AL em 27 e os do AM em 13. O motivo
  # verdadeiro é outro, e a receita de leitura importa mais do que o motivo para
  # quem baixa o csv.gz e o lê cru, que é o público desta nota.
  "## Chave", "",
  "`id_municipio` é **texto de sete dígitos** e `ano` é inteiro. O código do",
  "IBGE é identificador, não quantidade: nada deveria somar, tirar média ou",
  "interpolar um código municipal, e o tipo é o que impede. Lê-lo como número",
  "ainda o converte para `double`, e aí a junção contra o Parquet, contra",
  "`00_diretorios__municipios` ou contra qualquer outra tabela daqui passa a",
  "falhar por diferença de tipo.", "",
  "O `.csv.gz` não carrega tipo, e tanto `read.csv()` quanto `readr::read_csv()`",
  "devolvem `id_municipio` como número. Declare o tipo na leitura:", "",
  "```r",
  'read.csv("10_saude.csv.gz", colClasses = c(id_municipio = "character"))',
  "",
  'readr::read_csv("10_saude.csv.gz",',
  '                col_types = readr::cols(id_municipio = readr::col_character()))',
  "```", "",
  "O `.parquet` não tem esse problema, porque preserva o tipo. Prefira-o sempre",
  "que puder.", "",
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
  "## Defeitos declarados", "",
  paste0("Estas duas não são as únicas. **", length(com_defeito), " das ",
         nrow(inv), " tabelas** deste release declaram pelo menos um"),
  "defeito ou limitação conhecida — no campo `observacoes` da tabela, em",
  "`dicionario/tabelas.csv`, ou no campo `problema` da variável, em",
  "`dicionario/variaveis.csv`. Os dois arquivos vão aqui.", "",
  "O relatório `qa/<slug>.md` de cada tabela também vai, dentro de",
  "`documentacao.tar.gz`, e reúne o que está declarado na seção **Defeitos",
  "declarados no dicionário**. Um relatório de checagens limpo não significa uma",
  "tabela sem defeito: as checagens não detectam o que não sabem procurar, e é",
  "por isso que o que se sabe fica escrito.", "",
  "**Leia o `qa/` da tabela antes de usá-la em análise.** As mais consequentes",
  "são `04_economia` (a série de PIB tem um fator de bloco e não está em reais",
  "de 2023), `06_financas` (receita inflada em uma ordem de grandeza, e colunas",
  "que publicam vazio como zero) e `13_seguranca` (códigos não municipais",
  "publicados, hoje marcados por `flag_codigo_nao_municipal`).", "",
  "## Licença", "",
  "Dados sob CC BY 4.0, condicionada pelas licenças das fontes. Três precisam de",
  "verificação antes de qualquer uso comercial: IEPS Data, Anuário do FBSP e o",
  "pacote de replicação de Kustov & Pardelli.", "",
  paste0("_Gerado por `tools/publicar_release.R` em ",
         format(Sys.time(), "%Y-%m-%d %H:%M"), "._"), ""
), file.path(dist, "NOTA-DO-RELEASE.md"), useBytes = TRUE)

# --- Somas de verificação ---------------------------------------------------
#
# O que o sha256 garante aqui não é integridade contra adversário: é conseguir
# provar, seis meses depois, que o arquivo que alguém baixou é o arquivo que
# foi publicado. É a mesma garantia que o manifesto de cada fonte dá para o
# dado bruto, pelo mesmo custo de 64 bytes.
#
# Este bloco roda por último de propósito. Antes ele vinha ANTES da nota do
# release, e a consequência era que o `NOTA-DO-RELEASE.md` — o único arquivo do
# release que é lido por gente, e o que carrega as ressalvas — era o único que
# ficava de fora do `SHA256SUMS.txt`.
arquivos <- list.files(dist, recursive = TRUE, full.names = TRUE)
arquivos <- arquivos[basename(arquivos) != "SHA256SUMS.txt"]
somas <- vapply(arquivos, function(a) {
  paste0(mape_sha256(a), "  ", sub(paste0("^", dist, "/"), "", a))
}, character(1))
writeLines(sort(unname(somas)), file.path(dist, "SHA256SUMS.txt"), useBytes = TRUE)

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
# `dados/*` deixou de servir: agora há uma subpasta `dados/dimensao/` com os
# .md, e o gh recusa diretório como anexo. Os glob dizem o formato.
message("    ", dist, "/dados/*.parquet ", dist, "/dados/*.csv.gz \\")
message("    ", dist, "/dicionario/*.csv ", dist, "/dicionario/README.md \\")
message("    ", dist, "/documentacao.tar.gz ", dist, "/LICENSE-DADOS \\")
message("    ", dist, "/INVENTARIO.csv ", dist, "/manifesto.json ",
        dist, "/SHA256SUMS.txt\n")
