# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Visão geral

ETL em R que constrói o **MAPEmunicipios**: um painel dos 5.570 municípios brasileiros, de 1989 a 2024, em 17 eixos temáticos, 26 tabelas publicadas e 432 variáveis documentadas.

A migração do legado terminou e as 26 tabelas estão publicadas em `dados/`. Mas **em 26/07/2026 uma auditoria independente levantou 105 grupos de defeito — sete deles críticos — e nenhum foi corrigido ainda.** Seis dos sete críticos são dado publicado errado; o outro é um comando que a versão anterior deste arquivo ensinava.

> **`auditoria/CONSOLIDADO.md` é o documento mais atual do repositório.** Treze auditores de escopo exclusivo (`A1.md`–`A13.md`) produziram 122 achados brutos, agrupados em 105; um verificador adversarial reexecutou todos, instruído a derrubá-los, e só 8 grupos não se reproduziram (estão marcados `NÃO REPRODUZIDO`). Cada grupo traz reprodução em R e a saída observada.
>
> Ele foi escrito **contra** o `README.md`, o `docs/` e este arquivo. Quando divergirem, a auditoria ganha — ela tem reprodução; os outros descrevem o estado pretendido. `auditoria/prompt-auditoria.md` guarda os briefings, se for rodar outra rodada.
>
> **Se a tarefa for corrigir os achados, leia `auditoria/prompt-correcao.md` antes de qualquer coisa.** É a missão completa da rodada de correção — as decisões já tomadas, os treze critérios de aceitação da § 12, e o ponto de retomada se o contexto for compactado (ele mais `auditoria/CORRECOES.csv`). Ainda não está versionado.

Os demais documentos continuam úteis para entender **por que** as coisas são assim:

- [`README.md`](README.md) — como dar manutenção (o mais longo; ver a errata abaixo)
- [`docs/encerramento-migracao.md`](docs/encerramento-migracao.md), [`docs/fechamento-etl.md`](docs/fechamento-etl.md) — o estado declarado no fim da migração
- [`docs/decisao-dois-repositorios.md`](docs/decisao-dois-repositorios.md) — por que o pacote R fica noutro repositório
- [`plano/`](plano/) — o raciocínio por trás de cada decisão de desenho
- [`pendencias/`](pendencias/) — as seis fontes que não migraram, com diagnóstico

**A árvore legada foi removida do repositório em 26/07/2026.** Ela vive no Drive compartilhado do MAPE, em `mape_municipios/`. Só que a remoção não veio acompanhada da reescrita dos produtores: **16 tabelas não têm caminho de reconstrução nesta árvore** — 14 dimensões saíam de `migrar_dimensoes.R`, que lê do legado; `15_dados_historicos` não tem produtor nenhum; e `tratar_municipios()` ainda aponta para `01_dimensoes_individuais/00_diretorios/processed/diretorios.xlsx`, que não existe. Das 26 publicadas, **só 3 são reproduzidas como publicadas** por um alvo do grafo.

**O pacote R vive noutro repositório**: `mape-iesp/MAPEmunicipios`. Este aqui é interno, para quem atualiza dado; aquele é público, para quem consome. O único acoplamento é o release do GitHub.

## A escrita destrutiva agora é barrada — achado 6, corrigido

Este era o achado crítico nº 6 da auditoria, e a versão de 26/07/2026 deste arquivo abria com um aviso em vermelho porque o comando de entrada do repositório apagava dado publicado: `tar_make(dim_11_transportes)` trocava 183.814 linhas e 5.570 municípios por 929 linhas e 133 municípios, e `tar_make(dim_09_educacao)` trocava 111.388 linhas por 60.672 e perdia a coluna `ano_ref_ideb`.

**Não faz mais.** `mape_escrever_tabela()` compara com a tabela publicada antes de gravar — linhas, colunas, chaves distintas e municípios distintos — e para com erro se a nova perder qualquer um dos quatro, ou se alguma coluna sumir. Os dois alvos que destruíam agora falham alto, nomeando o que falta:

```
Gravar '11_transportes' destruiria dado publicado. A gravação foi barrada.

  n_linhas      183.814 -> 929  (perde 182.885, 99,49%)
  n_chaves      183.814 -> 929  (perde 182.885, 99,49%)
  n_municipios  5.570 -> 133  (perde 5.437, 97,61%)
```

A perda continua possível quando é deliberada, e só assim: `permitir_perda = TRUE` **com** um `motivo_perda`, que fica registrado em `qa/perdas_autorizadas.csv`. Sem motivo, a autorização é recusada.

A causa-raiz permanece e é a assimetria da § "O grafo é menor do que a árvore de dados sugere": os Parquet publicados vieram dos scripts de migração já com o painel expandido, e `mape_consolidar_dimensao()` junta as fontes compactadas e para aí — ela não expande o painel. Enquanto os `tratar_*.R` de ideb, censup, tarifa_zero e tarifas não existirem, esses dois alvos não têm como reproduzir o publicado. A diferença é que agora eles dizem isso em vez de gravar por cima.

**Para inspecionar uma consolidação sem gravar**, chame a função com `publicar = FALSE` — o default é `TRUE`:

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")
novo <- mape_consolidar_dimensao("09_educacao", publicar = FALSE)
```

A guarda é coberta por `tests/testthat/test-escrita-guarda.R`: perda de linha, de município e de coluna têm de falhar; sobrescrita sem perda e tabela inédita têm de passar.

## Comandos

```bash
# Primeira vez, depois de clonar:
Rscript -e 'renv::restore()'
bash tools/hooks/instalar.sh

# Leitura do grafo — seguro, não grava nada
Rscript -e 'targets::tar_manifest()'                  # os 14 alvos que existem
Rscript -e 'targets::tar_outdated()'                  # devolve os 14: o grafo nunca fechou
Rscript -e 'targets::tar_visnetwork()'                # desenha o grafo

# Testes — 9 arquivos, 405 expectativas, segundos. Hoje: FAIL 0 | PASS 405
Rscript -e 'testthat::test_dir("tests/testthat")'
Rscript -e 'testthat::test_file("tests/testthat/test-chaves.R")'      # um arquivo só
Rscript -e 'testthat::test_dir("tests/testthat", filter = "painel")'  # por padrão no nome

# Empacotar o release que o pacote R consome
Rscript tools/publicar_release.R v1.0.0
```

**Medir uma tabela publicada** é a operação mais frequente aqui, porque a regra é não acreditar em número escrito em prosa:

```bash
Rscript -e 'd <- arrow::read_parquet("dados/dimensao/09_educacao.parquet")
            cat(nrow(d), ncol(d), length(unique(d$id_municipio)), range(d$ano), "\n")'
