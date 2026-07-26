# QA — 09_educacao/censup

Gerado em 2026-07-26 15:28:01.

## Resumo

- linhas: 10.642
- colunas: 12
- células vazias (todas as colunas): 0%

## Checagens

Checagens executadas: 12.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| cobertura_municipios | aviso | a tabela cobre apenas 15.9% dos municípios do diretório | A tabela cobre 885 dos 5.570 municipios (15,9%) porque o Censo da Educacao Superior so registra municipio-ano com pelo menos uma instituicao de ensino superior. Ausencia de linha aqui significa ausencia de instituicao, nao ausencia de medicao: o CensUp e censitario e anual. A serie completa municipio x ano, com o zero explicito, esta na dimensao 09_educacao. Cobertura baixa e a propriedade correta desta fonte, nao um defeito dela. |

## Defeitos declarados no dicionário

Estes 2 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (censup_instituicoes_ensino_superior_i) ERRO DE DIGITACAO publicado (falta o 'i' de instituicoes) enquanto as nove colunas irmas escrevem certo; origem censo_educacao_superior.R:53, congelado em renomear_variaveis.R:93
- (censup_ies_federais_i) 'instituicoes' de que nao esta no nome (sao IES do Censo da Educacao Superior); prefixo total_ generico. Mesma familia: _estaduais, _municipais, _especial, _privada_com_fins_lucrativos, _privada_sem_f

