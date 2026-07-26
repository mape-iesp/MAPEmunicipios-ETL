# 7. O contrato de documentação

## 7.1 Invertendo o fluxo

Hoje o dicionário é produzido depois da base e se alinha a ela por posição: a linha 27 descreve a
coluna 27, e não há chave de junção nenhuma. Verifiquei que esse alinhamento se sustenta no estado
atual, o que faz dele o artefato mais confiável do projeto — mas ele é frágil por construção,
porque qualquer coluna inserida no meio desloca todo o resto.

A mudança central é inverter o papel dele. O dicionário passa a ser **lido pelo pipeline**, para
três coisas: renomear as colunas de cada fonte, validar tipos e domínios, e gerar a documentação
publicada. Deixa de ser um registro do que foi feito e passa a ser a especificação do que deve ser
feito.

Sobre o formato: recomendo **CSV versionado no git**. Não YAML, porque o material é tabular e YAML
fica ruim com centenas de linhas de estrutura repetida. E definitivamente não XLSX — ele não
versiona em diff, não preserva tipo, e é a origem de boa parte dos problemas descritos no
diagnóstico. O CSV abre no Excel para quem preferir editar assim, e o `git diff` mostra exatamente
qual variável mudou.

```
dicionario/
├── dimensoes.csv     # slug, rótulo, ordem, número no legado
├── tabelas.csv       # uma linha por tabela publicada
├── variaveis.csv     # uma linha por variável
├── conceitos.csv     # o glossário canônico
├── deprecacao.csv    # nome antigo -> nome novo
└── proveniencia.csv  # gerado: data de extração, projeto GCP, hash
```

## 7.2 A distinção entre campo digitado e campo calculado

Antes das tabelas de campos, vale explicar a decisão que mais importa nesta seção, porque ela
resolve sozinha uma classe inteira de erro.

Alguns campos descrevem uma **intenção** e só uma pessoa pode preenchê-los: o que a variável
significa, qual a licença da fonte, com que periodicidade ela é publicada. Outros descrevem um
**fato sobre o arquivo** e podem ser calculados: quantas linhas ele tem, quantas variáveis, que anos
aparecem de fato, qual o percentual de vazios, qual o tipo real de cada coluna.

Hoje os dois tipos estão misturados e todos são digitados. É exatamente nos que deveriam ser
calculados que os números não fecham. A soma do campo `Total Variáveis` dá 533 contra 451 reais. O
artigo declara 182.407 observações contra 180.285 — e esse número, aliás, não é aleatório: 182.407 é
a contagem **antes** da deduplicação, o que sugere que alguém contou na etapa errada do pipeline.
Cinco bases anunciam cobertura até 2024 num painel que termina em 2023.

Nenhum desses erros é descuido. Eles são inevitáveis quando um número precisa ser atualizado à mão
toda vez que o dado muda. A solução é que campo calculado nunca seja digitado, e um teste falha se
alguém tentar.

O mesmo raciocínio se aplica à cobertura temporal, que passa a ser **dois campos separados**:
`cobertura_temporal_da_fonte`, que é o que a fonte publica e alguém digita, e
`cobertura_temporal_na_tabela`, que é o que a tabela entrega e é calculado. Só essa separação já
resolveria dois casos reais: o Censo da Educação Superior declarado como 1995-2023 quando entrega
2010-2023, e o Anuário do FBSP declarado sem ressalva quando cobre 27 municípios.

## 7.3 Documentação por tabela

O ponto de partida são os onze campos de `METADADOS Bases.xlsx`, que funcionam e são preservados.
Vale destacar que `Fonte Original`, `Fonte Extração` e `Link` estão **100% preenchidos** — a
procedência das 32 bases está documentada, e isso é um ativo real que não se joga fora numa
reestruturação.

Na tabela abaixo, **D** marca campo digitado e **G** marca campo gerado.

