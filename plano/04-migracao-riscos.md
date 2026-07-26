# 12. O plano de migração em fases

## 12.1 Por onde começar, e por quê

A escolha é entre começar pela infraestrutura ou por uma dimensão-piloto, e as duas versões puras
falham por motivos simétricos.

Começar por uma dimensão-piloto, sem infraestrutura nenhuma, produz uma dimensão bem-feita e nenhuma
convenção reaproveitável — cada decisão fica embutida naquele código específico. Começar por
infraestrutura completa produz funções desenhadas contra problemas imaginados, que quase nunca são
os problemas reais.

O caminho que proponho é intermediário: a Fase 1 entrega o **mínimo** de infraestrutura, a Fase 2
exercita esse mínimo numa dimensão de verdade, e a Fase 3 endurece a infraestrutura com o que a
Fase 2 ensinou.

| Fase | Nome | O que entrega | Esforço |
|---|---|---|---|
| 0 | Contenção ✅ | `.gitignore`, limpeza do `.git`, tag da base atual, hook | **concluída** |
| 1 | Fundação | `.Rproj`, `renv`, `_targets.R`, funções essenciais, schema do dicionário, diretórios migrados | 2 a 3 semanas |
| 2 | Piloto | Assistência Social e DH migrada e publicada | 2 semanas |
| 3 | Endurecimento | validação completa, teste de paridade, geração de documentação, pacote R | 3 a 4 semanas |
| 4 | Dimensões simples | Economia, Corrupção, Dados Históricos, Transportes, Saúde parcial, RH | 3 a 4 semanas |
| 5 | Dimensões médias | População, Sociedade, Energia, Educação, Habitação, Finanças | 4 a 5 semanas |
| 6 | Dimensões difíceis | Meio Ambiente, Saúde completa, Eleições | 3 a 4 semanas |
| 7 | Consumidores e encerramento | migrar análises e blog, corrigir o artigo, aposentar o legado | 1 a 2 semanas |

O total fica entre catorze e vinte semanas-pessoa. É ordem de grandeza, não cronograma.

## 12.2 O princípio que governa toda a migração

Esta é a decisão mais importante desta seção, e ela simplifica bastante o trabalho:
**esta etapa reestrutura o código, não atualiza os dados.**

Cada dimensão é migrada partindo dos artefatos que já existem no legado — os arquivos `.RData`
produzidos pelas extrações originais —, com exatamente o mesmo dado de entrada. Reextrair do
BigQuery fica para uma segunda etapa do trabalho, depois que a estrutura estiver de pé.

A razão para isso não é só economia de custo, embora ela seja real. É que **o teste de paridade só
funciona se apenas uma variável mudar por vez.** Se o dado for atualizado ao mesmo tempo que o
código, qualquer diferença encontrada fica ambígua: veio de uma correção de bug, de uma regressão,
ou simplesmente de a fonte ter publicado números novos? Mantendo o dado congelado, toda diferença é
atribuível ao código, e o teste passa a ser conclusivo.

Três consequências práticas:

Os scripts `extrair_*.R` são **escritos, mas não executados** durante a migração. Eles ficam
prontos, versionados e documentados, e a primeira execução real de cada um vira o primeiro teste
genuíno do procedimento de atualização descrito na seção 8.1. É um teste melhor do que qualquer um
que eu pudesse desenhar, porque exercita o caminho completo com uma pessoa real tentando usá-lo.

O custo de BigQuery durante a migração fica **próximo de zero**, o que também reduz a urgência de
definir teto de orçamento no projeto `mapemunicipios`.

E as faixas de anos ficam **parametrizadas desde já**, mesmo quando o valor parametrizado reproduz o
comportamento atual. O caso concreto é a dimensão de Eleições, onde `seq(2000, 2020, by = 4)` sai do
código e vai para a configuração, continuando a valer 2020 como último ano. Estender a série depois
passa a ser editar uma linha, e não mexer no script.

## 12.3 Fase 0 — executada

Esta fase já foi concluída. Registro o que foi feito e o resultado.

