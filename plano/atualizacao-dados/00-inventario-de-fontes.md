# 0. O inventário: de onde cada tabela vem, e o que impede reobtê-la

Medido em 26/07/2026, sobre a árvore publicada. Os números desta seção saíram do Parquet, não da
prosa — `FONTES.csv`, ao lado, é a mesma coisa em formato legível por código.

## 0.1 O quadro em uma frase

**Das 26 tabelas publicadas, uma tem caminho de atualização completo.** É
`00_diretorios/municipios`: tem `extrair_*.R`, tem `tratar_*.R`, tem manifesto com sha256, tem o
bruto em `raw/` e reproduz o Parquet publicado. Todas as outras 25 param em algum lugar antes disso.

| situação | quantas | quais |
|---|---:|---|
| extração + tratamento + manifesto + bruto | 1 | `00_diretorios/municipios` |
| tratamento e bruto, sem extração | 2 | `cadunico`, `disque100` |
| só manifesto, sem bruto e sem código | 5 | `adaptabrasil`, `atlas_ivs`, `tarifa_zero`, `tarifas`, `mcmv_fgts` |
| nem manifesto | 2 | `09_educacao/ideb`, `09_educacao/censup` |
| dimensão que consolida do próprio grafo | 1 | `01_assistencia_social_dh` |
| dimensão sem produtor nenhum | 15 | as outras 15 de `dados/dimensao/` |

As 15 dimensões sem produtor são o fato central deste plano, e vale dizê-lo sem rodeio:
**atualizar os dados é, na prática, escrever os produtores que nunca existiram.** Elas foram
publicadas por `tools/migracao/migrar_dimensoes.R`, que lia a árvore legada; a árvore legada foi
removida do repositório em 26/07/2026. Não há de onde reprocessá-las nesta árvore. Enquanto o
`tratar_*.R` de cada fonte não existir, "atualizar a dimensão X" não é uma operação que o
repositório saiba fazer.

## 0.2 As 10 tabelas de fonte

| fonte | linhas × mun. | janela | método hoje | `extrair` | `tratar` | manifesto | bruto |
|---|---:|---|---|:-:|:-:|:-:|:-:|
| `00_diretorios/municipios` | 5.570 × 5.570 | atemporal | bigquery | ✅ | ✅ | ✅ | ✅ |
| `01_.../cadunico` | 50.130 × 5.570 | 2015-2023 | download manual | ❌ | ✅ | ✅ | ⚠️ derivado |
| `01_.../disque100` | 59.990 × 5.567 | 2011-2023 | download manual | ❌ | ✅ | ✅ | ✅ |
| `03_.../adaptabrasil` | 5.570 × 5.570 | 2015 | download manual | ❌ | ❌ | ✅ | ❌ |
| `05_.../atlas_ivs` | 11.130 × 5.565 | 2000-2010 | download manual | ❌ | ❌ | ✅ | ❌ |
| `09_.../censup` | 10.642 × 885 | 2009-2023 | bigquery | ❌ | ❌ | ❌ | ❌ |
| `09_.../ideb` | 55.694 × 5.570 | 2005-2023 | bigquery | ❌ | ❌ | ❌ | ❌ |
| `11_.../tarifa_zero` | 578 × 106 | 1992-2024 | download manual | ❌ | ❌ | ✅ | ❌ |
| `11_.../tarifas` | 351 × 27 | 2005-2017 | download manual | ❌ | ❌ | ✅ | ❌ |
| `12_.../mcmv_fgts` | 11.153 × 4.610 | 2007-2024 | download manual | ❌ | ❌ | ✅ | ❌ |

Três observações que mudam o trabalho:

**`ideb` e `censup` não têm `MANIFESTO.yml`.** São as duas únicas fontes publicadas sem manifesto
nenhum — nem origem, nem licença, nem sha256, nem data. `dicionario/tabelas.csv` registra o dataset
(`basedosdados.br_inep_ideb`, `basedosdados.br_inep_censo_educacao_superior`), e é tudo que existe.
Criar os dois manifestos é pré-requisito de qualquer coisa.

