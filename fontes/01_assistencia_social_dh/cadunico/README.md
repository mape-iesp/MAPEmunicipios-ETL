# CadÚnico — famílias com cadastro atualizado

**Slug:** `01_assistencia_social_dh/cadunico`  
**Camada:** fonte  
**Dimensão:** 01_assistencia_social_dh

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Contagem de famílias inscritas no Cadastro Único com dados atualizados, por faixa de renda per capita, e a Taxa de Atualização Cadastral do município. Uma família é considerada atualizada quando a última alteração de campos sensíveis tem menos de 24 meses.

## Procedência

| | |
|---|---|
| Fonte original | Ministério do Desenvolvimento e Assistência Social (MDS/SAGI) |
| Fonte da extração | SAGI — indicador IN004 e Taxa de Atualização Cadastral |
| Link | <https://wiki-sagi.mds.gov.br/home/DS/Cad/I/IN004> |
| Método de acesso | `download_manual` |
| Licença | Dado publico federal. Uso livre com citacao da fonte, nos termos da Lei de Acesso a Informacao (Lei 12.527/2011) e do Decreto 8.777/2016 (Politica de Dados Abertos do Executivo Federal). Verificado em 26/07/2026. |
| Periodicidade da fonte | mensal |
| Script de ingestão | `fontes/01_assistencia_social_dh/cadunico/R/tratar_cadunico.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 50.130 |
| Colunas | 10 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano (snapshot de dezembro de cada ano) |
| Cobertura declarada pela fonte | 2015-2023 (snapshot de dezembro de cada ano) |
| **Cobertura observada na tabela** | **2015-2023** |
| Células vazias (colunas de conteúdo, sem as chaves) | 25% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `cadun_qtd_familias_atualizadas_i` | integer | familias | Famílias inscritas no CadÚnico com dados atualizados (última alteração de campos sensíveis há menos de 24 meses). | 0.0% |
| `cadun_qtd_familias_atualizadas_pobreza_pbf_i` | integer | familias | Famílias atualizadas na faixa de pobreza do Bolsa Família. | 55.6% |
| `cadun_qtd_familias_atualizadas_baixa_renda_i` | integer | familias | Famílias atualizadas na faixa de baixa renda. | 55.6% |
| `cadun_qtd_familias_atualizadas_rfpc_ate_meio_sm_i` | integer | familias | Famílias atualizadas com renda familiar per capita de até meio salário mínimo. | 0.0% |
| `cadun_qtd_familias_atualizadas_rfpc_acima_meio_sm_i` | integer | familias | Famílias atualizadas com renda familiar per capita acima de meio salário mínimo. | 55.6% |
| `cadun_qtd_familias_atualizadas_renda_zero_i` | integer | familias | Famílias atualizadas com renda declarada igual a zero. | 33.3% |
| `cadun_taxa_atualizacao_cadastral_pct` | double | percentual | Taxa de Atualização Cadastral: cadastros atualizados sobre o total de cadastros do município. Componente do Índice de Gestão Descentralizada do Bolsa Família. | 0.0% |
| `cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_pct` | double | percentual | Taxa de Atualização Cadastral restrita às famílias com renda per capita de até meio salário mínimo. | 0.0% |

## Ressalvas

O snapshot anual é o mês de dezembro, por causa de um filtro herdado do legado ('12$'). Isso descarta 2024, cujo arquivo bruto vai até novembro: a fonte cobre 2015-2024 e a tabela entrega 2015-2023. Rever se o snapshot deve passar a ser o último mês disponível. A origem desta fonte esteve perdida e foi reconstruída no planejamento; não há script de download, apenas o procedimento no README. LIMITAÇÃO CONHECIDA: a Taxa de Atualização Cadastral restrita à faixa de até meio salário mínimo passa de 100% em 59 municípios, todos no ano de 2016, chegando a 128,8%. Uma razão entre cadastros atualizados e cadastros totais não pode exceder 100% por definição; o excesso indica que numerador e denominador foram apurados em momentos diferentes, de modo que famílias que mudaram de faixa de renda entre as duas contagens aparecem só no numerador. Os valores foram MANTIDOS como vieram da fonte, sem truncamento, porque truncar esconderia o problema. A concentração em um único ano sugere falha na extração daquela edição. A outra taxa da mesma tabela tem máximo exatamente 100,00, o que indica que ela é truncada na origem e esta não é.

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("01_assistencia_social_dh/cadunico")
x <- mape_ler("01_assistencia_social_dh/cadunico", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 18:49 por `mape_gerar_documentacao()`._