O `.gitignore` passou a cobrir `mape_municipios/`, além de `**/raw/`, `dados/derivado/`, `_targets/`
e o lixo de sistema. A árvore legada estava desprotegida por omissão, e agora não está mais.

A limpeza do `.git` foi mais efetiva do que a estimativa. O `git fsck` confirmou que
`.git/lost-found` continha apenas *dangling blobs*, sem nenhuma referência apontando para eles, e a
remoção seguida de `git gc --aggressive --prune=now` levou o diretório **de 18 GB para 12 MB** — eu
havia estimado cerca de 600 MB. Os objetos soltos eram quase todos resíduo da tentativa abortada de
versionar o legado, e os arquivos do CadÚnico, sendo texto, comprimem muito bem.

A tag `dados-v1.0.0-legado` foi criada sobre o commit `20a3b11`, e a mensagem dela registra os
checksums SHA-256 dos quatro artefatos publicados. Isso resolve um problema que o plano original
tinha deixado em aberto: como a base publicada vive dentro de `mape_municipios/`, que não é
versionada, uma tag do git sozinha não congelava nada. Com os checksums na mensagem da tag, o teste
de paridade pode verificar que está comparando contra exatamente o mesmo artefato de referência.

Uma descoberta lateral: `base_municipios_brasileiros.RDa` e `base_municipios_brasileiros.RData` têm
o mesmo SHA-256. São o mesmo arquivo com dois nomes, o que acrescenta 56 MB de duplicação aos 4,4 GB
já conhecidos.

O hook de `pre-commit` foi instalado e testado — ele barra tanto caminhos em `mape_municipios/`
quanto arquivos acima de 20 MB. Como hooks não são versionados pelo git, ele vive em
`tools/hooks/pre-commit` e é instalado por `bash tools/hooks/instalar.sh`, que quem clonar o
repositório precisa rodar uma vez.

## 12.4 Qual dimensão deve ser o piloto

**Recomendo a Assistência Social e Direitos Humanos.**

O argumento mais forte é que ela **já tem uma fonte migrada**, o CadÚnico. Isso significa que o
piloto testa a convenção existente contra a convenção proposta, em vez de inventar do zero — e o
levantamento já mostrou que essa comparação rende: descobri que a nomenclatura não é produzida pelo
script, o que só ficou visível ao olhar o caso concreto.

Ela também tem três fontes com métodos de obtenção diferentes (arquivo local, microdados e MUNIC), o
que exercita o desenho sem ser gigantesca. E tem um caso de fonte que simplesmente não roda — o
suplemento de Direitos Humanos da MUNIC 2023, que quebra num pacote ausente —, o que força uma
decisão logo no início sobre o que fazer com fonte quebrada, em vez de deixar essa questão para a
décima dimensão.

As alternativas que considerei e descartei:

A **Economia** é simples demais. Fonte única, sem consolidação, sem múltiplas granularidades — ela
não validaria quase nada do desenho.

A **Identificação** precisa vir antes, mas não como piloto: ela é pré-requisito de todas as outras,
porque sem o diretório nenhuma tabela tem chave. Por isso ela entra na Fase 1, como parte da
fundação. E já está parcialmente migrada; falta apenas o `here()`, o Parquet e o abandono do
`.xlsx`.

O **Meio Ambiente** é arriscado demais para piloto. São quatro fontes, 78 colunas, dois trechos de
expansão artificial e um indicador perdido por junção mal especificada. Se o desenho estiver errado,
a lição custa quatro semanas em vez de duas.

## 12.5 O critério de pronto

Uma dimensão só entra em `dados/` quando **todos** os itens abaixo estiverem satisfeitos. A lista é
binária de propósito: meia migração é pior que nenhuma, porque cria uma terceira árvore para alguém
manter.

