# 4. As fases, a ordem e os critérios de aceitação

Oito fases, contando a 0. A ordem não é sugestão: cada uma produz o insumo da seguinte, e duas delas existem
justamente para impedir que a pressa destrua dado publicado.

A regra que atravessa todas: **nada é declarado pronto sem medição.** Este repositório já teve uma
auditoria que falsificou a maior parte das estatísticas escritas em prosa, e a lição foi registrada
como norma — número em texto é afirmação a verificar.

## Fase 0 — Linha de base, antes de tocar em qualquer coisa

Sem isto não há como provar depois que a atualização não quebrou nada.

```bash
Rscript tools/verificar_fechamento.R          # tem de sair com código 0 ANTES de começar
Rscript -e 'testthat::test_dir("tests/testthat")'
Rscript tools/validar_tudo.R
git status --porcelain                        # tem de estar vazio
```

Grave a medição das 26 tabelas — linhas, colunas, municípios distintos, faixa de anos — num arquivo
de base. É contra ele que a fase 6 compara.

**Se `verificar_fechamento.R` já sai com código diferente de zero antes de você começar, pare e
resolva isso primeiro.** Você estaria construindo sobre uma rodada não fechada.

## Fase 1 — Descoberta (trabalho de rede, e o grosso do paralelismo)

Objetivo: **saber, para cada uma das 26 tabelas, onde a origem está hoje e até quando ela vai.** Sem
baixar dado, sem escanear byte cobrado.

Por fonte, sete respostas:

1. A origem ainda publica? Em que URL, hoje?
2. Existe API ou espelho na Base dos Dados? Qual o identificador exato da tabela?
3. Qual o **último período publicado pela origem** (não o último que temos)?
4. Qual a periodicidade real (não a declarada)?
5. Qual a licença, com link?
6. O esquema mudou desde a última extração? Que colunas entraram ou saíram?
7. Em que degrau da escada (§ 1.1) ela cabe?

Saídas da fase, todas versionadas:

- `FONTES.csv` atualizado, com as colunas de descoberta preenchidas.
- `MANIFESTO.yml` de cada fonte com `url`, `orgao` e `licenca` — **e os dois manifestos que não
  existem, de `09_educacao/ideb` e `09_educacao/censup`, criados**.
- `dicionario/tabelas.csv` com `data_ultima_atualizacao_fonte` preenchido (hoje: vazio nas 26) e
  `cobertura_temporal_da_fonte` conferida.
- Um relatório curto por fonte com a evidência: URL consultada, data, o que se viu.

**Nenhuma linha de dado publicado muda nesta fase.** Ela é barata, é paralelizável, e é o que
transforma o resto do plano de especulação em execução.

## Fase 2 — Infraestrutura, só o que faltar

Não reescreva o que existe (§ 0.6). Escreva o que a fase 1 provou que falta. Candidatos prováveis:

- laço por edição para fontes publicadas um arquivo por ano (MUNIC, Disque 100);
- `retry`/`timeout`/`user-agent` em `mape_baixar()`, se algum portal exigir;
- helper de API no molde de `tools/atualizar_ipca.R`, se houver endpoint.

Tudo em `R/`, com teste em `tests/testthat/`. **A suíte tem hoje 564 expectativas e FAIL 0, em 14
arquivos; ela não pode regredir.** O número era 154, em 6 arquivos, antes da rodada de correção da auditoria e 413 ao fim dela — a primeira das três reverificações de 26/07/2026 o levou a 564, e a
frase seguinte era "26 das 62 funções `mape_*` podem virar `function(...) NULL` sem quebrar nenhum
teste": o achado 26 foi **fechado**, e `Rscript tools/sweep_mutacao.R` sobre as seis funções que
motivaram o achado — `mape_deflacionar`, `mape_marcar_nominal`, `mape_montar_base_larga`,
`mape_paridade`, `mape_esqueleto_painel` e `mape_sha256` — devolve hoje **0 de 6 sobreviventes**.

São **79** funções `mape_*` em `R/`, e o sweep completo custa cerca de vinte segundos por função —
rode-o sobre o que você mexer, não sobre tudo. Isso não transforma a suíte em rede de segurança:
ela cobre o que alguém se lembrou de cobrir, e o sweep mede a suíte, não o código. Escreva o teste
do que você mexer.

