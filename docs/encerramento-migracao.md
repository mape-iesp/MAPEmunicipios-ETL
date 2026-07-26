# Encerramento da migração


> **Retrato de 26/07/2026, no fim da migração.** Os números abaixo descrevem o estado *naquele momento*, e vários deles já não valem — a rodada de correção da auditoria mudou o repositório. Para o estado atual, veja `auditoria/RELATORIO-FINAL.md` e `CLAUDE.md`; para o estado no fecho do ETL, `docs/fechamento-etl.md`. Este documento fica como registro datado, e não como referência corrente.
As dezesseis dimensões com dado foram migradas, validadas e publicadas. A base
larga passou a ser um artefato derivado, gerado por função. O ambiente está
fixado por `renv`.

Este documento registra o estado final, o que ficou como pendência conhecida, e
o que a migração descobriu que ninguém sabia.

---

## O estado final

| | |
|---|---|
| Tabelas de dimensão publicadas | 16 |
| Tabelas de fonte publicadas | 3 |
| Diferenças não explicadas no teste de paridade | **0** |
| Erros de qualidade | 2, ambos chave duplicada herdada da fonte |
| Avisos de qualidade | 20, todos com justificativa registrada |
| Testes | 82, nenhuma falha |
| Pacotes no `renv.lock` | 147 |

A soma das dezesseis tabelas de dimensão em Parquet dá 127 MB, contra 431 MB da
base larga em CSV. Nenhum arquivo isolado passa do limiar de 20 MB, e o hook de
`pre-commit` confirmou isso a cada commit.

*(Errata de 26/07/2026, achado 96 da auditoria: os 127 MB não são o Parquet. São
o Parquet **mais** o `csv.gz`. Medido em 26/07/2026, na mesma convenção de
`mape_mb()`, que é base 1024: os dezesseis `dados/dimensao/*.parquet` somam
**66,7 MB**; os dezesseis `dados/dimensao/*.csv.gz` somam **60,4 MB**; os trinta
e dois juntos somam **127,1 MB**, que é o número da frase acima. O resto dela
continua valendo: nenhum arquivo versionado de `dados/` passa de 20 MB, e o maior
é `04_economia.parquet`, com 15,6 MB. Os 431 MB da base larga em CSV não foram
remedidos, porque ela deixou de ser versionada.)*

A base larga reconstruída tem 200.520 linhas por 424 colunas, com 50,7% de
células vazias — número que confirma a medição que sustentou a decisão de
publicar por dimensão.

*(Errata de 26/07/2026, achado 96 da auditoria: a taxa de células vazias não é
50,7%, e o motivo de circularem três valores diferentes é que ninguém dizia sobre
qual denominador. Medida em 26/07/2026 sobre a base gerada em memória por
`mape_montar_base_larga(deduplicar = TRUE)` — e não sobre
`dados/derivado/base_larga.parquet`, que está em disco, não é versionado e é
anterior às correções, com 183.810 × 440 —, ela dá: sobre **as 424 colunas**,
47.342.774 células vazias em 85.020.480, ou **55,68%**; sobre as **396 colunas de
conteúdo**, isto é, fora as duas chaves e as vinte e seis do bloco territorial de
`00_diretorios`, 47.044.838 em 79.405.920, ou **59,25%**. Com `flags = TRUE` são
439 colunas e 53,78%, porque as quinze colunas de presença de dimensão nunca são
vazias. Qualquer um dos três é maior do que os 50,7% declarados, o que torna o
argumento a favor de publicar por dimensão mais forte, e não mais fraco.)*

---

## O teste de paridade

Dezesseis dimensões, **zero diferenças não explicadas**.

O que torna esse resultado significativo é o mecanismo: as correções são
reivindicadas em `qa/paridade_esperada.csv` **antes** de o teste rodar. Um teste
em que se pode justificar qualquer diferença depois de ver o resultado não testa
nada.

E o teste é conclusivo porque a migração partiu dos artefatos que já existiam,
sem reextrair. Com o dado de entrada congelado, só o código mudou, e por isso
toda diferença encontrada é atribuível a ele.

---

## O que a migração descobriu

Estes achados não estavam no levantamento inicial. Todos apareceram porque
alguma validação é executável.

**A cobertura vacinal do SI-PNI chega a 51.175%.** Eu conhecia o caso de 13.050%
na BCG; a coluna agregada é muito pior. A causa é o denominador da população-alvo,
subestimado, combinado com a ausência de truncamento na fonte.

**A Taxa de Atualização Cadastral do CadÚnico passa de 100% em 59 municípios,
todos em 2016**, chegando a 128,8%. Uma razão entre cadastros atualizados e
cadastros totais não pode exceder 100%. A concentração num único ano descarta
ruído e aponta falha na extração daquela edição. A outra taxa da mesma tabela
tem máximo exatamente 100,00, ou seja, é truncada na origem e esta não é.

