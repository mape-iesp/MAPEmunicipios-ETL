# 2. As fontes de BigQuery: reextrair com escopo atualizado

Este é o degrau 1 da escada, e é onde está a maior parte do dado. A regra do capítulo: **descobrir
antes de escanear**, porque metadado é grátis e dado é cobrado.

## 2.1 Descoberta custa zero — use isso

Antes de escrever qualquer `SELECT`, três chamadas que **não** escaneiam byte nenhum e portanto não
custam nada:

```r
library(bigrquery)
b <- mape_billing_id()

# 1. Quais tabelas o dataset tem
bq_dataset_tables(bq_dataset("basedosdados", "br_inep_ideb"))

# 2. Qual o esquema de uma delas — nomes e tipos, sem ler linha
bq_table_fields(bq_table("basedosdados", "br_inep_ideb", "municipio"))

# 3. Quantas linhas e quantos bytes ela tem
bq_table_meta(bq_table("basedosdados", "br_inep_ideb", "municipio"))$numRows
```

E o dry-run, que mede o preço exato de uma consulta antes de executá-la:

```r
mape_query(sql, fonte = "09_educacao/ideb", so_estimar = TRUE)   # devolve bytes, não executa
```

**A fronteira temporal também se descobre barato.** `SELECT MAX(ano)` sobre uma tabela particionada
por ano escaneia só a coluna `ano` — meça com `so_estimar = TRUE` primeiro, e se passar de alguns
GiB, pare e reveja: a tabela provavelmente não está particionada como você supôs.

## 2.2 O que está atestado e o que precisa ser confirmado

**Não invente identificador de tabela.** A Base dos Dados renomeia e reorganiza datasets, e o
repositório só atesta sete. A coluna "atestado" abaixo diz onde o identificador aparece **neste
repositório**; tudo que não estiver atestado passa pela descoberta da § 2.1 antes de virar código.

| dimensão / fonte | identificador | atestado em |
|---|---|---|
| `00_diretorios/municipios` | `basedosdados.br_bd_diretorios_brasil.municipio` | ✅ `extrair_municipios.R:57` — escrito, **nunca executado** |
| `04_economia` | `basedosdados.br_ibge_pib.municipio` | ✅ consulta executada em 26/07/2026, 3,77 MiB |
| `02_populacao` | `basedosdados.br_ibge_populacao.municipio` | ⚠️ citado em `migracao-etl/02-...md` § 8.5, nunca executado |
| `06_financas` | `br_me_siconfi.municipio_receitas_orcamentarias` | ⚠️ citado no diagnóstico; **e é a consulta de 18,5 M linhas** |
| `03_meio_ambiente` (SNIS) | `br_mdr_snis.municipio_agua_esgoto` | ⚠️ citado no diagnóstico |
| `03_meio_ambiente` (PRODES) | `br_inpe_prodes.municipio_bioma` | ⚠️ citado no diagnóstico |
| `05_sociedade` | `br_ipea_avs.municipio` | ⚠️ citado no diagnóstico |
| `09_educacao/ideb` | dataset `br_inep_ideb` | ⚠️ só o dataset, em `tabelas.csv`; tabela a confirmar |
| `09_educacao/censup` | dataset `br_inep_censo_educacao_superior` | ⚠️ só o dataset; tabela a confirmar |
| `08_energia_internet` | Anatel — SCM e telefonia móvel | ❌ **a descobrir** |
| `10_saude` | SI-PNI e e-Gestor | ❌ **a descobrir** |
| `13_seguranca` | SIM / DATASUS | ❌ **a descobrir** |
| `16_eleicoes` | TSE — quatro tabelas | ❌ **a descobrir** |
| `07_recursos_humanos` | MUNIC — verificar se está na BD | ❌ **a descobrir**; hoje é xlsx por edição |
| `11_transportes` | Mobilidados/ITDP | ❌ **a descobrir** |

## 2.3 O molde de uma extração

`fontes/00_diretorios/municipios/R/extrair_municipios.R` é o único `extrair_*.R` que existe, e é o molde do formato — não da execução. Ele nunca rodou, e
chama `mape_query()` + `arrow::write_parquet()` direto, sem escrever manifesto. Copie a estrutura,
não a chamada: o critério 2 da § 2.6 exige `sha256`, `sql_hash` e `data_download`, e quem escreve
esses três é `mape_baixar_cache()`.
O que copiar dele:

```r
extrair_<fonte> <- function() {
  fonte <- "<dimensao>/<fonte>"          # dentro da função, nunca global

  anos <- mape_param("anos_painel")

  # Colunas listadas uma a uma: coluna nova a montante não entra em silêncio.
  # Agregação no servidor: o custo é por byte escaneado, não por byte devolvido.
  consulta <- sprintf("
    SELECT
      dados.id_municipio,
      CAST(dados.ano AS INT64) AS ano,
      CAST(SUM(dados.medida) AS FLOAT64) AS medida
    FROM `basedosdados.<dataset>.<tabela>` AS dados
    WHERE dados.ano BETWEEN %d AND %d
    GROUP BY 1, 2
  ", anos[1], anos[2])

  mape_baixar_cache(consulta, fonte = fonte, arquivo = "bruto.parquet")
}
```

`mape_baixar_cache()` faz três coisas de uma vez: consulta (com o freio), grava em `raw/`, e escreve
`sha256`, `sql_hash` e `data_download` no `MANIFESTO.yml`. **E não reconsulta se o arquivo já
existe** — para atualizar de verdade é preciso `forcar = TRUE`, e é isso que torna a atualização um
ato deliberado em vez de um efeito colateral de rodar o grafo.

Três armadilhas medidas, todas já pagas uma vez:

