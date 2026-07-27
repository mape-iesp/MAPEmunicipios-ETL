# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Visão geral

ETL em R que constrói o **MAPEmunicipios**: um painel dos 5.570 municípios brasileiros, de 1989 a 2024, em 17 eixos temáticos, 26 tabelas publicadas e 432 variáveis documentadas.

A migração do legado terminou e as 26 tabelas estão publicadas em `dados/`. Em 26/07/2026 uma auditoria independente levantou **105 grupos de defeito**, sete deles críticos, e os 105 foram trabalhados e depois reverificados na mesma data. O placar, medido em `auditoria/CORRECOES.csv`: **80 corrigidos, 19 mitigados** (marcados e detectáveis, mas a correção de fundo depende do responsável ou de insumo que não está aqui) e **6 confirmados como não reproduzidos**.


**Os 105 foram então REVERIFICADOS TRÊS VEZES**, também em 26/07/2026, por verificadores adversariais que reexecutaram cada reprodução contra a árvore em vez de acreditar no ledger. A primeira rodada: 77 se sustentaram, **cinco não se sustentavam** (26, 34, 55, 66 e 91) e 23 estavam parciais. A segunda, sobre esses 28: seis ainda parciais. A terceira, sobre esses seis: dois — e os dois eram **portões recém-escritos que nasceram quebrados e passavam sempre**. Daí vêm os critérios 13 a 17 de `verificar_fechamento.R`.
 A lição, que vale para o próximo: **quase todo parcial era código corrigido com o artefato publicado esquecido** — o `.md` gerado é o que o consumidor lê, e corrigir só o dicionário deixa a correção no lugar errado.

**O ponto de partida é `auditoria/RELATORIO-FINAL.md`**, que diz o que mudou, o que ficou aberto e o que depende de decisão. `auditoria/CORRECOES.csv` é o ledger, com uma linha por grupo. `Rscript tools/verificar_fechamento.R` confere mecanicamente se a rodada está fechada e sai com código diferente de zero se não estiver.

> **`auditoria/CONSOLIDADO.md` continua sendo a evidência.** Treze auditores de escopo exclusivo (`A1.md`–`A13.md`) produziram 122 achados brutos, agrupados em 105; um verificador adversarial reexecutou todos, instruído a derrubá-los, e 8 grupos não se reproduziram. Cada grupo traz reprodução em R e a saída observada — e é por isso que ele é imutável: os números dele foram medidos **antes** das correções, e várias das reproduções agora não reproduzem mais, o que é o resultado desejado.
>
> **Não repita número do `CONSOLIDADO.md` como se fosse o estado atual.** Para o estado atual, meça — ou leia `auditoria/RELATORIO-FINAL.md`, que traz o antes e o depois lado a lado.

Os demais documentos continuam úteis para entender **por que** as coisas são assim:

- [`README.md`](README.md) — como dar manutenção (o mais longo; ver a errata abaixo)
- [`docs/encerramento-migracao.md`](docs/encerramento-migracao.md), [`docs/fechamento-etl.md`](docs/fechamento-etl.md) — o estado declarado no fim da migração
- [`docs/decisao-dois-repositorios.md`](docs/decisao-dois-repositorios.md) — por que o pacote R fica noutro repositório
- [`plano/`](plano/) — o raciocínio por trás de cada decisão de desenho
- [`pendencias/`](pendencias/) — as seis fontes que não migraram, com diagnóstico

**A árvore legada foi removida do repositório em 26/07/2026.** Ela vive no Drive compartilhado do MAPE, em `mape_municipios/`. A remoção não veio acompanhada da reescrita dos produtores, e **15 tabelas continuam sem caminho de reconstrução nesta árvore** — 14 dimensões saíam de `migrar_dimensoes.R`, que lê do legado, e `15_dados_historicos` não tem produtor nenhum. `tratar_municipios()` foi consertado (achado 9): o arquivo bruto voltou do histórico do git para `raw/`, com sha256 no manifesto, e a função reproduz o Parquet publicado exatamente.

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

