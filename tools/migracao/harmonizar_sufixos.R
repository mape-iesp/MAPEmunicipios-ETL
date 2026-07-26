# Harmonização dos sufixos e das abreviações ---------------------------------
#
# Segunda e última passada de nomenclatura. A primeira (harmonizar_nomes.R)
# tratou dos prefixos genéricos; esta trata das 167 variáveis que atravessaram
# a migração sem sufixo do vocabulário fechado, e das abreviações inventadas
# que o plano bane na seção 6.1 — `cob_vac_bcg`, `tx_mort_aj_oms`,
# `desp_tot_saude_pc_mun`, `n_leitouti_nsus`.
#
# O sufixo não é decoração. Ele é a única coisa que permite a validação saber
# que uma coluna `_pct` cujos valores não passam de 1 está rotulada errada — foi
# assim que apareceram os quatro casos de razão chamada de proporção e o
# `margem_pct` que era proporção.
#
# Enquanto conferia cada faixa de valores contra o nome, quatro coisas
# apareceram e estão corrigidas aqui:
#
#   - `proporcao_votos_brancos_camara_vereadores` e a irmã de votos nulos vão
#     de 0 a 55, então são percentuais com nome de proporção. É o mesmo erro,
#     invertido, do `margem_pct` já corrigido.
#   - As seis colunas `ln_*_1920_z` dos dados históricos vão de 0 a 1 exatos.
#     Isso não é z-score, que é centrado em zero e não tem limite: é
#     normalização min-max. O nome mente duas vezes, no `ln_` e no `_z`.
#   - `tx_med` e `tx_enf` são por mil habitantes, como a descrição do IEPS diz,
#     e não por cem mil, como a unidade declarada dizia.
#   - `turno` é constante igual a 1 em todas as 133.496 linhas. Fica registrada
#     como coluna sem variação em vez de sugerir que existe segundo turno.
#
# Rodar com:  Rscript tools/migracao/harmonizar_sufixos.R

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) {
  source(f, encoding = "UTF-8")
}

vars <- mape_dicionario("variaveis", .recarregar = TRUE)
nc <- vars$nome_canonico

mapa <- list()
ajustes <- list()
notas <- list()

renomear <- function(de, para, unidade = NULL, escala = NULL, nota = NULL) {
  if (!de %in% nc) return(invisible(NULL))
  mapa[[de]] <<- para
  if (!is.null(unidade) || !is.null(escala)) {
    ajustes[[para]] <<- list(unidade = unidade, escala = escala)
  }
  if (!is.null(nota)) notas[[para]] <<- nota
}

# --- 03 Meio ambiente -------------------------------------------------------

# Os quatro biomas que ficaram fora do padrão dos irmãos amazonia/caatinga.
for (b in c("cerrado", "mata_atlantica", "pampa", "pantanal")) {
  renomear(paste0("desmatado_total_", b),
           paste0("area_desmatada_bioma_", b, "_km2"),
           unidade = "km2", escala = "km2")
}
renomear("area_desmatada_municipio_km2_lag1", "area_desmatada_municipio_lag1_km2",
         unidade = "km2", escala = "km2")

# AdaptaBrasil: prefixo de fonte + sufixo. As colunas "_classe" são a versão
# categórica do mesmo índice, e passam a dizer isso no nome.
ada <- list(
  c("capacidade_investimento_adaptacao", "adapta_capacidade_investimento_idx"),
  c("capacidade_investimento_adaptacao_classe", "adapta_capacidade_investimento_cat"),
  c("indice_capacidade_adaptacao_inundacoes_enxurradas", "adapta_capacidade_adaptacao_inundacoes_idx"),
  c("indice_capacidade_adaptacao_inundacoes_enxurradas_classe", "adapta_capacidade_adaptacao_inundacoes_cat"),
  c("indice_risco_inundacoes_enxurradas", "adapta_risco_inundacoes_idx"),
  c("indice_risco_inundacoes_enxurradas_classe", "adapta_risco_inundacoes_cat"),
  c("indice_vulnerabilidade_inundacoes_enxurradas", "adapta_vulnerabilidade_inundacoes_idx"),
  c("indice_vulnerabilidade_inundacoes_enxurradas_classe", "adapta_vulnerabilidade_inundacoes_cat"),
  c("adapta_indice_adesao_programa_cidades_resilientes", "adapta_adesao_cidades_resilientes_idx"),
  c("cidades_resilientes_classe", "adapta_adesao_cidades_resilientes_cat"),
  c("indice_capacidade_adaptativa_recursos_hidricos", "adapta_capacidade_recursos_hidricos_idx"),
  c("indice_capacidade_adaptativa_recursos_hidricos_classe", "adapta_capacidade_recursos_hidricos_cat"),
  c("indice_risco_seca", "adapta_risco_seca_idx"),
  c("indice_risco_seca_classe", "adapta_risco_seca_cat"),
  c("indice_vulnerabilidade_seca", "adapta_vulnerabilidade_seca_idx"),
  c("indice_vulnerabilidade_seca_classe", "adapta_vulnerabilidade_seca_cat")
)
for (p in ada) {
  renomear(p[1], p[2],
           unidade = if (grepl("_cat$", p[2])) "classe" else "indice",
           escala = if (grepl("_cat$", p[2])) "categoria" else "indice")
}

