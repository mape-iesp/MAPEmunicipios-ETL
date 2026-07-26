# QA — 11_transportes/tarifa_zero

Gerado em 2026-07-26 18:54:39.

## Resumo

- linhas: 578
- colunas: 4
- células vazias (todas as colunas): 20.42%

## Checagens

Checagens executadas: 17.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| cobertura_municipios | aviso | a tabela cobre apenas 1.9% dos municípios do diretório | A tabela cobre 106 dos 5.570 municipios (1,9%) porque so 106 municipios brasileiros ja adotaram tarifa zero no transporte publico. A fonte registra ocorrencias, e a ausencia de linha significa que o municipio nunca adotou a politica. Cobertura baixa e o fato medido. |
| schema | informativo | (tabela): 2 de 2 coluna(s) numérica(s) sem `dominio_valido` declarado (100%): a checagem de faixa não olhou essas. | — sem justificativa — |
| licenca | aviso | licenca = 'Levantamento do Observatorio da Tarifa Zero. A VERIFICAR: o Observatorio publica o levantamento abertamente, mas nao declara licenca formal.': a tabela não declara sob que licença é publicada, e o release a distribui como CC BY 4.0. | O Observatorio da Tarifa Zero publica o levantamento abertamente, mas nao declara licenca formal em lugar nenhum do site. Uso academico com citacao e defensavel; redistribuicao sob CC BY 4.0 exige confirmacao. Grupo 45. |

## Defeitos declarados no dicionário

Estes 2 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (tabela) DEFEITO ABERTO (auditoria 26/07/2026, achado 33): esta tabela e declarada CANONICA — a camada que guarda o observado — e ja vem EXPANDIDA: 81,7% das suas linhas sao carry_forward a partir do ano de adocao, e a evidencia foi apagada nelas (ano_ref_inicio_tarifa_zero fica NA em 472 linhas, apesar de ser atributo constante por municipio).
- (ano_ref_inicio_tarifa_zero) Ano de referência, não chave do painel: por isso o prefixo ano_ref_.