# Testes — 14 arquivos, 564 expectativas, segundos. Hoje: FAIL 0 | PASS 564
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

**A suíte não suja mais a árvore versionada** (achados 59 e 87): `mape_validar_tabela()` ganhou `gravar =`, as fixtures deixaram de usar o slug de uma tabela publicada, e `git status --porcelain` fica limpo depois de `test_dir()`.

`tar_make()` continua saindo com código 0 mesmo quando um alvo falha — use `Rscript tools/rodar_grafo.R`, que consulta `tar_meta()` e sai com código 1. O `error =` de `_targets.R` era `"abridge"` com um comentário que descrevia `"trim"`; agora é `"trim"`, que é o que o comentário sempre disse querer (achado 41).

## Antes de repetir um número, meça

A auditoria falsificou boa parte das estatísticas que circulavam aqui, e a rodada de correção as remediu. **A tabela de errata encolheu de dez linhas para três.** O que ainda é fácil de errar:

| a documentação antiga dizia | o que é, medido em 26/07/2026 |
|---|---|
| base larga com 440 colunas e as 16 dimensões | **424 colunas** (439 com `flags = TRUE`), 200.520 linhas, **15 das 16** dimensões — `15_dados_historicos` é transversal e fica fora por desenho, e agora a função **avisa** quando isso acontece |
| os `extrair_*.R` estão escritos | existe **um** (`fontes/00_diretorios/municipios/`), e ele nunca rodou. A primeira extração de verdade desta árvore foi a do PIB, em 26/07/2026, e ela é um cache pontual e não um `extrair_*.R` |
| 16 tabelas não têm caminho de reconstrução | continua verdade para **15**: `00_diretorios/municipios` voltou a ser reconstruível (achado 9), e reproduz o publicado com `all.equal == TRUE`. As outras 15 dependem de reescrever os produtores |

Os números correntes, todos medidos: **26** tabelas publicadas, **432** variáveis no dicionário, **147** pacotes no lockfile, **564** expectativas na suíte, **0 erros e 132 avisos** de validação — todos com justificativa registrada.

A regra prática não mudou, e é a lição central da auditoria: **número que aparece em prosa é afirmação a verificar, não fato.** Meça no Parquet. `Rscript tools/validar_tudo.R` e `Rscript tools/verificar_fechamento.R` medem por você.

## O grafo do `targets` é menor do que a árvore de dados sugere

Esta é a coisa mais fácil de errar no repositório, e a que mais custa tempo.

**Existem 26 tabelas em `dados/`, mas só 14 alvos no grafo**, e 10 deles têm registro em `_targets/meta/meta`. As tabelas fora do grafo foram produzidas por scripts de migração de uma vez só (`tools/migracao/migrar_dimensoes.R`, `tools/migracao/fatiar_fontes.R`) e **`tar_make()` não as reconstrói**. Elas estão versionadas e é assim que continuam existindo.

**Rode o grafo com `Rscript tools/rodar_grafo.R`, e não com `tar_make()` direto.** `tar_make()` sai com código 0 mesmo quando um alvo falha (achado 41); o wrapper consulta `tar_meta()` e sai com código 1, nomeando quem falhou.

O que de fato está no grafo:

| alvos | quais |
|---|---|
| `fonte_*` (3) | `00_diretorios_municipios`, `01_assistencia_social_dh_cadunico`, `01_assistencia_social_dh_disque100` — os três constroem |
| `valida_*` (3) | um por fonte acima |
| `dim_*` (3) | `dim_01_assistencia_social_dh` (reproduz o publicado), `dim_09_educacao` e `dim_11_transportes` (**falham de propósito**: a guarda de perda barra a gravação, porque a consolidação das fontes não reproduz a dimensão publicada) |
| arquivo/doc (5) | `arquivo_dicionario`, `arquivo_tabelas`, `arquivo_parametros`, `documentacao`, `base_larga` |

