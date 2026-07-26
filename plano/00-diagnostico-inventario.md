# 0. Sumário executivo

O MAPEmunicipios funciona. Ele publica uma base de 180.285 linhas por 451 colunas, é citado num
artigo e alimenta três scripts de análise. O problema não é que ele esteja quebrado — é que não
existe, em lugar nenhum do pipeline, uma declaração do que cada tabela promete entregar.

Essa ausência tem uma consequência prática que atravessa todo o diagnóstico: os defeitos não
aparecem. Uma cadeia de dezesseis junções encadeadas, um `distinct()` que apaga duplicatas sem
perguntar de onde vieram, e um vetor de 451 nomes aplicado por posição absorvem qualquer erro em
silêncio. Encontrei valores inflados em cem vezes, a mortalidade do Rio de Janeiro subestimada em
97% durante três anos, e duas colunas de eleições com os rótulos trocados. Nenhum desses erros
gerou uma mensagem, um aviso ou uma linha de log. Eles simplesmente foram publicados.

O plano propõe oito mudanças de fundo.

**A unidade canônica do ETL passa a ser a fonte de dados, e não a dimensão temática.** Isso soa
contraintuitivo, porque o objetivo declarado fala em dimensões. Mas a auditoria mostrou que
"dimensão" não delimita nada: quatro das dezessete têm uma única fonte efetiva e nenhum script
consolidador — a pasta da dimensão é literalmente uma cópia manual do arquivo da subpasta. O SIM
é extraído duas vezes, em duas dimensões diferentes. O IDEB aparece em três lugares. A dimensão
continua existindo, e continua sendo o que o usuário final baixa, mas passa a ser uma tabela
*gerada* a partir das tabelas de fonte.

**A base larga de 451 colunas deixa de ser o produto principal e passa a ser gerada por função.**
Metade das suas 81,3 milhões de células está vazia. Somando todas as dezessete saídas de dimensão
chega-se a cerca de 66 MB, contra 431 MB da base larga em CSV. Quem quer só meio ambiente hoje
precisa baixar 431 MB para usar 78 colunas.

**O dicionário de metadados deixa de ser subproduto e passa a ser entrada do pipeline.** Hoje ele
é gerado depois, e se alinha à base por posição — não há chave de junção, apenas a coincidência de
que a linha 27 do dicionário descreve a coluna 27 da base. Verifiquei que essa coincidência se
sustenta hoje, o que faz dele o artefato mais confiável do projeto. Invertendo o fluxo, ele passa
a ser lido pelo código para renomear colunas, validar tipos e gerar a documentação publicada.

**Valores monetários passam a ser armazenados em reais correntes.** Oito scripts hoje aplicam o
deflator do IPCA com base fixa em dezembro de 2023 e gravam o resultado *por cima* da coluna
original, com o mesmo nome. O valor nominal não existe em lugar nenhum do repositório. Depois da
mudança, a deflação vira uma função aplicada na leitura, com o ano-base num único arquivo de
configuração.

**As tabelas passam a guardar apenas o que foi observado.** Sete trechos do pipeline hoje replicam
observações para preencher anos vazios — duas medições censitárias viram vinte linhas, um retrato
de 2015 vira onze. Nada na base distingue o dado medido do dado replicado. A expansão passa a ser
uma função que sempre marca o que imputou.

**Todo acesso a coluna por posição numérica desaparece.** São quatro mecanismos independentes, e
nenhum deles falha quando desalinha. Explico cada um na seção 1.4.

**O pipeline passa a ser orquestrado por `targets`, com o ambiente fixado por `renv`.** A escolha
do `targets` foi sua; registro na seção 9 o trade-off, porque ele condiciona bastante o desenho.

**A documentação passa a ter dois níveis, tabela e variável, com separação explícita entre campos
digitados e campos calculados.** É precisamente nos campos que alguém digitou à mão que os números
não fecham: a soma das variáveis declaradas dá 533 contra 451 reais, e o artigo declara 182.407
observações contra 180.285.

A migração é incremental, uma dimensão por vez, e cada dimensão só é promovida depois de passar num
teste de paridade contra a base publicada hoje. Esse teste classifica cada diferença encontrada em
três categorias: correções de bug que eu previ e reivindiquei de antemão, renomeações que não mudam
valor, e diferenças que ninguém explicou. Só a terceira categoria bloqueia.

O legado permanece intacto e consultável até a última dimensão migrar. A estimativa de esforço é de
catorze a vinte semanas-pessoa, com cerca de um terço em infraestrutura.

---

# 1. Diagnóstico consolidado

## 1.1 O que verifiquei diretamente

Antes de propor qualquer coisa, confirmei os números que sustentam as decisões mais caras.

**A base tem 451 colunas, e não 452.** O header do CSV publicado mostra 452 campos, mas o primeiro
é uma coluna sem nome, produto de um `write.csv` feito sem `row.names = FALSE`. As linhas de dado
são 180.285. A correção que você já tinha feito ao `CLAUDE.md` está certa.

**O dicionário bate exatamente com a base.** Carreguei `mape_municipios DICIONÁRIO.xlsx` (451 linhas
por 5 campos) e comparei o campo `Nome_banco` com os nomes das colunas do CSV: `identical()` retorna
`TRUE`. A ordem é idêntica, sem nenhuma exceção. Isso é o que torna o dicionário utilizável como
ponto de partida.

**Consegui medir a largura de cada dimensão na base final.** As dezessete colunas `dimensao_*`
funcionam como marcadores de fronteira: tudo entre uma flag e a anterior pertence à dimensão da
flag. Extraí as posições e cheguei às larguras da tabela da seção 2.1, cuja soma dá exatamente 451.
Esse mapa é insumo direto do modelo de dados alvo, porque diz quantas colunas cada tabela nova
precisa acomodar.

