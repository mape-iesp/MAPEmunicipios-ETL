# Registra a dimensão 01_assistencia_social_dh no dicionário -----------------
# Uso:  Rscript tools/migracao/registrar_01_assistencia_social_dh.R

for (f in list.files(here::here("R"), pattern = "[.]R$", full.names = TRUE)) {
  source(f, encoding = "UTF-8")
}

# ---------------------------------------------------------------------------
# CadÚnico
# ---------------------------------------------------------------------------
mape_registrar_tabela(
  slug = "01_assistencia_social_dh/cadunico",
  dimensao = "01_assistencia_social_dh",
  nome_publicado = "CadÚnico — famílias com cadastro atualizado",
  descricao = paste(
    "Contagem de famílias inscritas no Cadastro Único com dados atualizados,",
    "por faixa de renda per capita, e a Taxa de Atualização Cadastral do",
    "município. Uma família é considerada atualizada quando a última alteração",
    "de campos sensíveis tem menos de 24 meses."),
  chave_primaria = "id_municipio, ano",
  granularidade = "municipio x ano (snapshot de dezembro de cada ano)",
  metodo_acesso = "download_manual",
  fonte_original = "Ministério do Desenvolvimento e Assistência Social (MDS/SAGI)",
  fonte_extracao = "SAGI — indicador IN004 e Taxa de Atualização Cadastral",
  link = "https://wiki-sagi.mds.gov.br/home/DS/Cad/I/IN004",
  licenca = "a verificar",
  periodicidade_fonte = "mensal",
  cobertura_temporal_da_fonte = "2015-2024 (mensal)",
  regra_preenchimento_temporal = "nenhuma",
  script_ingestao = "fontes/01_assistencia_social_dh/cadunico/R/tratar_cadunico.R",
  citacao_recomendada = paste(
    "MDS/SAGI. Cadastro Único para Programas Sociais, indicadores municipais.",
    "Compilado no MAPEmunicipios."),
  observacoes = paste(
    "O snapshot anual é o mês de dezembro, por causa de um filtro herdado do",
    "legado ('12$'). Isso descarta 2024, cujo arquivo bruto vai até novembro:",
    "a fonte cobre 2015-2024 e a tabela entrega 2015-2023. Rever se o snapshot",
    "deve passar a ser o último mês disponível.",
    "A origem desta fonte esteve perdida e foi reconstruída no planejamento;",
    "não há script de download, apenas o procedimento no README.",
    "LIMITAÇÃO CONHECIDA: a Taxa de Atualização Cadastral restrita à faixa de",
    "até meio salário mínimo passa de 100% em 59 municípios, todos no ano de",
    "2016, chegando a 128,8%. Uma razão entre cadastros atualizados e cadastros",
    "totais não pode exceder 100% por definição; o excesso indica que numerador",
    "e denominador foram apurados em momentos diferentes, de modo que famílias",
    "que mudaram de faixa de renda entre as duas contagens aparecem só no",
    "numerador. Os valores foram MANTIDOS como vieram da fonte, sem truncamento,",
    "porque truncar esconderia o problema. A concentração em um único ano",
    "sugere falha na extração daquela edição. A outra taxa da mesma tabela tem",
    "máximo exatamente 100,00, o que indica que ela é truncada na origem e esta",
    "não é.")
)

