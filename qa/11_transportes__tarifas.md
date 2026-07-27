# QA — 11_transportes/tarifas

Gerado em 2026-07-26 23:01:02.

## Resumo

- linhas: 351
- colunas: 5
- células vazias (todas as colunas): 4.62%

## Checagens

Checagens executadas: 19.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| cobertura_municipios | aviso | a tabela cobre apenas 0.5% dos municípios do diretório | A tabela cobre 27 dos 5.570 municipios (0,5%) porque o levantamento de tarifas de transporte publico so abrange as capitais e algumas regioes metropolitanas. E uma amostra declarada pela origem, nao uma perda desta migracao. ATENCAO ao consumir: qualquer agregado nacional calculado sobre esta tabela descreve 27 municipios, e mape_cobertura() nao deixava isso visivel (grupo 21 da auditoria). |
| schema | informativo | (tabela): 1 de 3 coluna(s) numérica(s) sem `dominio_valido` declarado (33%): a checagem de faixa não olhou essas. | — sem justificativa — |

## Defeitos declarados no dicionário

Estes 3 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (comprometimento_tarifa_sobre_renda_domesticas_negras_prop) Sem escala no nome (fracao 0-1)
- (comprometimento_tarifa_sobre_salario_minimo_prop) Sem 'renda' e sem escala no nome (fracao 0-1); denominador so no nome parcialmente
- (tarifa_onibus_urbano_brl2023) Plural generico, sem unidade (R$), sem dizer que e passagem de onibus urbano e sem marca de deflacao - e o MESMO NOME em duas escalas (nominal x 12/2023)