Duas divergências dos metadados ficaram confirmadas por esse caminho. Energia e Internet declara 31
variáveis e entrega 10. Educação declara 25 e entrega 35 — os dois números estão trocados entre si
em relação à realidade.

**O `.git` tem 18 GB, e a maior parte é lixo.** São 3,2 GB em `objects` (2,68 GiB de objetos soltos
mais 504 MiB já empacotados) e 15 GB em `.git/lost-found`. O `lost-found` é resíduo de um `git fsck`
que alguém rodou em algum momento; nada aponta para ele.

**A soma de todas as saídas de dimensão é de cerca de 66 MB**, excluindo `geolocalizacao.RData`
(30,7 MB), que nunca chega à base final. Comparado aos 431 MB da base larga em CSV, esse número é o
argumento quantitativo mais forte a favor de publicar por dimensão: o conjunto modular inteiro cabe
confortavelmente num repositório git, e a base larga não cabe.

**A árvore legada está mesmo desprotegida.** `mape_municipios/` aparece como não rastreada no
`git status`, e não há nenhuma linha no `.gitignore` que a cubra. Está fora do controle de versão
por omissão, não por decisão.

## 1.2 Onde o inventário anterior estava errado

Sete correções, todas com consequência sobre alguma decisão do plano.

**A convenção de nomes do CadÚnico não é produzida pelo script.** Esta é a correção mais importante,
porque o inventário anterior a tratava como precedente consolidado. Os nomes no padrão
`cadun_qtd_familias_atualizadas_i` já vêm prontos no cabeçalho dos arquivos `raw/*.txt`. Abri o
`raw/2015.txt` e o cabeçalho é idêntico ao do `processed/cadunico.csv`, exceto pelas colunas de
chave. O script `01_CadUnico/R/script.R` lê, filtra o mês de dezembro, deriva o ano e junta com o
diretório — ele não renomeia nada. A convenção veio de uma extração manual feita a montante, cuja
origem não existe no repositório. Não há, hoje, nada que garanta que a próxima fonte siga o mesmo
padrão, porque nunca houve código impondo esse padrão.

**O campo de tipo do dicionário chama-se `Operacionalização`.** O dicionário tem cinco campos:
`Nome_original`, `Nome_banco`, `Dimensão`, `Descrição` e `Operacionalização`. Esse último contém
`NUM` (309 vezes), `STRING` (40), `FLOAT64` (15), `INT64` (11), `GEOGRAPHY` (1) e 75 vazios — ou
seja, três vocabulários misturados, um do R, um do BigQuery e um informal, num campo cujo nome
sugere outra coisa inteiramente. Não existe campo de operacionalização de fato. Descobri também que
três variáveis reais estão sem dimensão atribuída: `id`, `qtd_uh` e `ano_eleicao`.

**As flags `dimensao_*` não são criadas pelos scripts de dimensão.** O `CLAUDE.md` afirma que cada
script adiciona `dimensao_<nome> <- 1` à sua tabela antes da junção. Não é o que acontece: nenhum
dos treze scripts de dimensão que foram lidos cria essa coluna. Todas as dezessete nascem dentro de
`2 Junção Bases/municipalityBR.qmd`. Isso importa porque significa que uma tabela de dimensão,
publicada isoladamente, não carrega a própria marca de cobertura — a semântica dessa coluna só
existe dentro do arquivo de junção.

**A premissa sobre as escalas na Saúde é falsa.** O inventário dizia que os oito conceitos
duplicados entre SI-PNI e IEPS estavam em escalas diferentes, proporção de 0 a 1 contra percentual
de 0 a 100. Ambos estão em 0 a 100. A diferença real é outra, e é mais interessante: o IEPS trunca
os valores em 100, e o SI-PNI não trunca. A coluna `cobertura_bcg` do SI-PNI chega a **13.050%**,
por erro de denominador na população-alvo.

Mais grave: `cobertura_hepatite_b` e `cob_vac_hepb` **não medem a mesma coisa**. O indicador do IEPS
cobre apenas crianças até 30 dias de vida, conforme o codebook da própria fonte; o do SI-PNI é
geral. A correlação entre as duas colunas é de 0,061. Fundir os oito pares como se fossem versões
concorrentes do mesmo número destruiria informação.

**São dez cópias de `diretorios.xlsx`, não nove.** Todas com o mesmo md5. A décima é
`01_dimensoes_individuais/00_diretorios/processed/`, na árvore nova — ou seja, a duplicação já
atravessou para a estrutura que deveria corrigi-la.

**`total_receitas_fundeb` mede a dedução do FUNDEB, não uma receita.** O nome afirma o oposto do
conteúdo. Isso importa mais do que os erros de digitação conhecidos, porque essa variável está entre
as quarenta que os scripts de análise e o artigo consomem — alguém pode ter somado uma dedução como
se fosse arrecadação.

**As duplicatas dos dados históricos foram contadas errado.** São 54 chaves duplicadas e 54 linhas
excedentes, num total de 5.646 linhas. O número 5.646 é o total da tabela, não a contagem de
duplicatas. As de `financas_municipais` (222 chaves, 235 linhas excedentes) estavam corretas.

## 1.3 O que não consegui verificar

Registro para que ninguém tome nenhum desses pontos como confirmado.

Tudo que exigiria consultar o BigQuery ficou de fora, porque geraria cobrança real. Isso inclui a
cobertura atual das tabelas remotas da Base dos Dados e o conteúdo das fontes SIA e SINAN.

Não carreguei `base_municipios_brasileiros.csv` inteiro (431 MB) — usei apenas o cabeçalho e
contagem de linhas. As contagens de valores ausentes por coluna vêm da inspeção do arquivo `.RDa`
feita separadamente.

Confirmei que `ivs_original.xlsx` (138 MB) dá erro de descompactação, mas não inspecionei o conteúdo.

