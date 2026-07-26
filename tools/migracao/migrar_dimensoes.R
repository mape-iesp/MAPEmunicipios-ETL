# Migra as dimensões restantes a partir dos artefatos do legado --------------
#
# Uso:  Rscript tools/migracao/migrar_dimensoes.R [slug ...]
#       sem argumento, migra todas as que estiverem configuradas aqui.
#
# Cada entrada de CONFIG diz o que é específico daquela dimensão. Tudo o que é
# comum está em mape_migrar_do_legado().

for (f in list.files(here::here("R"), pattern = "[.]R$", full.names = TRUE)) {
  source(f, encoding = "UTF-8")
}

L <- "1 Dimensões Individuais"

CONFIG <- list(
  "02_populacao" = list(
    arquivo = "2 População - Códigos e Dados/populacao_brasileira.RData",
    nome_publicado = "População residente e composição religiosa",
    descricao = paste(
      "População residente municipal estimada pelo IBGE e proporção de",
      "adeptos por grupo religioso, esta última medida apenas nos censos de",
      "2000 e 2010 e replicada para os anos intermediários no legado."),
    fonte_original = "IBGE", fonte_extracao = "Base dos Dados e censobr",
    periodicidade_fonte = "anual (população) e censitária (religião)",
    cobertura_temporal_da_fonte = "1991-2023",
    regra_preenchimento_temporal = "valor_unico_replicado",
    observacoes = paste(
      "As cinco colunas de composição religiosa vêm dos censos de 2000 e 2010",
      "e são replicadas sobre 1996-2005 e 2006-2015. A coluna ano_censo é a",
      "única pista de que o valor é replicado, e ela sobreviveu por acidente.",
      "A população de 2023 vem de um arquivo cujo merge com o diretório foi",
      "feito à mão no Excel, sem código — ver a seção 8.5 do plano.")
  ),
  "03_meio_ambiente" = list(
    arquivo = "3 Meio-Ambiente - Códigos e Dados/meio_ambiente.RData",
    descartar = "nome",
    nome_publicado = "Meio ambiente: desastres, saneamento, desmatamento e risco climático",
    descricao = paste(
      "Reúne quatro fontes com coberturas muito diferentes: desastres do Atlas",
      "S2iD, saneamento do SNIS, desmatamento do PRODES e índices de risco e",
      "capacidade adaptativa do AdaptaBrasil."),
    fonte_original = "SEDEC/MIDR e CEPED/UFSC, SNIS, INPE e MCTI",
    fonte_extracao = "Base dos Dados e downloads manuais",
    periodicidade_fonte = "anual, com exceções",
    cobertura_temporal_da_fonte = "1991-2023",
    regra_preenchimento_temporal = "valor_unico_replicado",
    observacoes = paste(
      "QUATRO FONTES COM COBERTURAS QUE MAL SE SOBREPÕEM: o Atlas de Desastres",
      "vai de 1991 a 2023, o SNIS de 1995 a 2022, o PRODES de 2000 a 2022, e o",
      "AdaptaBrasil é um RETRATO ÚNICO DE 2015 replicado sobre 2010-2020.",
      "As dezesseis colunas do AdaptaBrasil chegam ao artefato com nomes",
      "AB1.1 a AB9.2 e só recebem nome legível no renomeio posicional da etapa",
      "3 do legado. O mapeamento foi reconstruído e gravado em",
      "tools/migracao/mapa_renomeio_posicional.csv.",
      "DOIS INDICADORES PERDIDOS POR JUNÇÃO MAL ESPECIFICADA: oito indicadores",
      "do AdaptaBrasil são de 2015 e dois são de 2016; a junção inclui o ano na",
      "chave, o consolidador filtra ano == 2015, e os dois de 2016 somem — não",
      "por decisão, mas por consequência.",
      "indice_risco_seca é numérica e indice_risco_inundacoes_enxurradas é",
      "texto, vindas da mesma fonte e do mesmo bloco, porque a segunda usa o",
      "sentinela textual NaoDisponivel. O tratamento de sentinelas recupera o",
      "tipo.")
  ),
  "06_financas" = list(
    arquivo = "6 Finanças - Códigos e Dados/financas_municipais.RData",
    descartar = "nome",
    nome_publicado = "Finanças municipais: receitas orçamentárias e emendas parlamentares",
    descricao = paste(
      "Receitas orçamentárias municipais do SICONFI e valores de emendas",
      "parlamentares por função orçamentária, da CGU."),
    fonte_original = "Tesouro Nacional (SICONFI) e Controladoria-Geral da União",
    fonte_extracao = "Base dos Dados e Portal da Transparência",
    periodicidade_fonte = "anual",
    cobertura_temporal_da_fonte = "1989-2024",
    observacoes = paste(
      "CHAVE DUPLICADA NA ORIGEM: 222 pares município-ano aparecem mais de uma",
      "vez, com 235 linhas excedentes. A causa provável é a junção entre",
      "receitas e emendas, feita sem verificação de cardinalidade, combinada",
      "com o fato de as emendas serem associadas ao município POR NOME, sem UF",
      "— 1.067 de 11.649 linhas têm UF divergente, e o próprio comentário do",
      "script legado admite o problema.",
      "As 24 colunas de emendas chegam ao artefato com nomes em Title Case e",
      "com acento, gerados por pivot_wider (Comércio.e.serviços,",
      "Ciência.e.Tecnologia). Elas colidem com os NOMES DAS PRÓPRIAS DIMENSÕES",
      "do painel. O mapeamento para valor_emendas_* foi reconstruído e gravado.",
      "A receita própria é classificada por expressão regular sobre texto",
      "livre, procurando IPTU, ITBI e ISS no nome da conta.",
      "total_receitas_fundeb MEDE A DEDUÇÃO do FUNDEB, não uma receita.",
      "Os valores já vêm deflacionados para dezembro de 2023, sem sufixo.")
  ),
  "04_economia" = list(
    arquivo = "4 Economia - Códigos e Dados/pib_municipio.RData",
    descartar = c("id_municipio_nome", "populacao"),
    nome_publicado = "PIB municipal e valor adicionado",
    descricao = paste(
      "Produto Interno Bruto municipal, valor adicionado por setor e",
      "indicadores derivados, do Sistema de Contas Regionais do IBGE."),
    fonte_original = "IBGE — Contas Regionais",
    fonte_extracao = "Base dos Dados",
    periodicidade_fonte = "anual",
    cobertura_temporal_da_fonte = "1999-2021",
    observacoes = paste(
      "A coluna `populacao` que acompanhava esta fonte foi DESCARTADA: ela é",
      "uma segunda extração da mesma tabela do IBGE já publicada em",
      "02_populacao, idêntica em 100% das linhas comparáveis, e a duplicação",
      "faz a mesma consulta ser faturada duas vezes.",
      "CONSEQUÊNCIA CONHECIDA: pib_per_capita foi calculado com esse",
      "denominador, que o legado descarta depois da junção. ERRATA de",
      "26/07/2026 (achado 62): daqui saía a afirmação de que a coluna não",
      "seria reproduzível a partir da base publicada, e ela é FALSA —",
      "pib_brl2023 / populacao_residente_i, de 02_populacao, reproduz a",
      "coluna em 127.786 de 127.786 linhas, com desvio máximo de 7,3e-12.",
      "Ao reextrair, o cálculo deve usar 02_populacao explicitamente.",
      "Os valores monetários já vêm deflacionados para dezembro de 2023, e a",
      "série nominal não existe no repositório.")
  ),
  "05_sociedade" = list(
    arquivo = "5 Sociedade - Códigos e Dados/sociedade.RData",
    nome_publicado = "Vulnerabilidade social e desenvolvimento humano",
    descricao = paste(
      "Índice de Vulnerabilidade Social, seus subíndices e o IDHM, do Atlas",
      "da Vulnerabilidade Social do Ipea."),
    fonte_original = "Ipea — Atlas da Vulnerabilidade Social",
    fonte_extracao = "Base dos Dados",
    periodicidade_fonte = "censitária",
    cobertura_temporal_da_fonte = "2000 e 2010",
    regra_preenchimento_temporal = "valor_unico_replicado",
    observacoes = paste(
      "São DUAS observações reais por município, dos censos de 2000 e 2010,",
      "replicadas sobre 1996-2015. A coluna ano_avs registra o ano da medição",
      "e é a única forma de distinguir o dado medido do replicado.",
      "Ao adotar o armazenamento por observação (decisão 3.3 do plano), esta",
      "tabela cai de 111.300 para cerca de 11.140 linhas.")
  ),
  "07_recursos_humanos" = list(
    arquivo = "7 Recursos Humanos - Códigos e Dados/munic_RH.RData",
    nome_publicado = "Recursos humanos da administração municipal",
    descricao = paste(
      "Vínculos da administração direta e indireta municipal por tipo",
      "(estatutários, CLT, comissionados, estagiários), da pesquisa MUNIC."),
    fonte_original = "IBGE — Pesquisa de Informações Básicas Municipais",
    fonte_extracao = "arquivos .xlsx da MUNIC, por edição",
    periodicidade_fonte = "bienal",
    cobertura_temporal_da_fonte = "2009-2023, faltando 2010, 2016 e 2022",
    observacoes = paste(
      "DEFEITO CORRIGIDO NA MIGRAÇÃO: a planilha de 2019 traz 80 linhas",
      "fantasma, que contêm apenas o caractere '-' e atravessavam o pipeline",
      "com id_municipio nulo. Elas são eliminadas aqui.",
      "DEFEITO NÃO CORRIGIDO: em 2011 a variável de existência de",
      "administração indireta recebeu a coluna do total de funcionários, o que",
      "torna essa coluna categórica em onze anos e numérica em 2011.",
      "As edições de 2010, 2016 e 2022 nunca foram baixadas.")
  ),
  "08_energia_internet" = list(
    arquivo = "9 Energia e Internet - Códigos e Dados/energia_internet.RData",
    descartar = "nome_municipio",
    nome_publicado = "Energia elétrica e acesso à internet",
    descricao = paste(
      "Densidade de acessos de banda larga fixa e de telefonia móvel, e",
      "cobertura de eletricidade."),
    fonte_original = "Anatel e IBGE",
    fonte_extracao = "Base dos Dados e arquivos locais",
    periodicidade_fonte = "anual",
    cobertura_temporal_da_fonte = "2004-2024",
    observacoes = paste(
      "Dez das doze colunas desta dimensão eram homônimas entre banda larga e",
      "telefonia móvel no legado, distinguíveis apenas pelo arquivo de origem.",
      "Os prefixos anatel_bl_ e anatel_tm_ resolvem isso.",
      "Os metadados declaram 31 variáveis; a tabela entrega 10.")
  ),
  "09_educacao" = list(
    arquivo = "10 Educação - Códigos e Dados/educacao.RData",
    nome_publicado = "IDEB, SAEB e ensino superior",
    descricao = paste(
      "Notas do IDEB e do SAEB agregadas por município e contagem de",
      "instituições de ensino superior."),
    fonte_original = "INEP",
    fonte_extracao = "Base dos Dados",
    periodicidade_fonte = "bienal",
    cobertura_temporal_da_fonte = "2005-2023 (anos ímpares)",
    regra_preenchimento_temporal = "carry_forward",
    observacoes = paste(
      "O IDEB é BIENAL e o painel anual é construído replicando cada edição",
      "para o ano seguinte: 55.694 das 111.388 linhas carregam valores",
      "duplicados do ano ímpar anterior, e a única pista é comparar ano com",
      "ano_ideb.",
      "DEFEITO CONHECIDO: as colunas do Censo da Educação Superior tiveram NA",
      "trocado por zero por índice posicional, fabricando 27.850 linhas que",
      "afirmam ZERO instituições quando o correto seria ausência de dado.",
      "As colunas media_saeb_* NÃO vêm do SAEB: a extração do SAEB nunca foi",
      "implementada, e o único bloco ativo do script é sintaticamente inválido.")
  ),
  "10_saude" = list(
    arquivo = "11 Saúde - Códigos e Dados/saude.RData",
    descartar = "nome",
    nome_publicado = "Saúde: cobertura vacinal, atenção básica e indicadores IEPS",
    descricao = paste(
      "Cobertura vacinal por imunobiológico (SI-PNI), cobertura da atenção",
      "básica e da Estratégia Saúde da Família (e-Gestor), e indicadores de",
      "mortalidade, hospitalização e despesa do IEPS."),
    fonte_original = "Ministério da Saúde (SI-PNI, e-Gestor) e IEPS",
    fonte_extracao = "Base dos Dados e IEPS Data",
    periodicidade_fonte = "anual",
    cobertura_temporal_da_fonte = "1994-2021",
    observacoes = paste(
      "OITO CONCEITOS MEDIDOS DUAS VEZES, por SI-PNI e por IEPS. As duas",
      "séries são mantidas, porque não são versões concorrentes do mesmo",
      "número: o IEPS trunca em 100 e o SI-PNI não. E no caso da hepatite B",
      "elas medem populações DIFERENTES — o IEPS cobre só crianças até 30 dias",
      "—, com correlação de 0,061 entre as duas.",
      "A cobertura do SI-PNI chega a 13.050% por erro de denominador na",
      "população-alvo; os valores são mantidos e o domínio declarado.",
      "PERDA CONHECIDA: o arquivo do IEPS consumido tem 33.420 linhas contra",
      "66.840 do bruto — metade da fonte se perde antes de chegar aqui.",
      "As fontes SIA, SIM e SINAN têm script e nenhuma saída; ver pendencias/.")
  ),
  "11_transportes" = list(
    arquivo = "12 Transportes - Códigos e Dados/transportes.RData",
    descartar = "municipio_tarifa_zero",
    nome_publicado = "Tarifas de transporte público e tarifa zero",
    descricao = paste(
      "Tarifa de ônibus e comprometimento de renda com transporte público",
      "(Mobilidados), e adoção de política de tarifa zero."),
    fonte_original = "Mobilidados/ITDP e levantamento Daniel Santini",
    fonte_extracao = "Base dos Dados e planilha colaborativa",
    periodicidade_fonte = "eventual",
    cobertura_temporal_da_fonte = "1992-2024",
    observacoes = paste(
      "A COBERTURA DE 100% NA BASE PUBLICADA É ARTEFATO. A fonte Mobilidados",
      "cobre 27 municípios; o restante do painel é esqueleto com valor",
      "imputado por soma acumulada.",
      "DEFEITO CONHECIDO: os cinco municípios que adotaram a tarifa zero e",
      "depois a encerraram (entre eles Palmas e Paulínia) aparecem com zero em",
      "TODOS os anos, inclusive naqueles em que a política estava em vigor,",
      "porque a aba de encerrados da planilha nunca é lida.",
      "A tarifa já vem deflacionada para dezembro de 2023, sem sufixo.")
  ),
  "12_habitacao" = list(
    arquivo = "13 Habitação e Zoneamento - Códigos e Dados/habitacao.RData",
    nome_publicado = "Minha Casa Minha Vida — faixa financiada com FGTS",
    descricao = paste(
      "Unidades habitacionais contratadas e valores do programa Minha Casa",
      "Minha Vida, restrito à faixa financiada com recursos do FGTS."),
    fonte_original = "Ministério das Cidades / Caixa",
    fonte_extracao = "arquivo local sem URL registrada",
    periodicidade_fonte = "eventual",
    cobertura_temporal_da_fonte = "2007-2019",
    observacoes = paste(
      "ESCOPO: cobre APENAS a faixa financiada com FGTS. A faixa subsidiada",
      "com recursos do OGU não existe no repositório — o arquivo que deveria",
      "contê-la é byte a byte idêntico ao do FGTS.",
      "DEFEITO GRAVE NÃO CORRIGIDO NESTA MIGRAÇÃO: os valores monetários estão",
      "inflados em até cem vezes por um gsub aninhado na ordem errada, que",
      "remove o ponto decimal que ele mesmo acabou de criar. Corrigir exige",
      "reprocessar a fonte, o que está fora do escopo desta etapa; ver",
      "pendencias/.",
      "O painel começa em 2007, dois anos antes da criação do programa.")
  ),
  "13_seguranca" = list(
    arquivo = "14 Segurança - Códigos e Dados/seguranca.RData",
    descartar = c("sigla_uf_nome", "id_municipio_nome"),
    nome_publicado = "Mortalidade violenta e ocorrências criminais",
    descricao = paste(
      "Óbitos por causas violentas do SIM/DataSUS e ocorrências criminais",
      "registradas do Anuário Brasileiro de Segurança Pública."),
    fonte_original = "Ministério da Saúde (SIM) e Fórum Brasileiro de Segurança Pública",
    fonte_extracao = "Base dos Dados",
    periodicidade_fonte = "anual",
    cobertura_temporal_da_fonte = "1996-2021",
    observacoes = paste(
      "COBERTURA MUITO DESIGUAL ENTRE AS DUAS FONTES. O SIM cobre os 5.570",
      "municípios de 1996 a 2019. O Anuário do FBSP cobre 27 municípios (as 26",
      "capitais mais Brasília) de 2016 a 2021, ou seja, 162 linhas: as 26",
      "colunas quantidade_* têm dado em 0,09% do painel.",
      "DEFEITO NÃO CORRIGIDO: a mortalidade do Rio de Janeiro entre 1996 e 1998",
      "está subestimada em cerca de 97%, porque o SIM codificou os óbitos do",
      "município em 30 pseudo-códigos sub-municipais que a junção descarta.",
      "DEFEITO NÃO CORRIGIDO: uma quebra de linha dentro da expressão regular",
      "de classificação faz com que nenhum óbito com causa X96 seja contado",
      "como homicídio.",
      "27 códigos de UF disfarçados de município existem na fonte e não entram",
      "nesta tabela; devem ir para uma tabela em nível de UF.")
  ),
  "14_corrupcao" = list(
    arquivo = "15 Corrupção e Transparência - Códigos e Dados/corrupcao.RData",
    nome_publicado = "Fiscalização da CGU em entes federativos",
    descricao = paste(
      "Ações de fiscalização da Controladoria-Geral da União em municípios",
      "sorteados, com montante fiscalizado e proporção de falhas graves."),
    fonte_original = "Controladoria-Geral da União",
    fonte_extracao = "microdados do Programa de Fiscalização em Entes Federativos",
    periodicidade_fonte = "eventual",
    cobertura_temporal_da_fonte = "2006-2018",
    observacoes = paste(
      "GRANULARIDADE REAL É EVENTO, NÃO PAINEL. O programa audita municípios",
      "SORTEADOS, e o dado bruto é uma tabela de constatações dentro de ordens",
      "de serviço dentro de ciclos de sorteio. A agregação para município-ano",
      "produz 1.516 linhas, que na base larga ocupavam 180.285 — ou seja,",
      "99,2% de células vazias. É o caso que justifica sozinho publicar",
      "tabelas separadas.",
      "DEFEITO NÃO CORRIGIDO: montante_fiscalizado é atributo da ordem de",
      "serviço e é somado uma vez por constatação, inflando o valor em 4,87",
      "vezes na mediana e até 34,2 vezes. total_acao conta constatações",
      "(82.664) e não ações de fiscalização (22.713).",
      "DEFEITO NÃO CORRIGIDO: o deflator usa o ano da fiscalização quando",
      "deveria usar o ano do repasse, que existe no bruto e é ignorado.")
  ),
  "16_eleicoes" = list(
    arquivo = "17 Eleições - Códigos e Dados/eleicoes.RData",
    nome_publicado = "Eleições municipais e alinhamento político",
    descricao = paste(
      "Resultados das eleições municipais: comparecimento, votos por",
      "candidato eleito e segundo colocado, concentração partidária e",
      "alinhamento com o governo estadual."),
    fonte_original = "Tribunal Superior Eleitoral",
    fonte_extracao = "Base dos Dados e pacotes de acesso ao TSE",
    periodicidade_fonte = "quadrienal",
    cobertura_temporal_da_fonte = "2000-2020",
    regra_preenchimento_temporal = "carry_forward",
    observacoes = paste(
      "O PAINEL ANUAL NÃO TEM DADO ANUAL: é carry-forward puro. O valor do ano",
      "da eleição é replicado nos três anos seguintes do mandato.",
      "DEFEITO GRAVE: os rótulos de votos brancos e nulos estão TROCADOS. A",
      "coluna chamada proporcao_votos_nulos_prefeitura contém votos BRANCOS,",
      "por causa de um rename() que passa o mesmo argumento de origem duas",
      "vezes. O dicionário e a planilha de variáveis documentam as duas ao",
      "contrário do conteúdo, então concordam entre si e discordam do dado.",
      "ESCALAS INCOMPATÍVEIS na mesma tabela: pct_votos_eleito está em 0-1 e",
      "pct_votos_governador_eleito está em 0-100.",
      "Sete variáveis de governador são, na verdade, UF x ano replicadas em",
      "todos os municípios do estado.",
      "1,28 GB de microdados do TSE de 2022 e 2024 estão em disco e não são",
      "referenciados por nenhum script; a série para em 2020.")
  )
)

