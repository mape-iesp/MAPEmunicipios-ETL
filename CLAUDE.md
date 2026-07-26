# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Visão geral

ETL em R que constrói o MAPEmunicipios: um painel de dados dos 5.570 municípios brasileiros no formato `id_municipio × ano`. A base final (`base_municipios_brasileiros`) tem 180.285 linhas × 451 colunas — o CSV publicado mostra 452 campos no header porque o `write.csv` foi feito sem `row.names = FALSE` —, resultado da junção de 17 dimensões temáticas (identificação, população, meio-ambiente, economia, sociedade, finanças, RH, assistência social/DH, energia e internet, educação, saúde, transportes, habitação, segurança, corrupção, dados históricos, eleições).

O repositório está em transição entre duas estruturas:

- **`01_dimensoes_individuais/`** — estrutura nova, versionada, em construção. Hoje contém apenas `00_diretorios/`.
- **`mape_municipios/`** — árvore legada (~18 GB), agora **coberta pelo `.gitignore`**. Contém o pipeline completo original e é a referência canônica de como cada dimensão foi produzida. Leia à vontade; não versione.

> ⚠️ **Leia [`plano/`](plano/) antes de escrever código novo.** A reestruturação do ETL está planejada
> em detalhe, e várias convenções descritas mais abaixo neste arquivo **vão mudar** — a estrutura de
> diretórios, o nome dos scripts, o formato de saída e a política de versionamento de dados. O
> [índice do plano](plano/README.md) diz o que muda em cada fase. As seções abaixo descrevem o estado
> **atual**, que ainda é majoritariamente o legado.

## Comandos

Não há build, testes nem linter configurados. O trabalho é executar scripts R individualmente.

```bash
# Scripts da estrutura nova — sempre a partir da raiz do repositório (usam here())
Rscript "01_dimensoes_individuais/00_diretorios/R/script.R"

# Scripts legados — usam caminhos relativos ao próprio diretório, então é preciso entrar nele
cd "mape_municipios/1 Dimensões Individuais/11 Saúde - Códigos e Dados" && Rscript saude.R

# Etapa de junção legada (Quarto)
cd "mape_municipios/2 Junção Bases" && quarto render municipalityBR.qmd
```

Ambiente: R 4.5.2, quarto disponível. Não existe `renv`/lockfile — pacotes vêm da biblioteca global do usuário. Os principais são `tidyverse`, `openxlsx`, `basedosdados`, `here`, `rio`; análises usam `sf`/`geobr`, `fixest`/`plm`, `deflateBR`.

**`basedosdados` exige autenticação no Google Cloud.** O projeto oficial é **`mapemunicipios`**, com faturamento habilitado. No legado há quatro projetos diferentes escritos dentro do código (`dados-importacao`, `base-dos-dados-429117`, `municipality-carlos`, `dissertacao-de-mestrado-399114`); nenhum sobrevive à migração. Em código novo, use `MAPE_GCP_BILLING` no `.Renviron`, nunca uma chamada literal a `set_billing_id`.

**Quem apenas consome os dados publicados não precisa de conta no Google Cloud.** A credencial só é necessária para atualizar fontes que vêm do BigQuery. Cuidado ao rodar scripts legados: vários consultam o BigQuery sem filtro e geram cobrança real — o do SICONFI baixa 18,5 milhões de linhas, e há scripts que executam a consulta e descartam o resultado.

## Arquitetura do pipeline

O fluxo é hierárquico, em três níveis de agregação, e roda inteiramente por materialização em arquivo — não há orquestrador, cada etapa lê o output em disco da anterior.

1. **Fonte → dimensão.** Cada fonte de dados (SIA, SIM, IEPS, IDEB, SICONFI, Emendas, Desastres, Desmatamento…) tem um script próprio que baixa/lê o dado bruto e grava um arquivo por fonte. Ex.: `11 Saúde - Códigos e Dados/{Atenção Básica,IEPS,Imunizações,SIA,SIM,SINAN}/*.R`.
2. **Dimensão consolidada.** Um script no nível da dimensão (`saude.R`, `meio_ambiente.R`, `educacao.R`…) faz `full_join` das fontes por `c("id_municipio", "ano")` e grava `<dimensao>.RData` + `<dimensao>.xlsx`.
3. **Junção geral.** `2 Junção Bases/municipalityBR.qmd` lê os 17 `.xlsx` de dimensão e os empilha em joins sucessivos (`d1 → d2 → … → d16`), gravando `base_municipios_brasileiros1.*`.
4. **Renomeação e dedup.** `3 Renomear e excluir duplicados/renomear_variaveis.R` substitui *todos* os nomes de coluna por um vetor posicional de 451 nomes e aplica `distinct(id_municipio, ano, .keep_all = TRUE)`. O resultado final vai para `4 Base completa/`.

Etapas auxiliares: `5 Análise Exploratória de Dados/` (modelos e gráficos), `6 Metadados/` (dicionário de variáveis em xlsx), `7 Textos Blog/` (posts em Quarto que consomem a base final).

### Contrato de dados