Sobre as linhas com chave nula, sei que treze sobrevivem no artefato publicado, mas não consegui
determinar de qual dimensão cada uma veio. E há uma inconsistência aritmética que vale registrar: a
população contribui com 42 linhas de chave nula e o RH com 81, o que soma 123, mas a base
pré-deduplicação tem 122. Pelo menos uma linha carrega as duas marcas, o que significa que duas
chaves nulas se encontraram e se fundiram numa junção — o `dplyr` casa `NA` com `NA` por padrão, e
a junção do RH em `municipalityBR.qmd:207` não desativa esse comportamento. Não confirmei.

Por fim, não determinei se o SICONFI deflaciona todas as rubricas ou apenas um subconjunto.

## 1.4 Os cinco padrões que atravessam o pipeline inteiro

Estes cinco padrões produzem, entre eles, a maior parte dos defeitos individuais. Vale resolvê-los
estruturalmente, porque cada um vale por dezenas de correções pontuais.

### Acesso a coluna por posição numérica

Este é o mais perigoso, e aparece em quatro formas independentes que nunca falham quando desalinham.

A primeira é o **preenchimento de vazios por índice**. Em `meio_ambiente.R:83-85` há
`meio_ambiente[, 29:53] <- lapply(...)`, que troca `NA` por zero nas colunas 29 a 53. O mesmo padrão
está em `educacao.R:29-31` (`[, 28:37]`), `habitacao.R:68-70` (`[, 3:8]`) e
`assistencia_social_DH.R:68-70` (`[, 29:34]`). Se uma coluna for inserida antes da posição 29, o
intervalo passa a apontar para outras variáveis e o script continua rodando normalmente.

A segunda é a **conversão de tipo por índice**. `seguranca.R:35` faz
`seguranca[, 3:38] <- lapply(..., as.numeric)`. O objeto tem 68 colunas, e o intervalo cobre até a
38. É exatamente por isso que **27 colunas `quantidade_*` chegam à base final como texto** em vez de
número: elas estão depois da posição 38 e nunca foram convertidas.

A terceira é a **remoção de blocos na junção**. O arquivo de junção corta blocos inteiros de
colunas por posição: `municipalityBR.qmd:63` faz `meio_ambiente[, -c(3:28)]`, a linha 169 faz
`financas[, -c(13:38)]` e a linha 228 faz `dh_as[, -c(3:28)]`. Os três intervalos são diferentes
entre si porque cada dimensão traz as colunas do diretório em posições diferentes. Não há como
escrever um teste genérico para isso.

A quarta é o **renomeio final**. `renomear_variaveis.R` define um vetor de 451 nomes escritos à mão
e aplica `names(base) <- novos_nomes`. O R só emite erro se o comprimento do vetor for diferente do
número de colunas. Se uma dimensão ganhar uma coluna e outra perder uma, o comprimento continua 451
e **todos os nomes deslizam uma posição**, sem erro, sem aviso. O detalhe que torna isso quase
cômico: das 451 posições, apenas 44 de fato mudam de nome. As outras 407 são reescritas idênticas a
si mesmas. O mecanismo mais arriscado do pipeline existe para fazer 10% de trabalho útil.

### Credencial e constante escritas dentro do código

Há quatro projetos do Google Cloud diferentes espalhados pelo pipeline. O mais comum é
`dados-importacao`, em cerca de vinte scripts. Mas `bandalarga.R:18` e `telefonia.R:13` usam
`base-dos-dados-429117`; `script_sociedade_ivs.R:31` usa `municipality-carlos`; e
`Script_MunicipalityBR.R:29` usa `dissertacao-de-mestrado-399114`, sendo também o único script que
abandona o pacote `basedosdados` e chama o `bigrquery` diretamente. Na prática, o custo de
reconstruir a base está distribuído por quatro contas, três delas aparentemente pessoais.

O mesmo vale para a constante `"12/2023"`, que aparece em oito chamadas de `ipca()`. Alterar o
ano-base exige encontrar e editar as oito. Editar sete produz uma tabela com duas bases de deflação
convivendo, e nada acusaria isso.

### A deflação destrói o valor nominal

Este ponto merece destaque separado porque é irreversível. As oito chamadas seguem a forma
`mutate(across(..., ~ ipca(...)))`, **sem sufixo no nome da coluna resultante**. O valor deflacionado
sobrescreve o valor corrente, mantendo o mesmo nome. Nada registra que a operação aconteceu: nem o
nome da coluna, nem o dicionário, nem os metadados — a palavra "IPCA" sequer aparece no documento
mestre de metadados. Recuperar a série nominal exige reextrair a fonte original.

### O mesmo trecho copiado em vez de escrito como função

O bloco que expande uma tabela para um painel completo aparece literalmente idêntico, incluindo os
comentários em português, em cinco lugares: `meio_ambiente.R:21-27`, `assistencia_social_DH.R:14-20`,
`Script_MunicipalityBR.R:70-76`, `habitacao.R:21-27` e novamente `meio_ambiente.R:121-127`. O que
muda entre eles é só a faixa de anos — 1991 a 2023 nos três primeiros, 2007 a 2023 no quarto, 2010 a
2020 no quinto.

E a tabela que replica observações censitárias aparece duas vezes, idêntica, em `populacao.R:23-27`
e `sociedade.R:17-21`. São sete cópias de duas funções que ninguém chegou a escrever.

### Não há contrato entre o que a fonte cobre e o que a base entrega

Sete blocos de dado já baixado, e em vários casos já pago, não chegam ao painel — cada um por um
motivo diferente e sem relação com os outros.