# --- 05 Sociedade -----------------------------------------------------------

for (v in c("ivs", "ivs_infraestrutura_urbana", "ivs_capital_humano",
            "ivs_renda_trabalho", "idhm")) {
  renomear(v, paste0(v, "_idx"), unidade = "indice de 0 a 1", escala = "indice")
}
renomear("classe_prosperidade_social", "prosperidade_social_cat",
         unidade = "classe", escala = "categoria")

# --- 06 Finanças ------------------------------------------------------------

renomear("emendas_localidade_gasto_texto", "emendas_localidade_gasto_cat",
         unidade = "texto", escala = "categoria")
renomear("localidade_gasto_2", "emendas_localidade_gasto_secundaria_cat",
         unidade = "texto", escala = "categoria")
renomear("tipo_emenda", "emendas_tipo_cat", unidade = "texto", escala = "categoria")

for (v in grep("^valor_emendas_", nc, value = TRUE)) {
  renomear(v, paste0("emendas_valor_", sub("^valor_emendas_", "", v), "_brl2023"),
           unidade = "BRL de dezembro de 2023", escala = "brl")
}

# --- 07 Recursos humanos ----------------------------------------------------

for (v in c("comissionados_direta", "estagiarios_direta",
            "sem_vinculo_permanente_direta", "estatutarios_indireta",
            "clt_indireta", "comissionados_indireta", "estagiarios_indireta",
            "sem_vinculo_permanente_indireta")) {
  renomear(v, paste0("munic_servidores_", v, "_i"),
           unidade = "servidores", escala = "contagem")
}

# --- 08 Energia e internet --------------------------------------------------

# Acessos por 100 domicílios: chega a 319, então não é percentual. O sufixo
# _p100dom entra no vocabulário pelo mesmo motivo que _p100k já estava lá —
# uma taxa precisa dizer qual é o denominador.
for (t in c("bl", "tm")) {
  renomear(paste0("anatel_", t, "_densidade_media_anual_por_100_dom"),
           paste0("anatel_", t, "_densidade_p100dom"),
           unidade = "acessos por 100 domicilios", escala = "taxa")
  renomear(paste0("anatel_", t, "_densidade_media_anual_capital_uf"),
           paste0("anatel_", t, "_densidade_capital_uf_p100dom"),
           unidade = "acessos por 100 domicilios", escala = "taxa")
}
for (a in c("00", "10")) {
  renomear(paste0("cobertura_eletricidade_", a),
           paste0("censo_cobertura_eletricidade_", if (a == "00") 2000 else 2010, "_pct"),
           unidade = "%", escala = "0-100",
           nota = paste("O ano fica no nome porque a coluna é um retrato",
                        "censitário replicado no painel, e não uma série."))
}

# --- 09 Educação ------------------------------------------------------------

renomear("ideb_nota_media_municipio", "ideb_nota_municipio_idx",
         unidade = "escore de 0 a 10", escala = "indice")
renomear("ideb_nota_saeb_padronizada_media", "saeb_nota_padronizada_municipio_idx",
         unidade = "escore padronizado", escala = "indice")
renomear("ideb_meta_projetada_media", "ideb_meta_projetada_municipio_idx",
         unidade = "escore de 0 a 10", escala = "indice")
