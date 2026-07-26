# Censo da Educação Superior — instituições por natureza jurídica

**Slug:** `09_educacao/censup`  
**Camada:** fonte  
**Dimensão:** 09_educacao

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Contagem de instituições de ensino superior no município, aberta por dependência administrativa e por natureza jurídica das privadas.

## Procedência

| | |
|---|---|
| Fonte original | INEP — Censo da Educação Superior |
| Fonte da extração | basedosdados.br_inep_censo_educacao_superior |
| Link | <https://www.gov.br/inep/pt-br/areas-de-atuacao/pesquisas-estatisticas-e-indicadores/censo-da-educacao-superior> |
| Método de acesso | `bigquery` |
| Licença | a verificar |
| Periodicidade da fonte | anual |
| Script de ingestão | não informado |

## O que a tabela contém

| | |
|---|---|
| Linhas | 10.642 |
| Colunas | 12 |
| Municípios distintos | 885 de 5.570 (15.9%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 2009-2023 |
| **Cobertura observada na tabela** | **2009-2023** |
| Células vazias | 0% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `censup_instituicoes_ensino_superior_i` | double | contagem | Total de Instituições de Ensino Superior | 0.0% |
| `censup_ies_federais_i` | double | contagem | Total de Instituições de Ensino Superior Públicas Federais | 0.0% |
| `censup_ies_estaduais_i` | double | instituições | Total de Instituições de Ensino Superior Públicas Estaduais | 0.0% |
| `censup_ies_municipais_i` | double | instituições | Total de Instituições de Ensino Superior Públicas Municipais | 0.0% |
| `censup_ies_privadas_com_fins_lucrativos_i` | double | instituições | Total de Instituições de Ensino Superior Privadas com fins lucrativos | 0.0% |
| `censup_ies_privadas_sem_fins_lucrativos_i` | double | instituições | Total de Instituições de Ensino Superior Privadas sem fins lucrativos | 0.0% |
| `censup_ies_privadas_particulares_i` | double | instituições | Total de Instituições de Ensino Superior Privadas Particulares | 0.0% |
| `censup_ies_especiais_i` | double | instituições | Total de Instituições de Ensino Superior Especiais | 0.0% |
| `censup_ies_privadas_comunitarias_i` | double | instituições | Total de Instituições de Ensino Superior Privadas Comunitárias | 0.0% |
| `censup_ies_privadas_confessionais_i` | double | instituições | Total de Instituições de Ensino Superior Privadas Confessionais | 0.0% |

## Ressalvas

A tabela publicada declara cobertura 1995-2023 e entrega 2009-2023: fora dessa faixa todas as contagens são zero, e o zero é preenchimento e não medição. Aqui ficam só os municipio-ano com pelo menos uma instituição.

**`censup_instituicoes_ensino_superior_i`** — ERRO DE DIGITACAO publicado (falta o 'i' de instituicoes) enquanto as nove colunas irmas escrevem certo; origem censo_educacao_superior.R:53, congelado em renomear_variaveis.R:93

**`censup_ies_federais_i`** — 'instituicoes' de que nao esta no nome (sao IES do Censo da Educacao Superior); prefixo total_ generico. Mesma familia: _estaduais, _municipais, _especial, _privada_com_fins_lucrativos, _privada_sem_f

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("09_educacao/censup")
x <- mape_ler("09_educacao/censup", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 01:47 por `mape_gerar_documentacao()`._

