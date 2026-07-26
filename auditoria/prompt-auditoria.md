# Prompt de auditoria independente do MAPEmunicipios-ETL

Este documento existe para ser **copiado e colado** em outras instâncias do Claude
Code, rodando em paralelo, cada uma com um recorte diferente do repositório.

## Como usar

1. Abra N sessões do Claude Code na raiz do repositório.
2. Em cada uma, cole o **Preâmbulo comum** (seção 1) seguido de **um único
   briefing** (seção 2). Não dê dois briefings ao mesmo agente.
3. Quando todos terminarem, use a seção 3 para consolidar.

Há 13 briefings. Se for rodar só alguns, rode **A13, A3, A1, A4 e A11** — nessa
ordem de prioridade. A13 é o mais barato e já se sabe que rende; A3 cobre a área
de maior risco estrutural (sete fontes que nunca foram extraídas da origem).

Cada agente tem área exclusiva. Não dê o mesmo briefing a dois agentes, e não
deixe um agente "dar uma olhada geral" — a redundância que interessa está na
fase de consolidação, onde os achados são verificados de novo.

---

# 1. Preâmbulo comum

*(cole isto primeiro, em toda instância)*

---

Você é um auditor independente do **MAPEmunicipios-ETL**, um pipeline em R que
publica um painel dos 5.570 municípios brasileiros (1989–2024) em 26 tabelas e
431 variáveis. O repositório está em estado "concluído" e a documentação afirma
que a migração terminou, que a validação passa e que o teste de paridade não
tem diferença inexplicada.

**Sua tarefa é descobrir onde isso não é verdade.**

## A regra de ouro

Este repositório é documentado com uma confiança acima da média: o `README.md`,
o `CLAUDE.md`, os `qa/*.md` e os `README.md` gerados afirmam números específicos
e invariantes fortes. **Trate cada afirmação da documentação como uma hipótese a
testar, nunca como fato estabelecido.** Documentação segura de si é mais
perigosa que documentação omissa, porque desestimula a verificação.

Sempre que a documentação disser "a chave é única", "toda coluna `_pct` está
entre 0 e 100", "a cobertura observada é 2005–2023" ou "zero diferenças não
explicadas — **meça você mesmo no Parquet publicado** e compare. Divergência
entre o que está escrito e o que está no dado é uma das classes de erro que
mais interessa aqui.

## Restrições rígidas — leia antes de rodar qualquer coisa

Esta auditoria é **estritamente somente-leitura sobre os artefatos do projeto**.

**NUNCA execute:**

- `targets::tar_make()` em nenhuma forma. Ele **sobrescreve os Parquet
  publicados** em `dados/` via `mape_escrever_tabela()`. Uma auditoria que
  altera o objeto auditado não é auditoria.
- Nenhum `fontes/*/*/R/extrair_*.R`, nem `mape_query()`, nem `mape_baixar()`,
  nem qualquer função que toque no BigQuery. **Consultas ao BigQuery geram custo
  de faturamento real.** O legado tem consultas que baixam 18,5 milhões de
  linhas.
- Nenhum script de `tools/migracao/`. São scripts de uma vez só, que reescrevem
  `dados/` e `dicionario/`.
- `tools/publicar_release.R`.
- Nenhuma chamada às funções `tratar_*` diretamente (elas escrevem tabela).

**NUNCA escreva** em `dados/`, `dicionario/`, `qa/` (exceto o seu relatório, ver
abaixo), `docs/`, `fontes/`, `dist/`, `_targets/`. Não faça commit, não faça
`git add`, não altere código-fonte. Se quiser propor uma correção, **descreva o
patch no relatório** em vez de aplicá-lo.

**Ao terminar, rode `git status` e confirme que a árvore está limpa** a menos do
seu arquivo de relatório. Se algo mais aparecer modificado, **reporte como achado
e restaure com `git checkout -- <arquivo>`** antes de encerrar.

⚠️ **`mape_validar_tabela()` tem efeito colateral: ela grava em `qa/`.** Já está
confirmado que rodar `testthat::test_dir("tests/testthat")` reescreve
`qa/00_diretorios__municipios.md` (só o carimbo de data muda, mas o arquivo é
versionado e a árvore suja). Antes de chamar qualquer função de validação, **leia
`R/validacao.R` e veja se ela chama `mape_gravar_relatorio_qa()`**, e se há
argumento para desligar a gravação. Se não houver, faça a checagem replicando a
lógica em vez de chamando a função, ou restaure o arquivo depois. Que a suíte de
testes suje um artefato publicado é, por si só, um achado — reporte-o quem for o
agente A6 ou A10, uma vez só.

## Ambiente

R 4.5.2 com `renv` ativo pelo `.Rprofile` — qualquer `Rscript -e '...'` já pega a
biblioteca certa. Todo comando imprime
`The project is out-of-sync — use renv::status()`: **é ruído esperado** (24
pacotes do tidyverse instalados e não usados), ignore.

Carregue a camada de funções assim (é seguro — nenhum arquivo de `R/` tem efeito
colateral no carregamento):

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")
```

Para ler **todas as tabelas publicadas** sem tocar no pipeline:

```r
tabelas <- read.csv("dicionario/tabelas.csv", stringsAsFactors = FALSE, encoding = "UTF-8")

caminho <- function(slug) file.path(
  "dados", if (grepl("/", slug)) "fonte" else "dimensao", paste0(slug, ".parquet")
)

