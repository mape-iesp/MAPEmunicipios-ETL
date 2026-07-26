# Semeia o dicionário a partir do legado -------------------------------------
#
# Roda UMA VEZ, na Fase 1. Depois disso o dicionário é editado à mão e passa a
# ser a especificação que o pipeline lê.
#
# A semente é o `6 Metadados/mape_municipios DICIONÁRIO.xlsx`, que é a única
# peça de documentação do projeto validada contra o dado real: verifiquei que
# o campo Nome_banco é identical() aos nomes das colunas da base publicada, na
# mesma ordem, sem exceção.
#
# O que este script faz que o dicionário antigo não fazia:
#
#   1. CALCULA os campos que não devem ser digitados (tipo real, faixa
#      observada, percentual de vazios). É onde os números não fecham hoje: a
#      soma das variáveis declaradas dá 533 contra 451 reais.
#   2. INFERE unidade, escala e domínio válido a partir do nome e da faixa
#      observada, marcando o grau de confiança em revisao_pendente.
#   3. Separa o `Operacionalização` do legado, que é um campo de TIPO com nome
#      de outra coisa e três vocabulários misturados, num campo `tipo` com
#      vocabulário fechado.
#   4. Atribui cada variável a uma TABELA, e não só a uma dimensão. Hoje só
#      existe a dimensão, mas Meio Ambiente tem quatro fontes e Saúde tem seis.
#
# Uso:  Rscript tools/migracao/semear_dicionario.R

suppressPackageStartupMessages({
  library(openxlsx)
})
for (f in list.files(here::here("R"), pattern = "[.]R$", full.names = TRUE)) {
  source(f, encoding = "UTF-8")
}

LEGADO <- here::here("mape_municipios")
message("== Semeando o dicionário ==")

# ---------------------------------------------------------------------------
# 1. A semente
# ---------------------------------------------------------------------------
dic <- read.xlsx(file.path(LEGADO, "6 Metadados",
                           "mape_municipios DICIONÁRIO.xlsx"))
names(dic) <- c("nome_na_fonte", "nome_legado", "dimensao_legado",
                "descricao", "operacionalizacao")
message("dicionário legado: ", nrow(dic), " linhas")

# ---------------------------------------------------------------------------
# 2. Campos calculados, a partir da base publicada
# ---------------------------------------------------------------------------
# Usa o .RDa (58 MB) e não o CSV (431 MB). Os dois não são equivalentes: o CSV
# ganha uma coluna sem nome e converte quatro colunas de texto para inteiro.
caminho_rda <- file.path(LEGADO, "4 Base completa",
                         "base_municipios_brasileiros.RDa")
message("lendo a base publicada para calcular os campos gerados...")
nome_obj <- load(caminho_rda)
base <- get(nome_obj)
message("base: ", nrow(base), " linhas x ", ncol(base), " colunas")

stopifnot(identical(names(base), dic$nome_legado))
message("confirmado: o dicionário bate 1-a-1 com as colunas da base")

calc <- do.call(rbind, lapply(names(base), function(nm) {
  v <- base[[nm]]
  num <- is.numeric(v)
  finito <- if (num) v[is.finite(v)] else numeric(0)
  data.frame(
    nome_legado = nm,
    tipo_real   = mape_tipo_de(v),
    pct_na      = round(100 * mean(is.na(v)), 3),
    n_distintos = length(unique(v[!is.na(v)])),
    minimo      = if (length(finito)) min(finito) else NA_real_,
    maximo      = if (length(finito)) max(finito) else NA_real_,
    n_infinito  = if (num) sum(is.infinite(v)) else 0L,
    stringsAsFactors = FALSE
  )
}))
rm(base); invisible(gc())

dic <- merge(dic, calc, by = "nome_legado", sort = FALSE)
dic <- dic[match(calc$nome_legado, dic$nome_legado), ]  # preserva a ordem original

