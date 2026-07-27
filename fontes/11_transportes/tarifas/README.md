# Tarifa de ônibus urbano e comprometimento de renda

**Slug:** `11_transportes/tarifas`  
**Camada:** fonte  
**Dimensão:** 11_transportes

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Valor da tarifa de ônibus urbano, deflacionado para dezembro de 2023, e o peso dela sobre o salário mínimo e sobre a renda de domicílios chefiados por pessoas negras.

## Procedência

| | |
|---|---|
| Fonte original | Levantamento próprio MAPE a partir de decretos municipais |
| Fonte da extração | compilacao manual |
| Link | não informado |
| Método de acesso | `download_manual` |
| Licença | Levantamento proprio do MAPE a partir de decretos municipais, que sao atos publicos. A compilacao e do projeto e e publicada sob CC BY 4.0. |
| Periodicidade da fonte | eventual |
| Script de ingestão | não informado |

## O que a tabela contém

| | |
|---|---|
| Linhas | 351 |
| Colunas | 5 |
| Municípios distintos | 27 de 5.570 (0.5%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano com tarifa levantada |
| Cobertura declarada pela fonte | 2005-2017 |
| **Cobertura observada na tabela** | **2005-2017** |
| Células vazias (colunas de conteúdo, sem as chaves) | 7.69% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `comprometimento_tarifa_sobre_renda_domesticas_negras_prop` | double | proporcao | Comprometimento da renda para trabalhadoras domésticas negras | 23.1% |
| `comprometimento_tarifa_sobre_salario_minimo_prop` | double | proporcao | Comprometimento da renda de um salário mínimo | 0.0% |
| `tarifa_onibus_urbano_brl2023` | double | BRL de dezembro de 2023 | Tarifa de transporte público para 26 capitais e Distrito Federal | 0.0% |

## Ressalvas

Cobertura restrita: 351 municipio-ano com tarifa levantada, de um painel de 183.814. Os valores estão deflacionados e a série nominal não existe no repositório — ver pendencias/serie-nominal.md.

**`comprometimento_tarifa_sobre_renda_domesticas_negras_prop`** — Sem escala no nome (fracao 0-1)

**`comprometimento_tarifa_sobre_salario_minimo_prop`** — Sem 'renda' e sem escala no nome (fracao 0-1); denominador so no nome parcialmente

**`tarifa_onibus_urbano_brl2023`** — Plural generico, sem unidade (R$), sem dizer que e passagem de onibus urbano e sem marca de deflacao - e o MESMO NOME em duas escalas (nominal x 12/2023)

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("11_transportes/tarifas")
x <- mape_ler("11_transportes/tarifas", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 22:10 por `mape_gerar_documentacao()`._