# ---------------------------------------------------------------------------
alvos <- commandArgs(trailingOnly = TRUE)
if (!length(alvos)) alvos <- names(CONFIG)
alvos <- intersect(alvos, names(CONFIG))

resumo <- list()
for (d in alvos) {
  cfg <- CONFIG[[d]]
  message("\n", strrep("=", 70), "\n", d, "\n", strrep("=", 70))

  args_reg <- cfg[intersect(names(cfg), c(
    "nome_publicado", "descricao", "fonte_original", "fonte_extracao", "link",
    "licenca", "periodicidade_fonte", "cobertura_temporal_da_fonte",
    "regra_preenchimento_temporal", "citacao_recomendada", "observacoes"))]
  do.call(mape_registrar_dimensao_legado, c(
    list(dimensao = d,
         chave_primaria = "id_municipio, ano",
         granularidade = "municipio x ano",
         metodo_acesso = "arquivo_local",
         script_ingestao = "tools/migracao/migrar_dimensoes.R"),
    args_reg))

  x <- tryCatch(
    mape_migrar_do_legado(
      dimensao = d, arquivo = cfg$arquivo,
      descartar = cfg$descartar, renomear = cfg$renomear,
      inteiras = cfg$inteiras),
    error = function(e) { message("ERRO: ", conditionMessage(e)); NULL }
  )
  if (is.null(x)) { resumo[[d]] <- c(NA, NA); next }

  qa <- suppressWarnings(mape_validar_tabela(x, d, erro = FALSE))
  par <- suppressWarnings(tryCatch(mape_paridade(d),
                                   error = function(e) { message("paridade: ", conditionMessage(e)); NULL }))
  resumo[[d]] <- c(
    linhas = nrow(x), colunas = ncol(x),
    qa_erros = sum(qa$gravidade == "erro"), qa_avisos = sum(qa$gravidade == "aviso"),
    paridade_nao_explicada = if (is.null(par)) NA else sum(par$classe == "c_nao_explicada")
  )
}

message("\n", strrep("=", 70), "\nRESUMO\n", strrep("=", 70))
print(do.call(rbind, resumo))
