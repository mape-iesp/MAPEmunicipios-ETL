# Fatiamento das fontes de granularidade divergente ---------------------------
#
# Este script fecha a decisão 3.3 do plano: as tabelas canônicas guardam o que
# foi observado, não o painel expandido.
#
# A migração em lote publicou as dimensões como o legado as produzia, porque o
# teste de paridade exige comparar o mesmo objeto. Isso deixou dentro de cinco
# dimensões blocos de coluna cuja granularidade nativa não é município por ano:
# o IVS é censitário, o IDEB é bienal, o AdaptaBrasil é um retrato de 2015, e o
# MCMV e a tarifa zero registram ocorrências, não uma série.
#
# Guardar esses blocos expandidos significa guardar a mesma medição vinte vezes
# e chamar o resultado de painel. Este script os extrai para tabelas de fonte
# próprias, cada uma com a sua granularidade real.
#
# O que NÃO muda: as tabelas de dimensão continuam sendo o painel município x
# ano, e continuam idênticas ao que passou na paridade. A fonte é o dado; a
# dimensão é a apresentação dele no painel. Quem quiser o observado lê a fonte;
# quem quiser a série lê a dimensão.
#
# Rodar com:  Rscript tools/migracao/fatiar_fontes.R

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) {
  source(f, encoding = "UTF-8")
}

