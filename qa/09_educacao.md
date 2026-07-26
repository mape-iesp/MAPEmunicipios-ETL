# QA — 09_educacao

Gerado em 2026-07-26 15:40:48.

## Resumo

- linhas: 111.388
- colunas: 37
- células vazias (todas as colunas): 21.29%

## Checagens

Checagens executadas: 14.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| schema | informativo | (tabela): 25 de 35 coluna(s) numérica(s) sem `dominio_valido` declarado (71%): a checagem de faixa não olhou essas. | — sem justificativa — |
| zero_inflacao | aviso | censup_instituicoes_ensino_superior_i: 5 ano(s) com 99% ou mais de zeros exatos (2005, 2006, 2007, 2008, 2024), enquanto 15 ano(s) têm dado. Ano inteiro zerado costuma ser vazio publicado como zero, e o valor certo para 'não medido' é NA. | problema da variável censup_instituicoes_ensino_superior_i: ERRO DE DIGITACAO publicado (falta o 'i' de instituicoes) enquanto as nove colunas irmas escrevem certo; origem censo_educacao_superior.R:53, congelado em renomear_variaveis.R:93 |
| zero_inflacao | aviso | censup_ies_privadas_particulares_i: 19 ano(s) com 99% ou mais de zeros exatos (2005, 2006, 2007, 2008, 2010, 2011, 2012, 2013, ...), enquanto 1 ano(s) têm dado. Ano inteiro zerado costuma ser vazio publicado como zero, e o valor certo para 'não medido' é NA. | MUDANCA DE CLASSIFICACAO NA ORIGEM, em 2010. Ate 2009 o Censo da Educacao Superior classificava a instituicao privada como 'particular'; de 2010 em diante a categoria foi substituida pelo par 'com fins lucrativos' / 'sem fins lucrativos', mais 'comunitaria' e 'confessional'. Por isso censup_ies_privadas_particulares_i so tem dado em 2009 e as demais so a partir de 2010: os zeros marcam o regime em que a categoria nao existia, nao ausencia de instituicoes. NAO SOME as categorias ao longo do tempo sem tratar a quebra de 2010, e nao interprete a queda a zero de 'particulares' como fechamento de instituicoes. |

## Defeitos declarados no dicionário

Estes 2 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (tabela) DEFEITO CONHECIDO: as colunas do Censo da Educação Superior tiveram NA trocado por zero por índice posicional, fabricando 27.850 linhas que afirmam ZERO instituições quando o correto seria ausência de dado.
- (ano_ref_ideb) Ano da EDICAO da avaliacao (impares 2005-2023, numeric) convivendo com ano do painel (character); nada no nome indica que e a chave que distingue medicao de valor replicado