## Fase 3 — Extração, uma fonte por vez

Ordem em [`02-bigquery.md`](02-bigquery.md) § 2.4. Para cada fonte:

```r
# 1. dimensionar (custa zero)
mape_query(sql, fonte = "<slug>", so_estimar = TRUE)

# 2. extrair com cache e manifesto
mape_baixar_cache(sql, fonte = "<slug>", arquivo = "bruto.parquet", forcar = TRUE)
```

**`forcar = TRUE` é o que distingue atualizar de reler o cache.** Sem ele, `mape_baixar_cache()`
devolve o arquivo que já está lá e não consulta nada.

Regra de parada: se o dry-run passar do teto, **não suba o teto**. Reduza o escopo — menos colunas,
filtro no servidor, `GROUP BY`. Subir o teto é decisão do responsável, registrada em
`config/parametros.yml`.

## Fase 4 — Tratamento e publicação, fonte por fonte

Para cada fonte extraída: escrever `tratar_<fonte>.R` (se não existir), registrar no dicionário,
publicar, validar.

Aqui a **guarda de escrita** entra em cena, e vai barrar coisa. Releia [§ 1.4](01-arquitetura-da-atualizacao.md).
O caminho quando ela barra:

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")
novo <- mape_consolidar_dimensao("<slug>", publicar = FALSE)   # inspeciona sem gravar
```

Diagnostique antes de autorizar. `permitir_perda = TRUE` sem `motivo_perda` é recusado, e é assim
de propósito.

**Mudança de valor publicado exige reivindicação prévia** em `qa/paridade_esperada.csv`. Uma série
revisada pela origem não é defeito, mas também não é silêncio: é diferença declarada antes de rodar.

## Fase 5 — As dimensões

As 15 dimensões sem produtor só se reconstroem depois que as fontes delas existirem. Duas já têm
alvo no grafo e **falham de propósito** hoje — `dim_09_educacao` e `dim_11_transportes` —, porque a
consolidação das fontes não reproduz a dimensão publicada. Elas são o termômetro: quando o
`tratar_*.R` de ideb, censup, tarifa_zero e tarifas existir, esses dois alvos param de falhar.

Lembre da assimetria que causa isso: `mape_consolidar_dimensao()` junta fontes compactadas e **não
expande o painel**. As dimensões publicadas vieram da migração já expandidas. Reconstruir uma
dimensão significa consolidar **e** expandir, com `mape_expandir_painel()` marcando o que replicou.

Uma armadilha e uma guarda, na expansão: ela quebra em tabela que já tenha coluna `ano`
(`painel.R:70-76`), e `metodo = "replicar"` para com erro quando o mesmo município tem mais de um
ano medido (`painel.R:84-95`) — o produto cartesiano que gerava chave duplicada em silêncio foi
barrado no achado 58.

## Fase 6 — Fechamento

```bash
Rscript tools/recalcular_dicionario.R          # a MONTANTE do grafo, quando o dado muda
Rscript tools/rodar_grafo.R                    # e não tar_make direto: este sai com código 1
Rscript tools/validar_tudo.R
Rscript -e 'testthat::test_dir("tests/testthat")'
Rscript tools/verificar_fechamento.R
git status --porcelain                         # limpo
```

E a comparação contra a fase 0: nenhuma tabela perdeu linha, coluna, chave ou município sem
autorização registrada; toda tabela que ganhou anos ganhou os anos esperados; todo aviso novo de
validação tem justificativa.

**A documentação gerada é regerada, não editada — e não sai toda do mesmo comando.**
`dicionario/README.md`, `dados/dimensao/*.md` e os `README.md` de fonte saem de
`tar_make(documentacao)`; `qa/<slug>.md` sai de `mape_validar_tabela()`, que é o que
`Rscript tools/validar_tudo.R` roda; `qa/paridade_<dim>.md` sai de `mape_paridade()`.

### Regenerar não é acabamento. É onde a rodada passada falhou

Isto vale mais do que parece, e o preço já foi pago. Depois de os treze critérios de fechamento
passarem, a auditoria reverificou os 105 grupos **três vezes**. A primeira derrubou cinco que
estavam dados por corrigidos, e o diagnóstico foi o mesmo em quase todos os 23 parciais:

> **o código era corrigido, o `.md` publicado continuava com o texto velho, e o critério media o
> código.** Um critério que não olha não prova.

Foi por isso que `tools/verificar_fechamento.R` passou de 13 para **18 critérios** — os 13 a 17
nasceram dessas reverificações, e existem porque nenhum dos anteriores olhava o **artefato**. Dois
deles, aliás, nasceram quebrados e passavam sempre.

Para esta rodada, três consequências práticas:

- **O artefato é o que o consumidor lê.** Corrigir o dicionário e esquecer o `.md` gerado deixa a
  correção no lugar errado. Regere e **confira o `git diff` do gerado**, não só o do código.
- **Ao acrescentar critério ao verificador, faça-o falhar de propósito uma vez** antes de confiar
  nele. Um portão que nunca foi visto reprovando não é um portão.
- **`git status --porcelain` limpo é critério, não formalidade.** `validar_tudo.R` reescreve os 26
  `qa/*.md` com carimbo de hora novo — na linha de base a única diferença deve ser essa; qualquer
  outra é dado ou documentação que mudou sem você saber.

## Fase 7 — Release, e só depois de duas decisões

O release v1.0.0 está montado em `dist/v1.0.0/` e **não foi publicado**. Antes de publicar qualquer
release com dado atualizado, duas coisas precisam estar resolvidas, e nenhuma é técnica:

1. **A licença de `13_seguranca`.** O Anuário do FBSP sai, em algumas edições, sob CC BY-NC-ND, e o
   release redistribui como CC BY 4.0. É incompatibilidade, não formalidade.
2. **A série de PIB de `04_economia`.** O fator de bloco é 4× em 1999-2000, 3× em 2001-03, 2× em
   2004-10 e 1× de 2011 em diante, medido por divisibilidade no Parquet publicado; contra a
   origem, que só começa em 2002, a razão é exatamente 3,0000 em 2002-03 e 2,0000 em 2004-10.
   Publicar antes de decidir distribui um defeito crítico conhecido.

## O registro da rodada

Mantenha um ledger, no molde de `auditoria/CORRECOES.csv`: **uma linha por fonte**, com `status`
(`pendente`, `descoberta`, `extraida`, `publicada`, `bloqueada`, `nao-automatizavel`), o que se
mediu antes, o que se mediu depois, o commit e a observação. Um `status = bloqueada` sem observação
é um item que ninguém vai conseguir retomar.

Ao final, um relatório com quatro seções, que é o que a próxima pessoa vai ler primeiro: **o que
mudou no dado publicado**, **o que ficou aberto e por quê**, **o que depende de decisão do
responsável**, e **quanto custou** (bytes escaneados, de `qa/custo_bigquery.csv`).

## Os critérios de aceitação da rodada inteira

| # | critério | como conferir |
|---|---|---|
| 1 | as 26 tabelas continuam validando sem erro | `Rscript tools/validar_tudo.R` |
| 2 | nenhuma perdeu linha, coluna, chave ou município sem autorização | comparação com a fase 0 + `qa/perdas_autorizadas.csv` |
| 3 | a suíte não regrediu (≥ 564 expectativas, FAIL 0) | `test_dir("tests/testthat")` |
| 4 | toda fonte tocada tem manifesto completo e proveniência registrada | `MANIFESTO.yml` + `dicionario/proveniencia.csv` |
| 5 | nenhuma consulta rodou sem dry-run e sem registro de custo | `qa/custo_bigquery.csv` |
| 6 | nenhum ano literal em script de extração | leitura dos `extrair_*.R` |
| 7 | `data_ultima_atualizacao_fonte` preenchido nas 26 linhas | `dicionario/tabelas.csv` |
| 8 | a documentação gerada foi regerada, não editada | `tar_make(documentacao)` + `git diff` |
| 9 | `verificar_fechamento.R` sai com código 0 | o próprio |
| 10 | o ledger não tem `pendente` sem observação | o próprio |