renomear("ideb_nota_media_ef_anos_finais", "ideb_nota_ef_anos_finais_idx",
         unidade = "escore de 0 a 10", escala = "indice")
renomear("ideb_nota_media_ef_anos_iniciais", "ideb_nota_ef_anos_iniciais_idx",
         unidade = "escore de 0 a 10", escala = "indice")

for (v in grep("^media_(ideb|saeb|projecao)_", nc, value = TRUE)) {
  qual <- sub("^media_([a-z]+)_.*$", "\\1", v)
  resto <- sub("^media_[a-z]+_", "", v)
  novo <- switch(qual,
    ideb = paste0("ideb_nota_", resto, "_idx"),
    saeb = paste0("saeb_nota_", resto, "_idx"),
    projecao = paste0("ideb_meta_projetada_", resto, "_idx"))
  renomear(v, novo, unidade = "escore de 0 a 10", escala = "indice")
}

# --- 10 Saúde ---------------------------------------------------------------

# Coberturas vacinais do SI-PNI. As irmãs já publicadas trazem o prefixo pni_;
# estas doze ficaram sem, e como o IEPS também publica cobertura vacinal no
# mesmo painel, o prefixo aqui é obrigatório e não cosmético.
for (v in grep("^cobertura_(bcg|dtp|dtpa|febre|hepatite|penta|polio|sarampo|tetra|triplice)",
               nc, value = TRUE)) {
  renomear(v, paste0("pni_", v, "_pct"), unidade = "%", escala = "0-100")
}

# Coberturas vacinais do IEPS Data. Mesmo conceito, outra fonte, outro
# denominador — é exatamente por isso que as duas famílias precisam de prefixo.
vac_ieps <- c(bcg = "bcg", rota = "rotavirus", menin = "meningococo_c",
              pneumo = "pneumococica", polio = "poliomielite",
              tvd1 = "triplice_viral_dose1", penta = "pentavalente",
              hepa = "hepatite_a")
for (ab in names(vac_ieps)) {
  renomear(paste0("cob_vac_", ab),
           paste0("ieps_cobertura_vacinal_", vac_ieps[[ab]], "_pct"),
           unidade = "%", escala = "0-100")
}

prenatal <- c(adeq = "adequado", zero = "nenhuma_consulta",
              `1a6` = "1_a_6_consultas", `7m` = "7_ou_mais_consultas")
for (ab in names(prenatal)) {
  renomear(paste0("pct_prenatal_", ab),
           paste0("ieps_prenatal_", prenatal[[ab]], "_pct"),
           unidade = "%", escala = "0-100")
}

mort <- c(
  tx_mort_aj_oms = "ieps_taxa_mortalidade_padronizada_oms_p100k",
  tx_mort_csap_aj_oms = "ieps_taxa_mortalidade_csap_padronizada_oms_p100k",
  tx_mort_evit_aj_oms = "ieps_taxa_mortalidade_evitavel_padronizada_oms_p100k",
  tx_mort_aj_cens = "ieps_taxa_mortalidade_padronizada_censo_p100k",
  tx_mort_evit_aj_cens = "ieps_taxa_mortalidade_evitavel_padronizada_censo_p100k",
  tx_leito_sus = "ieps_leitos_sus_p100k",
  tx_leitouti_sus = "ieps_leitos_uti_sus_p100k",
  tx_leito_nsus = "ieps_leitos_nao_sus_p100k",
  tx_leitouti_nsus = "ieps_leitos_uti_nao_sus_p100k"
)
for (de in names(mort)) {
  renomear(de, unname(mort[de]), unidade = "por 100 mil habitantes",
           escala = "taxa")
}

# Médicos e enfermeiros são por MIL habitantes, não por cem mil: a descrição do
# IEPS diz isso e o máximo observado (27,7 médicos) confirma.
prof <- c(tx_med = "ieps_medicos_p1k", tx_enf = "ieps_enfermeiros_p1k",
          tx_med_ch = "ieps_medicos_carga_horaria_p1k",
          tx_enf_ch = "ieps_enfermeiros_carga_horaria_p1k")
for (de in names(prof)) {
  renomear(de, unname(prof[de]), unidade = "por mil habitantes", escala = "taxa",
           nota = paste("A unidade declarada dizia 'por 100 mil habitantes' e",
                        "estava errada: a descrição da fonte e a faixa",
                        "observada mostram que é por mil."))
}

