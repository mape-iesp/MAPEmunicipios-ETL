# QA — 09_educacao/censup

Gerado em 2026-07-26 15:40:48.

## Resumo

- linhas: 10.642
- colunas: 12
- células vazias (todas as colunas): 0%

## Checagens

Checagens executadas: 14.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| cobertura_municipios | aviso | a tabela cobre apenas 15.9% dos municípios do diretório | A tabela cobre 885 dos 5.570 municipios (15,9%) porque o Censo da Educacao Superior so registra municipio-ano com pelo menos uma instituicao de ensino superior. Ausencia de linha aqui significa ausencia de instituicao, nao ausencia de medicao: o CensUp e censitario e anual. A serie completa municipio x ano, com o zero explicito, esta na dimensao 09_educacao. Cobertura baixa e a propriedade correta desta fonte, nao um defeito dela. |
| zero_inflacao | aviso | censup_ies_privadas_com_fins_lucrativos_i: 1 ano(s) com 99% ou mais de zeros exatos (2009), enquanto 14 ano(s) têm dado. Ano inteiro zerado costuma ser vazio publicado como zero, e o valor certo para 'não medido' é NA. | MUDANCA DE CLASSIFICACAO NA ORIGEM, em 2010. Ate 2009 o Censo da Educacao Superior classificava a instituicao privada como 'particular'; de 2010 em diante a categoria foi substituida pelo par 'com fins lucrativos' / 'sem fins lucrativos', mais 'comunitaria' e 'confessional'. Por isso censup_ies_privadas_particulares_i so tem dado em 2009 e as demais so a partir de 2010: os zeros marcam o regime em que a categoria nao existia, nao ausencia de instituicoes. NAO SOME as categorias ao longo do tempo sem tratar a quebra de 2010, e nao interprete a queda a zero de 'particulares' como fechamento de instituicoes. |
| zero_inflacao | aviso | censup_ies_privadas_sem_fins_lucrativos_i: 1 ano(s) com 99% ou mais de zeros exatos (2009), enquanto 14 ano(s) têm dado. Ano inteiro zerado costuma ser vazio publicado como zero, e o valor certo para 'não medido' é NA. | MUDANCA DE CLASSIFICACAO NA ORIGEM, em 2010. Ate 2009 o Censo da Educacao Superior classificava a instituicao privada como 'particular'; de 2010 em diante a categoria foi substituida pelo par 'com fins lucrativos' / 'sem fins lucrativos', mais 'comunitaria' e 'confessional'. Por isso censup_ies_privadas_particulares_i so tem dado em 2009 e as demais so a partir de 2010: os zeros marcam o regime em que a categoria nao existia, nao ausencia de instituicoes. NAO SOME as categorias ao longo do tempo sem tratar a quebra de 2010, e nao interprete a queda a zero de 'particulares' como fechamento de instituicoes. |
| zero_inflacao | aviso | censup_ies_privadas_particulares_i: 14 ano(s) com 99% ou mais de zeros exatos (2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, ...), enquanto 1 ano(s) têm dado. Ano inteiro zerado costuma ser vazio publicado como zero, e o valor certo para 'não medido' é NA. | MUDANCA DE CLASSIFICACAO NA ORIGEM, em 2010. Ate 2009 o Censo da Educacao Superior classificava a instituicao privada como 'particular'; de 2010 em diante a categoria foi substituida pelo par 'com fins lucrativos' / 'sem fins lucrativos', mais 'comunitaria' e 'confessional'. Por isso censup_ies_privadas_particulares_i so tem dado em 2009 e as demais so a partir de 2010: os zeros marcam o regime em que a categoria nao existia, nao ausencia de instituicoes. NAO SOME as categorias ao longo do tempo sem tratar a quebra de 2010, e nao interprete a queda a zero de 'particulares' como fechamento de instituicoes. |
| zero_inflacao | aviso | censup_ies_privadas_comunitarias_i: 14 ano(s) com 99% ou mais de zeros exatos (2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, ...), enquanto 1 ano(s) têm dado. Ano inteiro zerado costuma ser vazio publicado como zero, e o valor certo para 'não medido' é NA. | MUDANCA DE CLASSIFICACAO NA ORIGEM, em 2010. Ate 2009 o Censo da Educacao Superior classificava a instituicao privada como 'particular'; de 2010 em diante a categoria foi substituida pelo par 'com fins lucrativos' / 'sem fins lucrativos', mais 'comunitaria' e 'confessional'. Por isso censup_ies_privadas_particulares_i so tem dado em 2009 e as demais so a partir de 2010: os zeros marcam o regime em que a categoria nao existia, nao ausencia de instituicoes. NAO SOME as categorias ao longo do tempo sem tratar a quebra de 2010, e nao interprete a queda a zero de 'particulares' como fechamento de instituicoes. |
| zero_inflacao | aviso | censup_ies_privadas_confessionais_i: 14 ano(s) com 99% ou mais de zeros exatos (2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, ...), enquanto 1 ano(s) têm dado. Ano inteiro zerado costuma ser vazio publicado como zero, e o valor certo para 'não medido' é NA. | MUDANCA DE CLASSIFICACAO NA ORIGEM, em 2010. Ate 2009 o Censo da Educacao Superior classificava a instituicao privada como 'particular'; de 2010 em diante a categoria foi substituida pelo par 'com fins lucrativos' / 'sem fins lucrativos', mais 'comunitaria' e 'confessional'. Por isso censup_ies_privadas_particulares_i so tem dado em 2009 e as demais so a partir de 2010: os zeros marcam o regime em que a categoria nao existia, nao ausencia de instituicoes. NAO SOME as categorias ao longo do tempo sem tratar a quebra de 2010, e nao interprete a queda a zero de 'particulares' como fechamento de instituicoes. |

## Defeitos declarados no dicionário

Estes 2 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (censup_instituicoes_ensino_superior_i) ERRO DE DIGITACAO publicado (falta o 'i' de instituicoes) enquanto as nove colunas irmas escrevem certo; origem censo_educacao_superior.R:53, congelado em renomear_variaveis.R:93
- (censup_ies_federais_i) 'instituicoes' de que nao esta no nome (sao IES do Censo da Educacao Superior); prefixo total_ generico. Mesma familia: _estaduais, _municipais, _especial, _privada_com_fins_lucrativos, _privada_sem_f

