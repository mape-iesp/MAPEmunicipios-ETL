# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Visão geral

ETL em R que constrói o **MAPEmunicipios**: um painel dos 5.570 municípios brasileiros, de 1989 a 2024, em 17 eixos temáticos, 26 tabelas publicadas e 431 variáveis documentadas.

> ✅ **O ETL está completo.** A migração do legado terminou, as sete funções prometidas no plano existem, os nomes foram harmonizados e a documentação é gerada.
>
> - [`README.md`](README.md) — como dar manutenção (é o documento principal)
> - [`docs/encerramento-migracao.md`](docs/encerramento-migracao.md) — o estado da migração
> - [`docs/fechamento-etl.md`](docs/fechamento-etl.md) — o que esta etapa entregou
> - [`docs/decisao-dois-repositorios.md`](docs/decisao-dois-repositorios.md) — por que o pacote R fica noutro repositório
> - [`plano/`](plano/) — o raciocínio por trás de cada decisão de desenho
>
> O legado em `mape_municipios/` (18 GB) continua sendo a referência de como cada número foi produzido, e é o alvo do teste de paridade. **Nunca é tocado nem versionado.**

**O pacote R vive noutro repositório**: `mape-iesp/MAPEmunicipios`. Este aqui é interno, para quem atualiza dado; aquele é público, para quem consome. O único acoplamento é o release do GitHub.

## Comandos

```bash
# Primeira vez, depois de clonar:
Rscript -e 'renv::restore()'
bash tools/hooks/instalar.sh

# Pipeline
Rscript -e 'targets::tar_make()'                      # o que estiver desatualizado
Rscript -e 'targets::tar_make(dim_09_educacao)'       # uma dimensão
Rscript -e 'targets::tar_make(documentacao)'          # regera os README
Rscript -e 'targets::tar_visnetwork()'                # desenha o grafo

# Testes (154)
Rscript -e 'testthat::test_dir("tests/testthat")'

# Empacotar o release que o pacote R consome
Rscript tools/publicar_release.R v1.0.0
```

Ambiente: R 4.5.2, fixado por `renv` (128 pacotes no lockfile). Quarto disponível.

## Consumir os dados

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