renomear("n_leito_nsus", "ieps_leitos_nao_sus_i", unidade = "leitos", escala = "contagem")
renomear("n_leitouti_nsus", "ieps_leitos_uti_nao_sus_i", unidade = "leitos", escala = "contagem")

# O único par nominal/deflacionado que sobreviveu ao legado inteiro. Vale
# preservá-lo com os dois sufixos, porque em todo o resto do repositório a
# série nominal foi sobrescrita e não existe mais.
desp <- c(
  desp_tot_saude_pc_mun = c("ieps_despesa_saude_total_per_capita_brl_nominal", "BRL correntes do ano"),
  desp_recp_saude_pc_mun = c("ieps_despesa_saude_recursos_proprios_per_capita_brl_nominal", "BRL correntes do ano"),
  desp_tot_saude_pc_mun_def = c("ieps_despesa_saude_total_per_capita_brl2023", "BRL de dezembro de 2023"),
  desp_recp_saude_pc_mun_def = c("ieps_despesa_saude_recursos_proprios_per_capita_brl2023", "BRL de dezembro de 2023")
)
for (de in c("desp_tot_saude_pc_mun", "desp_recp_saude_pc_mun",
             "desp_tot_saude_pc_mun_def", "desp_recp_saude_pc_mun_def")) {
  novo <- if (grepl("_def$", de)) {
    if (grepl("_tot_", de)) "ieps_despesa_saude_total_per_capita_brl2023"
    else "ieps_despesa_saude_recursos_proprios_per_capita_brl2023"
  } else {
    if (grepl("_tot_", de)) "ieps_despesa_saude_total_per_capita_brl_nominal"
    else "ieps_despesa_saude_recursos_proprios_per_capita_brl_nominal"
  }
  renomear(de, novo,
           unidade = if (grepl("_def$", de)) "BRL de dezembro de 2023" else "BRL correntes do ano",
           escala = "brl")
}

# --- 11 Transportes ---------------------------------------------------------

renomear("ano_inicio_tarifa_zero", "ano_ref_inicio_tarifa_zero",
         unidade = "ano", escala = "ano",
         nota = "Ano de referência, não chave do painel: por isso o prefixo ano_ref_.")
renomear("adota_tarifa_zero", "flag_adota_tarifa_zero",
         unidade = "0 ou 1", escala = "binaria")

# --- 15 Dados históricos ----------------------------------------------------

# As seis colunas nomeadas _z vão de 0 a 1 exatos, o que exclui z-score
# (centrado em zero, sem limite) e indica normalização min-max. O nome também
# promete logaritmo, e o resultado da normalização não é um log.
hist <- c(
  ln_receita_per_capita_1920_z = "receita_tributaria_1920_norm_idx",
  ln_administracao_publica_1920_z = "servidores_administracao_publica_1920_norm_idx",
  ln_forca_publica_1920_z = "servidores_forca_publica_1920_norm_idx",
  ln_ferrovia_1920_z = "redes_ferroviarias_1920_norm_idx",
  ln_distancia_litoral_km_z = "distancia_litoral_norm_idx",
  ln_distancia_capital_estadual_km_z = "distancia_capital_estadual_norm_idx"
)
for (de in names(hist)) {
  renomear(de, unname(hist[de]), unidade = "indice normalizado de 0 a 1",
           escala = "indice",
           nota = paste("O nome antigo prometia log e z-score. Os valores vão",
                        "de 0 a 1 exatos, o que é normalização min-max: um",
                        "z-score é centrado em zero e não tem limite superior."))
}
renomear("ano_fundacao_estimado", "ano_ref_fundacao_estimado", unidade = "ano",
         escala = "ano")

# --- 16 Eleições ------------------------------------------------------------

# Vão de 0 a 55, então são percentuais com nome de proporção. Mesmo erro do
# margem_pct já corrigido, na direção oposta.
renomear("proporcao_votos_brancos_camara_vereadores", "tse_votos_brancos_camara_pct",
         unidade = "%", escala = "0-100",
         nota = "Chamada de proporção e medida em percentual: chega a 19,45.")
renomear("proporcao_votos_nulos_camara_vereadores", "tse_votos_nulos_camara_pct",
         unidade = "%", escala = "0-100",
         nota = "Chamada de proporção e medida em percentual: chega a 55,41.")
