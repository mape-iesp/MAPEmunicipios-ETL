# QA — 01_assistencia_social_dh/cadunico

Gerado em 2026-07-26 22:10:19.

## Resumo

- linhas: 50.130
- colunas: 10
- células vazias (todas as colunas): 20%

## Checagens

Checagens executadas: 20.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| schema | aviso | cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_pct: 59 valor(es) fora do domínio [0,100] (observado: 18.03 a 128.8) | 59 municipios de 2016 passam de 100%, ate 128,8%. Uma razao entre cadastros atualizados e cadastros totais nao pode exceder 100% por definicao; o excesso indica que numerador e denominador foram apurados em momentos diferentes, de modo que familias que mudaram de faixa de renda entre as duas contagens aparecem so no numerador. A concentracao num unico ano sugere falha na extracao daquela edicao do CadUnico. Os valores foram MANTIDOS como vieram da fonte, sem truncamento, porque truncar esconderia o problema. A outra taxa da mesma tabela tem maximo exatamente 100,00, o que indica que ela e truncada na origem e esta nao e. Analise completa em docs/fase-2-piloto.md. |

## Defeitos declarados no dicionário

Estes 1 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (tabela) LIMITAÇÃO CONHECIDA: a Taxa de Atualização Cadastral restrita à faixa de até meio salário mínimo passa de 100% em 59 municípios, todos no ano de 2016, chegando a 128,8%.