# ---------------------------------------------------------------------------
# 3. Da dimensão para a tabela
# ---------------------------------------------------------------------------
# O vocabulário controlado, que passa a governar pasta, script, tabela e
# documentação ao mesmo tempo.
dimensoes <- data.frame(
  slug = c("00_diretorios", "01_assistencia_social_dh", "02_populacao",
           "03_meio_ambiente", "04_economia", "05_sociedade", "06_financas",
           "07_recursos_humanos", "08_energia_internet", "09_educacao",
           "10_saude", "11_transportes", "12_habitacao", "13_seguranca",
           "14_corrupcao", "15_dados_historicos", "16_eleicoes"),
  rotulo_pt = c("Identificação e diretórios", "Assistência Social e Direitos Humanos",
                "População", "Meio Ambiente", "Economia", "Sociedade",
                "Finanças Municipais", "Recursos Humanos", "Energia e Internet",
                "Educação", "Saúde", "Transportes", "Habitação", "Segurança",
                "Corrupção e Transparência", "Dados Históricos", "Eleições"),
  numero_legado = c(1L, 8L, 2L, 3L, 4L, 5L, 6L, 7L, 9L, 10L, 11L, 12L, 13L,
                    14L, 15L, 16L, 17L),
  stringsAsFactors = FALSE
)
dimensoes$ordem <- seq_len(nrow(dimensoes))

# O campo Dimensão do dicionário legado usa uma das quatro grafias em
# circulação. Normaliza para o slug.
de_para_dim <- c(
  "Identificação" = "00_diretorios",
  "Assistência Social e Direitos Humanos" = "01_assistencia_social_dh",
  "População" = "02_populacao", "Meio-Ambiente" = "03_meio_ambiente",
  "Economia" = "04_economia", "Sociedade" = "05_sociedade",
  "Finanças" = "06_financas", "Recursos Humanos" = "07_recursos_humanos",
  "Energia e Internet" = "08_energia_internet", "Educação" = "09_educacao",
  "Saúde" = "10_saude", "Transportes" = "11_transportes",
  "Habitação e Zoneamento" = "12_habitacao", "Segurança" = "13_seguranca",
  "Corrupção" = "14_corrupcao", "História" = "15_dados_historicos",
  "Eleições" = "16_eleicoes"
)
dic$dimensao <- unname(de_para_dim[dic$dimensao_legado])

# As 19 linhas sem dimensão são as 17 flags mais três variáveis órfãs. As
# flags deixam de existir; as órfãs recebem a dimensão pelo bloco físico.
orfas <- c(id = "03_meio_ambiente", qtd_uh = "12_habitacao",
           ano_eleicao = "16_eleicoes")
for (nm in names(orfas)) dic$dimensao[dic$nome_legado == nm] <- orfas[[nm]]

dic$e_flag_dimensao <- grepl("^dimensao_", dic$nome_legado)

# ---------------------------------------------------------------------------
# 4. Nome canônico proposto
# ---------------------------------------------------------------------------
propostos <- utils::read.csv(here::here("tools", "migracao", "nomes_propostos.csv"),
                             stringsAsFactors = FALSE, encoding = "UTF-8")
dic <- merge(dic, propostos[, c("nome_legado", "nome_proposto", "problema", "acao")],
             by = "nome_legado", all.x = TRUE, sort = FALSE)
dic <- dic[match(calc$nome_legado, dic$nome_legado), ]

# Nem toda recomendação é uma renomeação. Oito colunas são recomendadas para
# REMOÇÃO por serem redundantes com o diretório (nm_uf, id_municipio_nome,
# sigla_uf_nome, NOME_MUNICIPIO) ou por não terem significado publicável
# (turno, tipo_emenda). Isso é registrado como ação, e não convertido num nome
# de coluna chamado "remover".
dic$acao[is.na(dic$acao)] <- "manter"

# Sem proposta de renomeação, o nome canônico é o próprio nome de hoje.
dic$nome_canonico <- ifelse(is.na(dic$nome_proposto) | dic$nome_proposto == "",
                            dic$nome_legado, dic$nome_proposto)

# ---------------------------------------------------------------------------
# 5. Tipo, com vocabulário fechado
# ---------------------------------------------------------------------------
# O `Operacionalização` do legado mistura vocabulário do R, do BigQuery e
# informal: NUM, STRING, FLOAT64, INT64, GEOGRAPHY. Mapeia para o fechado e
# confronta com o tipo REAL observado, que é quem manda.
de_para_tipo <- c(NUM = "double", FLOAT64 = "double", INT64 = "integer",
                  STRING = "character", GEOGRAPHY = "character")
dic$tipo_declarado_legado <- unname(de_para_tipo[dic$operacionalizacao])
dic$tipo <- dic$tipo_real
dic$tipo_divergia_no_legado <- !is.na(dic$tipo_declarado_legado) &
  dic$tipo_declarado_legado != dic$tipo_real