renomear("pct_votos_governador_segundo_lugar", "tse_votos_governador_segundo_lugar_pct",
         unidade = "%", escala = "0-100")
renomear("nep_prefeitura", "nep_prefeitura_idx", unidade = "indice", escala = "indice")
renomear("nep_camara_vereadores", "nep_camara_idx", unidade = "indice", escala = "indice")
renomear("fracionalizacao_prefeitura", "fracionalizacao_prefeitura_idx",
         unidade = "indice de 0 a 1", escala = "indice")
renomear("fracionalizacao_camara_vereadores", "fracionalizacao_camara_idx",
         unidade = "indice de 0 a 1", escala = "indice")
renomear("margem_votos", "tse_margem_votos_i", unidade = "votos", escala = "contagem")
renomear("turno", "turno_i", unidade = "turno", escala = "contagem",
         nota = paste("Constante igual a 1 em todas as linhas: a base só traz",
                      "primeiro turno. Mantida para não quebrar consumidor, mas",
                      "não informa nada."))
renomear("ano_eleicao", "ano_ref_eleicao", unidade = "ano", escala = "ano")
renomear("partido_segundo_colocado", "partido_segundo_colocado_cat",
         unidade = "sigla", escala = "categoria")
renomear("sg_partido_governador_eleito", "partido_governador_eleito_cat",
         unidade = "sigla", escala = "categoria")
renomear("composicao_coligacao_governador_eleito", "coligacao_governador_eleito_cat",
         unidade = "texto", escala = "categoria")
renomear("composicao_coligacao_governador_segundo_lugar",
         "coligacao_governador_segundo_lugar_cat", unidade = "texto", escala = "categoria")
renomear("nm_urna_governador_eleito", "nome_urna_governador_eleito")
renomear("nm_urna_governador_segundo_lugar", "nome_urna_governador_segundo_lugar")

# --- Aplicação --------------------------------------------------------------

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

dep <- data.frame(
  nome_antigo = names(mapa), nome_novo = unname(mapa),
  dimensao = vars$dimensao[match(names(mapa), vars$nome_canonico)],
  motivo = ifelse(
    names(mapa) %in% names(notas)[match(unname(mapa), names(notas))],
    "", ""),
  data = format(Sys.Date(), "%Y-%m-%d"),
  stringsAsFactors = FALSE
)
dep$motivo <- vapply(seq_len(nrow(dep)), function(i) {
  n <- notas[[dep$nome_novo[i]]]
  if (!is.null(n)) n else
    "sufixo do vocabulario fechado ausente ou abreviacao inventada (secao 6.1 do plano)"
}, character(1))

idx <- match(names(mapa), vars$nome_canonico)
vars$nome_canonico[idx] <- unname(mapa)

for (nm in names(ajustes)) {
  j <- which(vars$nome_canonico == nm)
  if (!length(j)) next
  a <- ajustes[[nm]]
  if (!is.null(a$unidade)) vars$unidade[j] <- a$unidade
  if (!is.null(a$escala))  vars$escala[j]  <- a$escala
  vars$confianca_inferencia[j] <- "alta"
  vars$revisao_pendente[j] <- FALSE
  vars$motivo_revisao[j] <- NA_character_
}
for (nm in names(notas)) {
  j <- which(vars$nome_canonico == nm)
  if (length(j)) {
    vars$problema[j] <- notas[[nm]]
  }
}

utils::write.csv(vars, mape_caminho("dicionario", "variaveis.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8", na = "")

arq_dep <- mape_caminho("dicionario", "deprecacao.csv")
antigo <- utils::read.csv(arq_dep, stringsAsFactors = FALSE, encoding = "UTF-8")
for (cl in setdiff(names(dep), names(antigo))) antigo[[cl]] <- NA
for (cl in setdiff(names(antigo), names(dep))) dep[[cl]] <- NA
dep <- rbind(antigo[, names(dep)], dep)
dep <- dep[!duplicated(dep$nome_antigo, fromLast = TRUE), ]
utils::write.csv(dep, arq_dep, row.names = FALSE, fileEncoding = "UTF-8", na = "")
message("depreciação: ", nrow(dep), " linhas")

.mape_cache_dic$dic_variaveis <- NULL

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

message("\ntabelas reescritas: ", n_tocadas, " | colunas renomeadas: ", length(mapa))
