# Dicionário do MAPEmunicipios

<!-- GERADO por mape_gerar_documentacao_completa(). Não edite à mão. -->

O painel cobre 5.570 municípios brasileiros, de 1989 a 2024.

| | |
|---|---|
| Dimensões | 17 |
| Tabelas publicadas | 26 (16 de dimensão, 10 de fonte) |
| Variáveis documentadas | 432 |
| Variáveis pendentes de revisão | 24 |
| Tamanho total em Parquet | 72.5 MB |

## Tabelas de dimensão

A dimensão é o painel município × ano, e é o que a maior parte das pessoas
quer. Cada uma junta as fontes do seu tema.

| tabela | linhas | colunas | municípios | anos | MB |
|---|---|---|---|---|---|
| [`01_assistencia_social_dh`](../dados/dimensao/01_assistencia_social_dh.md) | 67.406 | 16 | 5.570 | 2011-2023 | 1.08 |
| [`02_populacao`](../dados/dimensao/02_populacao.md) | 179.930 | 9 | 5.570 | 1991-2023 | 1.13 |
| [`03_meio_ambiente`](../dados/dimensao/03_meio_ambiente.md) | 183.810 | 77 | 5.570 | 1991-2023 | 10.62 |
| [`04_economia`](../dados/dimensao/04_economia.md) | 127.786 | 19 | 5.570 | 1999-2021 | 15.6 |
| [`05_sociedade`](../dados/dimensao/05_sociedade.md) | 111.300 | 10 | 5.565 | 1996-2015 | 0.23 |
| [`06_financas`](../dados/dimensao/06_financas.md) | 180.023 | 39 | 5.570 | 1989-2024 | 6.81 |
| [`07_recursos_humanos`](../dados/dimensao/07_recursos_humanos.md) | 66.824 | 17 | 5.570 | 2009-2023 | 1.17 |
| [`08_energia_internet`](../dados/dimensao/08_energia_internet.md) | 111.288 | 12 | 5.570 | 2004-2024 | 2.87 |
| [`09_educacao`](../dados/dimensao/09_educacao.md) | 111.388 | 37 | 5.570 | 2005-2024 | 4.8 |
| [`10_saude`](../dados/dimensao/10_saude.md) | 149.144 | 65 | 5.570 | 1994-2021 | 10.98 |
| [`11_transportes`](../dados/dimensao/11_transportes.md) | 183.814 | 7 | 5.570 | 1991-2024 | 0.06 |
| [`12_habitacao`](../dados/dimensao/12_habitacao.md) | 94.832 | 8 | 5.570 | 2007-2024 | 0.32 |
| [`13_seguranca`](../dados/dimensao/13_seguranca.md) | 132.907 | 66 | 5.640 | 1996-2021 | 2.54 |
| [`14_corrupcao`](../dados/dimensao/14_corrupcao.md) | 1.516 | 8 | 1.352 | 2006-2018 | 0.04 |
| [`15_dados_historicos`](../dados/dimensao/15_dados_historicos.md) | 5.646 | 9 | 5.592 | — | 0.33 |
| [`16_eleicoes`](../dados/dimensao/16_eleicoes.md) | 133.496 | 36 | 5.568 | 2000-2023 | 8.12 |

## Tabelas de fonte

A fonte guarda o dado **como foi observado**, na granularidade nativa dela.
Onde a dimensão repete a mesma medição em vários anos para preencher o
painel, a fonte guarda a medição uma vez só. É a diferença entre as 183.814
linhas de `11_transportes` e as 578 linhas de `11_transportes/tarifa_zero`.

| tabela | linhas | colunas | municípios | anos | MB |
|---|---|---|---|---|---|
| [`00_diretorios/municipios`](../fontes/00_diretorios/municipios/README.md) | 5.570 | 27 | 5.570 | — | 0.48 |
| [`01_assistencia_social_dh/cadunico`](../fontes/01_assistencia_social_dh/cadunico/README.md) | 50.130 | 10 | 5.570 | 2015-2023 | 0.7 |
| [`01_assistencia_social_dh/disque100`](../fontes/01_assistencia_social_dh/disque100/README.md) | 59.990 | 8 | 5.567 | 2011-2023 | 0.37 |
| [`03_meio_ambiente/adaptabrasil`](../fontes/03_meio_ambiente/adaptabrasil/README.md) | 5.570 | 19 | 5.570 | 2015-2015 | 0.12 |
| [`05_sociedade/atlas_ivs`](../fontes/05_sociedade/atlas_ivs/README.md) | 11.130 | 9 | 5.565 | 2000-2010 | 0.16 |
| [`09_educacao/censup`](../fontes/09_educacao/censup/README.md) | 10.642 | 12 | 885 | 2009-2023 | 0.03 |
| [`09_educacao/ideb`](../fontes/09_educacao/ideb/README.md) | 55.694 | 26 | 5.570 | 2005-2023 | 3.72 |
| [`11_transportes/tarifa_zero`](../fontes/11_transportes/tarifa_zero/README.md) | 578 | 4 | 106 | 1992-2024 | 0 |
| [`11_transportes/tarifas`](../fontes/11_transportes/tarifas/README.md) | 351 | 5 | 27 | 2005-2017 | 0.01 |
| [`12_habitacao/mcmv_fgts`](../fontes/12_habitacao/mcmv_fgts/README.md) | 11.153 | 8 | 4.610 | 2007-2024 | 0.22 |

## Arquivos do dicionário

| arquivo | o que guarda |
|---|---|
| `dimensoes.csv` | o vocabulário de dimensões: slug, rótulo e número no legado |
| `tabelas.csv` | uma linha por tabela, com procedência, licença e granularidade |
| `variaveis.csv` | uma linha por variável, com tipo, unidade, escala e domínio |
| `deprecacao.csv` | de-para dos nomes antigos, para quem tinha código escrito |

_Gerado em 2026-07-26 22:10._

