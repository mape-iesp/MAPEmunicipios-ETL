# 1. A arquitetura da atualização

Este documento fixa as regras. Os dois seguintes aplicam-nas fonte por fonte. Quem for executar
deve ler este antes de escrever a primeira linha de código, porque quase toda decisão aqui já foi
tomada errada uma vez no legado, e o custo está registrado.

## 1.1 A escada de acesso

Toda fonte é classificada num destes cinco degraus, e **só se desce um degrau com justificativa
escrita no manifesto**. O objetivo do projeto é subir todo mundo o mais alto possível.

| # | degrau | quando | como |
|---|---|---|---|
| 1 | **BigQuery / Base dos Dados** | a fonte está espelhada na BD | `mape_query()` com `SELECT` explícito e agregação no servidor |
| 2 | **API oficial** | o órgão publica endpoint estável (SIDRA, dados abertos) | `httr` + `mape_registrar_proveniencia()`, no molde de `tools/atualizar_ipca.R` |
| 3 | **HTTP com URL estável** | há link direto para o arquivo | `mape_baixar()` — sha256 e versão vão para o manifesto |
| 4 | **Pacote R** | existe pacote que encapsula o acesso | só se entrar no `renv.lock`; ver § 1.8 |
| 5 | **Manual documentado** | o portal exige seleção de filtros e não há API | procedimento passo a passo no `README.md` da fonte + manifesto com sha256 |

**Degrau 5 não é derrota, é declaração.** O que não se aceita mais é o estado atual de cinco fontes:
arquivo sem origem, sem data, sem hash e sem procedimento. A regra do plano original continua
valendo — *"não vale a pena escrever um raspador frágil para substituir cinco linhas de instrução"*
—, mas agora ela exige que as cinco linhas existam.

**Raspagem de HTML é o último recurso**, abaixo do degrau 5, e só com o seletor documentado e um
teste que falhe quando a página mudar. Um raspador que quebra em silêncio é pior que um download
manual anotado.

## 1.2 Extrair e tratar são coisas separadas, e a separação é o que permite atualizar

O scaffold de `mape_nova_fonte()` já impõe isso, e a razão está no cabeçalho que ele gera:
*"separar os dois é o que permite reprocessar sem rebaixar, e rebaixar sem reprocessar"*.

```
extrair_<fonte>()   →  raw/<arquivo>            (rede; caro; registra proveniência)
tratar_<fonte>()    →  dados/fonte/<slug>       (determinístico; roda quantas vezes quiser)
```

Regras que não são negociáveis, todas herdadas de defeito medido:

- **`extrair_` não limpa, não renomeia, não valida.** Se ele filtrar, o filtro vira parte do dado e
  ninguém mais sabe o que a origem trazia. O `raw/cadunico.csv` é o caso: dois passos aplicados na
  extração viraram dado, e a fonte deixou de ser a fonte.
- **`tratar_` não vai à rede.** Nunca. Se precisar de algo de fora, esse algo é uma extração.
- **O slug fica dentro da função**, não numa constante global: o `targets` carrega todos os scripts
  de fonte na mesma sessão, e a global do último sobrescreveria a dos anteriores.
- **O encadeamento do `tratar_` tem ordem fixa:** limpar cabeçalho → renomear pelo dicionário →
  sentinelas (com `converter_numerico = FALSE`) → normalizar chaves → derrubar chave nula → validar
  → publicar. Inverter sentinelas e chaves converte `id_municipio` para double e apaga o zero à
  esquerda.

## 1.3 O escopo é parâmetro, nunca literal

O pedido é "pegar sempre os dados mais atualizados possíveis". Isso **não** significa escrever
`WHERE ano >= 2000` e voltar aqui em 2027 para editar. Significa:

```r
# certo: o limite vem da configuração, e a consulta descobre o teto real da origem
anos <- mape_param("anos_painel")            # [1989, 2024]
sql <- sprintf("... WHERE ano BETWEEN %d AND %d", anos[1], anos[2])
```

E a janela do painel é uma decisão explícita: **ampliar `anos_painel` é uma edição de
`config/parametros.yml`, feita de propósito, não um efeito colateral de uma extração.** Se a origem
passou a publicar 2025 e o painel vai até 2024, a extração traz 2025, o `tratar_` o descarta, e o
relatório de QA avisa. Ampliar a janela muda **todas** as 26 tabelas — é decisão do responsável.

Três consequências práticas:

1. **`SELECT *` é proibido.** As colunas vão listadas uma a uma, como em
   `fontes/00_diretorios/municipios/R/extrair_municipios.R:29-56`, e pelo motivo que está escrito
   lá: *"para que uma coluna nova na tabela remota não entre em silêncio na base publicada"*.
2. **A cobertura observada é medida, não declarada.** Depois de extrair, compare o `range(ano)` do
   que veio com `cobertura_temporal_da_fonte` do dicionário, e atualize o campo.
3. **`data_ultima_atualizacao_fonte` passa a ser preenchido.** Hoje está vazio nas 26 linhas.

## 1.4 A guarda de escrita vai barrar a atualização — e está certa

`mape_escrever_tabela()` compara com o publicado antes de gravar e **para com erro** se a nova
perder linha, coluna, chave ou município (achado 6). Numa atualização isso vai acontecer, e há
exatamente dois casos:

**Caso A — a nova tabela cresce.** É o esperado: mais anos, mesmas colunas. Passa direto.

**Caso B — a nova tabela encolhe ou muda de forma.** A origem revisou a série, mudou o esquema, ou
o novo produtor não reproduz o que a migração publicou. **Aqui a guarda está certa e o reflexo de
contorná-la é o erro.** Antes de qualquer `permitir_perda = TRUE`:

1. Rode com `publicar = FALSE` e compare (`mape_consolidar_dimensao(..., publicar = FALSE)`).
2. Descubra **por que** encolheu. Perda de município costuma ser junção; perda de coluna costuma ser
   renomeação a montante.
3. Só então, se a perda for legítima, `permitir_perda = TRUE` **com** `motivo_perda` — que fica em
   `qa/perdas_autorizadas.csv`. Sem motivo, a autorização é recusada.

**Uma revisão a montante não é perda de dado, é dado novo.** O IBGE revisa o PIB, o DATASUS revisa
óbitos, o IPCA é revisado. Quando os valores mudam sem que linhas sumam, o que muda é o *valor
publicado* — e isso exige reivindicação em `qa/paridade_esperada.csv` antes de rodar, não depois.

## 1.5 O freio de custo, e por que ele não se negocia

O modelo on-demand do BigQuery **cobra por byte escaneado, não por byte devolvido**: um `LIMIT 10`
sobre uma tabela grande custa o mesmo que a consulta inteira. O legado tem o registro do que isso
custa — a consulta do SICONFI baixa 18,5 milhões de linhas, a do SIM varre o país inteiro sem filtro
de ano, e três scripts da Saúde executam a consulta e terminam em `summary()` sem gravar nada.

O freio de `mape_query()` tem quatro partes e **nenhuma é opcional**: dry-run sempre primeiro, teto
por consulta (`bq.teto_gib_consulta`, hoje 64 GiB), `maximum_bytes_billed` no servidor, e acumulado
de sessão (`bq.teto_gib_sessao`, 512 GiB) conferido contra `qa/custo_bigquery.csv`.

Regras de escrita de consulta:

- **Agregue no servidor, com `GROUP BY`.** Nunca num laço por município ou por ano.
- **Nunca traga coluna que será descartada.** A consulta legada do CensoSup trazia oito colunas de
  alto volume (nome e endereço da mantenedora) descartadas no `group_by` seguinte.
- **Use `so_estimar = TRUE` antes de rodar de verdade.** Custa zero e diz o preço.
- **`CAST(... AS FLOAT64)` no servidor** quando a coluna for `integer64`. A rodada de correção
  gastou uma consulta a mais exatamente por não fazer isso.

Referência de ordem de grandeza, medida: a consulta agregada do PIB (122.466 linhas devolvidas)
escaneou **3,77 MiB** e custou **US$ 0,00** — 0,006% do teto por consulta.

## 1.6 Proveniência: cada extração deixa rastro, e o rastro é versionado

| arquivo | o que registra | versionado? |
|---|---|---|
| `MANIFESTO.yml` (por fonte) | origem, URL, licença, `arquivo_local`, `sha256`, `versao_fonte`, `data_download` | **sim** |
| `dicionario/proveniencia.csv` | uma linha por extração: método, hash da consulta, linhas, duração, usuário | **sim** |
| `qa/custo_bigquery.csv` | bytes do dry-run, bytes cobrados, resumo do SQL | **sim** |
| `fontes/*/raw/` | o arquivo bruto | **não** (`.gitignore`) |

O bruto não é versionado; o sha256 dele é. São 64 bytes dando a mesma garantia que versionar 194 MB
de planilhas da MUNIC. `mape_verificar_raw()` confere antes de processar e falha se divergir.