O CadÚnico de 2024 é descartado por um filtro que só aceita o mês doze, e o arquivo de 2024 vai até
novembro. As edições de 2010, 2016 e 2022 da MUNIC nunca foram baixadas. Há 1,28 GB de microdados do
TSE de 2022 e 2024 em disco que nenhum script referencia, porque a lista de anos eleitorais está
fixada como `seq(2000, 2020, by = 4)`. A metade subsidiada do Minha Casa Minha Vida é lida em
`habitacao.R:13` e nunca usada. Setenta e sete variáveis do IVS são baixadas e não selecionadas. E
os scripts de SIA, SINAN, SIM da saúde, Templos e geolocalização têm código escrito, consomem
BigQuery, e não gravam saída nenhuma.

O tema comum não é falta de dado. É a ausência de qualquer declaração que compare o que se pretendia
entregar com o que se entregou. O sintoma mais visível disso é a soma de variáveis declaradas nos
metadados dar 533 contra 451 reais — a diferença de 82 é provavelmente essa mesma família de perdas.

## 1.5 Defeitos que ainda não haviam sido diagnosticados

Quinze problemas, todos em produção hoje, todos verificados por leitura de código ou inspeção dos
artefatos. Agrupo por gravidade e explico o mecanismo de cada um, porque vários não são óbvios.

### Os que alteram valores por ordem de magnitude

**Os valores do Minha Casa Minha Vida estão inflados em até cem vezes.** O script converte o formato
monetário brasileiro para numérico com duas substituições aninhadas:
`gsub("\\.", "", gsub(",", ".", .))`. A substituição interna roda primeiro e troca a vírgula decimal
por ponto. A externa então remove *todos* os pontos, inclusive o ponto decimal que a interna acabou
de criar. Um valor de `1.234,56` vira `123456`. As colunas `val_contratado` e `val_desembolsado` da
dimensão 13, e portanto as homônimas da base final, carregam esse erro.

**A mortalidade do Rio de Janeiro entre 1996 e 1998 está subestimada em cerca de 97%.** Nesses três
anos, o SIM codificou os óbitos do município em trinta pseudo-códigos sub-municipais, na faixa
`3345014` a `3345303`, correspondentes a regiões administrativas. Como a junção geral usa
`left_join` contra a lista de municípios reais, essas linhas simplesmente desaparecem. O que sobra
atribuído ao código `3304557` é uma fração do total. Qualquer série temporal de mortalidade ou
homicídio do maior município do país tem um buraco de três anos.

**A dimensão Corrupção conta o mesmo dinheiro várias vezes.** O campo `montante_fiscalizado` é um
atributo da ordem de serviço, mas o script o soma uma vez por *constatação*. Como uma ordem de
serviço gera várias constatações — são 82.664 constatações em 22.713 ordens —, o valor é multiplicado
pelo número de achados. A inflação mediana por célula município-ano é de 4,87 vezes, e a máxima
chega a 34,2. Pelo mesmo motivo, `total_acao` conta constatações e não ações de fiscalização, ficando
cerca de 3,6 vezes acima do que o dicionário afirma que ela mede.

**Metade dos dados do IEPS se perde silenciosamente.** O arquivo `ieps_municipality.xlsx` que
`saude.R` consome tem 33.420 linhas; o bruto da fonte tem 66.840. As 47 colunas do IEPS na base
final carregam metade dos valores que deveriam. E isso resolve um mistério do diagnóstico anterior:
os 33.420 valores não nulos de `sigla_uf` na base final vêm exatamente daqui. A coluna `sigla_uf`
que sobreviveu à junção é a que vazou do IEPS, e ela tem metade das linhas que deveria ter porque o
IEPS inteiro tem metade.

### Os que trocam o significado de uma coluna

**Duas colunas de eleições têm os rótulos trocados.** O script chama `rename()` passando o mesmo
argumento de origem duas vezes: primeiro `proporcao_votos_brancos_prefeitura = proporcao_votos_brancos`
e logo depois `proporcao_votos_nulos_prefeitura = proporcao_votos_brancos`. O segundo sobrescreve o
primeiro. O resultado é que existe uma coluna chamada `proporcao_votos_nulos_prefeitura` que contém
votos **brancos** (mediana 1,264), convivendo com `proporcao_votos_nulos` que contém nulos de fato
(mediana 4,455), e a coluna de brancos com nome correto não existe. Pior: o dicionário e a planilha
de variáveis descrevem as duas coluna trocadas — as duas fontes de documentação concordam entre si
e discordam do dado.

**A Educação fabrica zeros onde deveria haver ausência de dado.** O preenchimento por índice
`educacao[, 28:37]` troca `NA` por zero nas colunas do Censo da Educação Superior. Como o Censo só
cobre a partir de 2010, mas o painel começa antes, 27.850 linhas município-ano afirmam que havia
**zero instituições de ensino superior** no município, quando o correto seria dizer que não há dado.

**A deduplicação final escolhe a linha errada nos dados históricos.** Os 54 municípios duplicados são
todos do Tocantins, e a duplicação vem de a planilha de linhagem trazer tanto o registro anterior a
1988 (quando o território pertencia a Goiás) quanto o posterior. O `distinct()` mantém a primeira
ocorrência, que é a antiga. O município `1700400`, por exemplo, fica com
`estimativa_ano_fundacao = 1960` em vez de 1991.

### Os que comprometem a reprodutibilidade

**A fonte "MCMV subsidiado" não existe.** O arquivo `subsdiado_ogu.csv` é byte a byte idêntico a
`financiado_fgts_detalhado.csv` — mesmo md5. A faixa subsidiada com recursos do OGU, que é justamente
a de interesse social, nunca chegou ao repositório. E, como o objeto é lido e nunca usado, o código
dá a impressão de que ela está lá.

**O SAEB nunca foi implementado.** O único bloco de código ativo em `saeb.Rmd` é sintaticamente
inválido — contém `import(here:)` e uma chamada `df %>% mutate ()` malformada. Toda a extração está
comentada. As colunas `media_saeb`, `media_saeb_fundamental` e as demais da mesma família **não vêm
do SAEB**: são médias calculadas sobre a coluna de nota padronizada da tabela do IDEB.

