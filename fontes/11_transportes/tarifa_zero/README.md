# Municípios com tarifa zero no transporte público

**Slug:** `11_transportes/tarifa_zero`  
**Camada:** fonte  
**Dimensão:** 11_transportes

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Municípios que adotaram tarifa zero no transporte coletivo urbano, com o ano de início da política.

## Procedência

| | |
|---|---|
| Fonte original | Levantamento do Observatório da Tarifa Zero |
| Fonte da extração | compilacao manual |
| Link | <https://tarifazero.org/> |
| Método de acesso | `download_manual` |
| Licença | a verificar |
| Periodicidade da fonte | eventual |
| Script de ingestão | não informado |

## O que a tabela contém

| | |
|---|---|
| Linhas | 578 |
| Colunas | 4 |
| Municípios distintos | 106 de 5.570 (1.9%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano com a politica vigente |
| Cobertura declarada pela fonte | 2004-2024 |
| **Cobertura observada na tabela** | **1992-2024** |
| Células vazias | 40.8% |
| Regra de preenchimento temporal | `carry_forward` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `ano_ref_inicio_tarifa_zero` | double | ano | Ano início Tarifa Zero | 81.7% |
| `flag_adota_tarifa_zero` | double | 0 ou 1 | Adota Tarifa Zero | 0.0% |

## Ressalvas

O legado preenchia com zero todos os 183.814 municipio-ano do painel, o que faz a cobertura aparentar 100% quando a fonte registra 578 municipio-ano com a política. O zero não é medição: é a ausência de registro no levantamento.

**`ano_ref_inicio_tarifa_zero`** — Ano de referência, não chave do painel: por isso o prefixo ano_ref_.

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("11_transportes/tarifa_zero")
x <- mape_ler("11_transportes/tarifa_zero", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 01:47 por `mape_gerar_documentacao()`._