```
[ ] Scripts nomeados pelo padrão extrair_ / tratar_ / consolidar_
[ ] Nenhum setwd(), nenhum caminho relativo nu, todo caminho via here()
[ ] Nenhuma chamada literal a set_billing_id
[ ] Nenhuma constante de deflação escrita no código
[ ] Nenhum acesso a coluna por índice numérico
[ ] Nenhum código de depuração em produção (print, summary, str, ggplot exploratório)
[ ] library() apenas no topo do arquivo
[ ] Chave validada: única, sem nulos, domínio conferido contra o diretório
[ ] Órfãos de chave reportados em qa/, não descartados
[ ] Colunas harmonizadas, com sufixo de escala coerente com o valor
[ ] dicionario/variaveis.csv preenchido para todas as colunas, descrição incluída
[ ] dicionario/tabelas.csv preenchido, com licença e chave primária
[ ] MANIFESTO.yml para toda fonte de download manual, com sha256
[ ] Tabela de fonte publicada em Parquet, com o export validado
[ ] Tabela de dimensão gerada e publicada
[ ] Todas as checagens da seção 11.2 passando; avisos justificados
[ ] Teste de paridade rodado, com zero diferenças não explicadas
[ ] README.md da fonte gerado
[ ] CLAUDE.md atualizado
[ ] Alvos registrados no _targets.R
```

## 12.6 Como o legado e o novo convivem

O legado **não é tocado**. Ele continua sendo a referência canônica de como cada número foi
produzido, e é o alvo do teste de paridade. Enquanto a migração roda, a base publicada continua
sendo a `v1.0.0-legado`.

Cada dimensão migrada entra em `dados/`, é anunciada no changelog, e a partir daí a fatia
correspondente da base larga passa a vir da tabela nova.

O legado é aposentado quando três condições forem satisfeitas ao mesmo tempo: as dezessete dimensões
passarem no teste de paridade, os três scripts de análise estiverem migrados, e uma release
`dados-v2.0.0` estiver publicada. Nesse momento ele é arquivado fora do repositório, com um
`LEGADO.md` explicando o que era e onde foi parar. Ele não é apagado.

## 12.7 Quando e como os consumidores migram

São três scripts de código, e todos entram pela mesma porta: `import()` com caminho relativo, lendo
uma cópia física de 431 MB do CSV que vive na própria pasta do consumidor. Curiosidade que diz muito
sobre o estado atual: os três carregam `library(here)` e nenhum deles chega a usar `here()`.

Os arquivos são `Desastres.R:19` e `analise nota técnica.R:22`, ambos em `5 Análise Exploratória de
Dados/`, e `Desastres Ambientais no Brasil.qmd:45`, em `7 Textos Blog/`.

A migração, na Fase 7, troca a porta de entrada:

```r
# antes
base <- import("base_municipios_brasileiros.csv")

# depois
base <- mape_juntar(c("03_meio_ambiente", "02_populacao", "04_economia",
                      "05_sociedade", "10_saude", "16_eleicoes"))
```

São só as seis dimensões que eles de fato usam, cerca de quarenta colunas, em vez de 431 MB.

Três ajustes acompanham isso. O `rename()` de compatibilidade é **gerado** a partir de
`dicionario/deprecacao.csv`, não escrito à mão. Os **dois arquivos `.qmd` do blog são duplicatas** —
o diff entre eles é apenas o cabeçalho YAML e espaços em branco —, então eles viram um arquivo só
com dois formatos de saída; manter dois é garantir que divirjam. E as derivadas que cada consumidor
recria à mão hoje (`total_prejuizos`, `total_desastres_per_capita`, `idhm_100`,
`log_gasto_pbf_pc_def`, entre outras) sobem para o pacote como `mape_derivadas()`, porque atualmente
cada script tem a sua própria versão dessas contas.

O join com o `geobr` passa a usar `mape_para_geobr()`, resolvendo a dependência de tipo que hoje
funciona por coincidência.

Quanto aos **consumidores de números** — o artigo e o `Tabelas e Quadros.docx` —, como você confirmou
que o artigo é editável, a Fase 7 gera um relatório `qa/numeros_publicados.md` confrontando cada
número publicado com o valor recalculado, e o artigo é corrigido.

As figuras já publicadas **não são refeitas**. Elas ilustram a `v1.0.0-legado`, que continua
existindo e sendo citável pela tag.

---

# 13. Riscos e o que não fazer

## 13.1 Os riscos concretos

**A ordem errada na correção das chaves nulas.** Se alguém remover o `distinct()` antes de eliminar
as chaves nulas na origem, o artefato publicado piora de 13 para 122 linhas sem município. A
mitigação é a sequência escrita na seção 11.4, que é pré-requisito da Fase 4.

