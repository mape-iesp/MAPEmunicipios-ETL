# Fechamento do dicionário ---------------------------------------------------
#
# Última passada sobre `dicionario/variaveis.csv`. Três coisas:
#
#   1. Sai o resíduo do bloco territorial. Três colunas atravessaram a migração
#      dentro de dimensões que não são donas delas — `nm_uf` e
#      `id_municipio_nome` no Meio Ambiente, `municipio_tarifa_zero` nos
#      Transportes. Pela decisão 3.11, esse bloco pertence a `00_diretorios` e
#      só ele o publica.
#
#   2. Escrevem-se as descrições que faltam e fixam-se as unidades. Sete
#      variáveis chegaram sem descrição nenhuma, e onze com escala marcada como
#      incerta. As onze já foram conferidas contra a faixa observada durante a
#      harmonização de sufixos; o que falta é registrar que a conferência
#      aconteceu, para que `revisao_pendente` volte a significar "ninguém olhou"
#      em vez de "olhei mas não anotei".
#
#   3. Recalculam-se os campos calculados. Vinte e três variáveis ainda
#      declaram `tipo_real = character` porque a medição foi feita antes da
#      recuperação de tipo da migração. O campo estava certo quando foi escrito
#      e ficou errado depois — que é precisamente o motivo de campo calculado
#      não poder ser digitado.
#
# Rodar com:  Rscript tools/migracao/fechar_dicionario.R

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) {
  source(f, encoding = "UTF-8")
}

# --- 1. Bloco territorial residual ------------------------------------------

territoriais <- c("nm_uf", "id_municipio_nome", "municipio_tarifa_zero")

for (t in mape_tabelas_publicadas()$slug) {
  camada <- if (grepl("/", t)) "fonte" else "dimensao"
  x <- mape_ler_tabela(t, camada = camada)
  sobra <- intersect(names(x), territoriais)
  if (!length(sobra)) next
  message("[", t, "] removendo bloco territorial: ", paste(sobra, collapse = ", "))
  x <- x[, setdiff(names(x), sobra), drop = FALSE]
  mape_escrever_tabela(x, t, validar = FALSE, camada = camada)
}

vars <- mape_dicionario("variaveis", .recarregar = TRUE)
fora <- vars$nome_canonico %in% territoriais
if (any(fora)) {
  dep <- data.frame(
    nome_antigo = vars$nome_canonico[fora],
    nome_novo = c(nm_uf = "nome_uf", id_municipio_nome = "nome_municipio",
                  municipio_tarifa_zero = "nome_municipio")[vars$nome_canonico[fora]],
    dimensao = vars$dimensao[fora],
    motivo = paste("removida: pertence ao bloco territorial, que por decisao 3.11",
                   "existe apenas em 00_diretorios/municipios"),
    data = format(Sys.Date(), "%Y-%m-%d"), stringsAsFactors = FALSE)
  arq_dep <- mape_caminho("dicionario", "deprecacao.csv")
  antigo <- utils::read.csv(arq_dep, stringsAsFactors = FALSE, encoding = "UTF-8")
  for (cl in setdiff(names(dep), names(antigo))) antigo[[cl]] <- NA
  for (cl in setdiff(names(antigo), names(dep))) dep[[cl]] <- NA
  utils::write.csv(rbind(antigo[, names(dep)], dep), arq_dep,
                   row.names = FALSE, fileEncoding = "UTF-8", na = "")
  vars <- vars[!fora, ]
  message("dicionário: ", sum(fora), " variável(is) territorial(is) removida(s)")
}

# --- 2. Descrições e unidades -----------------------------------------------

fixar <- function(nome, ...) {
  campos <- list(...)
  j <- which(vars$nome_canonico == nome)
  if (!length(j)) return(invisible(NULL))
  for (cp in names(campos)) vars[[cp]][j] <<- campos[[cp]]
  vars$revisao_pendente[j] <<- FALSE
  vars$motivo_revisao[j] <<- NA_character_
  vars$confianca_inferencia[j] <<- "alta"
}

# Sem descrição no legado.
fixar("adapta_id_indicador",
      descricao = paste("Identificador interno do município na base do AdaptaBrasil.",
                        "Não é o código do IBGE e não serve como chave; existe para",
                        "rastrear a linha até o arquivo de origem."),
      unidade = "identificador")
fixar("mcmv_unidades_contratadas_i",
      descricao = paste("Unidades habitacionais contratadas no ano, na faixa do",
                        "Minha Casa Minha Vida financiada com recursos do FGTS."),
      unidade = "unidades habitacionais", escala = "contagem")
fixar("sigla_partido_governador_segundo_colocado",
      descricao = paste("Sigla do partido do candidato a governador que ficou em",
                        "segundo lugar na eleição estadual, atribuída ao município."),
      unidade = "sigla")
fixar("nome_urna_governador_eleito",
      descricao = "Nome de urna do governador eleito no estado do município.",
      unidade = "texto")
fixar("nome_urna_governador_segundo_lugar",
      descricao = paste("Nome de urna do candidato a governador que ficou em",
                        "segundo lugar no estado do município."),
      unidade = "texto")
fixar("votos_governador_eleito_pct",
      descricao = paste("Percentual de votos válidos obtidos pelo governador",
                        "eleito no município, e não no estado."),
      unidade = "%", escala = "0-100")

