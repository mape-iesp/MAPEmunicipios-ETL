# IDEB, SAEB e ensino superior

**Slug:** `09_educacao`  
**Camada:** dimensao  
**Dimensão:** 09_educacao

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Notas do IDEB e do SAEB agregadas por município e contagem de instituições de ensino superior.

## Procedência

| | |
|---|---|
| Fonte original | INEP |
| Fonte da extração | Base dos Dados |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | a verificar |
| Periodicidade da fonte | bienal |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 111.388 |
| Colunas | 37 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 2005-2023 (anos ímpares) |
| **Cobertura observada na tabela** | **2005-2024** |
| Células vazias | 22.5% |
| Regra de preenchimento temporal | `carry_forward` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `ano_ref_ideb` | double | codigo | Ano de realização do IDEB | 0.0% |

## Ressalvas

O IDEB é BIENAL e o painel anual é construído replicando cada edição para o ano seguinte: 55.694 das 111.388 linhas carregam valores duplicados do ano ímpar anterior, e a única pista é comparar ano com ano_ideb. DEFEITO CONHECIDO: as colunas do Censo da Educação Superior tiveram NA trocado por zero por índice posicional, fabricando 27.850 linhas que afirmam ZERO instituições quando o correto seria ausência de dado. As colunas media_saeb_* NÃO vêm do SAEB: a extração do SAEB nunca foi implementada, e o único bloco ativo do script é sintaticamente inválido.

**`ano_ref_ideb`** — Ano da EDICAO da avaliacao (impares 2005-2023, numeric) convivendo com ano do painel (character); nada no nome indica que e a chave que distingue medicao de valor replicado

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("09_educacao")
x <- mape_ler("09_educacao", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 01:47 por `mape_gerar_documentacao()`._