mape_tabelas_publicadas()                  # as 26 tabelas
mape_ler("saude")                          # uma dimensão, pelo nome
mape_ler("educacao/ideb", territorio = TRUE)
mape_cobertura("14_corrupcao")             # cobertura real, por ano
mape_derivadas("taxa_homicidios_p100k")    # indicador com o denominador visível
mape_montar_base_larga(flags = TRUE, deduplicar = TRUE)
```

**Quem só consome os dados publicados não precisa de conta no Google Cloud.** A credencial só é exigida para reextrair uma fonte do BigQuery. Ela vive em `MAPE_GCP_BILLING`, no `.Renviron` (que o `.gitignore` cobre, porque o repositório é público). Use `.Renviron.exemplo` como molde, e nunca uma chamada literal a `set_billing_id`.

**Nunca rode um script do legado.** Vários consultam o BigQuery sem filtro e geram custo real: o do SICONFI baixa 18,5 milhões de linhas, o do SIM varre o país inteiro, e alguns executam a consulta e descartam o resultado.

## Arquitetura

Três camadas, e a distinção entre as duas primeiras é a decisão central:

```
fonte  →  dimensão  →  base larga
```

**A fonte é canônica** e guarda o dado *como foi observado*, na granularidade nativa. `03_meio_ambiente/adaptabrasil` tem 5.570 linhas porque o AdaptaBrasil publica um retrato de 2015.

**A dimensão é derivada** e é o painel município × ano. `03_meio_ambiente` tem 183.810 linhas, com aquele retrato repetido de 2010 a 2020.

**A base larga** junta as 16 dimensões em 440 colunas. É derivada, gerada por função, não versionada.

### Árvore

```
config/parametros.yml      única fonte de verdade para constantes
dicionario/*.csv           a especificação: 431 variáveis, 26 tabelas
R/                         16 arquivos de funções comuns
fontes/<dim>/<fonte>/      extrair_*.R, tratar_*.R, MANIFESTO.yml, raw/
dados/{fonte,dimensao}/    Parquet + csv.gz, versionados abaixo de 20 MB
dados/derivado/            base larga (não versionada)
qa/                        relatórios de qualidade e de paridade
tools/                     migração, hooks, publicar_release.R
tests/testthat/            154 testes
docs/ plano/ pendencias/   documentação
mape_municipios/           legado, 18 GB, NUNCA versionado
```

### Contrato de dados

- **Chave**: `id_municipio` (texto de 7 dígitos) + `ano` (inteiro). Código não é quantidade.
- **`00_diretorios/municipios` é a espinha dorsal**, e é dono exclusivo do bloco territorial. Nenhuma outra tabela publica `nome_municipio` ou `sigla_uf`.
- **Códigos de 6 dígitos** viram 7 por `left_join` com o diretório em `id_municipio_6`.
- **`ano` só existe como chave.** Qualquer outro ano é `ano_ref_<fonte>`.
- **Sufixo obrigatório**, de vocabulário fechado: `_i`, `_pct`, `_prop`, `_razao`, `_p100k`, `_p1k`, `_p100dom`, `_brl_nominal`, `_brl2023`, `_km`, `_km2`, `_idx`, `_cat`, mais os prefixos `flag_` e `ano_ref_`. É isso que permite a validação **provar** que toda coluna `_pct` está entre 0 e 100.
- **Prefixo de fonte obrigatório** quando duas fontes medem o mesmo conceito: `pni_` contra `ieps_` na cobertura vacinal, `sim_` contra `fbsp_` na morte violenta.

### O dicionário é a especificação

Ele é **lido pelo código** para renomear colunas, validar tipos e domínios, e gerar a documentação. Não é subproduto.

Campos **calculados** (`tipo_real`, `pct_na`, `n_distintos`, `minimo`, `maximo`, `n_infinito`) são reescritos por `mape_recalcular_campos()` a cada execução. Editá-los não adianta — e é bom que não adiante, porque foi exatamente neles que os números da documentação antiga não fechavam.

Toda renomeação vai para `dicionario/deprecacao.csv`.

## Armadilhas conhecidas

- **`formatC(x, flag = "0")` sobre texto preenche com espaço, não com zero.** `mape_como_codigo()` preenche à mão por isso.
- **`integer64` é armadilha silenciosa.** `as.numeric(ano)` devolve `9.83e-321`; `sort()` e `range()` devolvem lixo sem erro. `mape_normalizar_chaves()` converte para `integer` sempre.
- **Duas tabelas têm chave duplicada herdada da fonte, e continuam tendo.** `06_financas` (222 chaves, emendas associadas por nome sem UF) e `15_dados_historicos` (54, Tocantins pré e pós-1988). Mantidas de propósito, para o problema ficar visível. `mape_montar_base_larga()` se recusa a rodar e nomeia a responsável.
- **A série nominal não existe.** Oito scripts do legado gravavam o valor deflacionado por cima do original. O único par que sobreviveu está na Saúde.
- **As coberturas vacinais do SI-PNI passam de 100%**, chegando a 51.175%. Domínio `[0,100]` declarado, para a validação avisar a cada execução.

## O que ainda está aberto

- A **primeira reextração nunca aconteceu**. Os `extrair_*.R` estão escritos e nunca rodaram.
- **Seis fontes não migraram**, com diagnóstico em `pendencias/`. Nenhuma contribui com coluna publicada.
- **Três licenças** precisam de verificação: IEPS Data, Anuário do FBSP e Kustov & Pardelli.
- **O release v1.0.0 está montado em `dist/` e não foi publicado.** O comando está no fim de `tools/publicar_release.R`.
