# QA — 02_populacao

Gerado em 2026-07-26 16:34:35.

## Resumo

- linhas: 179.930
- colunas: 9
- células vazias (todas as colunas): 25.68%

## Checagens

Checagens executadas: 18.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| schema | informativo | (tabela): 2 de 8 coluna(s) numérica(s) sem `dominio_valido` declarado (25%): a checagem de faixa não olhou essas. | — sem justificativa — |

## Defeitos declarados no dicionário

Estes 9 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (tabela) DEFEITO ABERTO (auditoria 26/07/2026, achado 28): a serie intercensitaria de nove a dez municipios e FABRICADA por extrapolacao linear, e nao estimada pelo IBGE.
- (ano) Chave do painel com cinco tipos diferentes entre dimensoes (numeric, character, integer, integer64) e coercao manual em cada join do municipalityBR.qmd
- (populacao_residente_i) Generico; colide com a populacao da dim 4 (removida em municipalityBR.qmd:97) e semanticamente com populacao_atendida_agua/esgoto/urbana do SNIS
- (censo_catolicos_prop) Prefixo prop_ em vez de sufixo de escala; declarada STRING no dicionario e numeric em populacao_brasileira.RData
- (censo_evangelicos_pentecostais_prop) Prefixo prop_ sem sufixo de escala (0-1)
- (censo_evangelicos_missao_prop) Prefixo prop_ sem sufixo de escala (0-1)
- (censo_espiritas_prop) Prefixo prop_ sem sufixo de escala (0-1)
- (censo_matriz_africana_prop) Prefixo prop_ sem sufixo de escala (0-1)
- (ano_ref_censo_religiao) Generico: nao diz que e o ano do Censo de religiao (2000/2010) replicado sobre 1996-2015; mesmo padrao de ano_avs, ano_ideb, ano_eleicao, ano_inicio

