# Minha Casa Minha Vida — faixa financiada com FGTS

**Slug:** `12_habitacao/mcmv_fgts`  
**Camada:** fonte  
**Dimensão:** 12_habitacao

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Unidades contratadas, entregues, vigentes e distratadas, e os valores contratado e desembolsado, na faixa do programa financiada com recursos do FGTS.

## Procedência

| | |
|---|---|
| Fonte original | Ministério das Cidades / Caixa Econômica Federal |
| Fonte da extração | planilha de acompanhamento do programa |
| Link | <https://www.gov.br/cidades/pt-br/assuntos/habitacao> |
| Método de acesso | `download_manual` |
| Licença | a verificar |
| Periodicidade da fonte | eventual |
| Script de ingestão | não informado |

## O que a tabela contém

| | |
|---|---|
| Linhas | 11.153 |
| Colunas | 8 |
| Municípios distintos | 4.610 de 5.570 (82.8%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano com contrato |
| Cobertura declarada pela fonte | 2009-2024 |
| **Cobertura observada na tabela** | **2007-2024** |
| Células vazias | 0% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `mcmv_unidades_contratadas_i` | double | unidades habitacionais | Unidades habitacionais contratadas no ano, na faixa do Minha Casa Minha Vida financiada com recursos do FGTS. | 0.0% |
| `mcmv_unidades_entregues_coorte_i` | double | contagem | Quantidade Unidades Habitacionais Entregues por ano no município | 0.0% |
| `mcmv_unidades_vigentes_em_20240930_i` | double | contagem | Quantidade Unidades Habitacionais Em construção  por ano no município | 0.0% |
| `mcmv_unidades_distratadas_em_20240930_i` | double | contagem | Quantidade Unidades Distratadas por ano no município | 0.0% |
| `mcmv_valor_contratado_brl2023` | double | R$ | Valor contratado no MCMV, por ano por município | 0.0% |
| `mcmv_valor_desembolsado_brl2023` | double | R$ | Valor desembolsado no MCMV, por ano por município | 0.0% |

## Ressalvas

O legado preenchia com zero os 94.832 municipio-ano do painel; a fonte registra 11.153 com pelo menos um contrato. As colunas 'vigentes' e 'distratadas' são posições em 30/09/2024, não fluxos do ano.

**`mcmv_unidades_contratadas_i`** — Sigla 'uh' (unidades habitacionais) opaca, sem prefixo de fonte nem de programa (MCMV/FGTS)

**`mcmv_unidades_entregues_coorte_i`** — Nao diz se sao entregues acumuladas ou no ano; na pratica e a soma dos contratos assinados no ano (entregues de coorte)

**`mcmv_unidades_vigentes_em_20240930_i`** — 'vigente' e um ESTOQUE medido na data_referencia (30/09/2024) imputado ao ano de assinatura - estoque tratado como fluxo

**`mcmv_unidades_distratadas_em_20240930_i`** — Mesmo problema de estoque-vs-fluxo

**`mcmv_valor_contratado_brl2023`** — Nome generico de valor monetario, sem fonte, sem programa e sem sufixo _def apesar de deflacionado para 12/2023 (habitacao.R:60-61); convive com 22 colunas valor_emendas_* que sao outro universo

**`mcmv_valor_desembolsado_brl2023`** — Idem; e a coluna mais afetada pelo bug de escala 100x

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("12_habitacao/mcmv_fgts")
x <- mape_ler("12_habitacao/mcmv_fgts", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 01:47 por `mape_gerar_documentacao()`._