# Cada entrada descreve uma fonte a extrair de dentro de uma dimensão.
#
#   colunas  — como localizar as colunas do bloco. Uma expressão regular sobre
#              os nomes canônicos, para que acrescentar uma coluna nova à fonte
#              não exija editar uma lista.
#   n_colunas_esperado — quantas colunas de conteúdo a regex TEM de capturar.
#              Achado 105: as regexes eram frágeis de dois jeitos opostos. A do
#              AdaptaBrasil tinha três alternativas que já não casam com nada
#              (`^capacidade_investimento_adaptacao`, `^indice_`,
#              `^cidades_resilientes` descrevem nomes que a harmonização
#              eliminou), e a do Atlas do IVS era `"."`, que casa TUDO. As duas
#              falhavam em silêncio: a primeira capturando menos do que devia se
#              o prefixo mudasse, a segunda capturando a dimensão inteira. Este
#              campo transforma os dois modos de falha em erro na hora.
#   metodo   — como desfazer a expansão. Ver mape_compactar_painel().
#
CONFIG <- list(

  list(
    slug = "03_meio_ambiente/adaptabrasil",
    dimensao = "03_meio_ambiente",
    # Os quatro prefixos antigos foram substituídos por um só: a harmonização
    # renomeou todas as colunas do bloco para `adapta_*`, e as outras três
    # alternativas não casavam mais nada.
    colunas = "^adapta_",
    n_colunas_esperado = 17L,
    metodo = "constante",
    ano_medicao = 2015L,
    nome_publicado = "AdaptaBrasil — risco climático, vulnerabilidade e capacidade adaptativa",
    descricao = paste(
      "Índices de risco, vulnerabilidade e capacidade de adaptação a inundações,",
      "enxurradas e seca, mais a adesão ao programa Cidades Resilientes.",
      "É um retrato único, não uma série: o AdaptaBrasil publica um valor por",
      "município, e o legado o replicava de 2010 a 2020 sem registrar que era",
      "o mesmo número onze vezes."
    ),
    chave_primaria = "id_municipio",
    granularidade = "municipio (retrato unico de 2015)",
    metodo_acesso = "download_manual",
    fonte_original = "AdaptaBrasil MCTI",
    fonte_extracao = "portal AdaptaBrasil (selecao manual de filtros)",
    link = "https://adaptabrasil.mcti.gov.br/",
    periodicidade_fonte = "eventual",
    cobertura_temporal_da_fonte = "2015",
    regra_preenchimento_temporal = "valor_unico_replicado",
    observacoes = paste(
      "O legado replicava o retrato de 2015 sobre 2010-2020, gerando 61.270",
      "linhas a partir de 5.570 medições. A replicação continua disponível na",
      "dimensao 03_meio_ambiente; aqui fica o observado."
    )
  ),

  list(
    slug = "05_sociedade/atlas_ivs",
    dimensao = "05_sociedade",
    # Era `"."`, que casa qualquer nome — inclusive as chaves e qualquer coluna
    # que a dimensão viesse a ganhar. A alternância explícita descreve o bloco.
    colunas = "^(ivs_|idhm_|vulnerabilidade_socioeconomica|prosperidade_social)",
    n_colunas_esperado = 7L,
    metodo = "ano_ref",
    ano_ref = "ano_ref_ivs",
    nome_publicado = "Atlas da Vulnerabilidade Social — IVS e IDHM",
    descricao = paste(
      "Índice de Vulnerabilidade Social e seus três subíndices, IDHM,",
      "percentual de vulneráveis à pobreza e classe de prosperidade social.",
      "Medido nos censos de 2000 e 2010."
    ),
    chave_primaria = "id_municipio, ano",
    granularidade = "municipio x ano censitario (2000 e 2010)",
    metodo_acesso = "download_manual",
    fonte_original = "IPEA — Atlas da Vulnerabilidade Social",
    fonte_extracao = "ivs.ipea.gov.br",
    link = "http://ivs.ipea.gov.br/",
    periodicidade_fonte = "censitaria",
    cobertura_temporal_da_fonte = "2000, 2010",
    regra_preenchimento_temporal = "valor_unico_replicado",
    observacoes = paste(
      "O legado replicava o censo de 2000 sobre 1996-2005 e o de 2010 sobre",
      "2006-2015, gerando 111.300 linhas a partir de 11.130 medições. Cinco",
      "municípios não aparecem nos dois censos."
    )
  ),

  list(
    slug = "09_educacao/ideb",
    dimensao = "09_educacao",
    colunas = "^ideb_|^media_ideb_|^media_saeb_|^media_projecao_|^ano_ref_ideb$",
    metodo = "ano_ref",
    ano_ref = "ano_ref_ideb",
    nome_publicado = "IDEB e SAEB por município, etapa e rede",
    descricao = paste(
      "Notas do IDEB e do SAEB e metas projetadas, agregadas por município e",
      "abertas por etapa de ensino (anos iniciais, anos finais, médio) e por",
      "rede (federal, estadual, municipal). Divulgação bienal."
    ),
    chave_primaria = "id_municipio, ano",
    granularidade = "municipio x ano de divulgacao (bienal, anos impares)",
    metodo_acesso = "bigquery",
    fonte_original = "INEP",
    fonte_extracao = "basedosdados.br_inep_ideb",
    link = "https://www.gov.br/inep/pt-br/areas-de-atuacao/pesquisas-estatisticas-e-indicadores/ideb",
    periodicidade_fonte = "bienal",
    cobertura_temporal_da_fonte = "2005-2023",
    regra_preenchimento_temporal = "carry_forward",
    observacoes = paste(
      "O legado propagava cada divulgação para o ano par seguinte, gerando",
      "111.388 linhas a partir de 55.694 medições."
    )
  ),

  list(
    slug = "09_educacao/censup",
    dimensao = "09_educacao",
    colunas = "^censup_|^total_instituicoes_",
    metodo = "preenchido",
    vazio = c(0),
    nome_publicado = "Censo da Educação Superior — instituições por natureza jurídica",
    descricao = paste(
      "Contagem de instituições de ensino superior no município, aberta por",
      "dependência administrativa e por natureza jurídica das privadas."
    ),
    chave_primaria = "id_municipio, ano",
    granularidade = "municipio x ano",
    metodo_acesso = "bigquery",
    fonte_original = "INEP — Censo da Educação Superior",
    fonte_extracao = "basedosdados.br_inep_censo_educacao_superior",
    link = "https://www.gov.br/inep/pt-br/areas-de-atuacao/pesquisas-estatisticas-e-indicadores/censo-da-educacao-superior",
    periodicidade_fonte = "anual",
    cobertura_temporal_da_fonte = "2009-2023",
    regra_preenchimento_temporal = "nenhuma",
    observacoes = paste(
      "A tabela publicada declara cobertura 1995-2023 e entrega 2009-2023: fora",
      "dessa faixa todas as contagens são zero, e o zero é preenchimento e não",
      "medição. Aqui ficam só os municipio-ano com pelo menos uma instituição."
    )
  ),

  list(
    slug = "11_transportes/tarifa_zero",
    dimensao = "11_transportes",
    colunas = "^ano_inicio_tarifa_zero$|^adota_tarifa_zero$",
    metodo = "preenchido",
    vazio = c(0),
    nome_publicado = "Municípios com tarifa zero no transporte público",
    descricao = paste(
      "Municípios que adotaram tarifa zero no transporte coletivo urbano, com",
      "o ano de início da política."
    ),
    chave_primaria = "id_municipio, ano",
    granularidade = "municipio x ano com a politica vigente",
    metodo_acesso = "download_manual",
    fonte_original = "Levantamento do Observatório da Tarifa Zero",
    fonte_extracao = "compilacao manual",
    link = "https://tarifazero.org/",
    periodicidade_fonte = "eventual",
    cobertura_temporal_da_fonte = "2004-2024",
    regra_preenchimento_temporal = "carry_forward",
    observacoes = paste(
      "O legado preenchia com zero todos os 183.814 municipio-ano do painel, o",
      "que faz a cobertura aparentar 100% quando a fonte registra 578",
      "municipio-ano com a política. O zero não é medição: é a ausência de",
      "registro no levantamento."
    )
  ),

  list(
    slug = "11_transportes/tarifas",
    dimensao = "11_transportes",
    colunas = "^tarifa_onibus_urbano|^comprometimento_tarifa",
    metodo = "preenchido",
    vazio = numeric(0),
    nome_publicado = "Tarifa de ônibus urbano e comprometimento de renda",
    descricao = paste(
      "Valor da tarifa de ônibus urbano, deflacionado para dezembro de 2023, e",
      "o peso dela sobre o salário mínimo e sobre a renda de domicílios",
      "chefiados por pessoas negras."
    ),
    chave_primaria = "id_municipio, ano",
    granularidade = "municipio x ano com tarifa levantada",
    metodo_acesso = "download_manual",
    fonte_original = "Levantamento próprio MAPE a partir de decretos municipais",
    fonte_extracao = "compilacao manual",
    link = NA_character_,
    periodicidade_fonte = "eventual",
    cobertura_temporal_da_fonte = "2018-2024",
    regra_preenchimento_temporal = "nenhuma",
    observacoes = paste(
      "Cobertura restrita: 351 municipio-ano com tarifa levantada, de um painel",
      "de 183.814. Os valores estão deflacionados e a série nominal não existe",
      "no repositório — ver pendencias/serie-nominal.md."
    )
  ),

  list(
    slug = "12_habitacao/mcmv_fgts",
    dimensao = "12_habitacao",
    colunas = "^mcmv_",
    metodo = "preenchido",
    vazio = c(0),
    nome_publicado = "Minha Casa Minha Vida — faixa financiada com FGTS",
    descricao = paste(
      "Unidades contratadas, entregues, vigentes e distratadas, e os valores",
      "contratado e desembolsado, na faixa do programa financiada com recursos",
      "do FGTS."
    ),
    chave_primaria = "id_municipio, ano",
    granularidade = "municipio x ano com contrato",
    metodo_acesso = "download_manual",
    fonte_original = "Ministério das Cidades / Caixa Econômica Federal",
    fonte_extracao = "planilha de acompanhamento do programa",
    link = "https://www.gov.br/cidades/pt-br/assuntos/habitacao",
    periodicidade_fonte = "eventual",
    cobertura_temporal_da_fonte = "2009-2024",
    regra_preenchimento_temporal = "nenhuma",
    observacoes = paste(
      "O legado preenchia com zero os 94.832 municipio-ano do painel; a fonte",
      "registra 11.153 com pelo menos um contrato. As colunas 'vigentes' e",
      "'distratadas' são posições em 30/09/2024, não fluxos do ano."
    )
  )
)

