# Vulnerabilidade social e desenvolvimento humano

**Slug:** `05_sociedade`  
**Camada:** dimensao  
**Dimensão:** 05_sociedade

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Índice de Vulnerabilidade Social, seus subíndices e o IDHM, do Atlas da Vulnerabilidade Social do Ipea.

## Procedência

| | |
|---|---|
| Fonte original | Ipea — Atlas da Vulnerabilidade Social |
| Fonte da extração | Base dos Dados |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | Dado publico federal. Uso livre com citacao da fonte, nos termos da Lei de Acesso a Informacao (Lei 12.527/2011) e do Decreto 8.777/2016 (Politica de Dados Abertos do Executivo Federal). Verificado em 26/07/2026. O Atlas da Vulnerabilidade Social e do Ipea, fundacao publica federal. |
| Periodicidade da fonte | censitária |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 111.300 |
| Colunas | 10 |
| Municípios distintos | 5.565 de 5.570 (99.9%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 2000 e 2010 |
| **Cobertura observada na tabela** | **1996-2015** |
| Células vazias (colunas de conteúdo, sem as chaves) | 0.01% |
| Regra de preenchimento temporal | `mapa_censitario_legado` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `ano_ref_ivs` | double | codigo | Ano de realização do Atlas | 0.0% |
| `ivs_idx` | double | indice de 0 a 1 | Índice de Vulnerabilidade Social | 0.0% |
| `ivs_infraestrutura_urbana_idx` | double | indice de 0 a 1 | Índice de Vulnerabilidade Social - Dimensão Infraestrutura Urbana | 0.0% |
| `ivs_capital_humano_idx` | double | indice de 0 a 1 | Índice de Vulnerabilidade Social - Dimensão Capital Humano | 0.0% |
| `ivs_renda_trabalho_idx` | double | indice de 0 a 1 | Índice de Vulnerabilidade Social - Dimensão Renda e Trabalho | 0.0% |
| `idhm_idx` | double | indice de 0 a 1 | Índice de Desenvolvimento Humano Municipal | 0.0% |
| `vulnerabilidade_socioeconomica_pct` | double | percentual | Proporção das pessoas com renda per capita inferior a meio salario mínimo e gastam mais de uma hora até o trabalho | 0.0% |
| `prosperidade_social_cat` | character | classe | Prosperidade Social | 0.1% |

A coluna `vazios` acima é medida **nesta** tabela. Já os campos calculados do dicionário (`pct_na`, `minimo`, `maximo`, `n_distintos`) são medidos na tabela em que a variável é observada, que para 7 destas colunas é outra: `ivs_idx` (05_sociedade/atlas_ivs), `ivs_infraestrutura_urbana_idx` (05_sociedade/atlas_ivs), `ivs_capital_humano_idx` (05_sociedade/atlas_ivs), `ivs_renda_trabalho_idx` (05_sociedade/atlas_ivs), `idhm_idx` (05_sociedade/atlas_ivs), `vulnerabilidade_socioeconomica_pct` (05_sociedade/atlas_ivs), `prosperidade_social_cat` (05_sociedade/atlas_ivs). Os dois números podem divergir muito, e divergem por desenho: a fonte guarda o observado e a dimensão o painel expandido.

## Ressalvas

São DUAS observações reais por município, dos censos de 2000 e 2010, replicadas sobre 1996-2015. A coluna ano_avs registra o ano da medição e é a única forma de distinguir o dado medido do replicado. Ao adotar o armazenamento por observação (decisão 3.3 do plano), esta tabela cai de 111.300 para cerca de 11.140 linhas.

**`ano_ref_ivs`** — Sigla opaca (AVS = Atlas da Vulnerabilidade Social); e o ano censitario 2000/2010 replicado sobre 1996-2015 em sociedade.R

**`ivs_idx`** — Sigla sem expansao e sem escala; e uma das colunas consumidas pelo artigo

**`ivs_infraestrutura_urbana_idx`** — Subindice sem escala no nome

**`vulnerabilidade_socioeconomica_pct`** — Prefixo proporcao_ sem sufixo de escala; escala real 0-100

**`prosperidade_social_cat`** — Nome sugere indice numerico, mas o tipo e character (classe categorica)

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("05_sociedade")
x <- mape_ler("05_sociedade", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 21:35 por `mape_gerar_documentacao()`._

