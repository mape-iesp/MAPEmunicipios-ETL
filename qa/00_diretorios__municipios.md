# QA — 00_diretorios/municipios

Gerado em 2026-07-26 23:00:26.

## Resumo

- linhas: 5.570
- colunas: 27
- células vazias (todas as colunas): 5.5%

## Checagens

Nenhum problema automático: as 11 checagens executadas passaram.

## Defeitos declarados no dicionário

Estes 3 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (flag_capital_uf) integer64 0/1, mas o nome se le como 'a UF da capital'; sem prefixo de flag
- (flag_amazonia_legal) Flag 0/1 sem prefixo; tipo integer64 em diretorios.RData e character em meio_ambiente.RData
- (centroide_wkt) Tipo wk_wkt em diretorios.RData que vira character no xlsx; sem CRS nem formato no nome