mape_atribuir_variaveis(
  slug = "01_assistencia_social_dh/cadunico",
  nomes_legado = c(
    "cadun_qtd_familias_atualizadas_i",
    "cadun_qtd_familias_atualizadas_pobreza_pbf_i",
    "cadun_qtd_familias_atualizadas_baixa_renda_i",
    "cadun_qtd_familias_atualizadas_rfpc_ate_meio_sm_i",
    "cadun_qtd_familias_atualizadas_rfpc_acima_meio_sm_i",
    "cadun_qtd_familias_atualizadas_renda_zero_i",
    "cadun_taxa_atualizacao_cadastral_d",
    "cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_d"
  ),
  renomear = c(
    cadun_taxa_atualizacao_cadastral_d = "cadun_taxa_atualizacao_cadastral_pct",
    cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_d =
      "cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_pct"
  ),
  fixar = list(
    cadun_qtd_familias_atualizadas_i = list(
      tipo = "integer", escala = "contagem", unidade = "familias",
      dominio_valido = "[0,Inf]",
      descricao = paste("Famílias inscritas no CadÚnico com dados atualizados",
                        "(última alteração de campos sensíveis há menos de 24 meses).")),
    cadun_qtd_familias_atualizadas_pobreza_pbf_i = list(
      tipo = "integer", escala = "contagem", unidade = "familias",
      dominio_valido = "[0,Inf]",
      descricao = "Famílias atualizadas na faixa de pobreza do Bolsa Família."),
    cadun_qtd_familias_atualizadas_baixa_renda_i = list(
      tipo = "integer", escala = "contagem", unidade = "familias",
      dominio_valido = "[0,Inf]",
      descricao = "Famílias atualizadas na faixa de baixa renda."),
    cadun_qtd_familias_atualizadas_rfpc_ate_meio_sm_i = list(
      tipo = "integer", escala = "contagem", unidade = "familias",
      dominio_valido = "[0,Inf]",
      descricao = paste("Famílias atualizadas com renda familiar per capita de",
                        "até meio salário mínimo.")),
    cadun_qtd_familias_atualizadas_rfpc_acima_meio_sm_i = list(
      tipo = "integer", escala = "contagem", unidade = "familias",
      dominio_valido = "[0,Inf]",
      descricao = paste("Famílias atualizadas com renda familiar per capita",
                        "acima de meio salário mínimo.")),
    cadun_qtd_familias_atualizadas_renda_zero_i = list(
      tipo = "integer", escala = "contagem", unidade = "familias",
      dominio_valido = "[0,Inf]",
      descricao = "Famílias atualizadas com renda declarada igual a zero."),
    cadun_taxa_atualizacao_cadastral_pct = list(
      tipo = "double", escala = "0-100", unidade = "percentual",
      dominio_valido = "[0,100]",
      descricao = paste("Taxa de Atualização Cadastral: cadastros atualizados",
                        "sobre o total de cadastros do município. Componente do",
                        "Índice de Gestão Descentralizada do Bolsa Família.")),
    cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_pct = list(
      tipo = "double", escala = "0-100", unidade = "percentual",
      dominio_valido = "[0,100]",
      descricao = paste("Taxa de Atualização Cadastral restrita às famílias com",
                        "renda per capita de até meio salário mínimo."))
  )
)

# ---------------------------------------------------------------------------
# Disque 100
# ---------------------------------------------------------------------------
mape_registrar_tabela(
  slug = "01_assistencia_social_dh/disque100",
  dimensao = "01_assistencia_social_dh",
  nome_publicado = "Disque 100 — denúncias de violações de direitos humanos",
  descricao = paste(
    "Contagem anual de violações de direitos humanos denunciadas ao Disque",
    "Direitos Humanos, por município, no total e por grupo vulnerável."),
  chave_primaria = "id_municipio, ano",
  granularidade = "municipio x ano",
  metodo_acesso = "download_manual",
  fonte_original = "Ministério dos Direitos Humanos e da Cidadania",
  fonte_extracao = "Microdados do Disque 100",
  link = NA_character_,
  licenca = "a verificar",
  periodicidade_fonte = "anual",
  cobertura_temporal_da_fonte = "2011-2023",
  regra_preenchimento_temporal = "nenhuma",
  script_ingestao = "fontes/01_assistencia_social_dh/disque100/R/tratar_disque100.R",
  citacao_recomendada = paste(
    "MDHC. Disque Direitos Humanos (Disque 100), microdados.",
    "Compilado no MAPEmunicipios."),
  observacoes = paste(
    "Não há URL, órgão de extração, data ou script de download registrados em",
    "nenhum lugar da árvore legada. A procedência precisa ser reconstruída",
    "antes de a fonte poder ser atualizada.",
    "A contagem é de DENÚNCIAS, não de violações confirmadas, e é sensível à",
    "propensão a denunciar — que varia entre municípios e ao longo do tempo.")
)

