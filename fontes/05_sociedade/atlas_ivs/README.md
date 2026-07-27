# Atlas da Vulnerabilidade Social — IVS e IDHM

**Slug:** `05_sociedade/atlas_ivs`  
**Camada:** fonte  
**Dimensão:** 05_sociedade

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Índice de Vulnerabilidade Social e seus três subíndices, IDHM, percentual de vulneráveis à pobreza e classe de prosperidade social. Medido nos censos de 2000 e 2010.

## Procedência

| | |
|---|---|
| Fonte original | IPEA — Atlas da Vulnerabilidade Social |
| Fonte da extração | ivs.ipea.gov.br |
| Link | <http://ivs.ipea.gov.br/> |
| Método de acesso | `download_manual` |
| Licença | Dado publico federal. Uso livre com citacao da fonte, nos termos da Lei de Acesso a Informacao (Lei 12.527/2011) e do Decreto 8.777/2016 (Politica de Dados Abertos do Executivo Federal). Verificado em 26/07/2026. Atlas da Vulnerabilidade Social, Ipea. |
| Periodicidade da fonte | censitaria |
| Script de ingestão | não informado |

## O que a tabela contém

| | |
|---|---|
| Linhas | 11.130 |
| Colunas | 9 |
| Municípios distintos | 5.565 de 5.570 (99.9%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano censitario (2000 e 2010) |
| Cobertura declarada pela fonte | 2000 e 2010 |
| **Cobertura observada na tabela** | **2000-2010** |
| Células vazias (colunas de conteúdo, sem as chaves) | 0.01% |
| Regra de preenchimento temporal | `mapa_censitario_legado` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `ivs_idx` | double | indice de 0 a 1 | Índice de Vulnerabilidade Social | 0.0% |
| `ivs_infraestrutura_urbana_idx` | double | indice de 0 a 1 | Índice de Vulnerabilidade Social - Dimensão Infraestrutura Urbana | 0.0% |
| `ivs_capital_humano_idx` | double | indice de 0 a 1 | Índice de Vulnerabilidade Social - Dimensão Capital Humano | 0.0% |
| `ivs_renda_trabalho_idx` | double | indice de 0 a 1 | Índice de Vulnerabilidade Social - Dimensão Renda e Trabalho | 0.0% |
| `idhm_idx` | double | indice de 0 a 1 | Índice de Desenvolvimento Humano Municipal | 0.0% |
| `vulnerabilidade_socioeconomica_pct` | double | percentual | Proporção das pessoas com renda per capita inferior a meio salario mínimo e gastam mais de uma hora até o trabalho | 0.0% |
| `prosperidade_social_cat` | character | classe | Prosperidade Social | 0.1% |

## Ressalvas

O legado replicava o censo de 2000 sobre 1996-2005 e o de 2010 sobre 2006-2015, gerando 111.300 linhas a partir de 11.130 medições. Cinco municípios não aparecem nos dois censos.

**`ivs_idx`** — Sigla sem expansao e sem escala; e uma das colunas consumidas pelo artigo

**`ivs_infraestrutura_urbana_idx`** — Subindice sem escala no nome

**`vulnerabilidade_socioeconomica_pct`** — Prefixo proporcao_ sem sufixo de escala; escala real 0-100

**`prosperidade_social_cat`** — Nome sugere indice numerico, mas o tipo e character (classe categorica)

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("05_sociedade/atlas_ivs")
x <- mape_ler("05_sociedade/atlas_ivs", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 21:35 por `mape_gerar_documentacao()`._

