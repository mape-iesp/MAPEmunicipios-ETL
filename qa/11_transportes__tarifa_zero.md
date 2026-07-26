# QA — 11_transportes/tarifa_zero

Gerado em 2026-07-26 15:10:41.

## Resumo

- linhas: 578
- colunas: 4
- células vazias (todas as colunas): 20.42%

## Checagens

Checagens executadas: 11.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| cobertura_municipios | aviso | a tabela cobre apenas 1.9% dos municípios do diretório | A tabela cobre 106 dos 5.570 municipios (1,9%) porque so 106 municipios brasileiros ja adotaram tarifa zero no transporte publico. A fonte registra ocorrencias, e a ausencia de linha significa que o municipio nunca adotou a politica. Cobertura baixa e o fato medido. |

## Defeitos declarados no dicionário

Estes 1 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (ano_ref_inicio_tarifa_zero) Ano de referência, não chave do painel: por isso o prefixo ano_ref_.