Duas regras de geração explicam a lista, e ambas estão em [`_targets.R`](_targets.R):

- **Um alvo `fonte_<slug>` só nasce se a função `tratar_<nome>` existir.** Só três `tratar_*.R` existem (`fontes/*/*/R/`); as outras sete pastas de fonte têm apenas um README gerado.
- **Um alvo `dim_<slug>` só nasce se a dimensão tiver ≥ 2 fontes publicadas em `dados/fonte/`.** Com uma fonte só, consolidar seria copiar.

**Rode `tar_manifest()` antes de invocar qualquer alvo pelo nome.** Para uma dimensão sem alvo — que é a maioria —, atualizar significa **escrever o `tratar_*.R` primeiro** (use `mape_nova_fonte()`). O critério 8 de `tools/verificar_fechamento.R` confere que todo alvo citado em bloco de código da documentação existe no grafo.

O alvo `documentacao` **deixou de gravar a própria dependência** (achado 69): ele recalcula os campos do dicionário em memória, e gravá-los tem comando próprio, `Rscript tools/recalcular_dicionario.R`, que roda **a montante** do grafo.

**Nunca edite `_targets.R`.** Os alvos são gerados a partir de `dicionario/tabelas.csv`. Acrescentar uma fonte é acrescentar uma linha lá e um `tratar_<nome>.R` — o grafo se ajusta sozinho.

## Consumir os dados

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

