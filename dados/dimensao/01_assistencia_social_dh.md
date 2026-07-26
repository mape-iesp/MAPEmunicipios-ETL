# Assistência Social e Direitos Humanos (dimensão consolidada)

**Slug:** `01_assistencia_social_dh`  
**Camada:** dimensao  
**Dimensão:** 01_assistencia_social_dh

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Tabela de dimensão, gerada pela junção das tabelas de fonte cadunico e disque100.

## Procedência

| | |
|---|---|
| Fonte original | MDS/SAGI e MDHC |
| Fonte da extração | derivada das tabelas de fonte desta dimensão |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | a verificar |
| Periodicidade da fonte | anual |
| Script de ingestão | `R/dimensao.R (mape_consolidar_dimensao)` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 67.406 |
| Colunas | 16 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 2011-2023 |
| **Cobertura observada na tabela** | **2011-2023** |
| Células vazias | 30% |
| Regra de preenchimento temporal | `nenhuma` |

## Ressalvas

Tabela DERIVADA. A camada canônica é a fonte; esta é gerada e republicada a cada execução.

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("01_assistencia_social_dh")
x <- mape_ler("01_assistencia_social_dh", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 01:47 por `mape_gerar_documentacao()`._