| Campo | | Observação |
|---|---|---|
| `slug_tabela`, `dimensao`, `nome_publicado` | D | do vocabulário controlado |
| `descricao`, `responsavel` | D | preservados |
| `fonte_original`, `fonte_extracao`, `link` | D | preservados, hoje sem nenhum vazio |
| `licenca`, `licenca_url` | D | novo |
| `periodicidade_fonte` | D | novo: anual, bienal, censitária ou eventual |
| `data_ultima_extracao` | **G** | novo, vem do registro de proveniência |
| `data_ultima_atualizacao_fonte` | D | novo |
| `chave_primaria` | D | novo |
| `granularidade` | D | novo, inclui os casos que não são município por ano |
| `metodo_acesso` | D | novo, vocabulário fechado: `bigquery`, `pacote_r`, `download_manual`, `api`, `arquivo_local` |
| `script_ingestao` | D | novo, o caminho do script |
| `citacao_recomendada` | D | novo |
| `regra_preenchimento_temporal` | D | novo: `nenhuma`, `carry_forward` ou `valor_unico_replicado`, com justificativa obrigatória |
| `cobertura_temporal_da_fonte` | D | |
| `cobertura_temporal_na_tabela` | **G** | |
| `total_variaveis`, `n_linhas`, `n_municipios`, `pct_na` | **G** | |

## 7.4 Documentação por variável

O ponto de partida aqui é o `DICIONÁRIO.xlsx`, que é a única peça de documentação validada contra o
dado real. Preserva `Nome_original`, `Nome_banco`, `Dimensão` e `Descrição`.

| Campo | | Observação |
|---|---|---|
| `tabela` | D | novo, e importante: hoje só existe a dimensão, mas Meio Ambiente tem quatro fontes e Saúde tem seis |
| `nome_canonico` | D | |
| `nome_na_fonte` | D | era `Nome_original` |
| `conceito` | D | novo, aponta para o glossário |
| `descricao` | D | preservada; 51 estão vazias e precisam ser escritas |
| `unidade` | D | novo, em campo próprio e não embutido no texto |
| `escala` | D | novo: `0-1`, `0-100`, `contagem`, `brl`, `indice` |
| `ano_base_deflator` | **G** | novo, vem do arquivo de configuração |
| `tipo` | D | vocabulário fechado: `character`, `integer`, `double`, `logical`, `date`, `geometry` |
| `dominio_valido` | D | novo, alimenta a validação |
| `obrigatoria` | D | novo |
| `tipo_real`, `pct_na`, `min`, `max` | **G** | |

O campo `tipo` merece explicação, porque a migração dele não é trivial. Como registrei no
diagnóstico, o campo que hoje guarda o tipo se chama `Operacionalização` e mistura três vocabulários:
`NUM` (309 ocorrências), `STRING` (40), `FLOAT64` (15), `INT64` (11), `GEOGRAPHY` (1), mais 75
vazios. Na migração ele é renomeado para `tipo`, mapeado para o vocabulário fechado e **confrontado
com o tipo real observado no arquivo**. Divergências interrompem a publicação. Já sei de duas:
`prefeito_eleito` e `partido` estão declarados como `NUM` e são texto.

## 7.5 A auditoria de descrições

Migrar o dicionário não é copiá-lo. Há erros conhecidos que precisam ser corrigidos no processo, e
uma validação que precisa passar a existir para que não voltem.

Primeiro, **as oito descrições duplicadas do bloco do PIB para o do SICONFI**, que afetam dezesseis
variáveis. O caso mais evidente é `total_receitas_fundeb`, documentado como "Produto Interno Bruto a
preços correntes" — e a variável, além de mal documentada, mede a dedução do FUNDEB e não uma
receita, como expliquei no diagnóstico. É uma variável errada no nome e na descrição ao mesmo tempo.

Segundo, **a documentação trocada de votos brancos e nulos** nas Eleições. Aqui há uma armadilha: o
dicionário e a planilha de variáveis concordam entre si e discordam do dado. Quem cruzar as duas
fontes de documentação vai concluir que estão certas.

