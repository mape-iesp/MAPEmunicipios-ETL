# QA — 11_transportes

Gerado em 2026-07-26 16:12:28.

## Resumo

- linhas: 183.814
- colunas: 7
- células vazias (todas as colunas): 57.06%

## Checagens

Checagens executadas: 17.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| schema | informativo | (tabela): 3 de 5 coluna(s) numérica(s) sem `dominio_valido` declarado (60%): a checagem de faixa não olhou essas. | — sem justificativa — |
| licenca | aviso | licenca = 'A VERIFICAR — combina o Mobilidados/ITDP (Instituto de Politicas de Transporte e Desenvolvimento, organizacao privada) com levantamentos abertos. Ver as licencas das fontes.': a tabela não declara sob que licença é publicada, e o release a distribui como CC BY 4.0. | A dimensao combina o Mobilidados/ITDP — Instituto de Politicas de Transporte e Desenvolvimento, organizacao privada — com levantamentos abertos e com o levantamento proprio do MAPE. As licencas das tres origens sao distintas e precisam ser verificadas uma a uma antes de qualquer publicacao formal. Grupo 45. |
| continuidade_painel | aviso | o último ano (2024) tem 4 linha(s), 0.1% da mediana dos anos anteriores (5.570). Série temporal calculada sobre a tabela quebra no último ponto. | O ultimo ano (2024) tem 4 linhas contra 5.570 dos anteriores. O esqueleto do painel foi montado ate 2023 e as 4 linhas de 2024 sao residuo das fontes (tarifa zero adotada em 2024 por 4 municipios), sem o preenchimento do painel. A assimetria e conhecida e vem do legado. Grupo 49. |

## Defeitos declarados no dicionário

Estes 1 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (tabela) DEFEITO CONHECIDO: os cinco municípios que adotaram a tarifa zero e depois a encerraram (entre eles Palmas e Paulínia) aparecem com zero em TODOS os anos, inclusive naqueles em que a política estava em vigor, porque a aba de encerrados da planilha nunca é lida.