mape_atribuir_variaveis(
  slug = "01_assistencia_social_dh/disque100",
  nomes_legado = c("total_violacoes", "total_violacoes_crianca_adolescente",
                   "total_violacoes_lgbtq", "total_violacoes_pcd",
                   "total_violacoes_pessoa_idosa", "total_violacoes_religiao"),
  renomear = c(
    total_violacoes = "disque100_violacoes_i",
    total_violacoes_crianca_adolescente = "disque100_violacoes_crianca_adolescente_i",
    total_violacoes_lgbtq = "disque100_violacoes_lgbtq_i",
    total_violacoes_pcd = "disque100_violacoes_pcd_i",
    total_violacoes_pessoa_idosa = "disque100_violacoes_pessoa_idosa_i",
    total_violacoes_religiao = "disque100_violacoes_religiao_i"
  ),
  fixar = list(
    disque100_violacoes_i = list(
      tipo = "integer", escala = "contagem", unidade = "denuncias",
      dominio_valido = "[0,Inf]",
      descricao = "Violações de direitos humanos denunciadas ao Disque 100."),
    disque100_violacoes_crianca_adolescente_i = list(
      tipo = "integer", escala = "contagem", unidade = "denuncias",
      dominio_valido = "[0,Inf]",
      descricao = "Denúncias cujo grupo vulnerável é criança ou adolescente."),
    disque100_violacoes_lgbtq_i = list(
      tipo = "integer", escala = "contagem", unidade = "denuncias",
      dominio_valido = "[0,Inf]",
      descricao = "Denúncias cujo grupo vulnerável é a população LGBTQIA+."),
    disque100_violacoes_pcd_i = list(
      tipo = "integer", escala = "contagem", unidade = "denuncias",
      dominio_valido = "[0,Inf]",
      descricao = "Denúncias cujo grupo vulnerável é pessoa com deficiência."),
    disque100_violacoes_pessoa_idosa_i = list(
      tipo = "integer", escala = "contagem", unidade = "denuncias",
      dominio_valido = "[0,Inf]",
      descricao = "Denúncias cujo grupo vulnerável é pessoa idosa."),
    disque100_violacoes_religiao_i = list(
      tipo = "integer", escala = "contagem", unidade = "denuncias",
      dominio_valido = "[0,Inf]",
      descricao = "Denúncias de violação por motivo de religião.")
  )
)

# ---------------------------------------------------------------------------
# MUNIC 2023, suplemento de Direitos Humanos: NÃO MIGRA
# ---------------------------------------------------------------------------
mape_registrar_pendencia(
  slug = "01_assistencia_social_dh/munic_dh",
  titulo = "MUNIC 2023 (suplemento de Direitos Humanos) não migra",
  diagnostico = paste(
    "O script `Munic/munic_DH.R` do legado não roda até o fim. Ele quebra em",
    "`library(labelled)`, um pacote que não está instalado nem declarado em",
    "lugar nenhum do projeto, e por isso nenhuma coluna desta fonte chega à",
    "saída da dimensão.\n\n",
    "Confirmei que a fonte não contribui com nada para a base publicada: as 14",
    "colunas da dimensão 8 vêm todas do Disque 100 (6) e do CadÚnico (8).",
    "Migrar uma fonte que não produz coluna nenhuma acrescentaria dado novo à",
    "base ao mesmo tempo que o código muda, o que contaminaria o teste de",
    "paridade — exatamente o que a seção 12.2 do plano existe para evitar."),
  evidencia = paste(
    "`8 Assistência Social e Direitos Humanos - Códigos e Dados/Munic/munic_DH.R`",
    "e o arquivo `Munic/Base_MUNIC_2023.xlsx`, que existe na pasta e nunca é",
    "lido até o fim."),
  impacto = paste(
    "Nada se perde em relação ao que está publicado hoje. O que se perde é o",
    "potencial: o suplemento de Direitos Humanos da MUNIC 2023 traz dados sobre",
    "a estrutura municipal de atendimento, que ninguém chegou a incorporar.",
    "Há também um `Base_MUNIC_2019.xlsx` órfão na mesma pasta, que nenhum",
    "script abre."),
  para_recuperar = paste(
    "Tratar como fonte NOVA, pelo procedimento da seção 8.2 do plano, e não",
    "como migração. Instalar `labelled`, ler o script até o fim para descobrir",
    "quais variáveis ele pretendia produzir, e registrar a fonte com manifesto",
    "próprio. Fica para depois da migração, porque acrescentar colunas novas",
    "agora quebraria a paridade.")
)

message("\n== dimensão 01_assistencia_social_dh registrada ==")