Terceiro, **escrever as 51 descrições vazias** e atribuir dimensão às três variáveis órfãs (`id`,
`qtd_uh` e `ano_eleicao`).

E, para que o primeiro problema não se repita, uma validação automática que sinaliza descrições
**idênticas** entre variáveis de tabelas diferentes. É o teste que teria pego o copiar-e-colar do
PIB para o SICONFI no momento em que aconteceu.

## 7.6 A licença dos dados

O repositório tem uma licença MIT, que cobre código e não dados.

Recomendo **CC BY 4.0** para a base compilada, com uma ressalva importante: ela é condicionada pelas
licenças das fontes. A maioria é composta de dados públicos brasileiros — IBGE, DataSUS, INEP, TSE,
CGU, SICONFI, Anatel — e todos são compatíveis com atribuição.

Mas três fontes precisam de verificação antes de qualquer publicação formal. O **IEPS Data** tem
licença própria. O **Anuário do FBSP** tem termos de uso próprios do Fórum. E o pacote de replicação
de **Kustov & Pardelli**, que alimenta a dimensão 16, tem licença desconhecida e nem sequer um DOI
registrado no repositório.

Verificar essas três licenças é tarefa minha na Fase 3, junto com o resto do endurecimento — você
não tem os termos, então vou atrás deles. Até lá, as tabelas ficam com `licenca = "a verificar"` e a
validação emite aviso. Na prática, isso significa `LICENSE` para o código, `LICENSE-DADOS` para os
dados, e um campo `licenca` por tabela.

## 7.7 Como a documentação é publicada e como ela não desatualiza

Cada pasta de fonte ganha um `README.md` **gerado** a partir do dicionário. Como ele nunca é escrito
à mão, ele nunca fica desatualizado por esquecimento. O mesmo vale para o índice geral em
`dicionario/README.md`, que lista todas as tabelas com cobertura e contagens calculadas.

A garantia de que isso funciona é mecânica: um alvo do `targets` regera toda a documentação, e um
teste de integração contínua falha se o que foi gerado divergir do que está commitado. Se alguém
alterar uma tabela sem atualizar o dicionário, o build quebra.

Não recomendo montar um site com `pkgdown` neste momento. A linha `docs/` do `.gitignore` o
bloquearia, e o custo de manutenção não se paga enquanto o público for interno.

---

# 8. Estratégia de atualização

Os três procedimentos abaixo são escritos do ponto de vista de quem chega ao projeto sem contexto
nenhum. Se algum deles exigir conhecimento que não está escrito, é um defeito do plano.

## 8.1 Adicionar um ano novo a uma fonte que já existe

Este é o caso mais comum: o IBGE publica o PIB de 2022, ou o SNIS publica 2023.

```bash
# Uma vez só, na primeira vez que você for atualizar qualquer coisa:
echo 'MAPE_GCP_BILLING=<seu-projeto-gcp>' >> .Renviron

# Se o ano for novo para a base inteira, amplie a janela do painel em
# config/parametros.yml:   anos_painel: [1991, 2024]

# Rode só a fonte que mudou:
Rscript -e 'targets::tar_make(fonte_ibge_pib)'

# Rode as validações dela:
Rscript -e 'targets::tar_make(valida_ibge_pib)'

# Regere a dimensão e a documentação:
Rscript -e 'targets::tar_make(c(dim_04_economia, doc_04_economia))'
```

**Nenhum script precisa ser editado.** Se a fonte mudou de schema, é preciso ajustar
`dicionario/variaveis.csv`; fora isso, só o arquivo de configuração.

O que validar é o relatório de qualidade: chave única, faixa de anos observada contra a declarada,
cobertura de municípios, tipos.

O que atualizar na documentação: nada manualmente. A cobertura na tabela, a contagem de linhas e a
data de extração são campos calculados.

