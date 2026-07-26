# MAPEmunicipios — ETL

Este repositório produz o **MAPEmunicipios**: um painel dos 5.570 municípios
brasileiros, de 1989 a 2024, organizado em 17 eixos temáticos e 26 tabelas.

Ele é o repositório **interno** do projeto — o lugar onde os dados são
extraídos, tratados, validados e publicados. Quem só quer *usar* os dados não
precisa dele:

> **Só quer os dados?** Use o pacote R.
> ```r
> remotes::install_github("mape-iesp/MAPEmunicipios")
> library(MAPEmunicipios)
> saude <- mape_ler("saude")
> ```
> Sem conta no Google Cloud, sem clonar 18 GB, sem entender `targets`.
> A documentação está em <https://mape-iesp.github.io/MAPEmunicipios/>.

Este README é para quem vai **dar manutenção** ao ETL.

---

## Sumário

- [O essencial em cinco minutos](#o-essencial-em-cinco-minutos)
- [Como o pipeline está organizado](#como-o-pipeline-está-organizado)
- [As três tarefas de manutenção](#as-três-tarefas-de-manutenção)
- [O dicionário é a especificação](#o-dicionário-é-a-especificação)
- [Validação e teste de paridade](#validação-e-teste-de-paridade)
- [As tabelas com defeito declarado](#as-tabelas-com-defeito-declarado)
- [Publicar um release](#publicar-um-release)
- [Armadilhas que já custaram caro](#armadilhas-que-já-custaram-caro)
- [O que ainda está aberto](#o-que-ainda-está-aberto)

---

## O essencial em cinco minutos

```bash
git clone https://github.com/mape-iesp/MAPEmunicipios-ETL.git
cd MAPEmunicipios-ETL

Rscript -e 'renv::restore()'      # instala os pacotes fixados no lockfile
bash tools/hooks/instalar.sh      # hook que barra arquivo grande e caminho do legado
```

O `renv::restore()` demora alguns minutos na primeira vez e nunca mais. O hook é
rápido e evita dois erros que já aconteceram: commitar um Parquet de centenas de
megabytes, e commitar um caminho de dentro da árvore legada.

Para conferir que está tudo de pé:

```bash
Rscript -e 'testthat::test_dir("tests/testthat")'   # 154 testes
Rscript -e 'targets::tar_visnetwork()'              # desenha o grafo
```

Para olhar um dado:

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

mape_tabelas_publicadas()             # as 26 tabelas
mape_ler("saude")                     # uma dimensão
mape_ler("educacao/ideb")             # uma fonte
mape_cobertura("14_corrupcao")        # quanto do painel ela cobre, por ano
```

**Você não precisa de credencial do Google Cloud para nada disso.** Ela só é
necessária para reextrair uma fonte que vem do BigQuery. Quando precisar, crie um
`.Renviron` a partir do `.Renviron.exemplo` e ponha o identificador do projeto
lá — ele não é versionado, porque o repositório é público.

---

## Como o pipeline está organizado

O fluxo tem três camadas, e a distinção entre as duas primeiras é a decisão mais
importante do desenho.

```
fonte  →  dimensão  →  base larga
```

**A fonte é a camada canônica.** Ela guarda o dado *como foi observado*, na
granularidade nativa dele. O AdaptaBrasil é um retrato de 2015, então
`03_meio_ambiente/adaptabrasil` tem 5.570 linhas — uma por município. O
levantamento de tarifa zero registra 578 município-ano com a política, então
`11_transportes/tarifa_zero` tem 578 linhas.

**A dimensão é derivada.** Ela é o painel município × ano, montado a partir das
fontes, com a replicação temporal declarada. `11_transportes` tem 183.814 linhas
porque o painel inteiro tem esse tamanho, e a coluna de adesão à tarifa zero foi
preenchida com zero em todo município-ano que a fonte não cobre.

Guardar as duas não é redundância: são perguntas diferentes. "Quantos municípios
adotaram tarifa zero?" se responde na fonte. "Como a adesão evolui ao lado do PIB
per capita?" se responde na dimensão. O pipeline antigo só tinha a segunda, e por
isso a resposta da primeira era 5.570 — todos, o tempo todo.

**A base larga** junta as **quinze** dimensões município × ano num único objeto de **424 colunas** (439 com `flags = TRUE`), com 200.520 linhas. São dezesseis dimensões publicadas: `15_dados_historicos` fica de fora **por desenho**, porque é transversal e não tem coluna `ano` — juntá-la por município replicaria os valores nos 36 anos. A função avisa quando isso acontece. *(Errata de 26/07/2026, achado 11 da auditoria: este parágrafo dizia 440 colunas e dezesseis dimensões, e as duas metades estavam erradas.)*
Ela existe porque três scripts de análise e um artigo publicado dependem dela;
como artefato derivado, custa um comando e não é versionada.

### A árvore

```
config/parametros.yml      a única fonte de verdade para constantes
dicionario/*.csv           a especificação: 432 variáveis, 26 tabelas
R/                         as funções comuns (16 arquivos)
fontes/<dim>/<fonte>/      extrair_*.R, tratar_*.R, MANIFESTO.yml, raw/
dados/fonte/               tabelas de fonte, em Parquet e csv.gz
dados/dimensao/            tabelas de dimensão, idem
dados/derivado/            base larga (não versionada)
qa/                        relatórios de qualidade e de paridade
tools/                     migração, hooks, empacotamento de release
tests/testthat/            154 testes
plano/                     o raciocínio por trás de cada decisão
docs/                      o registro do que foi feito e por quê
pendencias/                fontes que não migraram, com diagnóstico
qa/referencia/             base do pipeline antigo, p/ paridade (não versionada)
```

### A convenção de nomes

Scripts começam com o verbo do que fazem: `extrair_`, `tratar_`, `consolidar_`,
`montar_`, `validar_`. Alvos do `targets` seguem o slug da tabela:
`fonte_<slug>`, `valida_<slug>`, `dim_<slug>`.

Colunas seguem `[<prefixo_fonte>_]<conceito>[_<qualificador>]_<sufixo>`, tudo em
snake_case ASCII. O sufixo sai de um vocabulário fechado, e não é decoração — é o
que permite a validação **provar** que toda coluna `_pct` está entre 0 e 100:

| sufixo | significa | exemplo |
|---|---|---|
| `_i` | contagem | `sim_obitos_homicidio_i` |
| `_pct` | percentual de 0 a 100 | `ieps_cobertura_esf_pct` |
| `_prop` | proporção de 0 a 1 | `censo_catolicos_prop` |
| `_razao` | quociente que pode passar de 1 | `area_desmatada_sobre_area_municipio_razao` |
| `_p100k`, `_p1k`, `_p100dom` | taxa, com o denominador no nome | `ieps_medicos_p1k` |
| `_brl_nominal`, `_brl2023` | dinheiro, com a base no nome | `pib_brl2023` |
| `_km`, `_km2` | distância e área | `area_desmatada_bioma_cerrado_km2` |
| `_idx` | índice ou escore | `ivs_idx` |
| `_cat` | categoria | `adapta_risco_seca_cat` |
| `flag_` | binária (prefixo) | `flag_adota_tarifa_zero` |
| `ano_ref_` | ano de referência que não é a chave | `ano_ref_ideb` |

Duas regras que valem a pena decorar. O **prefixo de fonte é obrigatório** quando
mais de uma fonte mede o mesmo conceito — é o caso de `pni_` contra `ieps_` na
cobertura vacinal, e de `sim_` contra `fbsp_` na morte violenta. E **`ano` só
existe como chave do painel**: qualquer outro ano vira `ano_ref_*`.

---

## As três tarefas de manutenção

### 1. Um ano novo numa fonte que já existe

É o caso mais comum: o IBGE publica o PIB de 2023, o SNIS publica 2024.

**Antes de invocar um alvo pelo nome, confira que ele existe:**

```bash
Rscript -e 'targets::tar_manifest(fields = "name")'
```

Existem **14 alvos** para **26 tabelas publicadas**. Um alvo `fonte_<slug>` só
nasce quando a função `tratar_<nome>` existe, e hoje só três existem
(`00_diretorios/municipios`, `cadunico`, `disque100`); um alvo `dim_<slug>` só
nasce quando a dimensão tem duas ou mais fontes publicadas. As demais tabelas
vieram dos scripts de migração e **não são reconstruídas por `tar_make()`**.

Para uma fonte que **tem** alvo, o ciclo é:

```bash
# Uma vez só, se a fonte vier do BigQuery:
echo 'MAPE_GCP_BILLING=<projeto-gcp>' >> .Renviron

# Se o ano for novo para a base inteira, amplie a janela em
# config/parametros.yml:   anos_painel: [1989, 2025]

Rscript tools/rodar_grafo.R fonte_01_assistencia_social_dh_cadunico  # a fonte
Rscript tools/rodar_grafo.R dim_01_assistencia_social_dh             # a dimensão
Rscript tools/recalcular_dicionario.R                                # campos calculados
Rscript tools/rodar_grafo.R documentacao                             # a documentação
```

Use `tools/rodar_grafo.R` e não `tar_make()` direto: `tar_make()` sai com código
0 mesmo quando um alvo falha (achado 41 da auditoria), e o wrapper consulta
`tar_meta()` e sai com código 1 se houver erro.

Para uma dimensão **sem** alvo — que é a maioria —, atualizar significa
**escrever o `tratar_*.R` primeiro**. Use `mape_nova_fonte()` para o esqueleto e
acrescente a linha em `dicionario/tabelas.csv`; o grafo se ajusta sozinho.

*(Errata de 26/07/2026, achado 70 da auditoria: esta receita mandava rodar
`tar_make(fonte_04_economia_ibge_pib)` e `tar_make(dim_04_economia)`. Nenhum dos
dois alvos existe — `04_economia` não tem `tratar_*.R` e tem uma fonte só —, e os
dois falhavam com `Column doesn't exist`. A receita descrevia o estado pretendido
depois que a fonte tivesse o seu script de tratamento.)*

**Nenhum script precisa ser editado.** Se a fonte não mudou de schema, só o
arquivo de configuração muda. Se mudou, o que muda é `dicionario/variaveis.csv` —
e o build falha até você mexer nele, o que é deliberado.

O que conferir depois: o relatório em `qa/<slug>.md`. Ele diz se a chave continua
única, se a faixa de anos observada bate com a declarada, quanto do país a tabela
cobre e se algum tipo divergiu.

O que atualizar na documentação: **nada à mão**. Contagem de linhas, cobertura
temporal observada e percentual de vazios são medidos, não digitados.

### 2. Uma fonte nova numa dimensão que já existe

```r
mape_nova_fonte("03_meio_ambiente", "mapbiomas_cobertura")
```

Isso cria a pasta com `R/extrair_mapbiomas_cobertura.R`,
`R/tratar_mapbiomas_cobertura.R`, um `MANIFESTO.yml` para preencher e um README
que lista os seis passos que faltam. Os dois scripts já vêm com o encadeamento
certo, inclusive a ordem que importa: **limpar a chave nula antes de conferir
unicidade**, e não o contrário.

O script de extração usa `mape_query()` ou `mape_baixar()`. Nunca uma chamada
literal a `set_billing_id`, nunca um caminho relativo nu, nunca `setwd()`.

O terceiro passo é registrar a tabela e as variáveis no dicionário. **Sem isso o
build falha**, e essa mecânica é o que impede a documentação de ficar para
depois — que é exatamente o que aconteceu com as 51 descrições vazias do
dicionário antigo.

### 3. Uma dimensão nova

É o procedimento anterior mais uma linha em `dicionario/dimensoes.csv` e a pasta
`fontes/NN_<slug>/`.

Uma regra rígida: **a numeração é só de acréscimo**. Nunca renumere. O número
entra em caminho de arquivo, em nome de tabela publicada, em URL de release e na
documentação — renumerar quebra tudo isso de uma vez, em silêncio.

---

## O dicionário é a especificação

No pipeline antigo, o dicionário era produzido *depois* da base e se alinhava a
ela por posição: a linha 27 descrevia a coluna 27, sem nenhuma chave de junção.
Funcionava, e era frágil por construção — qualquer coluna inserida no meio
deslocava todo o resto.

Aqui o papel se inverte. O dicionário é **lido pelo código** para três coisas:
renomear as colunas de cada fonte, validar tipos e domínios, e gerar a
documentação publicada.

```
dicionario/
├── dimensoes.csv    o vocabulário de eixos: slug, rótulo, número no legado
├── tabelas.csv      uma linha por tabela: procedência, licença, granularidade
├── variaveis.csv    uma linha por variável: tipo, unidade, escala, domínio
├── deprecacao.csv   de-para dos nomes antigos
└── README.md        índice geral — GERADO, não edite
```

A distinção que mais importa nesse arquivo é entre **campo digitado** e **campo
calculado**. O que a variável significa, qual a licença da fonte, com que
periodicidade ela é publicada — isso só uma pessoa sabe. Quantas linhas a tabela
tem, que anos aparecem de fato, qual o percentual de vazios — isso se mede.

Os campos calculados (`tipo_real`, `pct_na`, `n_distintos`, `minimo`, `maximo`,
`n_infinito`) são reescritos por `mape_recalcular_campos()` a cada execução. Não
os edite: sua edição será sobrescrita, e é bom que seja. Foi exatamente nos
campos que deveriam ser calculados que os números da documentação antiga não
fechavam — a soma de `Total Variáveis` dava 533 contra 451 reais.

Se você mudar o nome de uma variável, registre a troca em `deprecacao.csv`. Nome
que some sem rastro é nome que volta como pergunta seis meses depois — e é o
`deprecacao.csv` que permite `mape_derivadas()` dizer "essa coluna foi renomeada"
em vez de devolver `NA` em silêncio.

---

## Validação e teste de paridade

### As checagens de qualidade

`mape_validar_tabela()` roda um conjunto de checagens sobre cada tabela publicada — o relatório em `qa/<slug>.md` imprime **quantas de fato rodaram**, porque duas delas dependem de o diretório de municípios poder ser lido. A regra
geral: **erro impede a publicação, aviso exige justificativa registrada** no campo
`observacoes` da tabela ou `problema` da variável. Aviso sem justificativa vira
erro — sem isso, aviso vira paisagem.

Estado atual, sobre as 26 tabelas: **0 erros e 120 avisos, todos com justificativa registrada** (medido em 26/07/2026 com `Rscript tools/validar_tudo.R`). Os avisos são muitos porque as checagens novas da rodada de correção — zero-inflação, quebra de nível, invariância temporal, continuidade do painel, cobertura temporal, licença e proveniência — olham coisas que ninguém olhava. Os dois erros que antes bloqueavam
chaves duplicadas herdadas das fontes e estão descritos na seção de armadilhas.

### O teste de paridade

`mape_paridade()` compara cada dimensão reconstruída com a base publicada pelo
pipeline antigo. Ele existe porque a reestruturação mexeu em 239 nomes de coluna
e em sete blocos de dado, e "eu acho que não quebrei nada" não é critério.

O que o torna confiável é o mecanismo: as diferenças aceitáveis são
**reivindicadas antes de rodar**, em `qa/paridade_esperada.csv`. Um teste em que
se pode justificar qualquer diferença depois de ver o resultado não testa nada.

```bash
Rscript -e '
  for (f in list.files("R", pattern="[.]R$", full.names=TRUE)) source(f, encoding="UTF-8")
  for (d in sub("[.]parquet$","", list.files("dados/dimensao", pattern="[.]parquet$")))
    mape_paridade(d)
'
```

Resultado atual: **zero diferenças não explicadas**.

A referência vive em `qa/referencia/base_municipios_brasileiros.RDa` e **não é
versionada** — são 56 MB, acima do limiar. Ela está no Drive compartilhado do
MAPE, em `mape_municipios/4 Base completa/`; copie de lá se for rodar a paridade.
Sem ela a validação continua funcionando; só a comparação contra o pipeline
antigo fica indisponível.

Uma ressalva honesta sobre o alcance dele. O teste é conclusivo *para a
migração*, porque ela partiu dos artefatos que já existiam, sem reextrair — com o
dado de entrada congelado, toda diferença é atribuível ao código. Na primeira
reextração de verdade essa propriedade se perde: dado e código mudam juntos, e aí
o que vale é a validação, não a paridade.

---

## As tabelas com defeito declarado

Uma tabela pode passar em todas as checagens e mesmo assim estar errada. As
checagens só encontram o que sabem procurar; o resto — o que alguém descobriu
lendo o dado, e que ninguém automatizou — está escrito à mão em dois campos do
dicionário: `observacoes`, em `dicionario/tabelas.csv`, e `problema`, em
`dicionario/variaveis.csv`. Declarar não é corrigir, e é por isso que esta seção
existe: até a auditoria de 26/07/2026, esses dois campos eram o único lugar onde
os defeitos apareciam, e nenhum documento de alto nível os mencionava.

Medido em 26/07/2026 (o comando está no fim da seção): **15 das 26 tabelas
publicadas** trazem marcador de defeito no campo `observacoes`, e **221 das 432
variáveis** têm o campo `problema` preenchido, espalhadas por 22 tabelas.
Juntando os dois campos, **25 das 26 tabelas declaram alguma coisa** — a única
que não declara nada é `01_assistencia_social_dh`, que é derivada das duas fontes
dela, e as duas declaram.

| tabela | o que o `observacoes` declara |
|---|---|
| `02_populacao` | a série intercensitária de nove a dez municípios é extrapolação linear fabricada, não estimativa do IBGE; propaga para o PIB per capita |
| `03_meio_ambiente` | 3.843 linhas de município-ano anteriores à instalação do município publicadas como zero, e não como ausência |
| `04_economia` | as onze colunas monetárias **não** estão em reais de 2023: são nominais multiplicadas por um fator inteiro que muda por bloco de anos |
| `06_financas` | receita inflada em cerca de uma ordem de grandeza por somar os três estágios e a hierarquia de contas; seis colunas publicam vazio como zero; buraco de 2018 a 2021 na receita própria |
| `07_recursos_humanos` | em 2011 a variável de administração indireta recebeu a coluna do total de funcionários: categórica em onze anos, numérica em um |
| `09_educacao` | `NA` trocado por zero por índice posicional no Censo da Educação Superior, fabricando 27.850 linhas com zero instituições; as oito colunas `saeb_nota_*` não vêm do SAEB |
| `10_saude` | `pni_cobertura_*` publica 0% onde a vacina ainda não existia no calendário; 2003 é extração truncada; 31,5% das células passam de 100% |
| `11_transportes` | a cobertura de 100% é artefato do esqueleto do painel; os cinco municípios que encerraram a tarifa zero aparecem com zero até nos anos em que a política valia |
| `12_habitacao` | 88,2% das linhas têm todas as colunas de conteúdo em zero, por preenchimento do esqueleto; as duas colunas monetárias têm defeito de escala |
| `13_seguranca` | 70 códigos não municipais publicados em 352 linhas, hoje marcados por `flag_codigo_nao_municipal`; a série do Rio em 1996-1998 fica 96,1% subestimada; X96 não é contado como homicídio |
| `14_corrupcao` | `cgu_montante_fiscalizado_brl2023` é atributo da ordem de serviço somado uma vez por constatação, o que infla 4,87 vezes na mediana; o deflator usa o ano da fiscalização e não o do repasse |
| `15_dados_historicos` | 54 chaves duplicadas, municípios do Tocantins com registro anterior e posterior a 1988, mantidas de propósito |
| `16_eleicoes` | o painel anual é carry-forward puro, sem dado anual; `votos_prefeito_eleito_prop` está em 0-1 e `votos_governador_eleito_pct` em 0-100 |
| `01_assistencia_social_dh/cadunico` | a Taxa de Atualização Cadastral passa de 100% em 59 municípios, todos em 2016, chegando a 128,8% |
| `11_transportes/tarifa_zero` | declarada canônica e já vem expandida: 81,7% das linhas são carry-forward, com a evidência apagada |

Onde ler o texto integral:

- **`qa/<slug>.md`**, seção *Defeitos declarados no dicionário* — é o único lugar
  que reúne, por tabela, o que os dois campos dizem. A barra do slug vira duplo
  sublinhado no nome do arquivo: `qa/09_educacao__ideb.md`.
- **`dicionario/tabelas.csv`**, campo `observacoes` — a fonte da coluna acima.
- **`dicionario/variaveis.csv`**, campo `problema` — o defeito de cada coluna,
  que é onde está o detalhe que importa para análise.
- **`mape_ler()`** avisa em tempo de execução, listando os primeiros e apontando
  para o `qa/` da tabela. O release também leva os `qa/*.md`, dentro de
  `documentacao.tar.gz`.

Uma ressalva sobre o aviso de `mape_ler()`: ele vê 11 das 15 tabelas da coluna
acima, não as 15. `mape_defeitos_declarados()` (`R/validacao.R`) descarta
qualquer trecho que contenha a palavra `CORRIGIDO` — inclusive `DEFEITO NÃO
CORRIGIDO`, que é como `07_recursos_humanos`, `13_seguranca` e `14_corrupcao`
escrevem os deles — e o marcador `CHAVE DUPLICADA`, de `15_dados_historicos`, não
está na lista que ele procura. Os quatro continuam visíveis pelo campo `problema`
das variáveis, que é o outro caminho da mesma função.

Para medir de novo:

```bash
Rscript -e '
  for (f in list.files("R", pattern="[.]R$", full.names=TRUE)) source(f, encoding="UTF-8")
  pub <- mape_tabelas_publicadas()
  tab <- mape_dicionario("tabelas"); var <- mape_dicionario("variaveis")
  marca <- "DEFEITO|LIMITA[ÇC][ÃA]O|CHAVE DUPLICADA|PERDA CONHECIDA|ESCALAS INCOMPAT"
  obs <- tab$observacoes[match(pub$slug, tab$slug_tabela)]
  sel <- !is.na(obs) & grepl(marca, obs)
  cat("com marcador em observacoes:", sum(sel), "de", nrow(pub), "\n")
  cat(paste0("  - ", pub$slug[sel], collapse="\n"), "\n")
  tem <- !is.na(var$problema) & nzchar(trimws(as.character(var$problema)))
  cat("variaveis com problema:", sum(tem), "de", nrow(var),
      "| em", length(unique(var$tabela[tem])), "tabelas\n")
  cat("uniao, como mape_ler() a ve:",
      sum(vapply(pub$slug, function(s) length(mape_defeitos_declarados(s)) > 0,
                 logical(1))), "\n")
'
```

---

## Publicar um release

O release é o único ponto de contato entre este repositório e o pacote R.

```bash
Rscript tools/publicar_release.R v1.1.0
```

Isso monta `dist/v1.1.0/` com uma tabela por arquivo (Parquet e csv.gz), o
dicionário inteiro, um `INVENTARIO.csv` com contagens medidas, um
`manifesto.json`, um `SHA256SUMS.txt` e a nota do release já escrita. No fim ele
imprime o comando do `gh` para publicar.

O dicionário vai junto de propósito. É o que permite o pacote saber tipo, unidade
e domínio de cada coluna sem embutir uma cópia que envelhece — uma variável nova
aparece em `mape_variaveis()` no dia seguinte à publicação do release, sem
precisar de nova versão do pacote.

### O que é versionado e o que não é

Dado bruto não é versionado desde a Fase 0: o `.gitignore` cobre `**/raw/`. A
procedência fica num `MANIFESTO.yml` versionado ao lado do script, com URL,
licença e `sha256`. São 64 bytes que dão a mesma garantia que versionar o
arquivo.

**Há uma exceção, e ela está no histórico:** o bruto do CadÚnico (~10,6 MiB
comprimidos) foi versionado no commit `20a3b11` e permanece na história do git.
A decisão de não reescrever o histórico por causa disso está registrada em
`plano/migracao-etl/03-versionamento-qa.md` §10.3 — é agregado municipal público, sem dado
pessoal, e reescrever invalidaria todos os hashes e todos os clones por 10,6 MiB.

*(Errata de 26/07/2026, achado 72 da auditoria: esta seção dizia que dado bruto
"**nunca**" é versionado, o que é falso em uma ocorrência conhecida e decidida.
Uma promessa absoluta com uma exceção não registrada é pior que a exceção.)*

Os campos `versao_fonte`, `data_download` e `baixado_por` do manifesto ficam em
branco nas fontes que vieram da árvore legada: o arquivo original nunca esteve
neste repositório e inventá-los seria pior que deixá-los vazios. Eles passam a
significar alguma coisa na primeira reextração.

Tabelas processadas **são** versionadas abaixo de 20 MB, o que cobre todas as 26
(a maior tem 15,6 MB). Acima disso vão para o release. O hook de `pre-commit`
barra qualquer coisa acima do limiar.

---

## Onde está a árvore legada

Ela **saiu do repositório em 26 de julho de 2026**, depois que a última
dependência de execução foi cortada. Eram 18 GB para 638 MB.

O original vive no **Drive compartilhado do MAPE**, em `mape_municipios/` — e é
mais completo que a cópia que estava aqui, com 736 arquivos contra 511. Baixe de
lá se precisar consultar como o pipeline antigo fazia alguma coisa.

O que dependia dele, e agora não depende mais:

| o quê | antes | agora |
|---|---|---|
| `tratar_cadunico.R` | lia de `mape_municipios/.../CadUnico/2_output/` | `fontes/.../cadunico/raw/`, sob manifesto |
| `tratar_disque100.R` | lia de `mape_municipios/.../Disque 100/` | `fontes/.../disque100/raw/`, sob manifesto |
| `mape_paridade()` | lia a base de `mape_municipios/4 Base completa/` | `qa/referencia/`, 56 MB |

Os scripts em `tools/migracao/` continuam citando caminhos do legado. Eles são
registro histórico de como a migração foi feita e não são executados pelo
pipeline; se você rodar um deles, vai precisar do legado de volta.

## Armadilhas que já custaram caro

Todas estas são reais e estão documentadas em `docs/` com evidência.

**Nunca rode um script do legado.** Vários fazem consulta ao BigQuery sem filtro
e geram custo de faturamento real. O do SICONFI baixa 18,5 milhões de linhas; o
do SIM varre o país inteiro. Alguns executam a consulta e **descartam o
resultado**. Ligue um alerta de orçamento no projeto do GCP antes da primeira
reextração.

**`id_municipio` é texto, sempre.** Não porque tenha zero à esquerda — nenhum
município brasileiro tem, já que o primeiro dígito do código do IBGE é a região,
de 1 a 5 —, mas porque **código não é quantidade**: nada deveria somar, tirar
média ou interpolar um identificador municipal, e o tipo é o que impede. Lê-lo
como número também o converte para `double`, e aí um `join` contra o Parquet ou
contra o diretório passa a falhar por diferença de tipo.

*(Errata de 26/07/2026, achado 57 da auditoria: este parágrafo afirmava que ler
`id_municipio` como número "perde o zero à esquerda de todo município do Acre, de
Alagoas e do Amazonas". É falso — os códigos do AC começam em 12, os de AL em 27
e os do AM em 13. A afirmação sustentava um ramo de `mape_como_codigo()` que
preenchia com zero qualquer entrada curta e fabricava códigos bem-formados
inexistentes; o ramo foi removido.)*

**Ao ler um `.csv.gz` publicado, declare o tipo da chave.** O CSV não carrega
tipo, e tanto `read.csv()` quanto `readr::read_csv()` devolvem `id_municipio`
como número — o que quebra qualquer junção contra o Parquet, contra
`00_diretorios/municipios` ou contra o pacote R. A receita:

```r
read.csv("dados/dimensao/09_educacao.csv.gz",
         colClasses = c(id_municipio = "character"))

readr::read_csv("dados/dimensao/09_educacao.csv.gz",
                col_types = readr::cols(id_municipio = readr::col_character()))
```

O Parquet não tem esse problema, porque preserva o tipo. Prefira-o sempre que
puder. *(Achado 103 da auditoria.)*

**`integer64` é uma armadilha silenciosa.** Em `populacao.RData`,
`as.numeric(ano)` devolve `9.83e-321`. Em `instituicoes.RData`, `sort()` e
`range()` sobre `ano` devolvem lixo sem erro. `mape_normalizar_chaves()` converte
`integer64` para `integer` explicitamente, sempre.

**Duas tabelas têm chave duplicada herdada da fonte, e continuam tendo.**
`06_financas` tem 222 chaves duplicadas porque as emendas parlamentares são
associadas ao município **por nome, sem UF** — 1.067 de 11.649 linhas têm UF
divergente, e o comentário do script antigo já admitia o problema.
`15_dados_historicos` tem 54, que são municípios do Tocantins com registro
anterior e posterior a 1988. As duplicatas foram **mantidas de propósito**, para
que o problema fique visível em vez de ser resolvido por escolha arbitrária.
`mape_montar_base_larga()` se recusa a rodar e nomeia a dimensão responsável;
aceitar a deduplicação exige passar `deduplicar = TRUE`, e a escolha fica no log.

**A série nominal não existe.** Oito scripts do legado aplicavam `ipca(...)` e
gravavam o resultado **por cima** da coluna original, com o mesmo nome.
Recuperar o valor corrente exige reextrair a fonte. O único par
nominal/deflacionado que sobreviveu está na Saúde
(`ieps_despesa_saude_total_per_capita_brl_nominal` e a irmã `_brl2023`).

**As coberturas vacinais do SI-PNI passam de 100%**, uma delas chegando a
51.175%. A causa é o denominador da população-alvo, subestimado, e a ausência de
truncamento na fonte. Os valores foram mantidos como a fonte publica, com o
domínio `[0,100]` declarado — de modo que a validação avisa a cada execução.

---

## O que ainda está aberto

Registrado com honestidade, porque saber o que falta vale mais que parecer
pronto.

**A primeira reextração nunca aconteceu.** Os scripts `extrair_*.R` estão
escritos e nunca foram executados. A primeira execução de cada um é o primeiro
teste real do procedimento de atualização, e é onde vão aparecer as diferenças
entre o que a fonte publicava em 2024 e o que ela publica agora.

**Seis fontes não migraram**, cada uma com diagnóstico em `pendencias/`: SIA,
SINAN e SIM da Saúde (consultam o BigQuery e terminam sem gravar saída),
geolocalização (175 MB de geometria que nunca entrou na base), Templos da
Sociedade (196 KB de código sem nenhum consumo), TSE 2022 e 2024 (1,28 GB que
nenhum script referencia), MCMV subsidiado (byte a byte idêntico ao do FGTS) e
MUNIC 2023 de direitos humanos (quebra em `library(labelled)`). Nenhuma delas
contribui com coluna alguma para a base publicada.

**Três licenças precisam de verificação** antes de qualquer publicação formal:
IEPS Data, Anuário do FBSP e o pacote de replicação de Kustov & Pardelli, que não
tem sequer DOI registrado. Até lá as tabelas ficam com
`licenca = "a verificar"`.

**As duas chaves duplicadas exigem reprocessar a fonte**, o que é trabalho de
extração e não de reestruturação. São o único bloqueio real que sobrou.

---

## Para entender por que as coisas são assim

| leitura | quando serve |
|---|---|
| [`plano/`](plano/) | o raciocínio por trás de cada decisão de desenho, em 6 documentos |
| [`docs/encerramento-migracao.md`](docs/encerramento-migracao.md) | o estado final da migração e o que ela descobriu |
| [`docs/decisao-dois-repositorios.md`](docs/decisao-dois-repositorios.md) | por que o pacote R fica noutro repositório |
| [`dicionario/README.md`](dicionario/README.md) | o índice das 26 tabelas, gerado |
| [`qa/`](qa/) | relatório de qualidade e de paridade de cada tabela |
| [`pendencias/`](pendencias/) | o que não migrou e o que seria preciso para recuperar |

---

## Licença

Código sob MIT. Dados sob CC BY 4.0, condicionada pelas licenças das fontes.