**Alguém interpretar a troca de painel expandido por observado como perda de dado.** Um consumidor
que esperava 111.300 linhas na Sociedade e recebe 11.140 pode concluir que sumiu informação. A
mitigação tem três partes: `mape_expandir_painel()` reproduz exatamente o comportamento antigo, o
teste de paridade cobre esse caso, e o changelog explica a mudança.

**Reescrever o histórico do git.** Invalidaria clones e referências a commits. A mitigação é
simplesmente não fazer isso: como mostrei na seção 10, o `lost-found` e o `gc` recuperam 17 GB sem
tocar em histórico nenhum.

**Migração pela metade.** Uma dimensão que fica no meio do caminho cria uma terceira árvore, pior que
as duas atuais. A mitigação é a lista binária de pronto: dimensão que não passa não entra em
`dados/`.

**Custo de BigQuery ao reconstruir.** Várias consultas rodam sem filtro, e há consultas que executam
e descartam o resultado. A mitigação é tripla: o `targets` não re-executa o que não mudou,
`mape_query()` guarda cache e registra os bytes faturados, e as fontes mortas simplesmente não
migram.

**Perda de uma fonte manual.** Se o `data.csv` da dimensão 16, os arquivos brutos do CadÚnico ou os
doze `.xlsx` da MUNIC desaparecerem, a dimensão correspondente fica irrecuperável. O manifesto com
checksum e procedimento mitiga isso daqui em diante, e a prioridade máxima vai para as duas fontes
cuja origem ninguém conhece.

**Correções que mudam números por ordem de magnitude.** O parsing do MCMV muda valores em até cem
vezes, e alguém pode ter usado o número errado. Como o uso é interno, o risco é gerenciável, mas
exige changelog explícito e mudança de versão maior.

**O `targets` virar barreira para bolsistas.** Mitigado pelas três medidas da seção 9.1.

**O dicionário desatualizar** e voltar a ser subproduto. Mitigado pela mecânica do build: sem entrada
no dicionário, a fonte não passa, e a documentação é gerada em vez de escrita.

**Licenças não verificadas.** IEPS, Anuário do FBSP e Kustov & Pardelli precisam ser verificados
antes da primeira publicação formal. Até lá, ficam marcados como pendentes.

## 13.2 O que não fazer

Algumas destas são tentações razoáveis, e é justamente por isso que vale escrevê-las.

**Não reescreva tudo de uma vez.** O legado é a única especificação executável que existe deste
pipeline. Uma reescrita de uma vez só perde a referência de paridade, e sem ela não há como saber se
uma diferença é correção ou regressão.

**Não troque de linguagem.** O público são pesquisadores em R. Mais importante: nenhum dos cinco
padrões estruturais do diagnóstico seria resolvido por Python, dbt ou SQL puro. Eles são problemas
de disciplina e de contrato, não de linguagem.

**Não corrija todos os erros de dados antes de estruturar o pipeline.** Sem estrutura, cada correção
é pontual e se perde na próxima extração. Com estrutura, a correção fica.

**Não migre as análises junto com o ETL.** As pastas de análise exploratória e de textos do blog, e
os cerca de 400 KB de código de replicação, vão para `analise/` na Fase 7, depois de o ETL
estabilizar.

**Não renumere dimensões depois de publicadas.** O número entra em caminho, nome de arquivo e
documentação. O arquivo `dimensoes.csv` só recebe acréscimos.

**Não funda os oito pares da Saúde num só.** A premissa das escalas diferentes é falsa, e no caso da
hepatite B os dois indicadores medem populações diferentes.

**Não refaça as figuras já publicadas.** Elas ilustram uma versão da base que continua existindo.

**Não automatize downloads que exigem seleção manual.** Um raspador frágil para o AdaptaBrasil ou o
IEPS é pior que cinco linhas de procedimento documentado.

**Não migre as fontes mortas.** SIA, SINAN, o SIM da Saúde, Templos e geolocalização têm código e
nenhuma saída. Se alguma delas for necessária, ela é uma fonte nova, e segue o procedimento da seção
8.2 — não é migração.

