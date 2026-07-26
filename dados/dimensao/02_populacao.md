# População residente e composição religiosa

**Slug:** `02_populacao`  
**Camada:** dimensao  
**Dimensão:** 02_populacao

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

População residente municipal estimada pelo IBGE e proporção de adeptos por grupo religioso, esta última medida apenas nos censos de 2000 e 2010 e replicada para os anos intermediários no legado.

## Procedência

| | |
|---|---|
| Fonte original | IBGE |
| Fonte da extração | Base dos Dados e censobr |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | a verificar |
| Periodicidade da fonte | anual (população) e censitária (religião) |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 179.930 |
| Colunas | 9 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 1991-2023 |
| **Cobertura observada na tabela** | **1991-2023** |
| Células vazias | 33% |
| Regra de preenchimento temporal | `valor_unico_replicado` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `ano` | integer | texto | Ano da coleta de dados | 0.0% |
| `populacao_residente_i` | double | contagem | População estimada IBGE | 0.3% |
| `censo_catolicos_prop` | double | proporcao | Proporção da população católica, códigos do Censo de 2010 e 2000 retirados do ISER | 38.5% |
| `censo_evangelicos_pentecostais_prop` | double | proporcao | Proporção da população evangélicos pentecostais, códigos do Censo de 2010 e 2000 retirados do ISER | 38.5% |
| `censo_evangelicos_missao_prop` | double | proporcao | Proporção da população evangélicos de missão, códigos do Censo de 2010 e 2000 retirados do ISER | 38.5% |
| `censo_espiritas_prop` | double | proporcao | Proporção da população espíritas, códigos do Censo de 2010 e 2000 retirados do ISER | 38.5% |
| `censo_matriz_africana_prop` | double | proporcao | Proporção da população religiões de matriz africana, códigos do Censo de 2010 e 2000 retirados do ISER | 38.5% |
| `ano_ref_censo_religiao` | double | codigo | Ano de realização do Censo | 38.5% |

## Ressalvas

As cinco colunas de composição religiosa vêm dos censos de 2000 e 2010 e são replicadas sobre 1996-2005 e 2006-2015. A coluna ano_censo é a única pista de que o valor é replicado, e ela sobreviveu por acidente. A população de 2023 vem de um arquivo cujo merge com o diretório foi feito à mão no Excel, sem código — ver a seção 8.5 do plano.

**`ano`** — Chave do painel com cinco tipos diferentes entre dimensoes (numeric, character, integer, integer64) e coercao manual em cada join do municipalityBR.qmd

**`populacao_residente_i`** — Generico; colide com a populacao da dim 4 (removida em municipalityBR.qmd:97) e semanticamente com populacao_atendida_agua/esgoto/urbana do SNIS

**`censo_catolicos_prop`** — Prefixo prop_ em vez de sufixo de escala; declarada STRING no dicionario e numeric em populacao_brasileira.RData

**`censo_evangelicos_pentecostais_prop`** — Prefixo prop_ sem sufixo de escala (0-1)

**`censo_evangelicos_missao_prop`** — Prefixo prop_ sem sufixo de escala (0-1)

**`censo_espiritas_prop`** — Prefixo prop_ sem sufixo de escala (0-1)

**`censo_matriz_africana_prop`** — Prefixo prop_ sem sufixo de escala (0-1)

**`ano_ref_censo_religiao`** — Generico: nao diz que e o ano do Censo de religiao (2000/2010) replicado sobre 1996-2015; mesmo padrao de ano_avs, ano_ideb, ano_eleicao, ano_inicio

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("02_populacao")
x <- mape_ler("02_populacao", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 01:47 por `mape_gerar_documentacao()`._