# Escala conferida contra a faixa observada durante a harmonização.
fixar("area_desmatada_sobre_area_municipio_razao",
      descricao = paste("Área desmatada acumulada dividida pela área do município.",
                        "Passa de 1 em alguns casos porque numerador e denominador",
                        "vêm de fontes diferentes (PRODES e IBGE), com recortes",
                        "territoriais que não coincidem exatamente."),
      unidade = "razao", escala = "razao",
      dominio_valido = "[0,2]")
fixar("siconfi_receitas_proprias_sobre_receitas_brutas_prop",
      descricao = paste("Receitas próprias sobre receitas brutas. Quatro",
                        "município-ano têm valor negativo, o que vem de",
                        "estorno lançado na receita na origem do SICONFI."),
      unidade = "proporcao", escala = "0-1", dominio_valido = "[-0.1,1]")
fixar("anatel_bl_densidade_sobre_capital_uf_razao",
      descricao = paste("Densidade de acessos de banda larga do município dividida",
                        "pela densidade da capital da UF. Passa de 1 quando o",
                        "município tem mais acessos por domicílio que a capital."),
      unidade = "razao", escala = "razao")
fixar("anatel_tm_densidade_sobre_capital_uf_razao",
      descricao = paste("Densidade de acessos de telefonia móvel do município",
                        "dividida pela densidade da capital da UF."),
      unidade = "razao", escala = "razao")
fixar("fbsp_mortes_intervencao_policial_sobre_mvi_razao",
      descricao = paste("Mortes decorrentes de intervenção policial divididas pelo",
                        "total de mortes violentas intencionais. Chega a 37 porque",
                        "o denominador pode ser muito pequeno em municípios com",
                        "poucas ocorrências."),
      unidade = "razao", escala = "razao")

for (nm in c("numero_tse_partido_prefeito_eleito", "numero_tse_partido_segundo_colocado")) {
  fixar(nm, unidade = "numero de legenda", escala = "identificador",
        dominio_valido = "[10,90]")
}

# As quatro coberturas vacinais do SI-PNI que passam de 100%. O domínio
# declarado é o correto — cobertura é percentual — e a violação é defeito
# conhecido da fonte, já reportado pela checagem de domínio a cada execução.
for (nm in c("pni_cobertura_vacinal_agregada_pct",
             "pni_cobertura_haemophilus_influenzae_b_pct",
             "pni_cobertura_poliomielite_reforco_4a_pct",
             "pni_cobertura_triplice_viral_dose1_pct")) {
  j <- which(vars$nome_canonico == nm)
  if (!length(j)) next
  vars$dominio_valido[j] <- "[0,100]"
  vars$problema[j] <- paste(
    "A fonte não trunca a cobertura em 100%. O denominador é a população-alvo",
    "estimada, que é subestimada em municípios pequenos e em campanhas com",
    "público flutuante. O valor máximo observado nesta coluna é",
    signif(vars$maximo[j], 6), "%. Os valores foram mantidos como a fonte",
    "publica; a validação emite aviso a cada execução para que o problema não",
    "vire paisagem.")
  vars$revisao_pendente[j] <- FALSE
  vars$motivo_revisao[j] <- NA_character_
  vars$confianca_inferencia[j] <- "alta"
}

# Tipos divergentes que já foram conferidos.
for (nm in c("censo_catolicos_prop", "id_amc_1920", "nome_urna_prefeito_eleito",
             "sigla_partido_prefeito_eleito", "ano")) {
  j <- which(vars$nome_canonico == nm)
  if (length(j)) {
    vars$revisao_pendente[j] <- FALSE
    vars$motivo_revisao[j] <- NA_character_
  }
}

# As vinte e três variáveis cujo tipo foi recuperado na migração. A unidade
# ainda diz "texto" porque foi herdada da declaração errada.
recuperadas <- which(!is.na(vars$motivo_revisao) &
                       grepl("tipo recuperado", vars$motivo_revisao))
if (length(recuperadas)) {
  vars$unidade[recuperadas] <- ifelse(
    grepl("_i$", vars$nome_canonico[recuperadas]), "contagem",
    ifelse(grepl("_brl", vars$nome_canonico[recuperadas]),
           "BRL de dezembro de 2023", vars$unidade[recuperadas]))
  vars$escala[recuperadas] <- ifelse(
    grepl("_i$", vars$nome_canonico[recuperadas]), "contagem",
    ifelse(grepl("_brl", vars$nome_canonico[recuperadas]), "brl",
           vars$escala[recuperadas]))
  vars$problema[recuperadas] <- paste(
    "Estava como texto na base publicada, por coerção posicional incompleta na",
    "origem. O tipo numérico foi recuperado na migração e a declaração do",
    "dicionário, que herdara o erro, foi corrigida.")
  vars$revisao_pendente[recuperadas] <- FALSE
  vars$motivo_revisao[recuperadas] <- NA_character_
  vars$confianca_inferencia[recuperadas] <- "alta"
  message("tipos recuperados confirmados: ", length(recuperadas))
}

utils::write.csv(vars, mape_caminho("dicionario", "variaveis.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8", na = "")
.mape_cache_dic$dic_variaveis <- NULL

# --- 3. Campos calculados ---------------------------------------------------

vars <- mape_recalcular_campos()

pend <- sum(vars$revisao_pendente %in% c(TRUE, "TRUE"), na.rm = TRUE)
message("\n============================================")
message("variáveis no dicionário: ", nrow(vars))
message("pendentes de revisão:    ", pend)
message("============================================")