- **`integer64`.** `as.numeric()` sobre `integer64` devolve `9.83e-321`; `sort()` e `range()`
  devolvem lixo sem erro. Resolva no servidor com `CAST(... AS FLOAT64)` ou `AS INT64`.
- **`id_municipio` é texto de 7 dígitos.** Não deixe virar número em lugar nenhum do caminho.
- **Consulta sem filtro de ano.** O script do SIM no legado varre o país inteiro a cada execução, e
  metade dele é código morto que ainda assim executa a consulta.

## 2.4 Ordem sugerida, por razão de custo e de dependência

**Primeiro `00_diretorios/municipios`**, sempre. Ele é a espinha dorsal: dono exclusivo do bloco
territorial e origem de toda conversão de 6 para 7 dígitos. Se o diretório mudar (município novo,
código novo), tudo a jusante muda. É também a extração mais barata, e a única com script escrito — que nunca foi executado nem
testado: `qa/custo_bigquery.csv` só registra as duas consultas do PIB, de 26/07/2026.

Depois, por ordem de retorno sobre risco:

| ordem | fonte | por quê |
|---:|---|---|
| 1 | `00_diretorios/municipios` | dependência de todo o resto; script escrito, falta a primeira execução |
| 2 | `04_economia` (PIB) | consulta já escrita e medida; **mas resolva o achado 1 antes** — a série publicada tem fator de bloco (3× em 2002-03, 2× em 2004-10), e reextrair sem decidir sobrescreve o defeito com outro |
| 3 | `09_educacao/ideb` | bienal, pequena; `dim_09_educacao` falha de propósito (a consolidação dá 60.672 linhas contra 111.388 e perde `ano_ref_ideb`), mas quem destrava isso é o `tratar_ideb.R`, não a reextração |
| 4 | `09_educacao/censup` | idem; cuidado com as colunas de alto volume |
| 5 | `02_populacao` | destrava denominador de toda taxa `_p100k` e `_p1k` — **e é o insumo do achado 28**: a população de nove municípios está fabricada por extrapolação linear entre 2013 e 2021 |
| 6 | `16_eleicoes` | 2024 está faltando e é a lacuna mais visível |
| 7 | `05_sociedade` (IVS) | censitária; decidir o que fazer com o Censo 2022 |
| 8 | `13_seguranca` (SIM) | **cara**: dimensione com dry-run e agregue no servidor — **e é o insumo do achado 47** |
| 9 | `10_saude`, `08_energia_internet`, `03_meio_ambiente`, `11_transportes` | múltiplas fontes por dimensão |
| 10 | `06_financas` (SICONFI) | **a mais cara de todas** e com três achados `mitigado` no ledger (3, 4, 5) — marcados e detectáveis, com o defeito ainda no dado |

**Duas dessas linhas subiram de importância em 27/07/2026**, e a razão não é custo nem dependência:
`02_populacao` (5) e `13_seguranca` (8) são o insumo que falta para fechar os achados 28 e 47, dois
dos sete grupos que o `RELATORIO-FINAL.md` § 4 declara bloqueados por falta de dado que não está no
repositório. Ver [`00-inventario-de-fontes.md`](00-inventario-de-fontes.md) § 0.7. Se a rodada
precisar ser encurtada, corte por baixo — mas não corte essas duas.

Uma tarefa que não é reextração e cabe aqui, porque é a mesma consulta: **acrescentar
`ano_instalacao` a `00_diretorios/municipios`**. A informação é do IBGE, e a guarda
`incluir_flag_instalado` de `R/painel.R` já existe e é **código morto por falta desse campo** — é o
achado 29, e ele fecha com uma coluna a mais no `SELECT` da extração do diretório.

## 2.5 O SICONFI merece parágrafo próprio

É a consulta que o legado usava para baixar 18,5 milhões de linhas, e a dimensão que ela alimenta
tem três classes de defeito `mitigado` no ledger: receita inflada em uma ordem de grandeza (achado 3),
vazio publicado como zero (4) e buraco de 2018-2021 (5). O relatório da auditoria separa as duas
coisas: *"Duas das três classes de defeito de `06_financas` — receita inflada em uma ordem de
grandeza e vazio publicado como zero em 2018-2021 — exigem reescrever a agregação sobre o dado de
origem"*. A terceira, o achado 4, é decisão de valor e não falta de insumo (§ 5, item 8).

Ou seja: **`06_financas` não é uma atualização, é uma reconstrução.** Trate-a como fonte nova, com
dry-run antes de cada passo, agregação no servidor, e comparação contra o publicado coluna a coluna
antes de gravar. Não a deixe para o fim por ser difícil — deixe para o fim porque as outras destravam
mais valor por byte escaneado.

## 2.6 Critério de aceitação de uma extração de BigQuery

Uma fonte de BigQuery está pronta quando **todas** valem:

1. `fontes/<dim>/<fonte>/R/extrair_<fonte>.R` existe, sem `SELECT *` e sem ano literal.
2. `MANIFESTO.yml` tem `url`, `orgao`, `licenca` preenchida, `sha256`, `sql_hash` e `data_download`.
3. `dicionario/proveniencia.csv` tem a linha da extração; `qa/custo_bigquery.csv` tem o custo.
4. `tratar_<fonte>.R` existe e o alvo `fonte_<slug>` aparece em `tar_manifest()`.
5. `Rscript tools/rodar_grafo.R` sai com código 0 para esse alvo.
6. `dicionario/tabelas.csv` tem `cobertura_temporal_da_fonte` e `data_ultima_atualizacao_fonte`
   **medidos**, não copiados.
7. `Rscript tools/validar_tudo.R` não introduz erro novo, e todo aviso novo tem justificativa.