**Um arquivo de entrada tem zero bytes.** `RELATORIO_DTB_BRASIL_MUNICIPIO.xls` está vazio nas duas
cópias existentes, e `ideb.R:16` tenta lê-lo com `read_excel()`. O script falha na segunda instrução.

**A cobertura de 100% da dimensão Transportes é artefato de construção.** A tabela é um esqueleto de
painel completo com valor imputado por `cumsum`, não dado observado — a fonte real cobre 27
municípios. E há um efeito colateral: os cinco municípios que adotaram a tarifa zero e depois a
encerraram (Palmas, Paulínia e outros três) aparecem com `adota_tarifa_zero = 0` em **todos** os
anos, inclusive naqueles em que a política estava em vigor, porque a aba de encerrados nunca é lida.

**Oitenta linhas fantasma da planilha da MUNIC de 2019 atravessam o pipeline.** A aba "Recursos
humanos" do arquivo tem 5.650 linhas de dado: 5.570 municípios reais mais 80 linhas que contêm
apenas o caractere `-`. O script lê a aba inteira sem filtro. Essas 80 linhas ficam com
`id_municipio` nulo e são a origem das 79 linhas excedentes do RH.

**O deflator da Corrupção está ancorado no ano errado.** O IPCA é aplicado usando `ano_evento`, o ano
em que a fiscalização ocorreu, quando o recurso auditado pertence a `ano_exercicio_repasse`. Essa
segunda coluna existe no arquivo bruto e é simplesmente ignorada. O efeito é subdeflacionar
sistematicamente valores antigos que foram auditados tardiamente.

**Montantes ausentes viram zero na Corrupção.** O uso de `na.rm = TRUE` converte em zero os 5.907
valores nulos de `montante_fiscalizado` (7,1% das linhas, concentrados até 2010). Isso cria uma
quebra de série artificial entre 2010 e 2011 que parece um fenômeno real.

---

# 2. Inventário das 17 dimensões

## 2.1 Panorama

A tabela abaixo cruza três coisas que até agora estavam separadas: quantas colunas cada dimensão
ocupa na base publicada (medido por mim, a partir das posições das flags `dimensao_*`), qual a
cobertura efetiva dessa dimensão, e o que a dimensão produz como artefato próprio.

A coluna de esforço é minha estimativa relativa para migrar, considerando número de fontes,
gravidade dos defeitos e quanto código morto precisa ser separado.

| # | Dimensão | Colunas | Cobertura | Saída própria | Consolidador | Esforço |
|---|---|---|---|---|---|---|
| 1 | Identificação | 27 | 99,8% | `diretorios` 5.570×27 (sem tempo); `geolocalizacao` 11.139×6 | nenhum | médio |
| 2 | População | 9 | 99,8% | 179.972×9 | `populacao.R` (75 linhas) | médio |
| 3 | Meio-Ambiente | 78 | 99,8% | 183.810×105 | `meio_ambiente.R` (163 linhas) | alto |
| 4 | Economia | 18 | 70,9% | 127.786×22 | nenhum | baixo |
| 5 | Sociedade | 9 | 61,7% | 111.300×10 | `sociedade.R` (40 linhas) | médio |
| 6 | Finanças | 38 | 94,8% | 181.950×65 | `financas_municipais.R` (41 linhas) | alto |
| 7 | Recursos Humanos | 16 | 37,1% | 66.905×17 | `munic_RH.R` | médio |
| 8 | Assistência Social e DH | 15 | 40,2% | 72.410×42 | `assistencia_social_DH.R` | médio |
| 9 | Energia e Internet | 11 | 58,6% | 111.425×13 | `energia_internet.R` | médio |
| 10 | Educação | 36 | 58,7% | 111.388×37 | `educacao.R` | baixo |
| 11 | Saúde | 65 | 82,7% | 149.144×67 | `saude.R` | alto |
| 12 | Transportes | 7 | 100% | 183.814×8 | `Script_MunicipalityBR.R` | baixo |
| 13 | Habitação | 7 | 52,5% | 94.832×8 | `habitacao.R` (85 linhas) | médio |
| 14 | Segurança | 64 | 73,5% | 132.907×68 | `seguranca.R` | médio |
| 15 | Corrupção | 7 | 0,8% | 1.516×8 | nenhum | baixo |
| 16 | Dados históricos | 9 | 100% | 5.646×9, **sem coluna `ano`** | `Dados Históricos - Script.R` | baixo |
| 17 | Eleições | 35 | 74,0% | 133.496×36 | `eleicoes_municipios.R` | alto |

Dois números dessa tabela precisam de ressalva. Os 100% de Transportes e de Dados Históricos não
significam boa cobertura: no primeiro caso, é o esqueleto imputado descrito na seção 1.5; no
segundo, é consequência de a tabela ser estática e ser juntada por município apenas, sem ano, o que
replica os mesmos valores em todos os anos da série.

E vale olhar para a linha da Corrupção junto com a da Meio-Ambiente. A Corrupção ocupa 180.285
linhas na base final para entregar 1.516 — ou seja, 99,2% das células dela são vazias. É o caso que
justifica sozinho o objetivo de publicar tabelas separadas.

## 2.2 As fontes das dimensões 7 a 17

Este levantamento não existia antes. Para cada fonte, o que interessa saber é: de onde o dado vem,
como ele é obtido, quais anos ele realmente cobre (não os que os comentários dizem), e o que impede
alguém de rodar o script de novo.

Uso três níveis de reprodutibilidade. **Sim** significa que roda sem intervenção. **Parcial**
significa que roda, mas trava numa credencial, num caminho de máquina ou numa constante escrita no
código. **Não** significa que depende de um arquivo local sem nenhum código que o produza.

### Dimensão 7 — Recursos Humanos