**O `raw/cadunico.csv` não é o bruto.** É a saída do pipeline legado, e o próprio manifesto declara
isso desde o achado 46: dois passos já vêm aplicados (o filtro `str_detect(anomes_s, '12$')`, que
reduz a série mensal ao retrato de dezembro, e a conversão de 6 para 7 dígitos). Quem rebaixar do
SAGI recebe a série mensal com código de 6 dígitos e precisa aplicar os dois — o segundo com
`mape_id7_de_id6()`.

**Cinco fontes têm manifesto sem `arquivo_local` e sem `sha256`.** São as que
`tools/migracao/fatiar_fontes.R` recortou da árvore legada: o bruto original nunca esteve neste
repositório. Os campos ficaram em branco de propósito, para serem preenchidos "na primeira
reextração" — que é exatamente o que este plano executa.

## 0.3 As 16 dimensões, e o que está a montante de cada uma

O levantamento por dimensão está em [`../migracao-etl/00-diagnostico-inventario.md`](../migracao-etl/00-diagnostico-inventario.md)
§ 2.2, feito sobre a árvore legada antes de ela ser removida. **Atenção à numeração:** aquele
documento usa a numeração legada de 1 a 17; aqui vale a numeração publicada. A correspondência é
`legado 1 → 00_diretorios`, `legado 8 → 01_assistencia_social_dh`, `legado 2..7 → 02..07`,
`legado 9..17 → 08..16`.

| dimensão | linhas | janela publicada | a montante | via provável |
|---|---:|---|---|---|
| `02_populacao` | 179.930 | 1991-2023 | IBGE (estimativas + censo) | BigQuery |
| `03_meio_ambiente` | 183.810 | 1991-2023 | SEDEC/MIDR + CEPED/UFSC, SNIS, INPE, MCTI | misto |
| `04_economia` | 127.786 | 1999-2021 | IBGE Contas Regionais | BigQuery |
| `05_sociedade` | 111.300 | 1996-2015 | Ipea — Atlas da Vulnerabilidade Social | BigQuery |
| `06_financas` | 180.023 | 1989-2024 | Tesouro (SICONFI) + CGU (emendas) | BigQuery + HTTP |
| `07_recursos_humanos` | 66.824 | 2009-2023 | IBGE — MUNIC | HTTP por edição |
| `08_energia_internet` | 111.288 | 2004-2024 | Anatel (SCM, móvel) + IBGE | BigQuery |
| `09_educacao` | 111.388 | 2005-2024 | INEP (IDEB, CensoSup) | BigQuery |
| `10_saude` | 149.144 | 1994-2021 | MS (SI-PNI, e-Gestor) + IEPS | misto |
| `11_transportes` | 183.814 | 1991-2024 | Mobilidados/ITDP + Obs. Tarifa Zero | misto |
| `12_habitacao` | 94.832 | 2007-2024 | Min. Cidades / Caixa | HTTP |
| `13_seguranca` | 132.907 | 1996-2021 | MS (SIM) + FBSP | BigQuery + manual |
| `14_corrupcao` | 1.516 | 2006-2018 | CGU | HTTP |
| `15_dados_historicos` | 5.646 | transversal | Kustov & Pardelli (2024) + IBGE 1872-2010 | **não reobtenível** |
| `16_eleicoes` | 133.496 | 2000-2023 | TSE | BigQuery |

## 0.4 As fronteiras temporais, que são o alvo da atualização

A janela do painel é `anos_painel: [1989, 2024]`, em `config/parametros.yml`. Sete dimensões param
antes de 2024, e **as lacunas abaixo são a lista de trabalho da atualização**:

| dimensão | último ano publicado | lacuna aparente |
|---|---:|---|
| `04_economia` | 2021 | o cache do PIB baixado em 26/07/2026 cobre **2002-2023** — dois anos já disponíveis e não publicados |
| `10_saude` | 2021 | SI-PNI e e-Gestor publicam além disso |
| `13_seguranca` | 2021 | o SIM publica além disso |
| `05_sociedade` | 2015 | censitária; o **Censo 2022** é uma fronteira nova inteira |
| `14_corrupcao` | 2018 | o programa da CGU continuou |
| `16_eleicoes` | 2023 | **as eleições municipais de 2024 não estão no painel** (`pendencias/16_eleicoes__tse_2022_2024.md`) |
| `02_populacao` | 2023 | estimativas anuais + o Censo 2022 |
| `07_recursos_humanos` | 2023 | faltam as edições de 2010, 2016 e 2022 da MUNIC |

