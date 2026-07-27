# QA — 11_transportes

Gerado em 2026-07-26 21:35:36.

## Resumo

- linhas: 183.814
- colunas: 7
- células vazias (todas as colunas): 57.06%

## Checagens

Checagens executadas: 20.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| schema | informativo | (tabela): 3 de 5 coluna(s) numérica(s) sem `dominio_valido` declarado (60%): a checagem de faixa não olhou essas. | — sem justificativa — |
| licenca | aviso | licenca = 'A VERIFICAR — combina o Mobilidados/ITDP (Instituto de Politicas de Transporte e Desenvolvimento, organizacao privada) com levantamentos abertos. Ver as licencas das fontes.': a tabela não declara sob que licença é publicada, e o release a distribui como CC BY 4.0. | A dimensao combina o Mobilidados/ITDP — Instituto de Politicas de Transporte e Desenvolvimento, organizacao privada — com levantamentos abertos e com o levantamento proprio do MAPE. As licencas das tres origens sao distintas e precisam ser verificadas uma a uma antes de qualquer publicacao formal. Grupo 45. |
| continuidade_painel | aviso | o último ano (2024) tem 4 linha(s), 0.1% da mediana dos anos anteriores (5.570). Série temporal calculada sobre a tabela quebra no último ponto. | O ultimo ano (2024) tem 4 linhas contra 5.570 dos anteriores. O esqueleto do painel foi montado ate 2023 e as 4 linhas de 2024 sao residuo das fontes (tarifa zero adotada em 2024 por 4 municipios), sem o preenchimento do painel. A assimetria e conhecida e vem do legado. Grupo 49. |
| faixa_declarada | aviso | ano: 4 valor(es) fora da faixa calculada declarada [1991, 2023] (observado aqui: 1991 a 2024). Os campos calculados desta coluna são medidos em `02_populacao`, e não aqui — a faixa descreve a outra tabela. | problema da variável ano: Chave do painel com cinco tipos diferentes entre dimensoes (numeric, character, integer, integer64) e coercao manual em cada join do municipalityBR.qmd |
| faixa_declarada | aviso | flag_adota_tarifa_zero: 183.236 valor(es) fora da faixa calculada declarada [1, 1] (observado aqui: 0 a 1). Os campos calculados desta coluna são medidos em `11_transportes/tarifa_zero`, e não aqui — a faixa descreve a outra tabela. | ACHADO 55, e e o caso que deu origem a checagem. Os campos calculados desta coluna (minimo, maximo, pct_na, n_distintos) sao medidos na FONTE 11_transportes/tarifa_zero, onde so existem linhas de municipio-ano que adotaram a tarifa zero e portanto o flag e 1 em 100% das linhas — dai minimo = maximo = 1. Na DIMENSAO, que e o painel completo, as 183.236 linhas de quem nao adotou trazem 0, e o 0 esta certo. Nao e dado fora de dominio: e a faixa do dicionario descrevendo outra tabela, por desenho. A documentacao gerada de 11_transportes traz a nota que nomeia as 5 colunas nessa situacao, e a coluna vazios dos .md passou a ser medida na tabela que o documento descreve. Medido em 26/07/2026. |

## Defeitos declarados no dicionário

Estes 1 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (tabela) DEFEITO CONHECIDO: os cinco municípios que adotaram a tarifa zero e depois a encerraram (entre eles Palmas e Paulínia) aparecem com zero em TODOS os anos, inclusive naqueles em que a política estava em vigor, porque a aba de encerrados da planilha nunca é lida.