A fonte principal é a pesquisa MUNIC do IBGE: doze arquivos `.xlsx`, um por ano, somando 194 MB, sem
URL, sem código de download, sem data de coleta e sem checksum. Eles simplesmente estão na pasta.
Faltam as edições de 2010, 2016 e 2022. Reprodutibilidade parcial.

O mapeamento das colunas de cada planilha é feito por posição (`A1` até `A65`), sem nenhum
dicionário ou asserção, e os deslocamentos mudam entre 2011 e 2014 sem explicação no código. Foi
exatamente aí que nasceu um defeito real: em 2011, a variável de existência de administração
indireta recebeu a coluna do *total de funcionários* da indireta. O resultado é que
`administracao_indireta` é categórica ("Sim"/"Não"/"Recusa") em onze anos e numérica em 2011, com
304 valores distintos.

Há ainda um detalhe de arquitetura que vale registrar: o `id_municipio` não vem de uma junção com o
diretório, e sim da tabela de população, através de um `merge`. O código original do município é
descartado no `select` final. Qualquer par município-ano ausente de `populacao.xlsx` perde o
identificador em silêncio, sem possibilidade de recuperação.

O segundo script da pasta, `Script Produção Banco de Dados Municipal.R`, é código de análise
(regressão, descontinuidade, `attach()`, `help()` interativo) misturado ao ETL, com cinco consultas
ao BigQuery sem filtro. Ele compartilha 521 linhas byte a byte idênticas com o `munic_RH.R` e lê três
arquivos que não existem na pasta.

### Dimensão 8 — Assistência Social e Direitos Humanos

Três fontes. O **CadÚnico** já foi migrado para a árvore nova e é discutido em detalhe na seção 2.6.
O ponto crítico é que não existe script, URL, README ou data de extração para os arquivos `.txt` em
lugar nenhum da árvore legada — procurei por `cadun`, `anomes_s` e `http` e não há nada.

O **Disque 100** cobre 2011 a 2023 e também não tem URL, órgão, data ou script de download.

O **suplemento de Direitos Humanos da MUNIC 2023** está numa situação diferente: o script existe, mas
quebra em `library(labelled)`, um pacote não instalado. **Nada dessa fonte chega à saída.**

### Dimensão 9 — Energia e Internet

Quatro fontes vivas. **Banda Larga** (Anatel/SCM, 2007-2024) e **Telefonia Móvel** (Anatel,
2019-2024) vêm do BigQuery com o projeto `base-dos-dados-429117`, diferente do resto do pipeline. O
script de telefonia tem um defeito próprio: chama `write_xlsx()` sem carregar o pacote `writexl`.

**Luz Para Todos** (2004-2020) depende do pacote `munifacil`, que não está no CRAN, e a subpasta tem
um `.Rproj` próprio que desloca a âncora do `here()`.

A **cobertura de eletricidade dos censos de 2000 e 2010** vem de um CSV local cujo DOI, no Harvard
Dataverse, aparece apenas na planilha de metadados e nunca no código.

Esta é a dimensão em que a colisão de nomes é mais aguda: dez das doze colunas são homônimas entre
banda larga e telefonia móvel (`densidade`, `capital`, `mes`, `sigla_uf` e assim por diante). Só o
arquivo de origem as distingue.

### Dimensão 10 — Educação

O **IDEB** vem do BigQuery e a série é bienal, com edições nos anos ímpares de 2005 a 2023. O painel
anual é construído replicando cada edição para o ano seguinte, sem nenhuma marca — 55.694 das 111.388
linhas carregam valores duplicados do ano ímpar anterior. A única pista disponível para o usuário é
comparar `ano` com `ano_ideb`.

O **Censo da Educação Superior** cobre 2010 a 2023, embora os metadados declarem 1995 a 2023. A
consulta traz oito colunas de alto volume (nome e endereço da mantenedora, entre outras) que são
descartadas imediatamente no `group_by`, gerando custo desnecessário a cada execução. A coluna `ano`
vem como `integer64`, o que faz `sort()` e `range()` devolverem resultados absurdos sem erro.

O **SAEB** nunca foi implementado (seção 1.5).

Há ainda um script órfão, `ideb.R`, que é uma versão anterior e defeituosa do `ideb_saeb.R`: ele
filtra os anos iniciais usando a coluna `ensino` (que só assume "fundamental" e "medio") em vez de
`anos_escolares`, o que produziria variáveis inteiramente vazias. Ele não contamina a base porque
nunca grava saída, mas cria ambiguidade sobre qual script é o produtor real.

### Dimensão 11 — Saúde

Três fontes vivas e três mortas. Entre as vivas, **Imunizações/SI-PNI** (1994-2021) e **Atenção
Básica/e-Gestor** (2007-2020) vêm do BigQuery; a consulta da atenção básica traz 19 campos e
descarta 17. O **IEPS** (2010-2021) vem de download manual e tem dois problemas graves: um
`setwd()` para um caminho de Google Drive compartilhado no Windows, apontando para uma pasta que já
foi renumerada, e a perda de metade das linhas descrita na seção 1.5.

As três mortas — **SIA**, **SIM** e **SINAN** — são o caso mais claro de desperdício do repositório.
Os scripts executam consultas ao BigQuery, geram custo, e terminam em `summary()` sem gravar nada.
Nenhuma coluna dessas fontes entra na dimensão. O `sia_2.R` tem ainda um bloco do script de
mortalidade colado dentro dele, referenciando um objeto que não existe naquele contexto.

Um detalhe que explica um defeito antigo: `saude.R` não faz `select` nenhum sobre o IEPS, então os 49
campos da fonte entram inteiros, incluindo `nome` e `sigla_uf`. É assim que uma coluna de
identificação acaba sendo publicada com origem na saúde.

### Dimensão 12 — Transportes