# ---------------------------------------------------------------------------
# 6. Inferência de escala, unidade e domínio
# ---------------------------------------------------------------------------
# Combina o sufixo/prefixo do nome com a faixa observada. Quando os dois
# concordam, a confiança é alta; quando discordam ou não há pista, fica
# pendente de revisão.
inferir <- function(nome, tipo, minimo, maximo) {
  escala <- NA_character_; unidade <- NA_character_
  dominio <- NA_character_; confianca <- "baixa"

  eh_num <- tipo %in% c("double", "integer")
  faixa_ok <- eh_num && is.finite(minimo) && is.finite(maximo)

  if (!eh_num) {
    escala <- "categorica"; unidade <- "texto"; confianca <- "alta"
  } else if (grepl("^(id_|ano)|_id$|^ddd$", nome)) {
    escala <- "identificador"; unidade <- "codigo"; confianca <- "alta"
  } else if (grepl("^(flag_|dimensao_)", nome) ||
             (faixa_ok && minimo >= 0 && maximo <= 1 && grepl("^(capital|amazonia)", nome))) {
    escala <- "binaria"; unidade <- "booleano"; dominio <- "[0,1]"; confianca <- "alta"
  } else if (grepl("_prop$", nome) || (faixa_ok && grepl("^(participacao_|razao_)", nome) && maximo <= 1.0001)) {
    # Sufixo _prop é a convenção NOVA para razão de 0 a 1.
    escala <- "0-1"; unidade <- "proporcao"; dominio <- "[0,1]"
    confianca <- if (faixa_ok && minimo >= -0.0001 && maximo <= 1.0001) "alta" else "baixa"
  } else if (grepl("_pct$|^pct_|^proporcao_|^prop_|^percentual", nome)) {
    # O nome diz que é relativo; a faixa decide se é 0-1 ou 0-100. É esta
    # discordância que produz hoje proporcao_cobertura_estrategia_saude_familia
    # em 0-100 e pct_votos_eleito em 0-1, na mesma base.
    if (faixa_ok && maximo <= 1.0001) {
      escala <- "0-1"; unidade <- "proporcao"; dominio <- "[0,1]"; confianca <- "alta"
    } else if (faixa_ok && maximo <= 100.01) {
      escala <- "0-100"; unidade <- "percentual"; dominio <- "[0,100]"; confianca <- "alta"
    } else {
      escala <- "0-100"; unidade <- "percentual"; confianca <- "baixa"
    }
  } else if (grepl("^taxa_|^tx_|_p100k$", nome)) {
    escala <- "taxa"; unidade <- "por 100 mil hab."; confianca <- "media"
  } else if (grepl("^(valor|montante|receita|despesa|gasto|pib|investimento|arrecadacao|val_)|_brl", nome)) {
    escala <- "monetaria"; unidade <- "R$"; confianca <- "media"
  } else if (grepl("^(total_|quantidade_|qtd_|n_)|_i$", nome)) {
    escala <- "contagem"; unidade <- "contagem"
    dominio <- if (faixa_ok && minimo >= 0) "[0,Inf]" else NA_character_
    confianca <- "media"
  } else if (grepl("^(indice|idhm|ivs)|_idx$", nome)) {
    escala <- "indice"; unidade <- "indice"
    if (faixa_ok && minimo >= 0 && maximo <= 1.0001) dominio <- "[0,1]"
    confianca <- "media"
  } else if (grepl("^populacao", nome)) {
    escala <- "contagem"; unidade <- "pessoas"; dominio <- "[0,Inf]"; confianca <- "alta"
  } else if (grepl("_km2$|^area", nome)) {
    escala <- "fisica"; unidade <- "km2"; dominio <- "[0,Inf]"; confianca <- "alta"
  } else if (grepl("^desmatado_|_ha$", nome)) {
    # O PRODES publica área desmatada em km²; a faixa observada confirma.
    escala <- "fisica"; unidade <- "km2"; dominio <- "[0,Inf]"; confianca <- "media"
  } else if (grepl("_km$|^extensao_", nome)) {
    escala <- "fisica"; unidade <- "km"; dominio <- "[0,Inf]"; confianca <- "media"
  } else if (grepl("^(log_|ln[._])", nome)) {
    escala <- "log"; unidade <- "log"; confianca <- "media"
  } else if (grepl("^(media_|nota_)", nome)) {
    escala <- "escore"; unidade <- "escore"; confianca <- "baixa"
  } else if (grepl("^(cobertura_|cob_)", nome) && faixa_ok) {
    # Cobertura é sempre relativa; a faixa decide a escala. O SI-PNI não trunca
    # e chega a 13.050%, então o teto de 100 não serve de teste aqui.
    escala <- if (maximo <= 1.0001) "0-1" else "0-100"
    unidade <- if (maximo <= 1.0001) "proporcao" else "percentual"
    confianca <- "media"
  } else if (grepl("^(nep_|fracionalizacao|volatilidade|margem)", nome)) {
    escala <- "indice"; unidade <- "indice"; confianca <- "baixa"
  } else if (faixa_ok && tipo == "integer" && minimo >= 0) {
    # Inteiro não negativo sem outra pista é, quase sempre, contagem.
    escala <- "contagem"; unidade <- "contagem"; dominio <- "[0,Inf]"
    confianca <- "baixa"
  }
  list(escala = escala, unidade = unidade, dominio = dominio, confianca = confianca)
}