## 13.3 O que fazer com os bugs que já estão em produção

Nem todos merecem o mesmo tratamento, e vale separar.

**Corrigir junto com a migração da dimensão** é o caminho para a maioria: o parsing do MCMV, a
reagregação do Rio de Janeiro, a expressão regular dos homicídios, o IEPS incompleto, os rótulos
trocados das eleições, a dupla contagem da Corrupção, os zeros fabricados da Educação, a linha errada
nos dados históricos, os dois problemas do deflator da Corrupção, a reconstituição de `sigla_uf`, as
chaves nulas, as duplicatas e o indicador perdido do AdaptaBrasil. Todos são defeitos de extração, e
corrigi-los no momento em que a fonte é reescrita é mais barato. O teste de paridade documenta cada
um.

**Corrigir logo, fora de fase**, dois casos baratos que afetam colunas consumidas: o `-Inf` em
`log_pib`, causado por `log10` aplicado sem tratar zeros, e o filtro em `pib_municipal.R:136-146` que
descarta linhas inteiras em silêncio — ele tem oito condições `>= 0`, e o `filter()` também elimina
valores nulos, então um único vazio em qualquer variável faz o município-ano perder todas as outras.

**Documentar como pendência conhecida**, sem corrigir agora: desmembramentos e fusões municipais; o
`rendimento_mensal_media` calculado com `mean(P001)` no Censo de 2000, quando `P001` é o **peso** da
pessoa e não a renda (só não afeta o resultado porque a coluna é descartada adiante); e as 30 chaves
duplicadas da População, até que a causa seja confirmada.

**Não corrigir, e sim remover**: as fontes mortas, o código de replicação acadêmica dentro do ETL e a
consulta ao Slave Voyages Consortium. Não são bugs — é código que não deveria estar ali.

Sobre os **números publicados que mudam**: como o artigo é editável, a Fase 7 produz a lista completa
das divergências. As maiores já são conhecidas. As observações passam de 182.407 para 180.285, e vale
notar que o número do artigo é a contagem antes da deduplicação, o que sugere que ele foi apurado na
etapa errada. As variáveis passam de 533 para 451. E os valores do MCMV, da Corrupção e do IEPS mudam
de magnitude por correção de defeito.

---

# 14. O que muda no `CLAUDE.md`

O `CLAUDE.md` é documentação de primeira classe, e "CLAUDE.md atualizado" está na lista de pronto de
cada dimensão. As alterações, agrupadas por fase em que devem acontecer:

**Na Fase 0**, corrigir a contagem: a base tem 451 colunas, e 452 é o número de campos no header do
CSV por causa da coluna sem nome.

**Na Fase 1**, o grosso das mudanças. Descrever o modelo alvo, com tabelas por fonte e por dimensão e
a base larga como derivada. Substituir os comandos `Rscript <caminho>` pelos alvos do `targets`, e
documentar como rodar uma fonte só. Acrescentar `renv::restore()` ao ambiente e declarar o
`munifacil`, que não está no CRAN. Documentar `MAPE_GCP_BILLING` e deixar claro que quem só consome
não precisa de conta no Google Cloud. Substituir o fluxo de quatro etapas pelo grafo de dependências.

Ainda na Fase 1, três correções ao contrato de dados. A primeira é factual: **a flag
`dimensao_<nome>` não é criada pelo script de dimensão**, ao contrário do que o arquivo afirma hoje —
todas nascem no arquivo de junção, e elas deixam de existir. A segunda é fixar `id_municipio` como
texto de sete dígitos e `ano` como inteiro, com aviso sobre `integer64`. A terceira é acrescentar
duas regras novas: valores monetários são armazenados como nominais, e as tabelas guardam o observado.

Sobre a estrutura nova, também na Fase 1: o nome dos scripts passa a seguir o padrão de verbos, a
saída passa a ser Parquet, e — correção importante — os dados brutos e processados **deixam de ser
commitados por padrão**.

