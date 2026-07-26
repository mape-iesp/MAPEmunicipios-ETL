# QA — 12_habitacao

Gerado em 2026-07-26 16:00:57.

## Resumo

- linhas: 94.832
- colunas: 8
- células vazias (todas as colunas): 0%

## Checagens

Checagens executadas: 15.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| schema | informativo | (tabela): 2 de 6 coluna(s) numérica(s) sem `dominio_valido` declarado (33%): a checagem de faixa não olhou essas. | — sem justificativa — |
| zero_inflacao | aviso | mcmv_unidades_contratadas_i: 7 ano(s) com 99% ou mais de zeros exatos (2007, 2008, 2019, 2020, 2021, 2022, 2023), enquanto 8 ano(s) têm dado. Ano inteiro zerado costuma ser vazio publicado como zero, e o valor certo para 'não medido' é NA. | problema da variável mcmv_unidades_contratadas_i: Sigla 'uh' (unidades habitacionais) opaca, sem prefixo de fonte nem de programa (MCMV/FGTS) |
| zero_inflacao | aviso | mcmv_unidades_entregues_coorte_i: 8 ano(s) com 99% ou mais de zeros exatos (2007, 2008, 2019, 2020, 2021, 2022, 2023, 2024), enquanto 7 ano(s) têm dado. Ano inteiro zerado costuma ser vazio publicado como zero, e o valor certo para 'não medido' é NA. | problema da variável mcmv_unidades_entregues_coorte_i: Nao diz se sao entregues acumuladas ou no ano; na pratica e a soma dos contratos assinados no ano (entregues de coorte) |
| zero_inflacao | aviso | mcmv_unidades_vigentes_em_20240930_i: 10 ano(s) com 99% ou mais de zeros exatos (2007, 2008, 2009, 2015, 2017, 2019, 2020, 2021, ...), enquanto 2 ano(s) têm dado. Ano inteiro zerado costuma ser vazio publicado como zero, e o valor certo para 'não medido' é NA. | problema da variável mcmv_unidades_vigentes_em_20240930_i: 'vigente' e um ESTOQUE medido na data_referencia (30/09/2024) imputado ao ano de assinatura - estoque tratado como fluxo |
| zero_inflacao | aviso | mcmv_valor_contratado_brl2023: 7 ano(s) com 99% ou mais de zeros exatos (2007, 2008, 2019, 2020, 2021, 2022, 2023), enquanto 8 ano(s) têm dado. Ano inteiro zerado costuma ser vazio publicado como zero, e o valor certo para 'não medido' é NA. | problema da variável mcmv_valor_contratado_brl2023: Nome generico de valor monetario, sem fonte, sem programa e sem sufixo _def apesar de deflacionado para 12/2023 (habitacao.R:60-61); convive com 22 colunas valor_emendas_* que sao outro universo |
| zero_inflacao | aviso | mcmv_valor_desembolsado_brl2023: 8 ano(s) com 99% ou mais de zeros exatos (2007, 2008, 2019, 2020, 2021, 2022, 2023, 2024), enquanto 7 ano(s) têm dado. Ano inteiro zerado costuma ser vazio publicado como zero, e o valor certo para 'não medido' é NA. | problema da variável mcmv_valor_desembolsado_brl2023: Idem; e a coluna mais afetada pelo bug de escala 100x |

## Defeitos declarados no dicionário

Nenhum.