Vale notar por que isso é tão mais curto que hoje. Os cinco obstáculos que travam a atualização
atualmente — credencial no código, base do deflator espalhada em oito lugares, data embutida no nome
do arquivo, ausência de registro de extração, e caminhos que dependem do diretório de trabalho —
foram todos resolvidos estruturalmente pelas funções comuns.

## 8.2 Adicionar uma fonte nova a uma dimensão existente

O primeiro passo cria o esqueleto:

```r
mape_nova_fonte("03_meio_ambiente", "mapbiomas_cobertura")
```

Isso gera `fontes/03_meio_ambiente/mapbiomas_cobertura/` com `R/extrair_mapbiomas_cobertura.R`,
`R/tratar_mapbiomas_cobertura.R` e um `README.md` inicial.

Depois vem escrever os dois scripts. O de extração usa `mape_query()` ou `mape_baixar()`, nunca uma
chamada literal a `set_billing_id`, nunca um caminho relativo nu, nunca `setwd()`. O de tratamento
segue o encadeamento padrão descrito na seção 6.5.

O terceiro passo é preencher a linha em `dicionario/tabelas.csv` e as linhas em
`dicionario/variaveis.csv`. **Sem isso o build falha**, e essa é a mecânica que impede a documentação
de ficar para depois — que é o que aconteceu com as 51 descrições vazias de hoje.

Por fim, registrar o alvo em `_targets.R`, incluir a fonte na lista do script de consolidação da
dimensão, e rodar `tar_make()`. As validações rodam sozinhas.

## 8.3 Adicionar uma dimensão nova

É o procedimento anterior, mais: uma linha em `dicionario/dimensoes.csv`, a pasta `fontes/NN_<slug>/`,
um script `consolidar_<slug>.R` e o alvo de dimensão.

Uma regra importante: **a numeração é só de acréscimo**. Nunca renumerar, porque o número entra em
caminho de arquivo, nome de tabela e documentação publicada.

## 8.4 As fontes de download manual

São oito na lista original — AdaptaBrasil, Atlas de Desastres, Emendas da CGU, `populacao_2023.xlsx`,
`area_total.xlsx`, `df_igrejas_nomes.csv`, `estimativas_pop.csv` e `evangelicos_censo2010.csv` — e o
levantamento acrescentou outras sete: os doze arquivos da MUNIC (194 MB), o IEPS, o MCMV/FGTS, os
microdados da CGU, o Banco Santini, o `data.csv` de Kustov & Pardelli e o
`IBGE_1872_2010_atualizado.xlsx`.

Todas recebem o mesmo tratamento: um arquivo `MANIFESTO.yml` versionado ao lado do script.

```yaml
fonte: atlas_desastres_s2id
orgao: SEDEC/MIDR e CEPED/UFSC
url: https://...              # obrigatório; se não houver, escrever 'indisponivel' e justificar
arquivo_local: BD_Atlas_1991_2023.xlsx   # sem data no nome
versao_fonte: "v1.0 2024-04-29"          # a data vive aqui
data_download: 2024-05-02
baixado_por: fulano
sha256: 3f2a...
licenca: ...
automatizavel: parcial        # sim, parcial ou nao
nota: "o download exige selecionar filtros manualmente no portal"
```

O arquivo bruto vive em `fontes/<dimensao>/<fonte>/raw/`, fora do controle de versão, mas com o
`sha256` registrado no manifesto, que é versionado. Uma função `mape_verificar_raw()` confere o hash
antes de processar e falha se ele divergir. São 64 bytes de garantia substituindo a confiança cega
de que o arquivo na pasta é o arquivo certo.

A versão e a data passam a viver no manifesto, e não no nome do arquivo. É o que resolve
`Emendas_CGU_8_10_2024.xlsx` e `BD_Atlas_1991_2023_v1.0_2024.04.29.xlsx`, cujos nomes precisam ser
editados no código toda vez que a fonte é atualizada.