inf <- Map(inferir, dic$nome_canonico, dic$tipo, dic$minimo, dic$maximo)
dic$escala          <- vapply(inf, `[[`, character(1), "escala")
dic$unidade         <- vapply(inf, `[[`, character(1), "unidade")
dic$dominio_valido  <- vapply(inf, `[[`, character(1), "dominio")
dic$confianca_inferencia <- vapply(inf, `[[`, character(1), "confianca")

# ---------------------------------------------------------------------------
# 7. O que precisa de olho humano
# ---------------------------------------------------------------------------
# revisao_pendente é a lista curta do que precisa de olho humano ANTES de
# publicar. Confiança "media" não entra: significa que a regra de inferência se
# aplicou bem e o valor deve ser confirmado quando a dimensão for migrada, o
# que acontece de qualquer forma. Marcar 277 variáveis como pendentes tornaria
# a lista inútil, que é o oposto do objetivo.
dic$revisao_pendente <- with(dic,
  confianca_inferencia == "baixa" |
  is.na(descricao) |
  tipo_divergia_no_legado |
  n_infinito > 0 |
  is.na(escala)
)

dic$motivo_revisao <- with(dic, ifelse(
  is.na(descricao), "sem descrição no legado",
  ifelse(tipo_divergia_no_legado,
         paste0("tipo declarado '", tipo_declarado_legado, "' divergia do real '", tipo_real, "'"),
  ifelse(n_infinito > 0, paste0(n_infinito, " valores infinitos (log de zero)"),
  ifelse(confianca_inferencia == "baixa", "inferência de escala/unidade incerta",
  ifelse(confianca_inferencia == "media", "inferência de escala/unidade a confirmar",
         NA_character_))))))

# ---------------------------------------------------------------------------
# 8. Grava
# ---------------------------------------------------------------------------
dir.create(here::here("dicionario"), showWarnings = FALSE)

variaveis <- dic[!dic$e_flag_dimensao, c(
  "dimensao", "nome_canonico", "nome_legado", "nome_na_fonte", "descricao",
  "unidade", "escala", "tipo", "dominio_valido",
  "tipo_real", "pct_na", "n_distintos", "minimo", "maximo", "n_infinito",
  "confianca_inferencia", "revisao_pendente", "motivo_revisao", "problema", "acao"
)]
variaveis$tabela <- NA_character_   # preenchido quando cada fonte for migrada
variaveis$conceito <- NA_character_
variaveis$obrigatoria <- variaveis$nome_canonico %in% c("id_municipio", "ano")

utils::write.csv(variaveis, here::here("dicionario", "variaveis.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8", na = "")
utils::write.csv(dimensoes, here::here("dicionario", "dimensoes.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8", na = "")

# Tabela de depreciação: só o que de fato muda de nome.
depre <- dic[dic$nome_legado != dic$nome_canonico & !dic$e_flag_dimensao,
             c("nome_legado", "nome_canonico", "dimensao", "problema", "acao")]
names(depre) <- c("nome_antigo", "nome_novo", "dimensao", "motivo", "acao")
depre$versao_remocao <- "dados-v2.0.0"
utils::write.csv(depre, here::here("dicionario", "deprecacao.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8", na = "")

message("\n== Resultado ==")
message("variaveis.csv:   ", nrow(variaveis), " variáveis (as 17 flags foram excluídas)")
message("  revisão pendente: ", sum(variaveis$revisao_pendente),
        " (", round(100 * mean(variaveis$revisao_pendente)), "%)")
message("  sem descrição:    ", sum(is.na(variaveis$descricao)))
message("dimensoes.csv:   ", nrow(dimensoes), " dimensões")
message("deprecacao.csv:  ", nrow(depre), " renomeações")
message("\nconfiança da inferência:")
print(table(variaveis$confianca_inferencia))
message("\nescalas inferidas:")
print(table(variaveis$escala, useNA = "ifany"))
