# QA — 05_sociedade/atlas_ivs

Gerado em 2026-07-26 22:10:40.

## Resumo

- linhas: 11.130
- colunas: 9
- células vazias (todas as colunas): 0.01%

## Checagens

Checagens executadas: 20.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| invariancia_temporal | aviso | vulnerabilidade_socioeconomica_pct: idêntica em 100% dos municípios entre os anos medidos, enquanto as colunas irmãs variam. Provavelmente é uma medição só, replicada — e a variação entre os anos é sempre zero por construção. | Ver a justificativa da dimensao 05_sociedade: uma medicao so, replicada nos dois anos censitarios. Grupo 14 da auditoria. |

## Defeitos declarados no dicionário

Estes 4 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (ivs_idx) Sigla sem expansao e sem escala; e uma das colunas consumidas pelo artigo
- (ivs_infraestrutura_urbana_idx) Subindice sem escala no nome
- (vulnerabilidade_socioeconomica_pct) Prefixo proporcao_ sem sufixo de escala; escala real 0-100
- (prosperidade_social_cat) Nome sugere indice numerico, mas o tipo e character (classe categorica)

