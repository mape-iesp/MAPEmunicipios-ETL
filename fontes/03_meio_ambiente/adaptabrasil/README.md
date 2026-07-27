# AdaptaBrasil — risco climático, vulnerabilidade e capacidade adaptativa

**Slug:** `03_meio_ambiente/adaptabrasil`  
**Camada:** fonte  
**Dimensão:** 03_meio_ambiente

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Índices de risco, vulnerabilidade e capacidade de adaptação a inundações, enxurradas e seca, mais a adesão ao programa Cidades Resilientes. É um retrato único, não uma série: o AdaptaBrasil publica um valor por município, e o legado o replicava de 2010 a 2020 sem registrar que era o mesmo número onze vezes.

## Procedência

| | |
|---|---|
| Fonte original | AdaptaBrasil MCTI |
| Fonte da extração | portal AdaptaBrasil (selecao manual de filtros) |
| Link | <https://adaptabrasil.mcti.gov.br/> |
| Método de acesso | `download_manual` |
| Licença | Dado publico federal. Uso livre com citacao da fonte, nos termos da Lei de Acesso a Informacao (Lei 12.527/2011) e do Decreto 8.777/2016 (Politica de Dados Abertos do Executivo Federal). Verificado em 26/07/2026. AdaptaBrasil MCTI. |
| Periodicidade da fonte | eventual |
| Script de ingestão | não informado |

## O que a tabela contém

| | |
|---|---|
| Linhas | 5.570 |
| Colunas | 19 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio` |
| Granularidade | municipio (retrato unico de 2015) |
| Cobertura declarada pela fonte | 2015 |
| **Cobertura observada na tabela** | **2015-2015** |
| Células vazias (colunas de conteúdo, sem as chaves) | 0% |
| Regra de preenchimento temporal | `valor_unico_replicado` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `adapta_id_indicador` | double | identificador | Identificador interno do município na base do AdaptaBrasil. Não é o código do IBGE e não serve como chave; existe para rastrear a linha até o arquivo de origem. | 0.0% |
| `adapta_capacidade_investimento_idx` | double | indice | Capacidade de investimento público municipal e renda da população - investimentos em políticas de adaptação e em populações socioeconomicamente vulneráveis  | 0.0% |
| `adapta_capacidade_investimento_cat` | character | classe | Capacidade de investimento público municipal e renda da população - investimentos em políticas de adaptação e em populações socioeconomicamente vulneráveis (CLASSE) | 0.0% |
| `adapta_capacidade_adaptacao_inundacoes_idx` | double | indice | Índice de capacidade adaptativa para inundações, enxurradas e alagamentos  | 0.0% |
| `adapta_capacidade_adaptacao_inundacoes_cat` | character | classe | Índice de capacidade adaptativa para inundações, enxurradas e alagamentos  (CLASSE) | 0.0% |
| `adapta_risco_inundacoes_idx` | double | indice | Índice de Risco para inundações, enxurradas e alagamentos  | 0.0% |
| `adapta_risco_inundacoes_cat` | character | classe | Índice de Risco para inundações, enxurradas e alagamentos (CLASSE) | 0.0% |
| `adapta_vulnerabilidade_inundacoes_idx` | double | indice | Índice de vulnerabilidade para inundações, enxurradas e alagamentos | 0.0% |
| `adapta_vulnerabilidade_inundacoes_cat` | character | classe | Índice de vulnerabilidade para inundações, enxurradas e alagamentos (CLASSE) | 0.0% |
| `adapta_adesao_cidades_resilientes_idx` | double | indice | Adesão ao Programa Cidades Resilientes  | 0.0% |
| `adapta_adesao_cidades_resilientes_cat` | character | classe | Adesão ao Programa Cidades Resilientes (CLASSE) | 0.0% |
| `adapta_capacidade_recursos_hidricos_idx` | double | indice | Índice de capacidade adaptativa - recursos hídricos | 0.0% |
| `adapta_capacidade_recursos_hidricos_cat` | character | classe | Índice de capacidade adaptativa - recursos hídricos (CLASSE) | 0.0% |
| `adapta_risco_seca_idx` | double | indice | Índice de risco de impacto para seca | 0.0% |
| `adapta_risco_seca_cat` | character | classe | Índice de risco de impacto para seca (CLASSE) | 0.0% |
| `adapta_vulnerabilidade_seca_idx` | double | indice | Índice de vulnerabilidade - seca  | 0.0% |
| `adapta_vulnerabilidade_seca_cat` | character | classe | Índice de vulnerabilidade - seca (CLASSE) | 0.0% |

## Ressalvas

O legado replicava o retrato de 2015 sobre 2010-2020, gerando 61.270 linhas a partir de 5.570 medições. A replicação continua disponível na dimensao 03_meio_ambiente; aqui fica o observado.

**`adapta_id_indicador`** — Nome maximamente generico (id interno do indicador AdaptaBrasil) que sobrevive ate a base publicada, posicao 97 de renomear_variaveis.R:44

**`adapta_adesao_cidades_resilientes_idx`** — Nome plural que parece uma lista/contagem de cidades; e o indicador de adesao do municipio ao programa (AB6.1)

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("03_meio_ambiente/adaptabrasil")
x <- mape_ler("03_meio_ambiente/adaptabrasil", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 21:34 por `mape_gerar_documentacao()`._