O campo `automatizavel` registra uma avaliação por fonte. As Emendas (Portal da Transparência) e o
Atlas de Desastres têm URL estável e podem virar chamadas a `mape_baixar()`. O AdaptaBrasil e o IEPS
exigem seleção manual de filtros no portal, então ficam como `nao`, com o procedimento escrito passo
a passo no `README.md` da fonte. Não vale a pena escrever um raspador frágil para substituir cinco
linhas de instrução.

## 8.5 O caso do `populacao_2023.xlsx`

Este arquivo merece tratamento à parte porque é o pior caso do repositório: o merge dele com o
diretório, gerando 33 colunas, foi feito **à mão no Excel**. É uma etapa do pipeline que não existe
em código nenhum e que ninguém consegue repetir.

**Recomendo substituir a fonte em vez de reescrever o merge.** A estimativa populacional de 2023 do
IBGE está disponível em `br_ibge_populacao.municipio`, na Base dos Dados — que é exatamente a mesma
tabela já usada para o período de 1991 a 2022 pelo `populacao_brasileira.R`. O `rbind` manual existe
apenas porque a extração original foi feita antes de a tabela remota ser atualizada com o ano novo.

Isso resolve dois problemas de uma vez. Elimina o passo manual e, muito provavelmente, elimina
também as 30 chaves duplicadas de `populacao_brasileira`, cuja causa candidata é justamente
`populacao.R:56`, que faz `rbind(populacao, populacao_23)` sem verificar se o ano já estava presente.

Se, no momento da migração, a tabela remota ainda não cobrir 2023, o plano B é reescrever o merge em
código, com `mape_join(relationship = "one-to-one")` e o arquivo sob manifesto. O que não pode
acontecer é repetir o passo no Excel.

---

# 9. Orquestração e reprodutibilidade

## 9.1 A escolha do `targets`

Você decidiu usar `targets`, e concordo. Registro o raciocínio porque ele condiciona bastante o
desenho do resto.

As alternativas eram um script mestre numerado, que é o mais simples de aprender mas não sabe o que
já rodou e portanto re-executa tudo sempre, e um `Makefile`, que é incremental mas tem sintaxe
hostil para o público-alvo e não entende objetos do R.

O argumento que faz o `targets` valer especificamente para este projeto é o custo: **ele não
re-executa o que não mudou**. Com cerca de 28 consultas ao BigQuery, várias delas sem filtro — a do
SICONFI baixa 18,5 milhões de linhas, a do SIM faz varredura nacional completa —, re-rodar o
pipeline inteiro cegamente custa dinheiro real toda vez.

A contrapartida é a curva de aprendizado, que importa porque o público são bolsistas rotativos.
Proponho três mitigações. O `_targets.R` é **gerado** a partir de `dicionario/tabelas.csv`, de modo
que ninguém precisa editá-lo à mão para acrescentar uma fonte. Os nomes de alvo seguem um padrão
previsível: `fonte_<slug>`, `valida_<slug>`, `dim_<slug>`, `doc_<slug>`. E um `CONTRIBUINDO.md`
traz os três procedimentos da seção 8 em forma de receita.

Além disso, `targets` é **invisível para quem só consome**. Quem baixa os dados publicados nunca
esbarra nele.

## 9.2 Rodar uma parte só

Este é pré-requisito do objetivo de facilitar a atualização, e sai de graça do grafo de dependências:

```r
targets::tar_make(fonte_snis_saneamento)   # uma fonte
targets::tar_make(dim_03_meio_ambiente)    # uma dimensão e as fontes de que ela depende
targets::tar_visnetwork()                  # desenha o grafo, mostrando o que está desatualizado
targets::tar_outdated()                    # lista o que rodaria
```

## 9.3 Eliminando `setwd()` e caminhos relativos

`setwd()` fica **proibido**. Os que existem hoje apontam para caminhos de Google Drive no Windows com
numeração de pasta já obsoleta — o do IVS aponta para "7 Sociedade", que hoje é a dimensão 5, e o do
IEPS aponta para "12 Saúde", que hoje é a 11. Nenhum deles roda em máquina alguma além da original.