**Nenhum desses "disponível a montante" foi verificado contra a origem.** São inferências do que os
órgãos publicam e da cobertura declarada em `dicionario/tabelas.csv`. Medir a fronteira real de cada
fonte é a fase 1 deste plano, e é trabalho de rede — ver [`04-fases-e-aceitacao.md`](04-fases-e-aceitacao.md).

Vale registrar o que isso implica: `data_ultima_atualizacao_fonte` está **vazio nas 26 linhas** de
`dicionario/tabelas.csv`. Não existe hoje, em lugar nenhum do repositório, um registro de quando
cada fonte foi atualizada pelo produtor. É esse campo que a fase 1 preenche.

## 0.5 O que não é reobtenível, e precisa de decisão em vez de código

Três casos não têm caminho programático nenhum, e nenhum volume de engenharia os resolve:

**`15_dados_historicos` (5.646 linhas, 7 das 8 colunas).** Vem do pacote de replicação de Kustov &
Pardelli (2024), e **não há pacote de replicação público**: a página dos autores traz só PDF e
figuras, o Harvard Dataverse não retorna nada, e o artigo está atrás do paywall da Elsevier. A oitava
coluna vem de `IBGE_1872_2010_atualizado.xlsx`, cuja planilha original foi distribuída **em CD-ROM**
com a publicação impressa de 2011 — e o passo `original → atualizado` é edição manual em Excel, sem
log, onde nascem os 54 registros duplicados. Esta tabela é citável e não reobtenível. Ou se escreve
aos autores, ou ela fica congelada e declarada como tal.

**`11_transportes/tarifas` (351 linhas, 27 municípios).** Compilação própria do MAPE a partir de
decretos municipais coletados um a um. Não há fonte a montante: o MAPE *é* a fonte. Atualizar
significa coletar decretos, o que é trabalho humano.

**`12_habitacao/mcmv_fgts` — a faixa subsidiada não existe.** O `subsdiado_ogu.csv` do legado era
byte a byte idêntico ao arquivo do FGTS (mesmo md5). Metade do programa nunca chegou ao repositório.
Registrado em `pendencias/12_habitacao__mcmv_ogu.md`, com decisão do usuário de seguir só com o FGTS.

## 0.6 O que existe de infraestrutura, e que o plano não precisa reinventar

Ao contrário do inventário acima, a camada de acesso está pronta e testada:

| função | arquivo | o que faz |
|---|---|---|
| `mape_query()` | `R/bigquery.R:120` | consulta com **dry-run obrigatório**, teto por consulta, `maximum_bytes_billed` e registro em `qa/custo_bigquery.csv` |
| `mape_baixar_cache()` | `R/bigquery.R:222` | consulta uma vez, grava em `raw/`, escreve sha256 e `sql_hash` no manifesto; não reconsulta se o arquivo existe |
| `mape_baixar()` | `R/ingestao.R:29` | baixa por HTTP, nome de arquivo estável, sha256 e versão no manifesto |
| `mape_verificar_raw()` | `R/bigquery.R:299` | confere o sha256 antes de processar e falha se divergir |
| `mape_nova_fonte()` | `R/ingestao.R:120` | scaffold: `extrair_`, `tratar_`, manifesto e README, com o encadeamento certo |
| `mape_registrar_proveniencia()` | `R/bigquery.R:263` | uma linha por extração em `dicionario/proveniencia.csv` |

E há um precedente que serve de molde para tudo que vem por rede: **a série do IPCA**
(`tools/atualizar_ipca.R`, achado 37). Um script explícito fala com a API, o resultado é fixado em
`config/ipca.csv` com a data e a base, o pipeline lê a cópia fixada, e `mape_serie_ipca()` confere
que a cópia e o YAML concordam. Rede num lugar só, resultado versionado, leitura reprodutível. É
esse o padrão a repetir.