```

Ambiente: R 4.5.2, fixado por `renv` (**147** pacotes no lockfile — README e a versão anterior deste arquivo diziam 128). `.Rprofile` ativa o `renv`, então qualquer `Rscript` já pega a biblioteca certa. Quarto disponível.

Todo `Rscript` imprime `The project is out-of-sync — use renv::status()`. **É ruído esperado**: pacotes do `tidyverse` estão instalados e no lockfile, mas nenhum código os usa. Não gaste tempo com isso.

Dois efeitos colaterais que sujam a árvore versionada, e convém saber antes: `mape_validar_tabela()` grava em `qa/` incondicionalmente, e a suíte reescreve o carimbo de data de `qa/00_diretorios__municipios.md`, que é versionado. A suíte passa e o diff é só a linha `Gerado em`; `git checkout -- qa/00_diretorios__municipios.md` desfaz.

`tar_make()` sai com código 0 mesmo quando um alvo falha, e `error = "abridge"` não faz o que o comentário de `_targets.R` diz. Não use o código de saída como sinal.

## Antes de repetir um número da documentação, confira

A auditoria falsificou boa parte das estatísticas que circulam em `README.md`, em `docs/` e na versão anterior deste arquivo. As mais fáceis de repetir por engano:

| a documentação diz | o que é | achado |
|---|---|---|
| base larga com 440 colunas e as 16 dimensões | 423 colunas e 15 dimensões: `mape_montar_base_larga()` descarta `15_dados_historicos` com um `next` silencioso (`R/dimensao.R:103` e `:122`) porque ela não tem coluna `ano` | 11 |
| a guarda de chave duplicada nomeia as duas responsáveis | nomeia só `06_financas`; as 54 duplicatas de `15_dados_historicos` nunca são vistas | 11 |
| "erro impede a publicação, sem exceção" | nenhum caminho de escrita roda as checagens de erro: `mape_escrever_tabela()` chama `mape_validar_schema()`, não `mape_validar_tabela()`; 23 das 26 tabelas foram gravadas com validação desligada | 22 |
| "aviso sem justificativa vira erro" | não existe em código | 38 |
| as doze checagens | a checagem 12 ("descrições idênticas entre tabelas") nunca foi implementada — e o defeito que ela previne está publicado: sete variáveis de `06_financas` carregam descrição do bloco do PIB de `04_economia` | 23, 18 |
| 2 erros e 23 avisos de validação | os `qa/*.md` gerados somam 25 avisos | 81 |
| paridade com zero diferenças não explicadas | a paridade trata ausência como igualdade, não compara número de linhas, e o curinga `*` imuniza 52,5% das colunas; `15_dados_historicos` nunca passou e não pode passar | 24, 25, 66, 67 |
| 128 pacotes no lockfile | 147 | 95 |
| os `extrair_*.R` estão escritos | existe **um** (`fontes/00_diretorios/municipios/`), e nunca rodou | — |
| `_brl2023` está em reais de dez/2023 | três colunas do IEPS em `10_saude` estão em reais de **dez/2021**, com `unidade` afirmando 2023 | 8 |

Regra prática: número que aparece em prosa neste repositório é afirmação a verificar, não fato. Meça no Parquet.

## O grafo do `targets` é menor do que a árvore de dados sugere

Esta é a coisa mais fácil de errar no repositório, e a que mais custa tempo.

**Existem 26 tabelas em `dados/`, mas só 14 alvos no grafo** — e **5 desses 14 nunca foram construídos** (`dim_01_assistencia_social_dh`, `dim_09_educacao`, `dim_11_transportes`, `documentacao`, `base_larga`: não há registro deles em `_targets/meta/meta`). As tabelas fora do grafo foram produzidas por scripts de migração de uma vez só (`tools/migracao/migrar_dimensoes.R`, `tools/migracao/fatiar_fontes.R`) e **`tar_make()` não as reconstrói**. Elas estão versionadas e é assim que continuam existindo.

O que de fato está no grafo:

| alvos | quais |
|---|---|
| `fonte_*` (3) | `00_diretorios_municipios` (falha: origem inexistente), `01_assistencia_social_dh_cadunico`, `01_assistencia_social_dh_disque100` |
| `valida_*` (3) | um por fonte acima |
| `dim_*` (3) | `dim_01_assistencia_social_dh`, `dim_09_educacao` ⛔, `dim_11_transportes` ⛔ |
| arquivo/doc (5) | `arquivo_dicionario`, `arquivo_tabelas`, `arquivo_parametros`, `documentacao`, `base_larga` |

Duas regras de geração explicam a lista, e ambas estão em [`_targets.R`](_targets.R):

- **Um alvo `fonte_<slug>` só nasce se a função `tratar_<nome>` existir.** Só três `tratar_*.R` existem (`fontes/*/*/R/`); as outras sete pastas de fonte têm apenas um README gerado.
- **Um alvo `dim_<slug>` só nasce se a dimensão tiver ≥ 2 fontes publicadas em `dados/fonte/`.** Com uma fonte só, consolidar seria copiar.

⚠️ **Seis comandos `tar_make()` da documentação não funcionam.** O README ensina uma receita com alvos que não existem (§ "Um ano novo numa fonte que já existe" manda rodar `tar_make(fonte_04_economia_ibge_pib)` e `tar_make(dim_04_economia)`; os dois falham com `Column doesn't exist`). A receita descreve o estado pretendido depois que a fonte tiver o seu `tratar_*.R`; hoje, para uma dimensão sem alvo, atualizar significa **escrever o `tratar_*.R` primeiro** (use `mape_nova_fonte()`). Rode `tar_manifest()` antes de invocar qualquer alvo pelo nome.

