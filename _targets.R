# Grafo de dependências do MAPEmunicipios ------------------------------------
#
# Roda com:
#   targets::tar_make()                          # tudo que estiver desatualizado
#   targets::tar_make(fonte_00_diretorios_municipios)   # uma fonte só
#   targets::tar_visnetwork()                    # desenha o grafo
#   targets::tar_outdated()                      # lista o que rodaria
#
# Por que targets e não um script mestre numerado: ele não re-executa o que não
# mudou. Com cerca de 28 consultas ao BigQuery no legado, várias sem filtro (a
# do SICONFI baixa 18,5 milhões de linhas, a do SIM varre o país inteiro),
# re-rodar tudo cegamente custa dinheiro real.
#
# Os alvos NÃO são escritos à mão: são gerados a partir de
# dicionario/tabelas.csv. Acrescentar uma fonte é acrescentar uma linha lá e um
# script tratar_<nome>.R — nunca editar este arquivo.
#
# Nomes de alvo, todos previsíveis a partir do slug da tabela:
#   fonte_<slug>   produz e publica a tabela de fonte
#   valida_<slug>  roda as checagens de qualidade sobre ela
#   dim_<slug>     consolida as fontes de uma dimensão
#   doc_<slug>     gera a documentação

library(targets)

tar_option_set(
  packages = c("arrow", "janitor", "yaml", "digest", "openxlsx", "dplyr"),
  format = "rds",
  error = "abridge"   # um alvo que falha não derruba os ramos independentes
)

# A camada de funções comuns e todos os scripts de tratamento das fontes.
tar_source("R")
for (f in list.files("fontes", pattern = "^tratar_.*[.]R$",
                     recursive = TRUE, full.names = TRUE)) {
  source(f, encoding = "UTF-8")
}

# ---------------------------------------------------------------------------
# Alvos gerados a partir do dicionário
# ---------------------------------------------------------------------------
caminho_tabelas <- "dicionario/tabelas.csv"
tabelas <- if (file.exists(caminho_tabelas)) {
  utils::read.csv(caminho_tabelas, stringsAsFactors = FALSE, encoding = "UTF-8")
} else {
  data.frame(slug_tabela = character(), stringsAsFactors = FALSE)
}

# Só entram no grafo as tabelas cujo script de tratamento existe. Uma linha no
# dicionário sem script é uma tabela planejada e ainda não migrada, e o grafo
# não deve quebrar por causa dela.
alvos_fonte <- list()
for (i in seq_len(nrow(tabelas))) {
  slug <- tabelas$slug_tabela[i]
  if (!grepl("/", slug)) next                     # tabela de dimensão, não de fonte
  nome_fonte <- basename(slug)
  fn <- paste0("tratar_", nome_fonte)
  if (!exists(fn)) next

  # Nome de alvo válido: barra e hífen não são aceitos como símbolo em R.
  alvo_fonte  <- paste0("fonte_",  gsub("[^A-Za-z0-9]", "_", slug))
  alvo_valida <- paste0("valida_", gsub("[^A-Za-z0-9]", "_", slug))

  alvos_fonte <- c(alvos_fonte, list(
    tar_target_raw(
      alvo_fonte,
      substitute({
        x <- FN()
        mape_escrever_tabela(x, SLUG)
        x
      }, list(FN = as.name(fn), SLUG = slug))
    ),
    tar_target_raw(
      alvo_valida,
      substitute(mape_validar_tabela(X, SLUG),
                 list(X = as.name(alvo_fonte), SLUG = slug))
    )
  ))
}

# ---------------------------------------------------------------------------
# Alvos de dimensão: consolidam as fontes de um tema.
#
# Só entra a dimensão que tem pelo menos duas fontes publicadas. Com uma fonte
# só, a "consolidação" seria uma cópia — e é justamente esse o caso de quatro
# dimensões do legado, em que o arquivo de dimensão é uma cópia manual do
# arquivo da subpasta.
# ---------------------------------------------------------------------------
alvos_dimensao <- list()
dimensoes_com_fonte <- unique(tabelas$dimensao[grepl("/", tabelas$slug_tabela)])
for (d in dimensoes_com_fonte) {
  fontes_d <- tabelas$slug_tabela[tabelas$dimensao == d & grepl("/", tabelas$slug_tabela)]
  publicadas <- fontes_d[file.exists(file.path("dados", "fonte",
                                               paste0(fontes_d, ".parquet")))]
  if (length(publicadas) < 2) next
  alvos_dimensao <- c(alvos_dimensao, list(
    tar_target_raw(
      paste0("dim_", gsub("[^A-Za-z0-9]", "_", d)),
      substitute(mape_consolidar_dimensao(D), list(D = d))
    )
  ))
}

# ---------------------------------------------------------------------------
# Documentação: um alvo por tabela publicada, mais o índice geral.
#
# A garantia de que a documentação não desatualiza é este alvo. Ele depende do
# dicionário, então mexer no dicionário sem regerar a documentação deixa o
# grafo desatualizado, e `tar_outdated()` diz isso.
# ---------------------------------------------------------------------------
alvos_doc <- list(
  tar_target(documentacao, {
    arquivo_dicionario; arquivo_tabelas    # dependência explícita
    mape_gerar_documentacao_completa()
  })
)

list(
  # O dicionário é entrada do pipeline: quando ele muda, tudo que depende dele
  # fica desatualizado. É isso que o torna especificação, e não subproduto.
  tar_target(arquivo_dicionario, "dicionario/variaveis.csv", format = "file"),
  tar_target(arquivo_tabelas,    "dicionario/tabelas.csv",   format = "file"),
  tar_target(arquivo_parametros, "config/parametros.yml",    format = "file"),

  alvos_fonte,
  alvos_dimensao,
  alvos_doc,

  # A base larga é derivada e não versionada: 66 MB que se reconstroem em um
  # comando. Ela continua existindo porque três scripts de análise e um artigo
  # dependem dela, e quebrar isso agora não traria ganho nenhum.
  tar_target(base_larga, {
    b <- mape_montar_base_larga(flags = TRUE, deduplicar = TRUE)
    mape_escrever_tabela(b, "base_larga", formatos = character(),
                         validar = FALSE, camada = "derivado")
    nrow(b)
  })
)