Todo caminho passa por `here()`, a partir da raiz. Isso inclui corrigir o
`00_diretorios/R/script.R`, que já viola a convenção da própria árvore nova.

Um lint na integração contínua rejeita `setwd(`, chamadas de leitura com caminho nu e
`set_billing_id("` literal.

## 9.4 Onde o `here()` ancora

O problema aqui é concreto e vale explicar, porque é a causa raiz de um defeito conhecido. A função
`here()` procura, subindo a árvore de diretórios, por um marcador de projeto — um `.Rproj`, um
`.git`, e alguns outros. A raiz do repositório não tem `.Rproj`, então hoje o `here()` ancora no
`.git`. Só que existem **sete arquivos `.Rproj` dentro do legado**, e cada um deles desloca a âncora
se a sessão do R for aberta dentro daquela subárvore. O caso mais explícito é `mcmv/mcmv.Rproj`: o
`mcmv.Rmd` **depende** dele para que `here("0_dados", ...)` resolva corretamente. São duas âncoras
diferentes no mesmo repositório.

A solução é criar um `MAPEmunicipios.Rproj` na raiz. Isso exige editar o `.gitignore`, que hoje
ignora `*.Rproj` como herança de um template:

```gitignore
# Ignora .Rproj em subpastas, mas versiona o da raiz, que é a âncora do here()
*.Rproj
!/MAPEmunicipios.Rproj
```

Como a árvore legada inteira passa a ser ignorada, os sete `.Rproj` dela deixam de interferir.

## 9.5 Fixando o ambiente com `renv`

**Recomendo adotar `renv`**, com escopo enxuto.

Sem ele, o `targets` garante metade da reprodutibilidade: ele sabe *o que* rodar, mas não *com
quê*. E há três dependências que hoje quebram de formas que ninguém antecipa.

O pacote `munifacil` **não está no CRAN** — só no GitHub — e é exigido por dois scripts sem estar
declarado em lugar nenhum. Quem tentar rodá-los vai receber um erro de pacote não encontrado e não
terá como saber de onde instalá-lo. O `deflateBR` não está instalado na máquina atual e é chamado no
**meio** de quatro scripts, o que significa que a falha só aparece depois de todo o processamento
pesado ter rodado. E `basedosdados`, `censobr` e `geobr` mudam de API entre versões.

O custo de manutenção é um `renv::snapshot()` quando uma dependência muda, e um `renv::restore()` a
mais para quem chega ao projeto. É pouco perto de um pipeline que não roda.

## 9.6 Credenciais

O `.Renviron` já está no `.gitignore`, então parte do caminho está andada. Basta uma linha:

```
MAPE_GCP_BILLING=<seu-projeto-gcp>
```

O projeto oficial do Google Cloud para o MAPEmunicipios existe e já tem faturamento habilitado. O
identificador dele **não é versionado**, porque o repositório é público: ele vive no `.Renviron`, e
`.Renviron.exemplo` serve de molde. Ele substitui os quatro projetos hoje espalhados pelo código (`dados-importacao`, `municipality-carlos`,
`dissertacao-de-mestrado-399114` e `base-dos-dados-429117`), e nenhum deles deve sobreviver à
migração. O valor entra também como padrão em `config/parametros.yml`, para que quem clonar o
repositório e tiver acesso ao projeto não precise configurar nada.

A função `mape_billing_id()` resolve em cascata e falha com mensagem acionável, e `mape_query()`
registra qual projeto e qual conta geraram cada extração — informação que hoje não existe em lugar
nenhum e que é o que permite saber, meses depois, de onde veio um número.

E, repetindo o que precisa estar na primeira tela do README: **quem só consome as tabelas publicadas
não precisa de conta no Google Cloud.** A credencial é exigida apenas para atualizar fontes que vêm
do BigQuery.
