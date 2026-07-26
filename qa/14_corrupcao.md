# QA — 14_corrupcao

Gerado em 2026-07-26 15:22:32.

## Resumo

- linhas: 1.516
- colunas: 8
- células vazias (todas as colunas): 0.01%

## Checagens

Checagens executadas: 12.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| cobertura_municipios | aviso | a tabela cobre apenas 24.3% dos municípios do diretório | A tabela cobre 1.352 dos 5.570 municipios (24,3%) porque a base de Kustov & Pardelli deriva do sorteio de auditorias da CGU, que e amostral por construcao. Municipio ausente nao e municipio sem corrupcao: e municipio nao sorteado. Qualquer inferencia sobre o universo dos municipios a partir desta tabela precisa tratar a selecao. |
| schema | informativo | (tabela): 2 de 6 coluna(s) numérica(s) sem `dominio_valido` declarado (33%): a checagem de faixa não olhou essas. | — sem justificativa — |

## Defeitos declarados no dicionário

Estes 6 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (cgu_constatacoes_i) Nome generico E semanticamente errado: conta CONSTATACOES, nao acoes; alem disso 'acao' e o nome de outra coluna do proprio bruto (cgu$acao = acao orcamentaria)
- (cgu_constatacoes_falha_grave_i) Sem prefixo de fonte; 'falha grave' e vocabulario interno da CGU nao definido na base
- (cgu_montante_fiscalizado_brl2023) Sem prefixo, sem unidade e sem indicacao de que esta deflacionado a 12/2023
- (cgu_montante_fiscalizado_com_falha_grave_brl2023) Ambiguo entre 'montante fiscalizado onde houve falha grave' e 'montante da falha grave' - e o primeiro, com dupla contagem
- (cgu_constatacoes_falha_grave_sobre_total_prop) Nao diz o denominador (constatacoes, incluindo as do tipo 'Informacao'); sem sufixo de escala
- (cgu_montante_falha_grave_sobre_fiscalizado_prop) O NOME MENTE: prefixo montante_ sugere valor monetario, mas o conteudo e uma PROPORCAO 0-1 (cgu.R:23). Congelado na base publicada, posicao 406 de renomear_variaveis.R:149

