# QA — 09_educacao

Gerado em 2026-07-26 15:22:30.

## Resumo

- linhas: 111.388
- colunas: 37
- células vazias (todas as colunas): 21.29%

## Checagens

Checagens executadas: 12.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| schema | informativo | (tabela): 25 de 35 coluna(s) numérica(s) sem `dominio_valido` declarado (71%): a checagem de faixa não olhou essas. | — sem justificativa — |

## Defeitos declarados no dicionário

Estes 2 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (tabela) DEFEITO CONHECIDO: as colunas do Censo da Educação Superior tiveram NA trocado por zero por índice posicional, fabricando 27.850 linhas que afirmam ZERO instituições quando o correto seria ausência de dado.
- (ano_ref_ideb) Ano da EDICAO da avaliacao (impares 2005-2023, numeric) convivendo com ano do painel (character); nada no nome indica que e a chave que distingue medicao de valor replicado

