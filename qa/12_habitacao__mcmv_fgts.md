# QA — 12_habitacao/mcmv_fgts

Gerado em 2026-07-26 15:22:32.

## Resumo

- linhas: 11.153
- colunas: 8
- células vazias (todas as colunas): 0%

## Checagens

Checagens executadas: 12.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| schema | informativo | (tabela): 2 de 6 coluna(s) numérica(s) sem `dominio_valido` declarado (33%): a checagem de faixa não olhou essas. | — sem justificativa — |

## Defeitos declarados no dicionário

Estes 6 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (mcmv_unidades_contratadas_i) Sigla 'uh' (unidades habitacionais) opaca, sem prefixo de fonte nem de programa (MCMV/FGTS)
- (mcmv_unidades_entregues_coorte_i) Nao diz se sao entregues acumuladas ou no ano; na pratica e a soma dos contratos assinados no ano (entregues de coorte)
- (mcmv_unidades_vigentes_em_20240930_i) 'vigente' e um ESTOQUE medido na data_referencia (30/09/2024) imputado ao ano de assinatura - estoque tratado como fluxo
- (mcmv_unidades_distratadas_em_20240930_i) Mesmo problema de estoque-vs-fluxo
- (mcmv_valor_contratado_brl2023) Nome generico de valor monetario, sem fonte, sem programa e sem sufixo _def apesar de deflacionado para 12/2023 (habitacao.R:60-61); convive com 22 colunas valor_emendas_* que sao outro universo
- (mcmv_valor_desembolsado_brl2023) Idem; e a coluna mais afetada pelo bug de escala 100x