mape_tabelas_publicadas()                  # as 26 tabelas
mape_ler("saude")                          # uma dimensão, pelo nome
mape_ler("educacao/ideb", territorio = TRUE)
mape_cobertura("14_corrupcao")             # duas colunas: presença de valor e valor informativo
mape_derivadas("taxa_homicidios_p100k")    # indicador com o denominador visível
mape_montar_base_larga(flags = TRUE, deduplicar = TRUE)
```

As duas ressalvas da auditoria foram corrigidas. `mape_cobertura()` passou a devolver **duas** medidas — `cobertura_pct` e `cobertura_substantiva_pct` (achado 21) — e o critério dela é o **valor**, não o prefixo: `ano_ref_*` e `flag_*` em zero são preenchimento e não contam; **`flag_*` ligado conta**, porque é observação de que o evento ocorreu. A primeira correção do achado 21 excluía `flag_` inteiro e trocava um erro pelo outro: `11_transportes` caía para 27 municípios quando 133 têm dado.
 E `mape_ler()` **avisa** quando a tabela pedida tem defeito declarado no dicionário, listando os primeiros e apontando para o `qa/` dela (achado 32).

Mesmo assim: **antes de responder pergunta substantiva sobre uma dimensão, leia o campo `observacoes` dela em `dicionario/tabelas.csv`.** Dezenove grupos ficaram como `mitigado`, o que quer dizer marcados e detectáveis, mas com o defeito ainda no dado. Os mais consequentes estão em `04_economia` (a série de PIB tem um fator de bloco), `06_financas` (receita inflada em uma ordem de grandeza, e duas colunas quase todas zero) e `13_seguranca` (70 códigos não municipais, agora marcados por `flag_codigo_nao_municipal`).

**Quem só consome os dados publicados não precisa de conta no Google Cloud.** A credencial só é exigida para reextrair uma fonte do BigQuery. Ela vive em `MAPE_GCP_BILLING`, no `.Renviron` (que o `.gitignore` cobre, porque o repositório é público). Use `.Renviron.exemplo` como molde, e nunca uma chamada literal a `set_billing_id`.

**Nunca rode um script do legado.** Vários consultam o BigQuery sem filtro e geram custo real: o do SICONFI baixa 18,5 milhões de linhas, o do SIM varre o país inteiro, e alguns executam a consulta e descartam o resultado.

## Arquitetura

Três camadas, e a distinção entre as duas primeiras é a decisão central:

```
fonte  →  dimensão  →  base larga
```

**A fonte é canônica** e deveria guardar o dado *como foi observado*, na granularidade nativa. `03_meio_ambiente/adaptabrasil` tem 5.570 linhas porque o AdaptaBrasil publica um retrato de 2015. (A promessa vaza em pelo menos dois lugares: `11_transportes/tarifa_zero` já vem expandida, com 81,7% de carry-forward e a evidência apagada, e `raw/cadunico.csv` é a saída do pipeline legado, não o bruto da origem.)

**A dimensão é derivada** e é o painel município × ano. `03_meio_ambiente` tem 183.810 linhas, com aquele retrato repetido de 2010 a 2020 — sem nenhum marcador que diga qual linha foi medida e qual foi replicada.

**A base larga** junta 15 dimensões em 424 colunas. É derivada, gerada por função, não versionada. (São 17 eixos em `dicionario/dimensoes.csv`; `00_diretorios` só tem tabela de fonte, e `15_dados_historicos` é descartada em silêncio.)

### Árvore

```
config/parametros.yml      única fonte de verdade para constantes
dicionario/*.csv           a especificação: 432 variáveis, 26 tabelas
R/                         16 arquivos de funções comuns
fontes/<dim>/<fonte>/      extrair_*.R, tratar_*.R, MANIFESTO.yml, raw/
dados/{fonte,dimensao}/    Parquet + csv.gz, versionados abaixo de 20 MB
dados/derivado/            base larga (não versionada)
qa/                        relatórios de qualidade e de paridade
auditoria/                 RELATORIO-FINAL.md e CORRECOES.csv primeiro; A1–A13 +
                           CONSOLIDADO.md são a evidência (secoes/ e *.local.md
                           não versionados)

tools/                     validar_tudo.R, verificar_fechamento.R, rodar_grafo.R,
                           recalcular_dicionario.R, sweep_mutacao.R, atualizar_ipca.R,
                           migração, hooks, publicar_release.R
tests/testthat/            14 arquivos; os que travam as correções desta rodada são
                           test-paridade.R, test-base-larga.R,
                           test-validacao-checagens.R e test-hook-pre-commit.R.
                           setup.R traz os auxiliares de fixture (raiz_de_teste(),
                           gravar_fixture(), limpar_caches_mape()) — use-os: teste
                           que grava fora de raiz descartável suja a árvore

docs/ plano/ pendencias/   documentação
qa/referencia/             base do pipeline antigo, p/ paridade (não versionada)
```

Tudo é escrito em português: comentário, nome de função, documento, mensagem de commit (frase descritiva, sem prefixo de convenção). Nome de coluna e slug são snake_case ASCII, sem acento.

### As constantes vivem em `config/parametros.yml`

Nenhuma delas deve ser reescrita dentro de um script — foi a prática oposta que produziu, no legado, oito cópias da base do deflator. Leia com `mape_param("chave")`. Estão lá a janela do painel (`anos_painel: [1989, 2024]`), o mês-base do deflator (`12/2023` → sufixo `brl2023`), a lista de sentinelas que viram `NA`, o contrato de tipo das chaves e os limiares de QA — inclusive `max_mb_versionavel: 20`, que é o número que o hook de `pre-commit` aplica.

### A camada `R/`

Uma responsabilidade por arquivo; `tar_source("R")` carrega tudo. São **79 funções `mape_*`**.

O achado 26 mediu que 26 delas podiam virar `function(...) NULL` sem quebrar teste nenhum. As que ele nomeou foram cobertas e **hoje morrem sob mutação** — medido, 0 de 6 sobrevivem entre `mape_montar_base_larga`, `mape_paridade`, `mape_esqueleto_painel`, `mape_sha256`, `mape_descricoes_repetidas` e `mape_colunas_invariantes`. **O número geral não foi remedido**: a varredura das 79 roda a suíte inteira uma vez por função e leva horas. Antes de confiar na suíte para pegar regressão numa função específica, meça aquela função:

```bash
Rscript tools/sweep_mutacao.R mape_deflacionar        # uma, em segundos
Rscript tools/sweep_mutacao.R                          # as 79, em horas
```

O script grava `R/zzz_mutacao_temporaria.R` enquanto roda e o remove no fim; se você o interromper, apague-o à mão.


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
- **Prefixo de fonte obrigatório** quando duas fontes medem o mesmo conceito: `pni_` contra `ieps_` na cobertura vacinal, `sim_` contra `fbsp_` na morte violenta. (Cuidado com a generalização: das oito colunas `ieps_cobertura_vacinal_*`, **cinco** são a mesma medida do `pni_` truncada em 100, e **três** — rotavírus, meningococo C e pneumocócica — não têm par `pni_` nenhum e são a única medição dessas vacinas no painel.)

- **A numeração das dimensões é só de acréscimo.** Nunca renumere: o número entra em caminho de arquivo, nome de tabela publicada, URL de release e documentação, e renumerar quebra tudo isso em silêncio.

### O dicionário é a especificação

Ele é **lido pelo código** para renomear colunas, validar tipos e domínios, e gerar a documentação. Não é subproduto — é entrada do grafo (`arquivo_dicionario`), então mexer nele deixa a documentação desatualizada e `tar_outdated()` diz isso.

Campos **calculados** (`tipo_real`, `pct_na`, `n_distintos`, `minimo`, `maximo`, `n_infinito`, `pct_zero`, `janela_efetiva`) são reescritos por `mape_recalcular_campos()` a cada execução, e o comando é `Rscript tools/recalcular_dicionario.R`. Editá-los não adianta.

**O cuidado que mais custa tempo**: eles são medidos na tabela declarada no campo `tabela`, que para **110 variáveis é a FONTE e não a dimensão**. A mesma coluna tem estatística diferente nas duas — `ano_ref_inicio_tarifa_zero` é 81,7% vazia na fonte e 99,9% na dimensão —, e o dicionário só guarda uma. Por isso a coluna `vazios` dos `.md` gerados passou a ser medida na tabela que o documento descreve, com nota nomeando as colunas cujos campos vêm de outra (achado 55); e por isso a checagem `faixa_declarada` trata divergência como aviso, e não erro, quando a medição vem de outra tabela.

Outro: 83 colunas publicadas não têm linha na documentação da tabela a que pertencem.

O campo `escala` tem vocabulário de **12 valores**, e nenhum código o lê — é especificação, não entrada: `contagem`, `brl`, `0-100`, `indice`, `categorica`, `taxa`, `0-1`, `fisica`, `identificador`, `binaria`, `razao`, `ano`. Sufixo de taxa (`_p100k`, `_p1k`, `_p100dom`) é `taxa` e **não** `0-100`: uma taxa por 100 mil não tem teto, e declará-la limitada foi defeito real (achado 101).


Toda renomeação vai para `dicionario/deprecacao.csv`. Os **203 renomeios resolvem numa coluna publicada**, seguindo a cadeia quando o nome mudou duas vezes — eram 7 destinos mortos, e o critério 15 de `verificar_fechamento.R` confere isso a cada execução.

### Arquivos gerados — não edite à mão

Cada um traz um aviso no cabeçalho. **Quem os escreve não é o mesmo comando:**

```
tar_make(documentacao)  ->  dicionario/README.md, dados/dimensao/*.md,
                            fontes/<dim>/<fonte>/README.md
mape_validar_tabela()   ->  qa/<slug>.md
mape_paridade()         ->  qa/paridade_<dim>.md
```

A versão anterior deste arquivo dizia que `tar_make(documentacao)` sobrescrevia os cinco. Não sobrescreve: `grep 'mape_caminho("qa"' R/documentacao.R` devolve zero. Para regerar QA use `Rscript tools/validar_tudo.R`; para paridade, `mape_paridade()` por dimensão.

Para mudar o que eles dizem, mude `dicionario/*.csv` ou o dado, e regere. **O critério 13 de `verificar_fechamento.R` regera tudo num espelho temporário e compara** — porque o padrão de defeito mais comum aqui foi corrigir o dicionário e esquecer o `.md`, que é o que o consumidor lê.

### Validação e paridade

`mape_validar_tabela()` roda até **20 checagens** por tabela (11 a 20, conforme o que a tabela tem)
 e escreve `qa/<slug>.md`.
 A regra é executada, e não só declarada: erro impede a publicação, aviso exige justificativa, e **aviso sem justificativa vira erro e bloqueia a gravação**. A justificativa é procurada em três lugares, nesta ordem: **`qa/justificativas.csv`** (casando `slug_tabela` + `checagem` + `coluna`, e a coluna sai do prefixo `"<coluna>: "` da descrição do achado), o campo **`problema`** da variável nomeada, e **`qa/erros_aceitos.csv`** para erro reivindicado. Por isso toda checagem nova deve começar a descrição pelo nome da coluna: sem esse prefixo a justificativa não casa e o aviso vira erro.
 `mape_escrever_tabela()` chama a validação antes de gravar. Use `gravar = FALSE` para inspecionar sem escrever.

Duas checagens são novas. **Exclusividade do bloco territorial**: nenhuma tabela além de `00_diretorios/municipios` deveria publicar nome de município ou de UF — hoje acusa exatamente um caso, `sigla_uf_nome` em `04_economia`. E **faixa declarada**: confronta o valor publicado contra o `[minimo, maximo]` que o dicionário guarda, e distingue os dois motivos possíveis. Se a coluna é medida naquela tabela, o dicionário está velho e isso é **erro**; se é medida noutra — 110 variáveis têm os campos calculados medidos na FONTE —, é aviso, e o caso vivo é `flag_adota_tarifa_zero`, que declara `[1, 1]` porque na fonte só há quem adotou, enquanto a dimensão tem 183.236 zeros legítimos.


`mape_paridade()` compara cada dimensão com a base do pipeline antigo, com as diferenças aceitáveis reivindicadas de antemão em `qa/paridade_esperada.csv`. Ela compara **o conjunto de chaves** (linha que só existe de um lado é achado), conta **valor→NA e NA→valor em separado**, e as **9 reivindicações nominais são todas alcançáveis** — eram 2 de 9. Um curinga `*` que não absorve diferença nenhuma emite aviso; uma reivindicação de coluna que não existe dos dois lados é registrada como **órfã**; e uma de coluna presente nos dois lados que não absorve diferença nenhuma, como **inerte**. As duas últimas contam como `c_nao_explicada` — ou seja, **manter reivindicação "por segurança" agora quebra o critério**: quando a diferença que ela explicava some, a linha tem de sair do CSV.
 Precisa de `qa/referencia/base_municipios_brasileiros.RDa`, que não é versionado (Drive do MAPE); `gravar = FALSE` roda sem escrever.

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
- **As coberturas vacinais do SI-PNI passam de 100%**: 445.721 células (31,5%) acima de 100, com máximo de 51.175%, e a justificativa registrada declara esse mesmo número.
- **Cinco das oito colunas `ieps_cobertura_vacinal_*` duplicam o SI-PNI** (coincidem com `min(pni_*, 100)` em 92,8% a 94,6% das linhas). As outras três — rotavírus, meningococo C e pneumocócica — **não têm par `pni_` e são a única medição dessas vacinas no painel**. A declaração valia para as oito e era falsa nessas três.
- **A série de PIB de `04_economia` tem três quebras de nível** (2001, 2004, 2011) que nenhum deflator explica, e `06_financas` tem colunas de receita infladas em uma ordem de grandeza e zeradas em 99% das linhas de alguns anos. Não use essas duas dimensões em análise sem ler os achados 1–5.
- **Códigos não municipais publicados**: 352 linhas de 70 códigos em `13_seguranca` inflam a soma nacional de homicídios em até 10,3%, e os 30 pseudo-códigos do Rio deixam a série municipal de 1996–1998 **96,1%** subestimada. Filtre por `flag_codigo_nao_municipal == 0` antes de qualquer agregado municipal.
- **O hook de `pre-commit` barra arquivo acima de 20 MB e caminho de `mape_municipios/`.** Instale-o (`bash tools/hooks/instalar.sh`) — o hook do seu clone não se atualiza sozinho quando o do repositório muda. O limiar sai de `config/parametros.yml`, e caminho com acento e arquivo removido da árvore depois do `git add` **passaram a ser barrados** (achados 61 e 84, com teste em `tests/testthat/test-hook-pre-commit.R`). `--no-verify` contorna, e quase nunca é o certo.

- **Dado bruto do CadÚnico (10,6 MiB) está no histórico público do git**, apesar da promessa de que `**/raw/` nunca é versionado. Exceção decidida e registrada em `plano/migracao-etl/03-versionamento-qa.md`; é agregado municipal público, sem PII.
- **O identificador do projeto GCP está em três commits do histórico remoto.** Os detalhes redigidos e o roteiro de remediação ficam em `auditoria/VAZAMENTO-GCP.local.md`, que não é versionado — não copie o conteúdo dele para arquivo que vá para o git.

## O que ainda está aberto

Os 105 grupos foram trabalhados em 26/07/2026 e **reverificados na mesma data**, um por um, por sete verificadores adversariais instruídos a derrubá-los. A reverificação achou **5 grupos que não se sustentavam** (26, 34, 55, 66, 91) e **23 parciais**; os 28 foram fechados, e é dessa rodada que vêm as checagens 13 a 17 de `verificar_fechamento.R`. O que sobrou é trabalho de fundo, não pendência de auditoria:

- **O caminho de reconstrução não existe para 15 tabelas.** Reescrever os produtores é o pré-requisito de qualquer reprocessamento. `00_diretorios/municipios` saiu dessa lista e reproduz o publicado com `all.equal == TRUE`.
- **A primeira reextração nunca aconteceu.** Existe um único `extrair_*.R` (`fontes/00_diretorios/municipios/`), e ele nunca rodou. A única extração de verdade foi a do PIB, um cache pontual.
- **Sete das dez fontes não têm `tratar_*.R`** e por isso não estão no grafo: adaptabrasil, atlas_ivs, censup, ideb, tarifa_zero, tarifas, mcmv_fgts. Os Parquet delas vieram de `tools/migracao/fatiar_fontes.R`.
- **Seis fontes não migraram**, com diagnóstico em `pendencias/`. Nenhuma contribui com coluna publicada.
- **Seis tabelas ainda declaram `licenca = "A VERIFICAR"`** (eram 26 sob "a verificar"). Três casos são substantivos: IEPS Data, Anuário do FBSP — cujo `CC BY-NC-ND` é **incompatível** com a redistribuição sob CC BY 4.0 que o release faz — e Kustov & Pardelli. A checagem `licenca` acusa as seis.
- **O release v1.0.0 está montado em `dist/` e não foi publicado.** O comando está no fim de `tools/publicar_release.R`. Resolva antes a licença de `13_seguranca`.

**Dezenove grupos continuam `mitigado`**: o defeito está no dado, declarado no dicionário e detectável por checagem, e a correção de fundo depende de decisão sua ou de insumo ausente. Os três que precisam de insumo são a escala de `12_habitacao` (falta a planilha original), os zeros anteriores à instalação do município (falta `ano_instalacao` no diretório) e o SICONFI bruto de `06_financas`. As decisões pendentes estão na § 5 de `auditoria/RELATORIO-FINAL.md`.
