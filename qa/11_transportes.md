# QA — 11_transportes

Gerado em 2026-07-26 15:40:50.

## Resumo

- linhas: 183.814
- colunas: 7
- células vazias (todas as colunas): 57.06%

## Checagens

Checagens executadas: 14.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| schema | informativo | (tabela): 3 de 5 coluna(s) numérica(s) sem `dominio_valido` declarado (60%): a checagem de faixa não olhou essas. | — sem justificativa — |

## Defeitos declarados no dicionário

Estes 1 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (tabela) DEFEITO CONHECIDO: os cinco municípios que adotaram a tarifa zero e depois a encerraram (entre eles Palmas e Paulínia) aparecem com zero em TODOS os anos, inclusive naqueles em que a política estava em vigor, porque a aba de encerrados da planilha nunca é lida.