todas <- lapply(setNames(tabelas$slug_tabela, tabelas$slug_tabela), function(s) {
  p <- caminho(s); if (file.exists(p)) arrow::read_parquet(p) else NULL
})
todas <- Filter(Negate(is.null), todas)
```

(Existe também `mape_ler()` e `mape_caminho_tabela()` em `R/consumo.R` e
`R/io.R` — use, mas **confira o que essas funções fazem antes de confiar nelas**:
elas próprias fazem parte do que está sob auditoria. Se `mape_ler()` renomeia ou
filtra alguma coisa, você precisa saber disso antes de tirar conclusão.)

Scripts de análise seus: escreva em um diretório temporário fora do repositório,
ou em `auditoria/` (que você pode criar). Nunca no meio do projeto.

## Mapa mínimo do repositório

```
fonte  →  dimensão  →  base larga
```

- **fonte** (`dados/fonte/<dim>/<nome>.parquet`, 10 tabelas): o dado *como
  observado*, na granularidade nativa. Ex.: AdaptaBrasil é um retrato de 2015,
  logo 5.570 linhas.
- **dimensão** (`dados/dimensao/<NN_slug>.parquet`, 16 tabelas): o painel
  município × ano, com replicação temporal declarada.
- **base larga**: junção das 16 dimensões, 440 colunas, derivada e não
  versionada (`mape_montar_base_larga()`).

`dicionario/*.csv` é **a especificação lida pelo código** (renomeio, tipos,
domínios, geração de documentação), não um subproduto. `config/parametros.yml` é
a única fonte de verdade para constantes.

**Fato estrutural que quase todo mundo erra:** existem 26 tabelas em `dados/`,
mas apenas **14 alvos** no grafo do `targets` (confira com
`targets::tar_manifest()`). Só 3 fontes têm `tratar_*.R`; as outras 23 tabelas
foram produzidas por scripts de migração de uma vez só e **não são reconstruíveis
por `tar_make()`**. Isso significa que a maior parte do dado publicado **nunca
passa pela validação automática do grafo**. Tenha isso em mente o tempo todo.

## Onde os defeitos já conhecidos estão escondidos

Antes de começar, **leia os campos `observacoes` de `dicionario/tabelas.csv` e
`problema` de `dicionario/variaveis.csv`, todos eles.** Não são notas de rodapé:
contêm defeitos graves declarados com todas as letras, inclusive marcados
`DEFEITO NÃO CORRIGIDO`, que **não aparecem no `README.md` nem no `CLAUDE.md`**.

Dois exemplos reais, do campo `observacoes` de `13_seguranca`:

- "a mortalidade do Rio de Janeiro entre 1996 e 1998 está subestimada em cerca de
  97%, porque o SIM codificou os óbitos do município em 30 pseudo-códigos
  sub-municipais que a junção descarta";
- "uma quebra de linha dentro da expressão regular de classificação faz com que
  nenhum óbito com causa X96 seja contado como homicídio".

Ou seja: uma variável de homicídio publicada está sistematicamente errada, e isso
está registrado em uma célula de CSV que ninguém lê. Extraia o **inventário
completo** desses defeitos declarados antes de procurar defeitos novos — você
precisa saber o que já é conhecido para não reportá-lo, e precisa checar se cada
um ainda vale.

## Medições de referência (já feitas — use, não refaça)

As 16 dimensões publicadas, medidas diretamente nos Parquet:

| dimensão | linhas | cols | anos | municípios |
|---|---:|---:|---|---:|
| 01_assistencia_social_dh | 67.406 | 16 | 2011–2023 | 5.570 |
| 02_populacao | 179.930 | 9 | 1991–2023 | 5.570 |
| 03_meio_ambiente | 183.810 | 77 | 1991–2023 | 5.570 |
| 04_economia | 127.786 | 19 | 1999–2021 | 5.570 |
| 05_sociedade | 111.300 | 10 | 1996–2015 | **5.565** |
| 06_financas | 180.023 | 39 | 1989–2024 | 5.570 |
| 07_recursos_humanos | 66.824 | 17 | 2009–2023 | 5.570 |
| 08_energia_internet | 111.288 | 12 | 2004–2024 | 5.570 |
| 09_educacao | 111.388 | 37 | 2005–2024 | 5.570 |
| 10_saude | 149.144 | 65 | 1994–2021 | 5.570 |
| 11_transportes | 183.814 | 7 | 1991–2024 | 5.570 |
| 12_habitacao | 94.832 | 8 | 2007–2024 | 5.570 |
| 13_seguranca | 132.907 | 65 | 1996–2021 | **5.640** |
| 14_corrupcao | 1.516 | 8 | 2006–2018 | 1.352 |
| 15_dados_historicos | 5.646 | 9 | **1872–2010** | **5.592** |
| 16_eleicoes | 133.496 | 36 | 2000–2023 | 5.568 |

O diretório tem exatamente 5.570 códigos únicos em 5.570 linhas.

Quatro anomalias já confirmadas nessa tabela, para você **aprofundar**, não
redescobrir:

1. **`13_seguranca` tem 5.640 códigos — 70 a mais que existem municípios.** Os
   órfãos são códigos de UF preenchidos com zero (`1100000`, `1200000`,
   `1300000`, …), em 352 linhas. `qa/13_seguranca.md` registra isso como
   **aviso**. Mas o campo `observacoes` da mesma tabela afirma que "27 códigos de
   UF disfarçados de município existem na fonte **e não entram nesta tabela**".
   **São 70, não 27, e eles entram.** A justificativa registrada contradiz o
   dado e contradiz o próprio relatório de QA. Investigue: quantas células de
   quais variáveis estão nessas 352 linhas; quem somar a coluna por ano
   dupla-conta estado com município? A escala do erro em uma soma nacional?
2. **`15_dados_historicos` tem 5.592 códigos** (27 órfãos, do tipo `1399902`,
   `2399903` — declarados como municípios extintos) **e anos de 1872 a 2010**,
   fora de `anos_painel: [1989, 2024]`. A tabela é declarada como transversal
   (`granularidade: municipio (transversal, sem ano)`) mas está publicada em
   `dados/dimensao/`. Uma tabela sem ano publicada como dimensão do painel é
   contradição de camada — verifique como ela entra (ou não) na base larga.
3. **`11_transportes` tem 183.814 linhas em 1991–2024.** Um painel retangular de
   34 anos daria 189.380. E 183.810 é exatamente 5.570 × 33 (1991–2023), o
   tamanho de `03_meio_ambiente`. Ou seja: 11_transportes parece ser um painel de
   33 anos **mais 4 linhas soltas de 2024**. Descubra que 4 linhas são essas.
4. **Nenhuma dimensão, exceto `03_meio_ambiente`, é retangular** (5.570 × nº de
   anos). Cada uma falha por uma quantidade diferente. Isso é intencional
   (município-ano sem cobertura é omitido) ou é perda de linha na junção?
   A resposta muda a interpretação de todo `NA` da base.

## Problemas já conhecidos — NÃO reporte como descoberta

Estes estão documentados e são deliberados. Reportá-los como novidade só polui o
relatório. **Você pode, e deve, reportar se descobrir que a descrição deles está
errada, que o escopo é maior do que o declarado, ou que a mitigação não funciona.**

1. `06_financas` tem 222 chaves duplicadas (emendas associadas por nome, sem UF)
   e `15_dados_historicos` tem 54 (Tocantins pré e pós-1988). Mantidas de
   propósito.
2. Coberturas vacinais do SI-PNI acima de 100%, uma chegando a 51.175%.
   Mantidas como a fonte publica, com domínio `[0,100]` declarado.
3. A série nominal foi perdida: oito scripts do legado gravavam o valor
   deflacionado por cima do original. Só sobreviveu um par na Saúde.
4. Seis fontes não migraram (diagnóstico em `pendencias/`).
5. Três licenças pendentes de verificação (IEPS, FBSP, Kustov & Pardelli).
6. A primeira reextração nunca aconteceu; existe um único `extrair_*.R`.
7. Estado declarado da validação: 2 erros e 23 avisos sobre as 26 tabelas.
8. Os defeitos já declarados em `observacoes`/`problema` (RJ 1996–1998
   subestimado em 97%; X96 nunca contado como homicídio; cobertura do FBSP
   limitada a 27 capitais; e os demais que você encontrar no inventário).
   **Não os reporte como novos — mas reporte se o defeito for maior do que o
   texto admite, se a mitigação descrita não existir no código, ou se ele
   deveria estar no `README`/`CLAUDE.md` e não está.** Um defeito conhecido que
   só o dicionário conhece é, na prática, um defeito escondido.

## Padrão de evidência — isto é o que separa auditoria de palpite

Nenhum achado entra no relatório sem:

1. **Afirmação** em uma frase, específica e falsificável.
   ✗ "o tratamento de datas parece frágil"
   ✓ "`09_educacao` tem 4.812 linhas com `ano` fora de `anos_painel`"
2. **Reprodução**: um trecho de R mínimo, colável, que qualquer pessoa roda para
   ver o mesmo.
3. **Saída observada**, colada de verdade. Não parafraseie o que o R imprimiu.
4. **Impacto**: o que quebra, para quem, e em que análise isso apareceria.
5. **Severidade**: `CRÍTICO` (dado publicado está errado ou a chave não fecha) /
   `ALTO` (invariante documentado é falso) / `MÉDIO` (inconsistência interna,
   documentação desmentida pelo dado) / `BAIXO` (higiene, risco futuro).

**Antes de reportar, tente refutar o seu próprio achado.** Pergunte: existe uma
leitura em que isso é intencional? A documentação já explica em algum lugar que
eu não li? Estou comparando a coisa certa (fonte com fonte, dimensão com
dimensão)? Meu código de verificação tem bug? Registre no relatório o que você
tentou para derrubar o achado e por que ele sobreviveu. Achado que você não
tentou refutar não deve ser reportado como confirmado — marque-o `SUSPEITA`.

**Falso positivo custa mais que falso negativo aqui.** O usuário vai consolidar
relatórios de doze agentes; vinte achados sólidos valem mais que duzentos
plausíveis. Ao mesmo tempo: **não invente achados para parecer produtivo.** Se a
sua área está sólida, escreva "verifiquei X, Y e Z; nada encontrado" e liste o
que você verificou. Um relatório vazio e honesto é um resultado válido e útil.

## Formato do relatório

Grave em `auditoria/<seu-codigo>.md` (ex.: `auditoria/A3.md`) e **também**
apresente o conteúdo na resposta final. Estrutura:

```markdown
# <Código> — <Título do briefing>

## Resumo
<3 a 6 linhas: o que foi verificado, quantos achados, o mais grave>

## Cobertura
| verifiquei | como | resultado |
|---|---|---|
<uma linha por checagem, INCLUSIVE as que não acharam nada>

## Achados

### <CÓDIGO>-01 · <SEVERIDADE> · <título curto>
**Afirmação:**
**Reprodução:**
```r
```
**Saída observada:**
```
```
**Impacto:**
**Tentativa de refutação:**
**Correção sugerida:** <descreva o patch, não aplique>

## Não verificado
<o que ficou de fora do seu escopo e por quê — outro agente pode pegar>
```

Fim do preâmbulo.

---

# 2. Briefings

## A1 — Contrato de nomes, sufixos e domínios

**Você audita:** se o vocabulário de nomes e os domínios prometidos valem para
as 431 variáveis publicadas, empiricamente, coluna por coluna.

O contrato declarado (`CLAUDE.md`, `README.md`, `plano/01-modelo-e-convencoes.md`):

- Sufixo obrigatório, de vocabulário fechado: `_i`, `_pct`, `_prop`, `_razao`,
  `_p100k`, `_p1k`, `_p100dom`, `_brl_nominal`, `_brl2023`, `_km`, `_km2`,
  `_idx`, `_cat`; prefixos `flag_` e `ano_ref_`.
- Tudo em snake_case ASCII.
- `ano` só existe como chave do painel; qualquer outro ano é `ano_ref_*`.
- `00_diretorios/municipios` é dono exclusivo do bloco territorial: **nenhuma
  outra tabela publica `nome_municipio` ou `sigla_uf`**.
- Prefixo de fonte obrigatório quando duas fontes medem o mesmo conceito
  (`pni_` × `ieps_`, `sim_` × `fbsp_`).

A tese do projeto é que o sufixo **permite provar** a faixa de valores. Teste a
prova, sobre todas as 26 tabelas:

- Toda `_pct` está em [0, 100]? Toda `_prop` em [0, 1]? Há `_prop` que na verdade
  guarda percentual (máximo > 1 e ≤ 100 sugere isso), ou `_pct` guardando
  proporção (máximo ≤ 1 sugere isso)?
- Toda `_i` é contagem: inteira, não negativa, sem valor fracionário disfarçado
  de `double`?
- Toda `flag_` só tem 0, 1 e `NA`? Alguma tem 2, -1, `TRUE`/`FALSE` como texto,
  ou `"sim"`/`"não"`?
- Toda `_p100k` / `_p1k` / `_p100dom` é não negativa e finita? Há `Inf` de
  divisão por zero?
- `_km` e `_km2` não negativas? `_idx` dentro da faixa que o dicionário declara?
- `_cat` é categórica de fato, ou é numérica com rótulo?
- `_brl2023` e `_brl_nominal`: existe alguma coluna de dinheiro **sem** sufixo
  monetário? Existe `_brl2023` cuja irmã `_brl_nominal` não existe (a
  documentação diz que só sobrou um par, na Saúde — confirme que os outros
  `_brl2023` estão declarados corretamente e não são nominais rotulados como
  deflacionados)?

Depois, o vocabulário em si:

- Liste toda coluna publicada cujo nome **não** termina em sufixo do vocabulário
  nem começa com `flag_`/`ano_ref_` nem é chave. Quantas são? Estão justificadas?
- Alguma coluna com acento, maiúscula, hífen, ponto ou espaço no nome?
- Colisão de nome entre dimensões diferentes que significam coisas diferentes
  (isso vira colisão na base larga de 440 colunas).
- Duas fontes medindo o mesmo conceito **sem** o prefixo de fonte exigido —
  procure pares suspeitos além dos dois documentados (população? PIB? cobertura?).
- Colunas com nome quase idêntico dentro da mesma tabela
  (`x_medio_idx` × `x_media_idx`), que sugerem erro de harmonização.

**Pista concreta:** a harmonização mexeu em 239 nomes
(`tools/migracao/harmonizar_nomes.R`, `harmonizar_sufixos.R`,
`nomes_propostos.csv`, `mapa_renomeio_posicional.csv`). Renomeio **posicional** é
exatamente o mecanismo frágil que o projeto acusa o legado de usar. Leia
`mapa_renomeio_posicional.csv` e verifique se algum renomeio trocou o significado
de uma coluna — isto é, se a coluna N da tabela antiga realmente é a coluna N da
nova. Se houver um só caso de troca, o dado publicado está errado com nome
convincente, que é a pior classe de erro possível.

---

## A2 — Chaves, integridade referencial e cardinalidade

**Você audita:** se a chave `id_municipio` + `ano` fecha em todas as tabelas, e
se as junções não perderam nem multiplicaram linha.

- `id_municipio` é `character` de 7 dígitos em **todas** as tabelas? Alguma
  virou numérico em algum ponto (o que apagaria o zero à esquerda de AC, AL e
  AM)? Procure valores com 6 caracteres, com espaço à esquerda (a armadilha do
  `formatC(flag="0")`), com `NA`, com texto não numérico.
- Toda `id_municipio` publicada existe em `00_diretorios/municipios`? Quantas
  órfãs por tabela? O parâmetro `qa: max_prop_chave_orfa: 0.01` é de fato
  aplicado, ou só declarado?
- O diretório tem exatamente 5.570 linhas e 5.570 códigos distintos?
  `id_municipio_6` é único? A conversão 6→7 (`mape_id7_de_id6()`) é 1-para-1,
  ou existe `id_municipio_6` que casa com mais de um de 7 dígitos (o que
  multiplicaria linhas silenciosamente em qualquer `left_join`)?
- Duplicidade de chave por tabela: confirme os dois casos conhecidos (222 em
  `06_financas`, 54 em `15_dados_historicos`) **e procure outros**. As contagens
  batem exatamente?
- `ano` é `integer` em todas? Sobrou algum `integer64` (a armadilha silenciosa:
  `as.numeric()` devolve `9.83e-321`, `sort()` e `range()` devolvem lixo sem
  erro)? Verifique com `class()` e `typeof()`, não com `is.numeric()`.
- Cada dimensão tem exatamente 5.570 × (nº de anos) linhas? Onde não tiver,
  qual é a explicação? O `README` cita `183.814` para `11_transportes` e o
  `CLAUDE.md` cita `183.810` para `03_meio_ambiente` — **os dois números são
  diferentes e ambos deveriam ser 5.570 × nº de anos**. Meça e explique a
  diferença; se as dimensões não têm todas o mesmo tamanho, o "painel" não é
  retangular e isso precisa estar documentado.
- Anos fora de `anos_painel: [1989, 2024]` em qualquer tabela?
- `16_eleicoes` só tem os `anos_eleicao` declarados
  (`[2000, 2004, 2008, 2012, 2016, 2020]`)? Se tiver 2024, o parâmetro está
  desatualizado; se não tiver, a série está incompleta.
- **Parquet × csv.gz**: as duas exportações de cada tabela têm o mesmo número de
  linhas, colunas e valores? Ao ler o `.csv.gz` com `read.csv()` padrão,
  `id_municipio` sobrevive como texto ou vira número e perde o zero? Se perde, a
  exportação pública tem armadilha embutida — verifique se está documentado.

---

## A3 — Painel: expansão temporal, `carry_forward` e compactação

**Você audita:** a decisão central do projeto — a separação fonte × dimensão — e
se a ida e a volta entre elas preservam o dado.

Esta é a área de maior risco do repositório, por um motivo específico: **sete das
dez tabelas de fonte não foram extraídas da origem, e sim recortadas de dentro
das dimensões já expandidas**, por `tools/migracao/fatiar_fontes.R`, usando
`mape_compactar_painel()`. Compactar um painel expandido é uma operação com
perda quando a premissa da compactação é falsa.

As sete: `03_meio_ambiente/adaptabrasil`, `05_sociedade/atlas_ivs`,
`09_educacao/censup`, `09_educacao/ideb`, `11_transportes/tarifa_zero`,
`11_transportes/tarifas`, `12_habitacao/mcmv_fgts`.

Verifique, para cada uma:

- Leia `tools/migracao/fatiar_fontes.R` e anote o `metodo` de compactação e a
  expressão regular de seleção de colunas de cada bloco.
- O `metodo = "constante"` supõe que o valor **não varia** ao longo dos anos
  dentro do município. **Isso é verdade no dado?** Meça: para cada bloco
  compactado como constante, quantos municípios têm mais de um valor distinto
  ao longo dos anos? Se algum tiver, a compactação escolheu um e descartou os
  outros — e a fonte "canônica" está errada.
- A regex de seleção de colunas pega exatamente as colunas do bloco? Sobra
  alguma coluna da dimensão que deveria ter ido para a fonte, ou foi levada
  alguma que não pertence ao bloco? Compare os nomes de coluna da fonte com os
  da dimensão de origem.
- O caminho de volta fecha: expandir a fonte com a regra declarada
  (`mape_expandir_painel()`, coluna `Regra de preenchimento temporal` na
  documentação gerada) reproduz **exatamente** o bloco correspondente da
  dimensão? Onde não reproduzir, quantas células divergem e em que direção?
- A cobertura temporal declarada bate com a observada? Ex.: o `README` gerado do
  IDEB diz cobertura 2005–2023 e 55.694 linhas, e afirma que o legado
  propagava para o ano par seguinte gerando 111.388 linhas. Confirme os três
  números no dado.
- `03_meio_ambiente/adaptabrasil` é um retrato de 2015 com 5.570 linhas, mas o
  `CLAUDE.md` diz que na dimensão ele aparece repetido **de 2010 a 2020**.
  Por que 2010–2020 e não o painel inteiro? Onde essa janela está declarada?
  Ela está no dado?
- `carry_forward`: alguma série é arrastada para frente indefinidamente,
  inclusive para anos posteriores ao fim da fonte, sem `flag_` ou `ano_ref_`
  que avise? Um valor de 2015 aparecendo como se fosse de 2024 sem marcação é
  erro grave de interpretação para quem consome.
- Preenchimento com **zero** × preenchimento com `NA`: o `README` diz que a
  adesão à tarifa zero foi "preenchida com zero em todo município-ano que a
  fonte não cobre". Zero e ausência são coisas diferentes. Quantas colunas do
  painel fazem isso? Está declarado no dicionário? Um zero inventado entra em
  média e em regressão como se fosse medição.

---

## A4 — O dicionário contra o dado publicado

**Você audita:** se a especificação descreve o que existe, e se o que existe está
descrito. O projeto afirma que o dicionário é lido pelo código e que os campos
calculados são remedidos a cada execução — a tese é que a documentação **não
pode** desatualizar. Teste a tese.

- Toda coluna presente em algum Parquet publicado tem linha em
  `dicionario/variaveis.csv`? Liste as órfãs.
- Toda linha de `variaveis.csv` corresponde a uma coluna que existe de fato?
  Liste as fantasmas.
- A contagem fecha em 431? E as 26 tabelas de `tabelas.csv` correspondem
  exatamente aos 26 arquivos em `dados/`? E os 17 slugs de `dimensoes.csv`?
- Campo `tipo` declarado × tipo real da coluna no Parquet: quantas divergências?
  (`integer` declarado e `double` real é divergência: significa que a coluna
  aceita fracionário.)
- Campos **calculados** (`tipo_real`, `pct_na`, `n_distintos`, `minimo`,
  `maximo`, `n_infinito`): recalcule você mesmo a partir dos Parquet e compare
  com o que está gravado no CSV. **Divergência aqui é achado de severidade alta**,
  porque significa que `mape_recalcular_campos()` não rodou depois da última
  alteração do dado, e a promessa central do desenho falhou. Foi exatamente
  nesses campos que os números do dicionário antigo não fechavam (533 × 451).
- Domínio declarado × valores observados: para toda variável com domínio, quantas
  células violam? Quantas dessas violações têm justificativa registrada em
  `problema`/`observacoes`?
- `pct_na` de 100% em alguma variável — coluna publicada inteiramente vazia?
- Descrições vazias ou reaproveitadas: quantas variáveis têm `descricao` em
  branco, ou com o mesmo texto de outra variável de sentido diferente? (O
  dicionário antigo tinha 51 descrições vazias — confirme que não voltaram.)
- `dicionario/deprecacao.csv` (416 linhas): todo nome **novo** listado existe
  hoje? Todo nome **antigo** de fato sumiu? Há nome renomeado em algum
  `tools/migracao/*.csv` que nunca chegou ao `deprecacao.csv`? Há entrada
  circular ou cadeia (A→B, B→C) que `mape_derivadas()` não resolveria?
- `unidade` e `escala`: alguma variável com unidade incompatível com o sufixo do
  nome (`_pct` com unidade "proporção", `_brl2023` com unidade "milhares")?

---

## A5 — Revisão de código da camada `R/`

**Você audita:** os 16 arquivos de `R/`, procurando bug de lógica. Leia o código
de verdade, não só as assinaturas. Não confie no comentário do cabeçalho: ele
descreve a intenção, e o bug mora na diferença entre intenção e implementação.

Prioridade, por risco:

1. **`R/chaves.R`** — `mape_como_codigo()` preenche zero à mão porque
   `formatC(flag="0")` sobre texto preenche com espaço. A implementação manual
   está certa para todos os casos: entrada com 5, 6, 7, 8 dígitos, com `NA`, com
   string vazia, com espaço, com número em notação científica, com `integer64`?
   `mape_normalizar_chaves()` converte `integer64`→`integer` sempre, inclusive
   quando a coluna vem aninhada ou com outro nome?
2. **`R/joins.R`** — `mape_join()` declara cardinalidade. A verificação
   realmente **falha** quando a cardinalidade é violada, ou só avisa? Um
   `left_join` many-to-many que multiplica linhas passa despercebido?
3. **`R/sentinelas.R`** — a lista de sentinelas inclui `""`, `"-"`, `"--"`,
   `"NA"`, `"N/A"`. Aplicar isso indiscriminadamente destrói dado legítimo: um
   município cujo nome ou cuja categoria contenha `"-"`, uma coluna de texto em
   que `""` significa "vazio declarado". `mape_tratar_sentinelas()` é aplicada
   por coluna, com controle, ou em bloco? Ela toca em coluna de chave? Os
   sentinelas numéricos (`-999`, `-9999`, `-99999`) podem ser valor legítimo em
   alguma variável (uma diferença, um saldo, uma altitude)?
4. **`R/dimensao.R`** — `mape_montar_base_larga()`: como resolve colisão de nome
   entre dimensões? `deduplicar = TRUE` escolhe **qual** linha das duplicadas —
   a primeira? a de maior valor? A escolha é determinística e registrada, ou
   depende da ordem de leitura? `mape_consolidar_dimensao()` usa `full_join` ou
   `left_join` sobre o esqueleto — e o que acontece com município-ano que existe
   na fonte e não no esqueleto?
5. **`R/deflacao.R`** — `mape_deflacionar()` usa `deflator_base: "12/2023"`. A
   série de IPCA vem de onde, e está fixada? Se ela for baixada em tempo de
   execução, o resultado **não é reprodutível** e duas execuções em meses
   diferentes produzem valores diferentes com o mesmo nome de coluna. Isso seria
   crítico.
6. **`R/io.R`** — `mape_escrever_tabela()` grava Parquet e csv.gz. A escrita do
   csv.gz preserva o tipo de `id_municipio`? Há `write.csv` sem `row.names =
   FALSE`? A escrita é atômica, ou uma falha no meio deixa arquivo truncado
   publicado?
7. **`R/painel.R`** — `mape_esqueleto_painel()` lê `anos_painel` do YAML ou tem
   literal? `mape_expandir_painel()` e `mape_compactar_painel()` são inversas?
8. **`R/consumo.R`** (23 KB, o maior) — é a interface que o pacote público
   espelha. `mape_ler()` com `territorio = TRUE` faz join com o diretório: pode
   multiplicar linha? `mape_cobertura()` mede o quê exatamente — linha não nula
   ou linha existente? `mape_derivadas()` calcula indicador com denominador:
   trata denominador zero, denominador `NA`, e anos em que numerador e
   denominador vêm de fontes com cobertura diferente?

Transversal, em tudo: uso de `==` com `NA`; `sum()`/`mean()` sem `na.rm`
declarado (ou **com** `na.rm = TRUE` onde isso mascara ausência e vira zero);
`ifelse()` que perde atributo; `as.numeric()` sobre `factor`; `match.arg()`
ausente; `subset()`/`with()` em código de biblioteca; leitura de CSV sem
`colClasses` que adivinha tipo errado; `stringsAsFactors`; comparação de ponto
flutuante com `==`; recorte por posição de coluna em vez de por nome.

E procure **constantes literais que deveriam vir de `config/parametros.yml`**:
`grep` por `1991`, `2023`, `2024`, `5570`, `1989` no código. O projeto acusa o
legado de espalhar `1991:2023` por cinco scripts. Confirme que não repetiu o erro.

---

## A6 — A validação: o guardião funciona?

**Você audita:** `mape_validar_tabela()` e as doze checagens de qualidade. Uma
validação que passa por não verificar nada é pior que nenhuma validação, porque
produz confiança.

- Leia `R/validacao.R` e liste as doze checagens, uma a uma, com o que cada uma
  **de fato** testa. Alguma passa vazia — por exemplo, itera sobre uma lista que
  pode estar vazia, ou só verifica quando o campo do dicionário está preenchido
  (e portanto nunca falha quando o campo está em branco)?
- A regra declarada é: **erro impede publicação; aviso exige justificativa
  registrada em `observacoes` (tabela) ou `problema` (variável); aviso sem
  justificativa vira erro.** Essa última cláusula está **implementada em
  código**, ou só escrita no `README`? Encontre a linha que a implementa. Se não
  existir, é achado alto: é o mecanismo que impede aviso de virar paisagem.
- Qual é o efeito prático de um "erro"? `mape_escrever_tabela()` recusa gravar,
  ou apenas registra no relatório e grava assim mesmo? Rastreie o caminho.
- **Rode a validação sobre as 26 tabelas publicadas** (só `mape_validar_tabela()`
  sobre tabelas já lidas — isso não escreve nada; confirme lendo a função
  antes) e compare com o estado declarado de **2 erros e 23 avisos**. Bate? Se
  não bate, os `qa/*.md` estão velhos e o número que a documentação anuncia é
  histórico.
- Compare a data de modificação dos `qa/*.md` com a dos Parquet correspondentes.
  Relatório mais antigo que o dado é relatório sobre outro dado.
- As 23 tabelas fora do grafo do `targets` **nunca são validadas
  automaticamente**. Quantos dos avisos/erros atuais estão nelas? Elas foram
  validadas alguma vez, ou o `qa/*.md` delas foi gerado por script de migração?
- `max_prop_chave_orfa: 0.01` e `tolerancia_paridade: 1.0e-9`: os dois parâmetros
  são realmente lidos por alguma função, ou estão órfãos no YAML? `grep` por
  cada chave do `parametros.yml` no código — parâmetro declarado e não usado é
  falsa sensação de configurabilidade.
- `max_mb_versionavel: 20` × o hook de `pre-commit` (que tem `LIMIAR_MB=20`
  **hard-coded**): dois lugares com o mesmo número é o padrão que o projeto diz
  combater. Confirme e reporte.

---

## A7 — Auditar o auditor: o teste de paridade

**Você audita:** `mape_paridade()` e `qa/paridade_esperada.csv`. O projeto
sustenta boa parte da sua credibilidade neste teste ("zero diferenças não
explicadas"). O mecanismo declarado — reivindicar as diferenças **antes** de
rodar — é bom em princípio. A pergunta é se a execução honra o princípio.

- Leia `R/migracao_legado.R`, função `mape_paridade()`. O que ela compara de
  fato: número de linhas? nomes de coluna? **valores célula a célula**? Se a
  comparação for de forma e não de conteúdo, "zero diferenças" significa muito
  menos do que parece.
- Como as chaves são alinhadas antes de comparar? Se o alinhamento for
  posicional em vez de por `id_municipio` + `ano`, o teste é inválido — e seria
  ironicamente o mesmo defeito que o projeto denuncia no dicionário antigo.
- Colunas que existem só de um lado: entram como diferença, ou são ignoradas em
  silêncio? Uma coluna que sumiu na migração e é ignorada é exatamente o erro
  que o teste deveria pegar.
- `NA` × `NA` conta como igual? `NA` × `0`? A tolerância `1e-9` é relativa ou
  absoluta, e o que ela faz com valores muito grandes (receita municipal em
  reais) e com zero?
- **Audite `qa/paridade_esperada.csv` linha por linha.** Cada reivindicação é
  específica (esta coluna, esta razão) ou é ampla o bastante para absorver
  qualquer diferença (um curinga, uma dimensão inteira, uma regex frouxa)? Uma
  única linha permissiva demais anula o teste.
- Quantas células/colunas do total ficam cobertas por reivindicação? Se for uma
  fração grande, "zero diferenças não explicadas" quer dizer "quase tudo foi
  explicado de antemão".
- **Existem 15 arquivos `qa/paridade_*.md`, para 16 dimensões. Falta
  `paridade_15_dados_historicos.md`.** Confirme, e descubra por quê: a dimensão
  não foi testada? falhou e o relatório não foi gravado? não existe no legado?
  Uma dimensão sem paridade é uma dimensão sem verificação de migração.
- A referência (`qa/referencia/base_municipios_brasileiros.RDa`) está presente
  na máquina? Se não estiver, **nenhuma conclusão de paridade pode ser
  verificada agora** — diga isso explicitamente no relatório em vez de assumir
  que passou. Se estiver, rode a paridade e compare com os `.md` gravados.
- Ressalva declarada: o teste é conclusivo *para a migração* porque o dado de
  entrada estava congelado. Verifique se algum `qa/paridade_*.md` afirma mais do
  que isso.

---

## A8 — Grafo do `targets`, reprodutibilidade e o que não é reconstruível

**Você audita:** se o pipeline reproduz o que publica.

- Rode `targets::tar_manifest()` e `targets::tar_outdated()` (nenhum dos dois
  executa alvo — confirme antes). Liste os alvos existentes e compare com as 26
  tabelas em `dados/`.
- Para cada uma das 23 tabelas **sem alvo**: existe algum caminho documentado
  para reconstruí-la? Qual script a produziu? Esse script ainda roda hoje, ou
  depende da árvore legada removida em 26/07/2026? Se nenhum caminho existir,
  **o dado publicado é irreprodutível** — descreva exatamente quais tabelas e o
  que se perde se um Parquet for corrompido.
- `_targets/meta/`: o cache diz que os alvos estão atualizados? A data dos
  objetos em cache é compatível com a dos Parquet em `dados/`? Cache que diz
  "atualizado" sobre um arquivo que mudou por fora é confiança falsa.
- `error = "abridge"` em `_targets.R`: um alvo que falha não derruba os ramos
  independentes. Isso significa que **`tar_make()` pode terminar com falhas e
  parecer sucesso**. Como o usuário descobre que um alvo falhou? Existe
  verificação depois do build?
- `fonte_00_diretorios_municipios` está no grafo, mas a pasta
  `fontes/00_diretorios/municipios/` **não tem `MANIFESTO.yml` nem `raw/`** —
  ao contrário de `cadunico` e `disque100`, que têm os dois. Leia
  `tratar_municipios.R`: de onde ele lê? Se ele lê de `dados/` (a própria saída)
  ou do BigQuery, o alvo tem dependência circular ou custo. Se ele depende de um
  `raw/` ausente, **rodar `tar_make()` hoje quebraria ou apagaria a espinha
  dorsal do projeto**. Não teste executando: leia o código e trace.
- A regra "só entra dimensão com ≥ 2 fontes publicadas" faz `dim_*` existir só
  para 01, 09 e 11. As outras 13 dimensões estão publicadas sem alvo. Isso é
  intencional e documentado, ou é efeito colateral não percebido da regra?
- O `README.md` (§ "Um ano novo numa fonte que já existe") ensina
  `tar_make(fonte_04_economia_ibge_pib)` e `tar_make(dim_04_economia)` —
  **nenhum dos dois existe**. Verifique se há outros comandos, em qualquer `.md`
  do repositório, que falhariam se alguém os copiasse. Documentação de
  manutenção que não roda é dívida operacional, não erro de digitação.
- `renv.lock` fixa 128 pacotes, mas 24 estão instalados e não usados. Algum
  pacote **usado** pelo código está fora do lockfile (o que quebraria um
  `renv::restore()` em máquina limpa)? Cheque os `library()`/`::` de todo o
  código contra o lockfile.

---

## A9 — Documentação gerada × medição de hoje

**Você audita:** se os números que a documentação publica correspondem ao dado
que está no disco agora. O projeto se define contra o legado justamente aqui: a
documentação antiga somava 533 variáveis onde havia 451.

Arquivos gerados a conferir: `dicionario/README.md`, `dados/dimensao/*.md`,
`fontes/*/*/README.md`, `qa/*.md`, `dist/v1.0.0/INVENTARIO.csv`,
`dist/v1.0.0/manifesto.json`, `dist/v1.0.0/NOTA-DO-RELEASE.md`.

- Para cada `.md` gerado: extraia os números afirmados (linhas, colunas,
  municípios distintos, cobertura observada, % de células vazias, % de vazios por
  variável) e **recalcule cada um** a partir do Parquet. Monte uma tabela
  divergência a divergência.
- As somas fecham? O total de variáveis do `dicionario/README.md` bate com a
  soma por tabela e com as linhas de `variaveis.csv`? O total de tabelas bate?
- Datas de geração ("_Gerado em ... por `mape_gerar_documentacao()`_") são
  posteriores à última modificação do Parquet correspondente? Onde não forem, a
  documentação descreve um dado que já mudou.
- **`dist/v1.0.0/`**: verifique `SHA256SUMS.txt` contra os arquivos de fato
  (`sha256sum -c` ou `digest`). O `INVENTARIO.csv` bate com o conteúdo? O
  conjunto de tabelas em `dist/` é o mesmo de `dados/`, e os arquivos são
  idênticos, ou o release foi montado antes da última alteração? Publicar um
  release que não corresponde ao repositório é erro que sai de casa.
- `dist/` contém o dicionário, de propósito, para o pacote público ler tipo e
  domínio. O dicionário em `dist/` é igual ao de `dicionario/`?
- Os números citados a mão em `README.md`, `CLAUDE.md` e `docs/*.md` (5.570 /
  1989–2024 / 17 eixos / 26 tabelas / 431 variáveis / 440 colunas / 183.810 /
  183.814 / 154 testes / 128 pacotes / 55.694 / 16 dimensões): confira cada um.
  Liste os que não fecham. Preste atenção especial a **440 colunas na base
  larga** — some as colunas das 16 dimensões, descontando as chaves repetidas, e
  veja se dá 440.

---

## A10 — Cobertura de teste e o que o teste não pega

**Você audita:** a suíte de 154 expectativas em 74 blocos `test_that`, 6
arquivos. Sua pergunta não é "os testes passam" (passam), e sim **"o que eles
deixariam passar"**.

- Monte o mapa: liste as ~60 funções `mape_*` de `R/` e marque quais têm teste
  direto, quais têm teste indireto e quais têm zero. Aponte as não testadas de
  maior risco.
- `tests/testthat/setup.R` monta um diretório sintético de **4 municípios**.
  Quanto da suíte roda sobre dado sintético e quanto sobre as tabelas
  publicadas? Teste que só vê dado sintético não pega erro no dado real — e é
  exatamente o dado real que o projeto publica.
- Para cada armadilha documentada, existe teste de regressão que falharia se ela
  voltasse?
  - `formatC(flag="0")` preenchendo com espaço
  - `integer64` em `ano`
  - deflacionado gravado por cima do nominal
  - código de 6 dígitos casando com mais de um de 7
  - `_pct` fora de [0,100]
  - `mape_montar_base_larga()` se recusando a rodar com chave duplicada e
    **nomeando a dimensão responsável**
  Onde não existir, escreva o teste que existiria (código completo, para o
  usuário colar) — sem adicioná-lo ao repositório.
- Há teste que passa vacuamente: `expect_true(TRUE)`, `expect_silent()` sobre
  função que nunca fala, `skip()` incondicional, `expect_error()` que captura o
  erro errado (erro de digitação em vez do erro de validação)?
- Os testes dependem de arquivo de `dados/` existir? Se sim, a suíte falharia em
  clone limpo — e o `README` promete `test_dir` logo após o `restore()`.
- Nenhum teste cobre `mape_paridade()` nem a geração de documentação sobre dado
  real. Confirme e dimensione o risco.

---

## A11 — Plausibilidade estatística e contradição entre fontes

**Você audita:** o dado como dado — não o esquema, e sim se os valores fazem
sentido no mundo. Erro de ETL costuma sobreviver a toda validação de tipo e
domínio e morrer na primeira olhada em uma distribuição.

Trabalhe sobre as 26 tabelas publicadas, com estatística descritiva:

- **Descontinuidades no tempo.** Para cada variável numérica, a série municipal
  dá salto implausível entre anos consecutivos (população caindo 90%, PIB
  multiplicando por mil, receita mudando de ordem de grandeza)? Salto que
  acontece **no mesmo ano para muitos municípios de uma vez** é assinatura de
  troca de fonte, mudança de unidade ou erro de junção — não de fenômeno real.
- **Degrau de unidade.** Variável monetária que muda de escala no meio da série
  (mil reais → reais) aparece como salto de 1000×. Procure.
- **Repetição suspeita.** Variável com o mesmo valor repetido por muitos anos
  para todos os municípios: é `carry_forward` legítimo e declarado, ou expansão
  não documentada? Meça, por variável, quantos anos distintos de valor realmente
  existem por município.
- **Valores impossíveis** dentro do sentido da variável: população zero ou
  negativa; área zero; taxa por 100 mil com denominador menor que o numerador;
  percentual de eleitorado acima da população; tarifa negativa; nº de
  instituições fracionário.
- **Contradição entre fontes que medem o mesmo conceito.** Os pares existem de
  propósito: `pni_*` × `ieps_*` na cobertura vacinal, `sim_*` × `fbsp_*` na
  morte violenta. Correlacione. Se a correlação for baixa ou o sinal divergir,
  isso é achado relevante para quem for usar qualquer uma das duas — e deveria
  estar documentado.
- **Coerência com agregado nacional conhecido.** Some por ano e compare com
  ordem de grandeza pública: população ~203 milhões em 2022; PIB nacional; total
  de homicídios ~40–50 mil/ano. Não precisa bater na casa decimal; precisa bater
  na ordem de grandeza. Divergência de 10× é erro de unidade ou de agregação.
- **Padrão de ausência.** `NA` concentrado em uma UF, em uma faixa de população
  ou em municípios criados depois de certo ano é assinatura de falha de junção,
  não de ausência da fonte. Cruze `pct_na` com UF e com porte municipal.
- **Zeros que deveriam ser `NA`.** Variável com massa anormal exatamente em zero
  (ver A3: preenchimento com zero onde a fonte não cobre). Quantifique: quantos
  zeros por variável, e qual a fração deles que corresponde a município-ano sem
  cobertura da fonte.
- **Municípios sistematicamente ausentes.** Existe município que aparece em
  poucas tabelas? Municípios criados depois de 1989 (Brasília? distritos
  emancipados nos anos 90 e 2000?) têm dado antes de existirem?

Priorize as dimensões de maior uso analítico: `02_populacao`, `04_economia`,
`06_financas`, `10_saude`, `13_seguranca`, `16_eleicoes`.

---

## A12 — Proveniência, licença e vazamento

**Você audita:** se dá para saber de onde veio cada dado, e se algo que não
deveria estar no repositório público está.

- `MANIFESTO.yml`: só `cadunico` e `disque100` têm. As outras oito fontes não
  têm proveniência versionada — o `README` afirma que "a procedência fica num
  `MANIFESTO.yml` versionado ao lado do script, com URL, versão, data e
  `sha256`". Isso vale para 2 de 10. Dimensione: para quantas tabelas publicadas
  é impossível dizer, hoje, de qual arquivo de origem elas vieram?
- Os `sha256` dos manifestos existentes conferem com os arquivos em `raw/`?
  (`mape_sha256()`, `mape_verificar_raw()`.)
- Campo `licenca` em `tabelas.csv`: quantas estão como "a verificar"? A
  documentação cita três (IEPS, FBSP, Kustov & Pardelli). Confirme o número real.
  Alguma tabela publicada sob licença incompatível com o CC BY 4.0 declarado no
  `README`?
- Alguma tabela de fonte que não é redistribuível está com o Parquet **versionado
  no git**? Isso é diferente de estar em `raw/` (ignorado).
- **Vazamento**: o repositório é público. Procure na árvore e no **histórico do
  git** (`git log -p -S`, `git grep` em todas as revisões) por: identificador de
  projeto GCP, `set_billing_id` com valor literal, chave de API, caminho absoluto
  com nome de usuário, e-mail pessoal, conteúdo de `.Renviron`. O `.Renviron`
  existe na máquina e está no `.gitignore` — confirme que **nunca** foi commitado.
- `.gitignore` cobre `**/raw/`, `dados/derivado/`, `dist/`, `qa/referencia/`,
  `renv/library/`. Há arquivo grande ou dado bruto que escapou e está versionado?
  Liste os 20 maiores arquivos rastreados pelo git e confirme que todos estão
  abaixo dos 20 MB declarados.
- O hook de `pre-commit` está instalado nesta cópia (`.git/hooks/pre-commit`)?
  Ele bloqueia o que promete? Leia; **não teste fazendo commit**.

---

## A13 — O inventário dos defeitos já declarados

**Você audita:** a distância entre o que o projeto **sabe** que está errado e o
que ele **conta** que está errado. Este briefing é barato e tem rendimento alto.

O campo `observacoes` de `dicionario/tabelas.csv` e o campo `problema` de
`dicionario/variaveis.csv` contêm defeitos graves escritos com todas as letras,
alguns marcados `DEFEITO NÃO CORRIGIDO`, que não aparecem em nenhum documento de
alto nível. Exemplo já confirmado: a mortalidade do Rio de Janeiro entre 1996 e
1998 está subestimada em ~97% em `13_seguranca`, e nenhum óbito com causa X96 é
contado como homicídio, por causa de uma quebra de linha dentro de uma expressão
regular.

Faça o seguinte:

1. **Extraia o inventário completo.** Percorra as 26 linhas de `observacoes` e as
   431 de `problema`; produza uma tabela: tabela/variável, texto do defeito,
   gravidade que o texto sugere, e se ele está marcado como corrigido, não
   corrigido ou ambíguo.
2. **Para cada defeito, verifique se ainda vale**, medindo no Parquet publicado.
   Textos herdados da migração podem descrever um problema já resolvido — ou
   subestimar um que piorou.
3. **Dimensione o que os textos não dimensionam.** "Subestimada em cerca de 97%"
   se refere a quantas linhas e a quais variáveis? Quem usa
   `sim_obitos_homicidio_i` do Rio nesses anos recebe que número, e qual seria o
   correto? O defeito do X96 afeta quantos óbitos no total, em quantos
   municípios, em quais anos?
4. **Confronte com os documentos de alto nível.** O `README.md` (§ "O que ainda
   está aberto") e o `CLAUDE.md` listam quatro pendências. Quantos defeitos do
   seu inventário deveriam estar nessa lista e não estão? Um defeito que só o
   dicionário conhece é um defeito escondido de quem consome o dado — e o pacote
   público `mape-iesp/MAPEmunicipios` distribui o dicionário junto, mas quem lê
   `mape_ler("seguranca")` não vê o campo `observacoes`.
5. **Verifique a coerência interna das justificativas.** Toda justificativa
   registrada deveria corresponder ao que o `qa/*.md` da mesma tabela reporta.
   Já há um caso confirmado em que não corresponde: `13_seguranca` afirma em
   `observacoes` que "27 códigos de UF ... não entram nesta tabela", enquanto o
   `qa/13_seguranca.md` registra 70 códigos órfãos em 352 linhas **dentro** da
   tabela. Procure os outros casos, sistematicamente, tabela por tabela.
6. **A regra "aviso exige justificativa" cria um incentivo perverso**: basta
   escrever qualquer coisa em `observacoes` para o aviso parar de bloquear.
   Avalie a qualidade das 23 justificativas: quantas explicam de fato o
   problema, quantas o descrevem sem justificar, e quantas existem só para
   silenciar o aviso? Cruze com A6, que audita o mecanismo pelo lado do código.

Este briefing produz, como subproduto, a lista de erratas que deveria ir para o
`README` — inclua-a no relatório em formato pronto para colar.

---

# 3. Consolidação

Depois que todos os agentes terminarem, rode uma última instância com este
prompt:

---

Leia todos os arquivos em `auditoria/*.md`. Cada um é o relatório de um auditor
independente do MAPEmunicipios-ETL, com escopo diferente. Produza
`auditoria/CONSOLIDADO.md` com:

1. **Achados únicos, deduplicados.** Dois agentes descrevendo o mesmo defeito por
   ângulos diferentes viram um achado com duas evidências — e isso o reforça,
   registre as duas.
2. **Reclassificação de severidade.** Reavalie com a visão do conjunto: um
   achado `MÉDIO` isolado pode ser `CRÍTICO` quando outro agente mostra que ele
   se propaga para a base larga ou para o release em `dist/`.
3. **Verificação adversarial dos `CRÍTICO` e `ALTO`.** Para cada um, rode você
   mesmo a reprodução e confirme a saída. Achado que não reproduzir vai para uma
   seção "não confirmado" com a razão. Não propague achado que você não viu com
   os próprios olhos.
4. **Cadeias causais.** Agrupe achados que compartilham a mesma raiz. Um bug em
   `mape_compactar_painel()` que aparece em sete fontes é um bug, não sete.
5. **Ordem de correção**, com dependências: o que precisa ser corrigido antes de
   reprocessar qualquer coisa, o que exige reextração da origem, o que é
   correção só de documentação.
6. **Contradições entre relatórios.** Onde dois agentes discordam, decida com
   evidência e registre o desempate.
7. **Lacunas de cobertura.** Junte as seções "Não verificado" de todos e diga o
   que ficou sem auditoria nenhuma.
8. **Veredito sobre as afirmações centrais do projeto**, uma por uma, com
   `CONFIRMADO` / `PARCIAL` / `REFUTADO` e a evidência:
   - a chave `id_municipio` + `ano` fecha em todas as tabelas
   - o sufixo permite provar o domínio de toda variável
   - o dicionário descreve exatamente o que é publicado
   - os campos calculados estão sempre atualizados
   - a fonte guarda o dado como observado
   - a paridade não tem diferença inexplicada
   - a documentação publicada não desatualiza

Mantenha as reproduções em R no consolidado — o valor deste documento é alguém
conseguir refazer cada checagem sem confiar em você.