# ---------------------------------------------------------------------------

registrar_e_publicar <- function(cfg) {
  message("\n===== ", cfg$slug, " =====")
  dim_tab <- mape_ler_tabela(cfg$dimensao, camada = "dimensao")

  chaves <- intersect(c("id_municipio", "ano"), names(dim_tab))
  candidatas <- setdiff(names(dim_tab), chaves)
  cols <- grep(cfg$colunas, candidatas, value = TRUE)

  # Achado 105: a guarda de SUB-captura existia (`!length(cols)`) e a de
  # SOBRE-captura não. A regex `"."` do Atlas do IVS casava a dimensão inteira e
  # o fatiamento seguia em frente. Uma contagem esperada pega os dois lados.
  if (!is.null(cfg$n_colunas_esperado) && length(cols) != cfg$n_colunas_esperado) {
    stop("O padrão '", cfg$colunas, "' capturou ", length(cols),
         " coluna(s) de '", cfg$dimensao, "' e o esperado é ",
         cfg$n_colunas_esperado, ".\n",
         "capturadas: ", paste(cols, collapse = ", "), "\n",
         "Se o bloco mudou de propósito, atualize n_colunas_esperado no CONFIG ",
         "no mesmo commit — é para isso que ele existe.", call. = FALSE)
  }

  if (!length(cols)) {
    stop("Nenhuma coluna de '", cfg$dimensao, "' casa com o padrão '",
         cfg$colunas, "'.", call. = FALSE)
  }
  message("colunas do bloco: ", length(cols))

  x <- dim_tab[, c(chaves, cols), drop = FALSE]

  # As colunas de dado excluem a de ano de referência: ela é chave, não medida.
  cols_dado <- setdiff(cols, cfg$ano_ref)

  y <- switch(
    cfg$metodo,
    ano_ref = mape_compactar_painel(x, metodo = "ano_ref",
                                    ano_ref = cfg$ano_ref, cols = cols_dado),
    constante = mape_compactar_painel(x, metodo = "constante", cols = cols_dado,
                                      ano_medicao = cfg$ano_medicao),
    preenchido = mape_compactar_painel(x, metodo = "preenchido", cols = cols_dado,
                                       vazio = cfg$vazio)
  )

  mape_validar_chave(y, intersect(c("id_municipio", "ano"), names(y)))

  args <- cfg[intersect(names(cfg), c(
    "dimensao", "nome_publicado", "descricao", "chave_primaria", "granularidade",
    "metodo_acesso", "fonte_original", "fonte_extracao", "link", "licenca",
    "periodicidade_fonte", "cobertura_temporal_da_fonte",
    "regra_preenchimento_temporal", "observacoes"))]
  do.call(mape_registrar_tabela, c(list(slug = cfg$slug), args))

  # As variáveis do bloco passam a pertencer à fonte. A dimensão continua
  # enxergando-as, porque mape_variaveis_de() de uma dimensão inclui as fontes.
  vars <- mape_dicionario("variaveis", .recarregar = TRUE)
  alvo <- vars$nome_canonico %in% setdiff(names(y), c("id_municipio", "ano")) &
    !is.na(vars$dimensao) & vars$dimensao == cfg$dimensao
  vars$tabela[alvo] <- cfg$slug
  utils::write.csv(vars, mape_caminho("dicionario", "variaveis.csv"),
                   row.names = FALSE, fileEncoding = "UTF-8", na = "")
  .mape_cache_dic$dic_variaveis <- NULL
  message("dicionário: ", sum(alvo), " variáveis reatribuídas a ", cfg$slug)

  mape_escrever_tabela(y, cfg$slug, validar = FALSE, camada = "fonte")
  mape_validar_tabela(y, cfg$slug)

  data.frame(slug = cfg$slug, dimensao = cfg$dimensao,
             linhas_dimensao = nrow(dim_tab), linhas_fonte = nrow(y),
             colunas = length(cols), metodo = cfg$metodo,
             stringsAsFactors = FALSE)
}

resumo <- do.call(rbind, lapply(CONFIG, registrar_e_publicar))
resumo$reducao_pct <- round(100 * (1 - resumo$linhas_fonte / resumo$linhas_dimensao), 1)

message("\n======================= RESUMO =======================")
print(resumo, row.names = FALSE)
message("\nlinhas antes: ", format(sum(resumo$linhas_dimensao), big.mark = "."),
        "  |  depois: ", format(sum(resumo$linhas_fonte), big.mark = "."),
        "  |  redução: ",
        round(100 * (1 - sum(resumo$linhas_fonte) / sum(resumo$linhas_dimensao)), 1), "%")

utils::write.csv(resumo, mape_caminho("qa", "fatiamento_fontes.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