**Na Fase 2**, duas correções que só ficaram claras ao migrar o piloto: registrar que os sufixos
`_i` e `_d` do CadÚnico **não são produzidos pelo script**, e sim herdados do arquivo bruto, junto
com o vocabulário fechado que passa a valer; e registrar a renomeação da pasta para
`01_assistencia_social_dh`. Também na Fase 2, a política sobre os nomes com erro de digitação muda:
eles **serão corrigidos**, com o registro em `deprecacao.csv`.

**Na Fase 3**, acrescentar duas seções novas: como rodar as validações e onde ver o resultado, e a
regra de que o dicionário é entrada do pipeline.

**Entre as Fases 4 e 7**, remover as armadilhas conhecidas conforme elas deixarem de existir — a
renomeação posicional, a instabilidade do tipo de `ano`, o `here()` ancorando em lugar errado — e
acrescentar as novas, como a ordem de correção das chaves nulas e o domínio válido da cobertura
vacinal.

---

# 15. As decisões que ainda dependem de você

## Já respondidas nesta sessão

Suas respostas fecharam quatro pontos que eu teria deixado em aberto, e todas estão refletidas no
plano.

O uso ser **interno** permitiu dispensar a camada de compatibilidade em tempo de execução e corrigir
tanto os erros de digitação quanto os nomes que enganam. O **GitHub ser suficiente** eliminou a
necessidade de depósito citável com DOI e simplificou a interface de consumo. A escolha do
**`targets`** definiu a orquestração, com as mitigações desenhadas para bolsistas rotativos e a
recomendação de adotar `renv` junto. E o **artigo ser editável** permitiu que as contagens passem a
ser calculadas e que o texto publicado seja corrigido, em vez de tratado como imutável.

O projeto oficial do Google Cloud é **`mapemunicipios`**, o que fecha a questão dos quatro projetos
espalhados pelo código. Nenhum dos antigos sobrevive à migração.

Uma segunda rodada de respostas fechou mais quatro pontos. A migração parte dos **artefatos
existentes**, sem reextrair — princípio detalhado na seção 12.2, e que decorre de a atualização dos
dados ficar para uma segunda etapa do trabalho. O **MCMV subsidiado** fica documentado como ausente,
e a dimensão passa a declarar que cobre apenas a faixa financiada com FGTS. As **eleições param em
2020**, com a faixa de anos parametrizada para que estendê-la depois seja trivial. E a **Fase 0 foi
executada** durante esta sessão.

## Ainda em aberto

Nenhuma destas bloqueia as Fases 0 e 1, que podem começar imediatamente.

**1. As licenças do IEPS, do Anuário do FBSP e do pacote de Kustov & Pardelli.** Você tem contato ou
registro dos termos de uso? Isso bloqueia a Fase 3, quando a primeira release pública seria montada.

**2. A origem dos arquivos brutos do CadÚnico.** Os dez `.txt` são a fonte já migrada, e não existe
nenhum registro de onde vieram — procurei por `cadun`, `anomes_s` e `http` em toda a árvore legada e
não há nada. Você lembra de qual portal ou relatório eles saíram? Sem isso a fonte não é atualizável,
e ela é justamente o piloto. Bloqueia a Fase 2.

**3. A origem do `data.csv` da dimensão 16** e do `IBGE_1872_2010_atualizado.xlsx`. O segundo é mais
urgente: o passo que transforma a versão "original" na "atualizada" é edição manual em Excel sem
registro, e é dentro dele que nascem os 54 duplicados. Bloqueia a Fase 6.

**4. O projeto `mapemunicipios` tem faturamento habilitado e teto de orçamento definido?** O projeto
já está escolhido, mas resta saber se ele aguenta uma reconstrução completa. A consulta do SICONFI
sozinha baixa 18,5 milhões de linhas, e a do SIM faz varredura nacional sem filtro. Recomendo
configurar um alerta de orçamento no console do GCP antes da Fase 4.

**5. A dimensão "Habitação e Zoneamento" não tem nenhum dado de zoneamento.** Renomear para
"Habitação" ou há intenção de acrescentar o zoneamento depois? Como a numeração é só de acréscimo, é
melhor decidir antes de publicar. Não bloqueia nada, mas fica mais barato decidir agora.
