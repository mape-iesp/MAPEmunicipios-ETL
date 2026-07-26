# Tarifas de transporte público e tarifa zero

**Slug:** `11_transportes`  
**Camada:** dimensao  
**Dimensão:** 11_transportes

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Tarifa de ônibus e comprometimento de renda com transporte público (Mobilidados), e adoção de política de tarifa zero.

## Procedência

| | |
|---|---|
| Fonte original | Mobilidados/ITDP e levantamento Daniel Santini |
| Fonte da extração | Base dos Dados e planilha colaborativa |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | a verificar |
| Periodicidade da fonte | eventual |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 183.814 |
| Colunas | 7 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 1992-2024 |
| **Cobertura observada na tabela** | **1991-2024** |
| Células vazias | 79.9% |
| Regra de preenchimento temporal | `nenhuma` |

## Ressalvas

A COBERTURA DE 100% NA BASE PUBLICADA É ARTEFATO. A fonte Mobilidados cobre 27 municípios; o restante do painel é esqueleto com valor imputado por soma acumulada. DEFEITO CONHECIDO: os cinco municípios que adotaram a tarifa zero e depois a encerraram (entre eles Palmas e Paulínia) aparecem com zero em TODOS os anos, inclusive naqueles em que a política estava em vigor, porque a aba de encerrados da planilha nunca é lida. A tarifa já vem deflacionada para dezembro de 2023, sem sufixo.

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("11_transportes")
x <- mape_ler("11_transportes", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 01:47 por `mape_gerar_documentacao()`._

