# Registra a tabela 00_diretorios/municipios no dicionário -------------------
#
# Cada tabela migrada precisa de uma linha em dicionario/tabelas.csv e de uma
# linha por coluna em dicionario/variaveis.csv. Sem isso a validação recusa
# publicar — é essa mecânica que impede a documentação de ficar para depois,
# que é como as 34 descrições vazias de hoje surgiram.
#
# Uso:  Rscript tools/migracao/registrar_00_diretorios.R

for (f in list.files(here::here("R"), pattern = "[.]R$", full.names = TRUE)) {
  source(f, encoding = "UTF-8")
}

TABELA <- "00_diretorios/municipios"

# ---------------------------------------------------------------------------
# 1. A tabela
# ---------------------------------------------------------------------------
# Os campos digitados descrevem intenção; os calculados são preenchidos por
# mape_gerar_documentacao() e ficam em branco aqui de propósito.
linha_tabela <- data.frame(
  slug_tabela = TABELA,
  dimensao = "00_diretorios",
  nome_publicado = "Diretório de municípios",
  descricao = paste(
    "Tabela de referência com os 5.570 municípios brasileiros: equivalências",
    "entre os códigos usados por IBGE, TSE, Receita Federal e Banco Central,",
    "hierarquia territorial completa (região, UF, mesorregião, microrregião,",
    "regiões imediata, intermediária, metropolitana e de saúde), e o centróide.",
    "É a espinha do painel: nenhuma outra tabela publica o bloco territorial."),
  responsavel = NA_character_,
  fonte_original = "IBGE",
  fonte_extracao = "Base dos Dados",
  link = "https://basedosdados.org/dataset/br-bd-diretorios-brasil",
  licenca = "a verificar",
  licenca_url = NA_character_,
  periodicidade_fonte = "eventual",
  data_ultima_atualizacao_fonte = NA_character_,
  chave_primaria = "id_municipio",
  granularidade = "municipio (transversal, sem dimensão temporal)",
  metodo_acesso = "bigquery",
  script_ingestao = "fontes/00_diretorios/municipios/R/extrair_municipios.R",
  citacao_recomendada = paste(
    "IBGE, via Base dos Dados. Diretório de municípios brasileiros.",
    "Compilado no MAPEmunicipios."),
  regra_preenchimento_temporal = "nenhuma",
  cobertura_temporal_da_fonte = "atemporal",
  observacoes = paste(
    "Snapshot dos municípios existentes hoje. Não representa a divisão",
    "territorial de anos anteriores: em 1991 havia cerca de 4.491 municípios,",
    "e Mojuí dos Campos foi criado em 2013. Ver a decisão 3.2 do plano.",
    "Durante a migração a tabela foi produzida a partir do artefato herdado,",
    "sem reextração, conforme a seção 12.2 do plano."),
  stringsAsFactors = FALSE
)

caminho_tabelas <- here::here("dicionario", "tabelas.csv")
if (file.exists(caminho_tabelas)) {
  tabelas <- utils::read.csv(caminho_tabelas, stringsAsFactors = FALSE,
                             encoding = "UTF-8")
  tabelas <- tabelas[tabelas$slug_tabela != TABELA, , drop = FALSE]
  # Alinha as colunas antes de empilhar, para o caso de o schema ter crescido.
  faltando <- setdiff(names(linha_tabela), names(tabelas))
  for (nm in faltando) tabelas[[nm]] <- NA
  tabelas <- rbind(tabelas[, names(linha_tabela)], linha_tabela)
} else {
  tabelas <- linha_tabela
}
utils::write.csv(tabelas, caminho_tabelas, row.names = FALSE,
                 fileEncoding = "UTF-8", na = "")
message("tabelas.csv: ", nrow(tabelas), " tabela(s) registrada(s)")

# ---------------------------------------------------------------------------
# 2. As variáveis
# ---------------------------------------------------------------------------
# Quatro colunas mudam de nome em relação ao publicado hoje, e cada mudança tem
# um motivo verificável, registrado aqui e em deprecacao.csv.
renomeacoes <- c(
  nome           = "nome_municipio",
  capital_uf     = "flag_capital_uf",
  amazonia_legal = "flag_amazonia_legal",
  centroide      = "centroide_wkt"
)

vars <- utils::read.csv(here::here("dicionario", "variaveis.csv"),
                        stringsAsFactors = FALSE, encoding = "UTF-8")

alvo <- vars$dimensao == "00_diretorios" & !is.na(vars$dimensao)
message("variáveis da dimensão 00_diretorios: ", sum(alvo))

for (i in which(alvo)) {
  legado <- vars$nome_legado[i]
  if (legado %in% names(renomeacoes)) {
    vars$nome_canonico[i] <- unname(renomeacoes[legado])
  }
  vars$tabela[i] <- TABELA
}

# Tipos e escalas que agora são fato, não inferência: as duas flags passam a
# ser inteiro 0/1 no tratamento, então o dicionário declara isso.
for (nm in c("flag_capital_uf", "flag_amazonia_legal")) {
  j <- which(vars$nome_canonico == nm)
  if (length(j)) {
    vars$tipo[j] <- "integer"
    vars$escala[j] <- "binaria"
    vars$unidade[j] <- "booleano"
    vars$dominio_valido[j] <- "[0,1]"
    vars$confianca_inferencia[j] <- "alta"
    vars$revisao_pendente[j] <- FALSE
    vars$motivo_revisao[j] <- NA_character_
  }
}

# id_municipio e id_municipio_6 são texto por contrato, e obrigatórios.
for (nm in c("id_municipio", "id_municipio_6")) {
  j <- which(vars$nome_canonico == nm & vars$tabela == TABELA)
  if (length(j)) {
    vars$tipo[j] <- "character"
    vars$escala[j] <- "identificador"
    vars$unidade[j] <- "codigo"
    vars$confianca_inferencia[j] <- "alta"
    vars$revisao_pendente[j] <- FALSE
    vars$motivo_revisao[j] <- NA_character_
  }
}
vars$obrigatoria[vars$nome_canonico == "id_municipio" & vars$tabela == TABELA] <- TRUE

utils::write.csv(vars, here::here("dicionario", "variaveis.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8", na = "")

message("variaveis.csv atualizado: ", sum(vars$tabela == TABELA, na.rm = TRUE),
        " variáveis atribuídas a ", TABELA)
message("  ainda pendentes de revisão nessa tabela: ",
        sum(vars$revisao_pendente & vars$tabela == TABELA, na.rm = TRUE))