O alvo `documentacao` grava a própria dependência, então o grafo não converge: ele fica desatualizado logo depois de rodar.

**Nunca edite `_targets.R`.** Os alvos são gerados a partir de `dicionario/tabelas.csv`. Acrescentar uma fonte é acrescentar uma linha lá e um `tratar_<nome>.R` — o grafo se ajusta sozinho.

## Consumir os dados

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

mape_tabelas_publicadas()                  # as 26 tabelas
mape_ler("saude")                          # uma dimensão, pelo nome
mape_ler("educacao/ideb", territorio = TRUE)
mape_cobertura("14_corrupcao")             # cobertura declarada, não real (ver abaixo)
mape_derivadas("taxa_homicidios_p100k")    # indicador com o denominador visível
mape_montar_base_larga(flags = TRUE, deduplicar = TRUE)
```

Duas ressalvas que a auditoria confirmou: `mape_cobertura()` conta coluna preenchida com zero como dado, e chega a reportar 100% onde a cobertura real é de 27 municípios (achado 21); e **nenhum dos defeitos conhecidos do dado chega a quem consome por `mape_ler()`** (achado 32). Se for responder pergunta substantiva sobre uma dimensão, leia a seção dela no `CONSOLIDADO.md` antes.

**Quem só consome os dados publicados não precisa de conta no Google Cloud.** A credencial só é exigida para reextrair uma fonte do BigQuery. Ela vive em `MAPE_GCP_BILLING`, no `.Renviron` (que o `.gitignore` cobre, porque o repositório é público). Use `.Renviron.exemplo` como molde, e nunca uma chamada literal a `set_billing_id`.

**Nunca rode um script do legado.** Vários consultam o BigQuery sem filtro e geram custo real: o do SICONFI baixa 18,5 milhões de linhas, o do SIM varre o país inteiro, e alguns executam a consulta e descartam o resultado.

## Arquitetura

Três camadas, e a distinção entre as duas primeiras é a decisão central:

```
fonte  →  dimensão  →  base larga
```

**A fonte é canônica** e deveria guardar o dado *como foi observado*, na granularidade nativa. `03_meio_ambiente/adaptabrasil` tem 5.570 linhas porque o AdaptaBrasil publica um retrato de 2015. (A promessa vaza em pelo menos dois lugares: `11_transportes/tarifa_zero` já vem expandida, com 81,7% de carry-forward e a evidência apagada, e `raw/cadunico.csv` é a saída do pipeline legado, não o bruto da origem.)

**A dimensão é derivada** e é o painel município × ano. `03_meio_ambiente` tem 183.810 linhas, com aquele retrato repetido de 2010 a 2020 — sem nenhum marcador que diga qual linha foi medida e qual foi replicada.

**A base larga** junta 15 dimensões em 423 colunas. É derivada, gerada por função, não versionada. (São 17 eixos em `dicionario/dimensoes.csv`; `00_diretorios` só tem tabela de fonte, e `15_dados_historicos` é descartada em silêncio.)

### Árvore

```
config/parametros.yml      única fonte de verdade para constantes
dicionario/*.csv           a especificação: 432 variáveis, 26 tabelas
R/                         16 arquivos de funções comuns
fontes/<dim>/<fonte>/      extrair_*.R, tratar_*.R, MANIFESTO.yml, raw/
dados/{fonte,dimensao}/    Parquet + csv.gz, versionados abaixo de 20 MB
dados/derivado/            base larga (não versionada)
qa/                        relatórios de qualidade e de paridade
auditoria/                 A1–A13 + CONSOLIDADO.md (secoes/ e *.local.md não versionados)
tools/                     migração, hooks, publicar_release.R
tests/testthat/            6 arquivos
docs/ plano/ pendencias/   documentação
qa/referencia/             base do pipeline antigo, p/ paridade (não versionada)
```

Tudo é escrito em português: comentário, nome de função, documento, mensagem de commit (frase descritiva, sem prefixo de convenção). Nome de coluna e slug são snake_case ASCII, sem acento.

### As constantes vivem em `config/parametros.yml`

Nenhuma delas deve ser reescrita dentro de um script — foi a prática oposta que produziu, no legado, oito cópias da base do deflator. Leia com `mape_param("chave")`. Estão lá a janela do painel (`anos_painel: [1989, 2024]`), o mês-base do deflator (`12/2023` → sufixo `brl2023`), a lista de sentinelas que viram `NA`, o contrato de tipo das chaves e os limiares de QA — inclusive `max_mb_versionavel: 20`, que é o número que o hook de `pre-commit` aplica.

### A camada `R/`

Uma responsabilidade por arquivo; `tar_source("R")` carrega tudo. **26 das 62 funções `mape_*` podem virar `function(...) NULL` sem quebrar nenhum teste** (achado 26), incluindo `mape_deflacionar()` e `mape_marcar_nominal()` — então não conte com a suíte para pegar uma regressão aqui.

| arquivo | o que resolve |
|---|---|
| `parametros.R` | `mape_param()` — leitura de `config/parametros.yml` |
| `chaves.R` | `mape_normalizar_chaves()`, `mape_como_codigo()`, `mape_id7_de_id6()` |
| `io.R` | `mape_ler_tabela()`, `mape_escrever_tabela()`, caminhos e camadas |
| `dicionario.R` | o dicionário como entrada: renomeio, tipos, `mape_recalcular_campos()` |
| `registro.R` | `mape_registrar_tabela()`, `mape_registrar_pendencia()` |
| `ingestao.R` | `mape_nova_fonte()` (scaffold), `mape_verificar_raw()`, manifestos |
| `bigquery.R` | `mape_query()`, `mape_baixar()`, `mape_billing_id()`, proveniência |
| `sentinelas.R` | `mape_tratar_sentinelas()` — os "NaoDisponivel" e "-" viram `NA` |
| `joins.R` | `mape_join()` com cardinalidade declarada |
| `painel.R` | `mape_esqueleto_painel()`, `mape_expandir_painel()`, `mape_compactar_painel()` |
| `dimensao.R` | `mape_consolidar_dimensao()`, `mape_montar_base_larga()`, `mape_paridade()` |
| `validacao.R` | `mape_validar_tabela()` — as checagens de qualidade |
| `deflacao.R` | `mape_deflacionar()`, `mape_marcar_nominal()` |
| `documentacao.R` | `mape_gerar_documentacao_completa()` |
| `consumo.R` | a interface pública: `mape_ler()`, `mape_cobertura()`, `mape_derivadas()` |
| `migracao_legado.R` | `mape_migrar_do_legado()` — histórico, não roda no grafo |

### Contrato de dados

Isto é o desenho pretendido, e a parte dele que a validação de fato prova é pequena — a prova prometida pelo sufixo existe para 4 dos 15 tokens do vocabulário. Continue seguindo o contrato ao escrever código novo; só não presuma que o dado publicado o cumpre.

- **Chave**: `id_municipio` (texto de 7 dígitos) + `ano` (inteiro). Código não é quantidade.
- **`00_diretorios/municipios` é a espinha dorsal**, e é dono exclusivo do bloco territorial. Nenhuma outra tabela deveria publicar `nome_municipio` ou `sigla_uf` (`04_economia` publica).
- **Códigos de 6 dígitos** viram 7 por `left_join` com o diretório em `id_municipio_6`.
- **`ano` só existe como chave.** Qualquer outro ano é `ano_ref_<fonte>`.
- **Sufixo obrigatório**, de vocabulário fechado: `_i`, `_pct`, `_prop`, `_razao`, `_p100k`, `_p1k`, `_p100dom`, `_brl_nominal`, `_brl2023`, `_km`, `_km2`, `_idx`, `_cat`, mais os prefixos `flag_` e `ano_ref_`.
- **Prefixo de fonte obrigatório** quando duas fontes medem o mesmo conceito: `pni_` contra `ieps_` na cobertura vacinal, `sim_` contra `fbsp_` na morte violenta. (`ieps_` não é independente de `pni_`: é a mesma medida truncada em 100.)
- **A numeração das dimensões é só de acréscimo.** Nunca renumere: o número entra em caminho de arquivo, nome de tabela publicada, URL de release e documentação, e renumerar quebra tudo isso em silêncio.

### O dicionário é a especificação

Ele é **lido pelo código** para renomear colunas, validar tipos e domínios, e gerar a documentação. Não é subproduto — é entrada do grafo (`arquivo_dicionario`), então mexer nele deixa a documentação desatualizada e `tar_outdated()` diz isso.

Campos **calculados** (`tipo_real`, `pct_na`, `n_distintos`, `minimo`, `maximo`, `n_infinito`) são reescritos por `mape_recalcular_campos()` a cada execução. Editá-los não adianta. Dois cuidados: `minimo`/`maximo` das colunas `integer64` do PIB são padrão de bits, não valores (`dicionario.R:201-202`), e 83 colunas publicadas não têm linha na documentação da tabela a que pertencem.

Toda renomeação vai para `dicionario/deprecacao.csv` (que hoje aponta 28 nomes novos inexistentes e não registra 7 renomeios).

### Arquivos gerados — não edite à mão

Cada um traz um aviso no cabeçalho, e `tar_make(documentacao)` sobrescreve todos:

```
dicionario/README.md          fontes/<dim>/<fonte>/README.md
dados/dimensao/*.md           qa/<slug>.md, qa/paridade_<dim>.md
```

Para mudar o que eles dizem, mude `dicionario/*.csv` ou o dado, e regere. Eles também erram: dois documentos gerados no mesmo minuto dão valores diferentes para "células vazias" da mesma tabela, e 5 das 7 tabelas com defeito declarado recebem "as doze checagens passaram".

### Validação e paridade

`mape_validar_tabela()` roda as checagens de qualidade e escreve `qa/<slug>.md`. O desenho era: erro impede a publicação, aviso exige justificativa registrada em `observacoes` (tabela) ou `problema` (variável), aviso sem justificativa vira erro. **Nada disso é executado nos caminhos de escrita** — ver a errata acima. Trate a validação como um relatório que você roda de propósito, não como um portão.

`mape_paridade()` compara cada dimensão com a base do pipeline antigo, com as diferenças aceitáveis reivindicadas de antemão em `qa/paridade_esperada.csv`. O teste é mais fraco do que parece: ausência conta como igualdade, número de linhas não é comparado, e oito das nove reivindicações nominais são inalcançáveis. Precisa de `qa/referencia/base_municipios_brasileiros.RDa`, que não é versionado (Drive do MAPE).

## Armadilhas conhecidas

Do código, e todas já custaram tempo:

- **`formatC(x, flag = "0")` sobre texto preenche com espaço, não com zero.** `mape_como_codigo()` preenche à mão por isso — e por isso mesmo fabrica um código de 7 dígitos bem-formado a partir de qualquer entrada curta, em vez do `NA` que a documentação promete.
- **`integer64` é armadilha silenciosa.** `as.numeric(ano)` devolve `9.83e-321`; `sort()` e `range()` devolvem lixo sem erro. `mape_normalizar_chaves()` converte para `integer` sempre.
- **`mape_tratar_sentinelas()` converte `id_municipio` de texto para double** — e o scaffold de `mape_nova_fonte()` faz isso em toda fonte nova. Renormalize a chave depois de chamar.
- **`mape_expandir_painel()` quebra em qualquer tabela que já tenha coluna `ano`** (`painel.R:82-86`), e `metodo = "replicar"` faz produto cartesiano quando há mais de um ano medido, gerando chave duplicada sem aviso.
- **`mape_deflacionar()` baixa a série de IPCA da API do IPEA a cada chamada.** Não é reprodutível nem registrado, e depende de rede.
- **`mape_join(relationship = "many-to-many")` multiplica linhas sem emitir o aviso que a própria documentação promete.**
- **`write.csv(..., fileEncoding = "UTF-8")` sobre uma conexão é ignorado pelo R**: o `csv.gz` sai na codificação nativa da sessão. E `id_municipio` volta como `integer` em qualquer `read.csv()` padrão.
- **Sete colunas de dinheiro estão declaradas `tipo = "integer"` e estouram o int32**: 23.761 células viram `NA` em silêncio no caminho do `csv.gz`.

Do dado publicado — o que mais importa não repetir como se estivesse resolvido:

- **Duas tabelas têm chave duplicada herdada da fonte, de propósito.** `06_financas` (222 chaves, emendas associadas por nome sem UF) e `15_dados_historicos` (54, Tocantins pré e pós-1988). A guarda de `mape_montar_base_larga()` só vê a primeira.
- **A série nominal não existe.** Oito scripts do legado gravavam o valor deflacionado por cima do original. O único par que sobreviveu está na Saúde.
- **As coberturas vacinais do SI-PNI passam de 100%**: 445.721 células (31,5%) acima de 100, máximo de 51.175% — e não os 13.050% que a justificativa registrada declara.
- **A série de PIB de `04_economia` tem três quebras de nível** (2001, 2004, 2011) que nenhum deflator explica, e `06_financas` tem colunas de receita infladas em uma ordem de grandeza e zeradas em 99% das linhas de alguns anos. Não use essas duas dimensões em análise sem ler os achados 1–5.
- **Códigos não municipais publicados**: 352 linhas de 70 códigos em `13_seguranca` inflam a soma nacional de homicídios em até 10,3%, e os 30 pseudo-códigos do Rio deixam a série municipal de 1996–1998 97% subestimada.
- **O hook de `pre-commit` barra arquivo acima de 20 MB e caminho de `mape_municipios/`.** Instale-o (`bash tools/hooks/instalar.sh`). Ele deixa passar caminho com acento e arquivo removido da árvore depois do `git add`; `--no-verify` contorna, e quase nunca é o certo.
- **Dado bruto do CadÚnico (10,6 MiB) está no histórico público do git**, apesar da promessa de que `**/raw/` nunca é versionado. Exceção decidida e registrada em `plano/03-versionamento-qa.md`; é agregado municipal público, sem PII.
- **O identificador do projeto GCP está em três commits do histórico remoto.** Os detalhes redigidos e o roteiro de remediação ficam em `auditoria/VAZAMENTO-GCP.local.md`, que não é versionado — não copie o conteúdo dele para arquivo que vá para o git.

## O que ainda está aberto

Ordem sugerida: os achados críticos primeiro, e o nº 6 antes de qualquer `tar_make()`.

- **Os 105 grupos de achado da auditoria, nenhum corrigido.** O plano de ataque está em `auditoria/prompt-correcao.md`, com os critérios de aceitação. Falta ainda a análise de fechamento (cadeias causais, ordem de correção com dependências, errata do README, veredito sobre as sete afirmações centrais do projeto) — a lista está no fim de `auditoria/CONSOLIDADO.md`.
- **O caminho de reconstrução não existe para 16 tabelas.** Reescrever os produtores é o pré-requisito de qualquer reprocessamento.
- **A primeira reextração nunca aconteceu.** Existe um único `extrair_*.R` (`fontes/00_diretorios/municipios/`), e ele nunca rodou.
- **Sete das dez fontes não têm `tratar_*.R`** e por isso não estão no grafo: adaptabrasil, atlas_ivs, censup, ideb, tarifa_zero, tarifas, mcmv_fgts. Os Parquet delas vieram de `tools/migracao/fatiar_fontes.R`.
- **Seis fontes não migraram**, com diagnóstico em `pendencias/`. Nenhuma contribui com coluna publicada.
- **As 26 tabelas estão sob `licenca = "a verificar"` e o release publica todas como CC BY 4.0.** Três casos são substantivos: IEPS Data, Anuário do FBSP e Kustov & Pardelli.
- **O release v1.0.0 está montado em `dist/` e não foi publicado.** O comando está no fim de `tools/publicar_release.R`. Publicá-lo antes de tratar os achados críticos distribui os defeitos.