- **Chave**: `id_municipio` (código IBGE de 7 dígitos, tratado como *character*) + `ano`.
- **`diretorios` é a espinha dorsal.** Vem de `basedosdados.br_bd_diretorios_brasil.municipio` e traz as equivalências entre os vários códigos municipais (`id_municipio`, `id_municipio_6`, `id_municipio_tse`, `id_municipio_rf`, `id_municipio_bcb`) além da hierarquia territorial. Precisa ser gerado antes de qualquer outra dimensão.
- **Códigos de 6 dígitos.** Várias fontes (CadÚnico, TSE, dados históricos) trazem o código IBGE sem o dígito verificador. O padrão é fazer `left_join` com `diretorios` por `id_municipio_6` para recuperar o código de 7 dígitos e então descartar o de 6.
- **Flag de dimensão.** As 17 colunas `dimensao_<nome>` **não são criadas pelos scripts de dimensão** — nenhum deles as cria. Todas nascem dentro de `2 Junção Bases/municipalityBR.qmd`, são codificadas como `1`/`NA` (nunca `0`), e nenhum consumidor as usa. O plano as elimina (ver `plano/01-modelo-e-convencoes.md`, seção 3.5).
- **Painel expandido.** Dimensões cujo dado não é anual (ex.: meio-ambiente) constroem um esqueleto `município × ano` via cross join com `data.frame(ano = 1991:2023)` antes de juntar, e às vezes extrapolam um ano de referência para uma faixa (AdaptaBrasil 2015 → 2010–2020).

### Armadilhas conhecidas

- **Tipo de `ano` nos joins.** O legado alterna `ano` entre character e numeric a cada dimensão e faz a coerção manualmente antes de cada `full_join`/`left_join`. Um join silenciosamente vazio quase sempre é incompatibilidade de tipo em `ano` ou em `id_municipio`.
- **`full_join` vs `left_join`.** A junção geral usa `full_join` em algumas dimensões e `left_join` em outras — a escolha não é uniforme e altera a contagem de linhas do painel. Preserve o que já existe ao mexer nessa etapa.
- **Renomeação posicional.** `renomear_variaveis.R` depende da *ordem* das colunas produzidas pelo `.qmd`. Qualquer variável adicionada, removida ou reordenada em `municipalityBR.qmd` desalinha o vetor inteiro e renomeia colunas erradas sem erro.
- **Erros de digitação e nomes que mentem.** Além de `dimensao_identificao` e `populacao_atentida_esgoto`, há casos piores: `total_receitas_fundeb` mede a **dedução** do FUNDEB, e `proporcao_votos_nulos_prefeitura` contém votos **brancos** (o dicionário documenta os dois ao contrário do conteúdo). Como o uso da base é interno, o plano corrige todos, com tabela de depreciação — ver `plano/01-modelo-e-convencoes.md`, seção 6.6.
- **`here()` no legado.** A raiz do repositório não tem `.Rproj`, então `here()` ancora no `.git`. Mas existem **7 arquivos `.Rproj` dentro do legado**, e cada um desloca a âncora se a sessão for aberta naquela subárvore. O `mcmv/mcmv.Rmd` chega a depender disso. O plano cria um `.Rproj` na raiz (o `.gitignore` já abre exceção para ele).
- **Valores deflacionados sobrescrevem os nominais.** Oito scripts aplicam `ipca(..., "12/2023")` e gravam o resultado por cima da coluna original, com o mesmo nome. A série nominal não existe em lugar nenhum do repositório, e nada registra que a deflação aconteceu.

## Estrutura nova (`01_dimensoes_individuais/`)

**Esta estrutura vai ser substituída.** O plano define uma árvore diferente, separando código (`fontes/`)
de dado (`dados/`) e trocando `script.R` por nomes com verbo (`extrair_`, `tratar_`, `consolidar_`).
Ver `plano/01-modelo-e-convencoes.md`, seção 4.4. Não invista em código novo aqui antes de ler aquilo.

O que existe hoje é `00_diretorios/`, com a convenção original:

```
NN_<dimensao>/NN_<fonte>/
  R/script.R
  raw/
  processed/
```

Duas regras da convenção original que continuam valendo, e que o próprio `00_diretorios/R/script.R`
viola (ele grava com caminho relativo nu e produz `.RData` + `.xlsx`):

- Caminhos sempre via `here()` a partir da raiz do repositório, nunca relativos ao cwd.
- Nomes de diretório em snake_case sem acento, com prefixo numérico.

Duas que **mudam**:

- A saída passa de CSV para **Parquet** (seção 3.8 do plano). O `.xlsx` sai do pipeline: ele não
  preserva tipos, e o pipeline atual depende de um acidente de serialização dele para funcionar.
- Os sufixos de variável deixam de ser herdados da fonte e passam a sair de um **vocabulário fechado
  e verificável** — `_i` para contagem, `_pct` para percentual de 0 a 100, `_prop` para razão de 0 a 1,
  `_p100k` para taxa por 100 mil, `_brl_nominal` e `_brl2023` para dinheiro (seção 6.2 do plano). O
  antigo `_d` desaparece por ser ambíguo entre percentual e proporção.

### Versionamento de dados

**Dados brutos não são versionados.** O `.gitignore` cobre `**/raw/`. A procedência de cada fonte fica
num `MANIFESTO.yml` versionado ao lado do script, com URL, versão, data de download e `sha256` — o
checksum dá a mesma garantia que versionar o arquivo, por 64 bytes.

Tabelas processadas **são** versionadas quando abaixo de 20 MB, o que cobre quase tudo (a soma de
todas as 17 saídas de dimensão é ~66 MB). Acima disso vão para release do GitHub. Um hook de
`pre-commit` bloqueia arquivos grandes e qualquer caminho em `mape_municipios/`; instale com
`bash tools/hooks/instalar.sh` depois de clonar.

Detalhes em `plano/03-versionamento-qa.md`, seção 10.
