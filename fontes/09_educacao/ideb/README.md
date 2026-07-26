# IDEB e SAEB por município, etapa e rede

**Slug:** `09_educacao/ideb`  
**Camada:** fonte  
**Dimensão:** 09_educacao

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Notas do IDEB e do SAEB e metas projetadas, agregadas por município e abertas por etapa de ensino (anos iniciais, anos finais, médio) e por rede (federal, estadual, municipal). Divulgação bienal.

## Procedência

| | |
|---|---|
| Fonte original | INEP |
| Fonte da extração | basedosdados.br_inep_ideb |
| Link | <https://www.gov.br/inep/pt-br/areas-de-atuacao/pesquisas-estatisticas-e-indicadores/ideb> |
| Método de acesso | `bigquery` |
| Licença | a verificar |
| Periodicidade da fonte | bienal |
| Script de ingestão | não informado |

## O que a tabela contém

| | |
|---|---|
| Linhas | 55.694 |
| Colunas | 26 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano de divulgacao (bienal, anos impares) |
| Cobertura declarada pela fonte | 2005-2023 |
| **Cobertura observada na tabela** | **2005-2023** |
| Células vazias | 32.8% |
| Regra de preenchimento temporal | `carry_forward` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `ideb_nota_municipio_idx` | double | escore de 0 a 10 | Média IDEB município | 1.4% |
| `saeb_nota_padronizada_municipio_idx` | double | escore padronizado | Média SAEB município | 1.4% |
| `ideb_meta_projetada_municipio_idx` | double | escore de 0 a 10 | Média Projeção IDEB município | 30.4% |
| `ideb_nota_fundamental_idx` | double | escore de 0 a 10 | — | 1.5% |
| `ideb_nota_medio_idx` | double | escore de 0 a 10 | — | 66.7% |
| `saeb_nota_fundamental_idx` | double | escore de 0 a 10 | — | 1.5% |
| `saeb_nota_medio_idx` | double | escore de 0 a 10 | — | 66.7% |
| `ideb_meta_projetada_fundamental_idx` | double | escore de 0 a 10 | — | 30.4% |
| `ideb_meta_projetada_medio_idx` | double | escore de 0 a 10 | — | 90.5% |
| `ideb_nota_ef_anos_finais_idx` | double | escore de 0 a 10 | — | 4.5% |
| `ideb_nota_ef_anos_iniciais_idx` | double | escore de 0 a 10 | — | 4.3% |
| `saeb_nota_anos_finais_idx` | double | escore de 0 a 10 | — | 4.5% |
| `saeb_nota_anos_iniciais_idx` | double | escore de 0 a 10 | — | 4.3% |
| `ideb_meta_projetada_anos_finais_idx` | double | escore de 0 a 10 | — | 30.9% |
| `ideb_meta_projetada_anos_iniciais_idx` | double | escore de 0 a 10 | — | 31.4% |
| `ideb_nota_rede_estadual_idx` | double | escore de 0 a 10 | — | 14.8% |
| `ideb_nota_rede_municipal_idx` | double | escore de 0 a 10 | — | 9.3% |
| `ideb_nota_rede_federal_idx` | double | escore de 0 a 10 | — | 98.7% |
| `saeb_nota_rede_estadual_idx` | double | escore de 0 a 10 | — | 14.8% |
| `saeb_nota_rede_municipal_idx` | double | escore de 0 a 10 | — | 9.3% |
| `saeb_nota_rede_federal_idx` | double | escore de 0 a 10 | — | 98.7% |
| `ideb_meta_projetada_rede_estadual_idx` | double | escore de 0 a 10 | — | 37.4% |
| `ideb_meta_projetada_rede_municipal_idx` | double | escore de 0 a 10 | — | 35.3% |
| `ideb_meta_projetada_rede_federal_idx` | double | escore de 0 a 10 | — | 99.3% |

## Ressalvas

O legado propagava cada divulgação para o ano par seguinte, gerando 111.388 linhas a partir de 55.694 medições.

**`ideb_nota_municipio_idx`** — Media NAO PONDERADA de todas as linhas do municipio, incluindo as tres redes; convive com media_ideb_rede_* sem hierarquia explicita no nome

**`saeb_nota_padronizada_municipio_idx`** — Atribui a fonte SAEB a um dado que vem da coluna nota_saeb_media_padronizada da tabela do IDEB (mesma familia: _fundamental, _medio, _anos_finais, _anos_iniciais, _rede_*)

**`ideb_meta_projetada_municipio_idx`** — 'projecao' de que indicador nao esta no nome: e a META do IDEB (mesma familia: _fundamental, _medio, _anos_finais, _anos_iniciais, _rede_*)

**`ideb_nota_ef_anos_finais_idx`** — 'anos' aqui significa SERIES escolares, no meio de uma base cuja chave temporal tambem se chama ano

**`ideb_nota_ef_anos_iniciais_idx`** — Idem; e um recorte que se SOBREPOE a media_ideb_fundamental sem prefixo que indique o eixo de corte

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("09_educacao/ideb")
x <- mape_ler("09_educacao/ideb", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 01:47 por `mape_gerar_documentacao()`._

