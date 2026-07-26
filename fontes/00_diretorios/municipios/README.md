# Diretório de municípios

**Slug:** `00_diretorios/municipios`  
**Camada:** fonte  
**Dimensão:** 00_diretorios

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Tabela de referência com os 5.570 municípios brasileiros: equivalências entre os códigos usados por IBGE, TSE, Receita Federal e Banco Central, hierarquia territorial completa (região, UF, mesorregião, microrregião, regiões imediata, intermediária, metropolitana e de saúde), e o centróide. É a espinha do painel: nenhuma outra tabela publica o bloco territorial.

## Procedência

| | |
|---|---|
| Fonte original | IBGE |
| Fonte da extração | Base dos Dados |
| Link | <https://basedosdados.org/dataset/br-bd-diretorios-brasil> |
| Método de acesso | `bigquery` |
| Licença | Dado publico federal. Uso livre com citacao da fonte, nos termos da Lei de Acesso a Informacao (Lei 12.527/2011) e do Decreto 8.777/2016 (Politica de Dados Abertos do Executivo Federal). Verificado em 26/07/2026. |
| Periodicidade da fonte | eventual |
| Script de ingestão | `fontes/00_diretorios/municipios/R/extrair_municipios.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 5.570 |
| Colunas | 27 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio` |
| Granularidade | municipio (transversal, sem dimensão temporal) |
| Cobertura declarada pela fonte | atemporal |
| **Cobertura observada na tabela** | **sem dimensão temporal** |
| Células vazias (colunas de conteúdo, sem as chaves) | 5.71% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `id_municipio` | character | codigo | ID Município - IBGE 7 Dígitos | 0.0% |
| `id_municipio_6` | character | codigo | ID Município - IBGE 6 Dígitos | 0.0% |
| `id_municipio_tse` | character | texto | ID Município - Tribunal Superior Eleitoral (TSE) | 0.0% |
| `id_municipio_rf` | character | texto | ID Município - Receita Federal (RF) | 0.0% |
| `id_municipio_bcb` | character | texto | ID Município - Banco Central do Brasil (BCB) | 0.0% |
| `nome_municipio` | character | texto | Nome do município | 0.0% |
| `sigla_uf` | character | texto | Sigla da Unidade da Federação | 0.0% |
| `nome_uf` | character | texto | Nome da Unidade da Federação | 0.0% |
| `id_uf` | character | texto | ID da Unidade da Federação - IBGE | 0.0% |
| `nome_regiao` | character | texto | Nome da Grande Região Brasileira | 0.0% |
| `flag_capital_uf` | integer | booleano | Município é a Capital da Unidade da Federação | 0.0% |
| `flag_amazonia_legal` | integer | booleano | Indicador se o município faz parte da Amazônia Legal | 0.0% |
| `ddd` | character | texto | Código de Discagem Direta a Distância (DDD) | 0.0% |
| `id_comarca` | character | texto | ID Sede Comarca | 0.0% |
| `id_regiao_saude` | character | texto | ID Região de Saúde | 0.0% |
| `nome_regiao_saude` | character | texto | Nome da Região de Saúde | 0.0% |
| `id_regiao_imediata` | character | texto | ID Região Imediata - IBGE | 0.0% |
| `nome_regiao_imediata` | character | texto | Nome da Região Imediata | 0.0% |
| `id_regiao_intermediaria` | character | texto | ID Região Intermediária - IBGE | 0.0% |
| `nome_regiao_intermediaria` | character | texto | Nome da Região Intermediária | 0.0% |
| `id_microrregiao` | character | texto | ID Microrregião - IBGE | 0.0% |
| `nome_microrregiao` | character | texto | Nome da Microrregião | 0.0% |
| `id_mesorregiao` | character | texto | ID Mesorregião - IBGE | 0.0% |
| `nome_mesorregiao` | character | texto | Nome da Mesorregião | 0.0% |
| `id_regiao_metropolitana` | character | texto | Lista de ID's da Região Metropolitana - IBGE | 74.3% |
| `nome_regiao_metropolitana` | character | texto | Lista de nomes da Região Metropolitana | 74.3% |
| `centroide_wkt` | character | texto | Centroide do município | 0.0% |

## Ressalvas

Snapshot dos municípios existentes hoje. Não representa a divisão territorial de anos anteriores: em 1991 havia cerca de 4.491 municípios, e Mojuí dos Campos foi criado em 2013. Ver a decisão 3.2 do plano. Durante a migração a tabela foi produzida a partir do artefato herdado, sem reextração, conforme a seção 12.2 do plano.

**`flag_capital_uf`** — integer64 0/1, mas o nome se le como 'a UF da capital'; sem prefixo de flag

**`flag_amazonia_legal`** — Flag 0/1 sem prefixo; tipo integer64 em diretorios.RData e character em meio_ambiente.RData

**`centroide_wkt`** — Tipo wk_wkt em diretorios.RData que vira character no xlsx; sem CRS nem formato no nome

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("00_diretorios/municipios")
x <- mape_ler("00_diretorios/municipios", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 20:38 por `mape_gerar_documentacao()`._