**Um cuidado ao rodar extrações, e ele já é concreto.** `R/bigquery.R:202` monta
`detalhe = paste0("projeto=", billing, "; bytes=", ...)`, ou seja, **o identificador do projeto GCP
entra num arquivo versionado a cada consulta**, e o repositório é público. As duas linhas de
`proveniencia.csv` tiveram esse identificador removido à mão em 26/07/2026 — mas a linha 202 não
mudou, então **a próxima extração o escreve de volta**.

Decida antes de rodar em lote, e as opções são três: parar de gravar o projeto no `detalhe`, gravar
um rótulo em vez do identificador, ou aceitar que ele fique. A auditoria já tratou os quatro
identificadores legados (achados 88 e 72) e o critério 9 de `tools/verificar_fechamento.R` confere
**só aqueles quatro** — o identificador corrente não está sob nenhuma checagem.

## 1.7 O que "atualizar" significa muda com a granularidade

Forçar tudo a caber em município × ano é a origem de boa parte dos defeitos publicados. Quatro
naturezas, quatro procedimentos:

| natureza | exemplo | o que atualizar significa |
|---|---|---|
| **painel anual** | PIB, SICONFI, SIM | acrescentar anos; a chave já é a certa |
| **censitária** | IVS (2000, 2010), religião | uma edição nova é uma **coluna de referência nova** (`ano_ref_*`), não um ano do painel. O **Censo 2022** é o caso vivo |
| **transversal** | diretório, `15_dados_historicos` | não tem ano; atualizar é trocar o retrato inteiro |
| **de evento** | fiscalizações da CGU, tarifa zero | a granularidade nativa é o evento. Agregar para município × ano é derivação, e pertence à dimensão, não à fonte |

**A camada de fonte guarda o observado.** Se a origem publica 106 eventos, a fonte guarda 106 linhas
— não 578 expandidas, que é o defeito aberto de `tarifa_zero` (achado 33). A expansão para o painel
é trabalho de `mape_expandir_painel()`, na dimensão, e ela marca o que replicou.

## 1.8 Dependência nova é decisão, não conveniência

O `renv.lock` tem **147 pacotes**. Estão lá `basedosdados` (0.2.3), `bigrquery` (1.6.2), `httr`
(1.4.8), `curl` (7.0.0), `readxl` (1.5.0), `openxlsx`, `rvest` (1.0.5), `jsonlite`, `arrow`, `yaml`,
`digest`, `deflateBR`.

**Não estão** `geobr`, `censobr`, `sidrar`, `ipeadatar`, `electionsBR`, `microdatasus` — e o legado
dependia de `munifacil`, que não está no CRAN. Acrescentar qualquer um é uma decisão a registrar,
com `renv::snapshot()`, e não uma linha de `library()` escrita no meio de um script.

Anote a assimetria: `dicionario/proveniencia.csv` registra duas chamadas a
`ipeadatar::ipeadata('PRECOS12_IPCA12')`, mas `ipeadatar` **não está no lockfile** — a série do IPCA
hoje é obtida por `deflateBR`, que está. É um lembrete de que proveniência registrada e ambiente
fixado podem divergir; confira os dois.

## 1.9 Licença antes de publicar, sempre

`tools/publicar_release.R:54` barra o release quando há erro de validação não reivindicado. Mas a
licença é decisão humana, e há uma **incompatibilidade conhecida**: o Anuário do FBSP sai, em algumas
edições, sob **CC BY-NC-ND**, e o release redistribui tudo como CC BY 4.0. `NC` proíbe uso comercial
e `ND` proíbe obra derivada — e uma tabela derivada é uma obra derivada.

Vinte das 26 tabelas já têm licença verificada (dado público federal, conferido em 26/07/2026). Seis
seguem `A VERIFICAR`: `13_seguranca` (FBSP), `10_saude` (IEPS), `14_corrupcao` e `15_dados_historicos`
(Kustov & Pardelli), `11_transportes` (Mobilidados/ITDP) e `11_transportes/tarifa_zero`
(Observatório). **Toda fonte nova entra com `licenca` preenchida ou não entra.**

## 1.10 Nada disso vale se a atualização não for repetível

O critério final de cada fonte não é "o dado novo entrou". É:

> Um segundo operador, sem contexto, roda `Rscript -e 'targets::tar_make(fonte_<slug>)'` daqui a um
> ano e obtém o dado do ano seguinte, sem editar código.

Se atualizar exigir editar um literal num script, o trabalho não terminou — falta parametrizar.