**Quatro colunas rotuladas como proporção são razões.** Densidade de acessos em
relação à capital, mortes por intervenção policial sobre mortes violentas, área
desmatada sobre área do município — todas podem legitimamente passar de 1.
Chamá-las de proporção mente sobre o domínio. Foi criado o sufixo `_razao`.

**`margem_pct` das eleições é o caso inverso**: valores que não passam de 1, com
sufixo de percentual.

**As Finanças têm 1.927 linhas com chave nula**, número que o levantamento não
tinha. Somadas às 42 da População, 81 dos Recursos Humanos e 137 de Energia e
Internet, são 2.187 linhas eliminadas na origem.

---

## Defeitos corrigidos

**As linhas de chave nula foram eliminadas na origem**, na ordem que o plano
determina: limpar a fonte primeiro, validar que não sobrou nenhuma, e só então
confiar na unicidade. Inverter essa ordem multiplicaria por nove as linhas sem
município no artefato publicado.

**Vinte e cinco colunas da Segurança e doze do Meio-Ambiente tiveram o tipo
recuperado.** Estavam como texto na base publicada, as primeiras por coerção
posicional incompleta (`seguranca.R` converte só as colunas 3 a 38 de um objeto
com 68) e as segundas por causa de um sentinela textual numa coluna e não na
irmã. O dicionário herdou a declaração errada e foi sincronizado, com a troca
registrada.

**O bloco territorial saiu de todas as dimensões** e existe só em
`00_diretorios`, eliminando os três cortes por índice numérico da etapa de junção.

**O renomeio posicional foi substituído por um mapeamento explícito.** Em
Meio-Ambiente e Finanças, 41 colunas tinham nome diferente entre o artefato e a
base publicada. Reconstruí a correspondência conferindo que os dois lados têm o
mesmo número de colunas depois de removida a sobra, e gravei o resultado como
tabela auditável em `tools/migracao/mapa_renomeio_posicional.csv`.

---

## O que continua sendo defeito, e por quê

Dois erros de qualidade persistem, os dois por chave duplicada herdada da fonte:

**Finanças: 222 chaves duplicadas, 235 linhas excedentes.** A causa é as emendas
parlamentares serem associadas ao município por nome, sem UF — 1.067 de 11.649
linhas têm UF divergente, e o próprio comentário do script legado admite o
problema. Corrigir exige reprocessar a fonte com join por código, o que é
extração de dado e não reestruturação de código.

**Dados históricos: 54 chaves duplicadas.** São municípios do Tocantins que
aparecem duas vezes na planilha de linhagem, com o registro anterior e o
posterior a 1988. O legado resolve mantendo a primeira ocorrência, que é a
antiga, e atribui ano de fundação errado a esses 54 municípios. **As duplicatas
foram mantidas de propósito**, para que o problema fique visível em vez de ser
resolvido por escolha arbitrária.

A consequência prática aparece na montagem da base larga: ela **se recusa a
rodar** e nomeia a dimensão responsável. Aceitar a deduplicação exige passar
`deduplicar = TRUE` explicitamente, e a escolha fica registrada no log. O legado
fazia isso em silêncio, com um `distinct()` cego que apagava a evidência.

---

## Fontes que não migraram

Seis pendências registradas em `pendencias/`, cada uma com diagnóstico, evidência,
impacto e o que seria preciso para recuperar.

| Fonte | Por quê |
|---|---|
| Saúde: SIA, SINAN e SIM | consultam o BigQuery, geram custo, e terminam sem gravar saída |
| Geolocalização | produz 175 MB de geometria que nunca entrou na base |
| Sociedade: Templos | 196 KB de código e 56 MB de dados, sem consumo em lugar nenhum |
| Eleições: TSE 2022 e 2024 | 1,28 GB em disco que nenhum script referencia |
| Habitação: MCMV subsidiado | o arquivo é byte a byte idêntico ao do FGTS |
| Assistência: MUNIC 2023 DH | quebra em `library(labelled)` |

Nenhuma delas contribui com coluna alguma para a base publicada. Migrar uma
fonte que não produz coluna acrescentaria dado novo ao mesmo tempo que o código
muda, e contaminaria o teste de paridade.

---

## O que fazer a seguir

A segunda etapa do trabalho, que é atualizar os dados, tem um caminho claro.
Os scripts `extrair_*.R` estão escritos e nunca foram executados; a primeira
execução de cada um é o primeiro teste real do procedimento de atualização.

Antes disso, três coisas valem a pena:

**Ligar um alerta de orçamento no projeto do Google Cloud.** Durante a migração
o custo foi zero, porque nada foi reextraído. A consulta do SICONFI baixa 18,5
milhões de linhas e a do SIM varre o país inteiro sem filtro.

**Revisar as variáveis marcadas em `dicionario/variaveis.csv`.** O campo
`revisao_pendente` aponta o que precisa de olho humano, com o motivo registrado
em `motivo_revisao`.

**Decidir sobre as duas chaves duplicadas.** Elas são o único bloqueio real que
sobrou, e as duas exigem reprocessar a fonte — trabalho de extração, não de
reestruturação.