Duas fontes. O **Banco Santini**, levantamento de municípios com tarifa zero, é uma planilha
colaborativa viva (a aba "sobre" registra inclusões quase semanais) lida de um arquivo local com a
data no nome, sem URL. A seleção de colunas é posicional: `select(-c(1, 3, 4, 7))`. Se a planilha
mudar de ordem, e ela muda, o script passa a remover as colunas erradas.

**Mobilidados** vem do BigQuery com o projeto pessoal `dissertacao-de-mestrado-399114` e cobre 2005 a
2017 para exatamente 27 municípios.

### Dimensão 13 — Habitação

Uma única fonte efetiva, o **MCMV financiado com FGTS** (2007-2019), obtida por download manual sem
URL e dependente do pacote `munifacil`, fora do CRAN. Os defeitos do parsing monetário e da fonte
subsidiada inexistente estão na seção 1.5.

Vale registrar uma observação de escopo: a dimensão se chama "Habitação e Zoneamento" e não há
nenhum dado de zoneamento, plano diretor ou uso do solo em lugar nenhum da pasta.

### Dimensão 14 — Segurança

Duas fontes, com naturezas muito diferentes. O **SIM** (DataSUS, 1996-2019) cobre os 5.570
municípios, mas a consulta não tem filtro de ano — cada execução faz uma varredura nacional completa
e cobrada. A primeira metade do script é código morto que ainda assim executa a consulta.

O **Anuário do Fórum Brasileiro de Segurança Pública** cobre **27 municípios** (as 26 capitais mais
Brasília) em seis anos, 2016 a 2021: 162 linhas ao todo. Isso significa que 26 das 451 colunas da
base final têm dado em 162 de 180.285 linhas, ou 0,09%, e nada na base ou na documentação avisa
disso.

Há também um defeito de expressão regular que vale explicar porque é sutil: a classificação de
homicídios usa uma alternância de códigos CID, e uma quebra de linha dentro da string literal fez
com que a alternativa depois de `X95|` virasse `"\n               X96"`, com os espaços incluídos.
Nenhum óbito com causa X96 (agressão por material explosivo) é classificado como homicídio.

### Dimensão 15 — Corrupção

Uma fonte, os microdados do Programa de Fiscalização em Entes Federativos da CGU, cobrindo 2006 a
2018. Não existe código que obtenha o arquivo — apenas a URL do dataset numa planilha de metadados.

O ponto estrutural mais importante desta dimensão é a granularidade. O dado bruto é uma tabela de
*eventos*: cada linha é uma constatação, dentro de uma ordem de serviço, dentro de um ciclo de
sorteio. O programa audita municípios sorteados, não todos os municípios todo ano. Agregar isso para
município-ano produz 1.516 linhas que ocupam 180.285 na base final.

### Dimensão 16 — Dados históricos

Cinco fontes, das quais duas alimentam a saída. A principal é o `data.csv` do pacote de replicação
de Kustov & Pardelli, um corte transversal sem coluna de ano, sem URL, sem DOI e sem versão
registrada. Dos 37 campos disponíveis, o script seleciona 8 e descarta 29 sem justificativa.

A segunda é `IBGE_1872_2010_atualizado.xlsx`, com a linhagem de nomes de município de 1872 a 2010.
Não existe script que gere a versão "atualizada" a partir da "original" — a transformação é edição
manual em Excel, sem log. É dentro dessa edição que nascem os 54 registros duplicados.

Há ainda uma função de pareamento por similaridade de nomes (Jaro-Winkler) que usa `which.min` **sem
limiar de distância**: todo nome de município de 1900 recebe obrigatoriamente um par de 1872, por
pior que seja a correspondência. O artefato afetado hoje não entra na base, mas o método está lá.

E há um trecho consultando a tabela do Slave Voyages Consortium no BigQuery, código exploratório
abandonado dentro do ETL, que gera custo e não produz nada.

### Dimensão 17 — Eleições

A dimensão com mais fontes e mais fragilidade. Quatro tabelas do TSE vêm do BigQuery; outras três vêm
de scripts em R que **não funcionam como estão**: os blocos de download têm `eval = FALSE`, os
comandos de exportação estão comentados, e as funções vivem num arquivo `0. Funcoes.Rmd` que nunca é
carregado com `source()`. Um dos arquivos lidos (`dep_fed_est.csv`, 39 MB) tem nome diferente do
que o script de download exportaria (`dep_fed_est_combined.csv`), de modo que nenhum código do
repositório o produz com o nome pelo qual ele é lido.

O painel anual não contém dado anual: é carry-forward puro. O valor do ano da eleição é replicado
nos três anos seguintes. Verifiquei no município `1100015`: `total_aptos_prefeitura` é exatamente
16781 em 2000, 2001, 2002 e 2003.

Há também escalas incompatíveis dentro da mesma tabela — `pct_votos_eleito` está entre 0 e 1,
enquanto `pct_votos_governador_eleito` está entre 0 e 100 — e cerca de 150 linhas que calculam
volatilidade eleitoral, representação feminina e ideologia partidária cujo resultado nunca entra na
tabela consolidada.

## 2.3 As granularidades que não são município por ano

Esta seção é o insumo mais importante para o modelo de dados, porque cada item aqui é um caso que
não cabe no painel sem uma decisão explícita. Hoje todos eles são forçados a caber, e é daí que vem
boa parte dos defeitos.

O **diretório** é transversal, sem ano. A **geolocalização** tem uma coluna chamada `ano` que na
verdade guarda a versão da malha cartográfica, o que é uma armadilha de nome.

O **censo de religião** e o **IVS** são censitários, com chave real `id_municipio × ano_censo` e
`id_municipio × ano_avs`, ambos com apenas dois valores (2000 e 2010).

O **AdaptaBrasil** é um retrato único de 2015, e a coluna de ano é descartada antes da expansão.

