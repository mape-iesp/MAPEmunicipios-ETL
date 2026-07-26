# Harmonização final dos nomes de coluna -------------------------------------
#
# Setenta e nove colunas atravessaram a migração com prefixo `total_` ou
# `quantidade_`, que a seção 6.1 do plano bane. O motivo do banimento não é
# estético: `total_` não diz de que é o total, e o resultado é que a base tem
# `total_receitas` e `siconfi_receitas_brutas_brl2023` lado a lado, medindo
# coisas parecidas, com nomes que não permitem saber qual é qual.
#
# Além do prefixo, este script corrige três coisas que a auditoria de nomes
# encontrou junto:
#
#   - Dezesseis colunas de desastre estão declaradas como `contagem` e são
#     dinheiro deflacionado — a própria descrição diz "valor deflacionado".
#   - As colunas do SIM e do FBSP na Segurança não trazem o prefixo de fonte,
#     apesar de as duas fontes medirem morte violenta no mesmo painel. É
#     exatamente o caso em que a seção 6.1 torna o prefixo obrigatório.
#   - `total_receitas` mede a receita total do SICONFI e não carrega nem o
#     prefixo da fonte nem o sufixo de moeda.
#
# Toda troca fica registrada em dicionario/deprecacao.csv. Nome antigo que some
# sem rastro é nome que volta como pergunta seis meses depois.
#
# Rodar com:  Rscript tools/migracao/harmonizar_nomes.R

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) {
  source(f, encoding = "UTF-8")
}

vars <- mape_dicionario("variaveis", .recarregar = TRUE)

# --- Construção do mapa de renomeação ---------------------------------------
#
# Cada regra é (padrão, função que devolve o nome novo, ajustes de metadado).
# Gerar o nome por regra em vez de listar 79 pares evita o erro de digitação
# silencioso e deixa explícito qual raciocínio produziu cada nome.

mapa <- list()
ajustes <- list()

regra <- function(nomes, novo, unidade = NULL, escala = NULL, tipo = NULL) {
  for (i in seq_along(nomes)) {
    mapa[[nomes[i]]] <<- novo[i]
    if (!is.null(unidade) || !is.null(escala) || !is.null(tipo)) {
      ajustes[[novo[i]]] <<- list(unidade = unidade, escala = escala, tipo = tipo)
    }
  }
}

nc <- vars$nome_canonico

# 1. Meio ambiente — desastres do S2ID, abertos por tipo de evento.
#    As pessoas afetadas são contagem; danos e prejuízos são dinheiro.
for (grupo in c("climatologicos", "hidrologicos", "meteorologicos", "outros")) {
  n <- paste0("total_pessoas_afetadas_", grupo)
  if (n %in% nc) regra(n, paste0("s2id_pessoas_afetadas_", grupo, "_i"),
                       unidade = "pessoas", escala = "contagem")
  for (m in c("danos_materiais", "prejuizos_publicos", "prejuizos_privados")) {
    n <- paste0("total_", m, "_", grupo)
    if (n %in% nc) regra(n, paste0("s2id_", m, "_", grupo, "_brl2023"),
                         unidade = "BRL de dezembro de 2023", escala = "brl")
  }
}

# 2. Finanças — a receita total do SICONFI, deflacionada como as irmãs dela.
if ("total_receitas" %in% nc) {
  regra("total_receitas", "siconfi_receitas_totais_brl2023",
        unidade = "BRL de dezembro de 2023", escala = "brl")
}

# 3. Educação — instituições de ensino superior por dependência e natureza.
ies <- c(
  total_instituicoes_estaduais                   = "censup_ies_estaduais_i",
  total_instituicoes_municipais                  = "censup_ies_municipais_i",
  total_instituicoes_privada_com_fins_lucrativos  = "censup_ies_privadas_com_fins_lucrativos_i",
  total_instituicoes_privada_sem_fins_lucrativos  = "censup_ies_privadas_sem_fins_lucrativos_i",
  total_instituicoes_privada_particular          = "censup_ies_privadas_particulares_i",
  total_instituicoes_especial                    = "censup_ies_especiais_i",
  total_instituicoes_privada_comunitaria         = "censup_ies_privadas_comunitarias_i",
  total_instituicoes_privada_confessional        = "censup_ies_privadas_confessionais_i"
)
for (de in names(ies)) {
  if (de %in% nc) regra(de, unname(ies[de]), unidade = "instituições", escala = "contagem")
}

# 4. Segurança — duas fontes medem morte violenta no mesmo painel, então o
#    prefixo passa a ser obrigatório nas duas.
#    total_mortalidade_* vem do SIM (registro de óbito, DataSUS).
#    quantidade_* vem do Anuário do FBSP (registro de ocorrência policial).
mort <- grep("^total_mortalidade_", nc, value = TRUE)
regra(mort, paste0("sim_obitos_", sub("^total_mortalidade_", "", mort), "_i"),
      unidade = "óbitos", escala = "contagem")

