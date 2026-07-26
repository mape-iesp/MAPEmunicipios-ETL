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
| Licença | a verificar |
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
| Células vazias | 0% |
| Regra de preenchimento temporal | `valor_unico_replicado` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `ano_ref_ivs` | double | codigo | Ano de realização do Atlas | 0.0% |

## Ressalvas

São DUAS observações reais por município, dos censos de 2000 e 2010, replicadas sobre 1996-2015. A coluna ano_avs registra o ano da medição e é a única forma de distinguir o dado medido do replicado. Ao adotar o armazenamento por observação (decisão 3.3 do plano), esta tabela cai de 111.300 para cerca de 11.140 linhas.

**`ano_ref_ivs`** — Sigla opaca (AVS = Atlas da Vulnerabilidade Social); e o ano censitario 2000/2010 replicado sobre 1996-2015 em sociedade.R

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("05_sociedade")
x <- mape_ler("05_sociedade", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 01:47 por `mape_gerar_documentacao()`._