O **IDEB** no bruto tem chave `id_municipio × ano × rede × ensino × anos_escolares`, colapsada por
média, e a série é bienal.

A **Tarifa Zero** é um cadastro de eventos de adesão. O **Mobilidados** cobre 27 municípios. O
**Anuário do FBSP** cobre 27 municípios.

A **Corrupção** é uma tabela de eventos, como descrito acima.

Os **dados históricos** são um corte transversal de 1920, com chave `amc1920`/`muncode`, sem ano.

As **eleições** têm chave real `id_municipio × ano × cargo × turno`, filtrada apenas no fim. E as
sete variáveis de governador são, na verdade, `UF × ano`, replicadas em todos os municípios do
estado.

Além dessas, há dois conjuntos de códigos que não são municípios e estão escondidos dentro de
tabelas municipais: 27 códigos de UF na Segurança (`1100000`, `1200000` e assim por diante, com
cinco zeros) e as 43 regiões administrativas do Rio de Janeiro já mencionadas.

## 2.4 Os sete trechos de expansão artificial

| Onde | Faixa gerada | Observações reais por município |
|---|---|---|
| `meio_ambiente.R:25` | 1991-2023 | esqueleto de 33 anos |
| `meio_ambiente.R:125` | 2010-2020 | **uma** (AdaptaBrasil 2015) |
| `sociedade.R:17-25` | 1996-2015 | **duas** (IVS 2000 e 2010) |
| `populacao.R:23-33` | 1996-2015 | **duas** (censos de religião) |
| `assistencia_social_DH.R:18` | 1991-2023, cortado em 2011 | — |
| `Script_MunicipalityBR.R:74` | 1991-2023 | — |
| `habitacao.R:25` | 2007-2023 | e o MCMV só existe desde julho de 2009 |
| `eleicoes_municipios.R:42-51` | mandato de 4 anos | uma por eleição |

Nenhuma linha da base final carrega marca de imputação. As únicas pistas que sobraram são as colunas
`ano_avs`, `ano_censo` e `ano_ideb`, que atravessaram o pipeline por acidente — e são justamente
algumas das que estão sem dimensão preenchida no dicionário.

## 2.5 Fontes órfãs: código escrito, nenhuma saída

Somando tudo, são cerca de 400 KB de código executável dentro da árvore de ETL que não produz nada
do painel e que consulta o BigQuery se alguém rodar por engano.

Os scripts de **SIA** (21 KB), **SINAN** (8,9 KB) e **SIM da saúde** não gravam saída. No caso do
SIM, há uma extração paralela e viva em `14 Segurança/SIM/SIM.R` — ou seja, a mesma fonte foi
implementada duas vezes e uma das implementações morreu.

A pasta **Templos** tem três scripts (196 KB no total) e 56 MB de dados, incluindo um CSV de 50 MB.
Procurei por `templo` e `igreja` em todos os `.R`, `.Rmd` e `.qmd` fora da própria pasta: zero
ocorrências.

A **geolocalização** produz um geojson de 105 MB, um shapefile de 38 MB e um `.RData` de 32 MB, e
nada disso entra na base — a junção lê apenas `diretorios.xlsx`.

O **MCMV subsidiado** é lido e nunca usado. Os **microdados do TSE de 2022 e 2024** ocupam 1,28 GB e
não são referenciados por nenhum script.

Por fim, `beyond-diversity-code-upd_2.R` (128 KB) é código de replicação de artigo acadêmico,
duplicado em duas pastas dentro da dimensão 16.

## 2.6 Como o CadÚnico migrado se compara ao legado

Este é o único caso já migrado, e portanto o único teste real da convenção da árvore nova.

A leitura é equivalente nos dois: o legado e o novo leem os mesmos arquivos e aplicam o mesmo filtro
`'12$'`, que seleciona o mês de dezembro — e, consequentemente, os dois descartam 2024, cujo arquivo
vai até novembro.

O novo é melhor num ponto concreto: ele recupera o código de sete dígitos usando
`00_diretorios/processed/diretorios.xlsx`, enquanto o legado usava um arquivo local de equivalência
sem origem documentada. Ele também usa `here()` e exporta CSV em vez do par `.RData` + `.xlsx`.

O que ele não faz, apesar de parecer fazer, é aplicar a convenção de nomes. Como expliquei na seção
1.2, os nomes já vêm prontos no arquivo bruto. A saída tem 50.130 linhas e 10 colunas.

## 2.7 O que ficou por inventariar

Estes pontos precisam de uma passada de leitura antes de a dimensão correspondente entrar em
migração. Registro explicitamente para que ninguém assuma que o levantamento está completo.

**A causa das 222 chaves duplicadas em Finanças continua desconhecida.** Ninguém leu `siconfi.R` nem
`Emendas/script.R` em profundidade. A hipótese mais provável combina duas coisas: a junção
`full_join(receitas, emendas, by = c("id_municipio", "ano" = "ano_emenda"))` em
`financas_municipais.R:29`, feita sem nenhuma verificação de cardinalidade, e o fato conhecido de que
as Emendas são associadas ao município por nome, sem UF.

**A causa das 30 chaves duplicadas em População também.** O candidato direto é `populacao.R:56`, que
faz `rbind(populacao, populacao_23)` sem `anti_join` nem `distinct` — se o arquivo principal já
contiver 2023, cada município duplica.

Faltam ainda: as chaves internas do IEPS, do Anuário, do Censo da Educação Superior e das Imunizações
(se são por vacina, por dose, ou outra coisa); a identificação de quais das 105 colunas de
`meio_ambiente.RData` são as do diretório copiado, para conferir se a remoção por índice ainda está
alinhada; e se `habitacao.R` deflaciona antes ou depois de preencher os vazios com zero — a leitura
sugere antes, o que significaria que os zeros imputados não passam pelo deflator, mas não confirmei
no resultado.