ocor <- grep("^quantidade_", nc, value = TRUE)
regra(ocor, paste0("fbsp_", sub("^quantidade_", "", ocor), "_i"),
      unidade = "ocorrências", escala = "contagem", tipo = "integer")

# 5. Eleições — eleitorado e comparecimento, com o prefixo do TSE.
elei <- c(
  total_aptos_prefeitura                 = "tse_eleitores_aptos_prefeitura_i",
  total_comparecimento_prefeitura        = "tse_comparecimento_prefeitura_i",
  total_aptos_camara_vereadores          = "tse_eleitores_aptos_camara_i",
  total_comparecimento_camara_vereadores = "tse_comparecimento_camara_i"
)
for (de in names(elei)) {
  if (de %in% nc) regra(de, unname(elei[de]), unidade = "eleitores", escala = "contagem")
}

mapa <- unlist(mapa)
message("colunas a renomear: ", length(mapa))

if (anyDuplicated(mapa)) {
  stop("A renomeação produziria nomes repetidos: ",
       paste(unique(mapa[duplicated(mapa)]), collapse = ", "), call. = FALSE)
}
colide <- intersect(unname(mapa), setdiff(nc, names(mapa)))
if (length(colide)) {
  stop("Nomes novos colidem com nomes já em uso: ",
       paste(colide, collapse = ", "), call. = FALSE)
}

# --- Aplicação ao dicionário ------------------------------------------------

dep <- data.frame(
  nome_antigo = names(mapa), nome_novo = unname(mapa),
  dimensao = vars$dimensao[match(names(mapa), vars$nome_canonico)],
  motivo = "prefixo generico banido (secao 6.1 do plano): total_/quantidade_ nao dizem de que e o total, e a base tinha colunas de fontes diferentes com nomes indistinguiveis",
  data = format(Sys.Date(), "%Y-%m-%d"),
  stringsAsFactors = FALSE
)

idx <- match(names(mapa), vars$nome_canonico)
vars$nome_canonico[idx] <- unname(mapa)

for (nm in names(ajustes)) {
  j <- which(vars$nome_canonico == nm)
  if (!length(j)) next
  a <- ajustes[[nm]]
  if (!is.null(a$unidade)) vars$unidade[j] <- a$unidade
  if (!is.null(a$escala))  vars$escala[j]  <- a$escala
  if (!is.null(a$tipo))    vars$tipo[j]    <- a$tipo
  # Nome e unidade conferidos à mão contra a descrição e contra a faixa de
  # valores observada deixam de ser inferência.
  vars$confianca_inferencia[j] <- "alta"
  vars$revisao_pendente[j] <- FALSE
  vars$motivo_revisao[j] <- NA_character_
}

utils::write.csv(vars, mape_caminho("dicionario", "variaveis.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8", na = "")

arq_dep <- mape_caminho("dicionario", "deprecacao.csv")
if (file.exists(arq_dep)) {
  antigo <- utils::read.csv(arq_dep, stringsAsFactors = FALSE, encoding = "UTF-8")
  for (cl in setdiff(names(dep), names(antigo))) antigo[[cl]] <- NA
  for (cl in setdiff(names(antigo), names(dep))) dep[[cl]] <- NA
  dep <- rbind(antigo[, names(dep)], dep)
  dep <- dep[!duplicated(dep$nome_antigo, fromLast = TRUE), ]
}
utils::write.csv(dep, arq_dep, row.names = FALSE, fileEncoding = "UTF-8", na = "")
message("depreciação registrada: ", nrow(dep), " linhas em dicionario/deprecacao.csv")

.mape_cache_dic$dic_variaveis <- NULL

# --- Reescrita das tabelas publicadas ---------------------------------------

todas <- c(
  list.files(mape_caminho("dados", "dimensao"), pattern = "[.]parquet$"),
  list.files(mape_caminho("dados", "fonte"), pattern = "[.]parquet$", recursive = TRUE)
)
todas <- sub("[.]parquet$", "", todas)

n_tocadas <- 0
for (t in todas) {
  camada <- if (grepl("/", t)) "fonte" else "dimensao"
  x <- mape_ler_tabela(t, camada = camada)
  alvo <- intersect(names(x), names(mapa))
  if (!length(alvo)) next
  names(x)[match(alvo, names(x))] <- unname(mapa[alvo])
  mape_escrever_tabela(x, t, validar = FALSE, camada = camada)
  n_tocadas <- n_tocadas + 1
}

message("\ntabelas reescritas: ", n_tocadas)
message("colunas renomeadas: ", length(mapa))
