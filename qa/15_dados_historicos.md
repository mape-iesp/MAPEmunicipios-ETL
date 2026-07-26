# QA — 15_dados_historicos

Gerado em 2026-07-26 16:35:06.

## Resumo

- linhas: 5.646
- colunas: 9
- células vazias (todas as colunas): 1.2%

## Checagens

Checagens executadas: 12.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| chave_unica | aviso | 54 chave(s) duplicada(s), 54 linha(s) excedente(s) | 54 chaves duplicadas / 54 linhas excedentes, HERDADAS DA FONTE E MANTIDAS DE PROPOSITO. Sao municipios do Tocantins que existem duas vezes na base de Kustov & Pardelli: uma vez sob Goias (pre-1988) e outra sob Tocantins (pos-1988), porque o estado foi criado pela Constituicao de 1988. As duas linhas sao observacoes historicas distintas do mesmo territorio. Colapsar apagaria a mudanca de unidade federativa, que e justamente o objeto da tabela. A tabela e transversal (sem coluna ano) e a chave declarada e so id_municipio. |
| dominio_chave | aviso | 27 código(s) fora do diretório em 27 linha(s) (0.478%). Exemplos: 1399902, 1599904, 2399903, 2399909, 2399910 | 27 codigos fora do diretorio atual de municipios, em 27 linhas (0,478%). Sao municipios EXTINTOS ou com codigo alterado desde a coleta historica de Kustov & Pardelli. O diretorio 00_diretorios/municipios descreve os 5.570 municipios vigentes; uma tabela de dados historicos necessariamente contem unidades que ja nao existem. Descartar as 27 linhas apagaria observacao historica valida. Elas ficam publicadas e declaradas. |
| schema | informativo | (tabela): 7 de 7 coluna(s) numérica(s) sem `dominio_valido` declarado (100%): a checagem de faixa não olhou essas. | — sem justificativa — |
| licenca | aviso | licenca = 'A VERIFICAR — mesma situacao de 14_corrupcao: compilacao historica de Kustov & Pardelli (2024) sobre dados do IBGE. O dado de base e publico; a compilacao e dos autores.': a tabela não declara sob que licença é publicada, e o release a distribui como CC BY 4.0. | Mesma situacao de 14_corrupcao: compilacao historica de Kustov & Pardelli (2024) sobre dados do IBGE. O dado de base e publico; a compilacao e dos autores. Grupo 45. |

## Defeitos declarados no dicionário

Estes 8 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (receita_tributaria_1920_norm_idx) O nome antigo prometia log e z-score. Os valores vão de 0 a 1 exatos, o que é normalização min-max: um z-score é centrado em zero e não tem limite superior.
- (servidores_administracao_publica_1920_norm_idx) O nome antigo prometia log e z-score. Os valores vão de 0 a 1 exatos, o que é normalização min-max: um z-score é centrado em zero e não tem limite superior.
- (servidores_forca_publica_1920_norm_idx) O nome antigo prometia log e z-score. Os valores vão de 0 a 1 exatos, o que é normalização min-max: um z-score é centrado em zero e não tem limite superior.
- (redes_ferroviarias_1920_norm_idx) O nome antigo prometia log e z-score. Os valores vão de 0 a 1 exatos, o que é normalização min-max: um z-score é centrado em zero e não tem limite superior.
- (id_amc_1920) Sem separador entre conceito e ano, sem prefixo id_; e chave estrangeira para uma malha (952 AMCs, formato '17AMC2097003') que nao existe em nenhuma outra tabela da base
- (distancia_litoral_norm_idx) O nome antigo prometia log e z-score. Os valores vão de 0 a 1 exatos, o que é normalização min-max: um z-score é centrado em zero e não tem limite superior.
- (distancia_capital_estadual_norm_idx) O nome antigo prometia log e z-score. Os valores vão de 0 a 1 exatos, o que é normalização min-max: um z-score é centrado em zero e não tem limite superior.
- (ano_ref_fundacao_estimado) Colide semanticamente com a coluna 'ano' da chave do painel; e a segunda coluna de ano com significado incompativel na base larga

