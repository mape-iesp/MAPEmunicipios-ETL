# 3. Modelo de dados alvo

Esta seção contém as oito decisões que determinam tudo o mais. Escrevi cada uma como um argumento:
qual é a situação hoje, quais são as saídas possíveis, o que recomendo e o que essa escolha custa.
Nenhuma delas está decidida por omissão.

## 3.1 Publicar por dimensão ou por fonte?

**Recomendo uma solução híbrida: a fonte é a camada canônica, onde o ETL escreve, e a dimensão é
uma tabela derivada, que é o que o usuário final baixa.**

A pergunta parece simples e não é. O objetivo declarado fala em dimensões, e a árvore nova já
publica por fonte — `01_CadUnico/processed/cadunico.csv` é uma de várias fontes da Assistência
Social. As duas opções puras têm problemas sérios.

Publicar **só por dimensão** reproduz, em escala menor, exatamente o problema que se quer resolver.
Meio Ambiente juntaria quatro fontes com coberturas que mal se sobrepõem: o AdaptaBrasil é um
retrato de 2015, o Atlas de Desastres vai de 1991 a 2023, o SNIS de 1995 a 2022 e o PRODES de 2000 a
2022. O resultado é uma tabela cheia de vazios estruturais, que é a base larga em miniatura. Saúde
seria pior: seis fontes e oito conceitos medidos duas vezes por fontes diferentes.

Publicar **só por fonte** contraria a letra do objetivo. Quem quer meio ambiente teria que baixar
quatro arquivos e descobrir sozinho como juntá-los, o que é justamente o trabalho que a base
existe para poupar.

O que me convenceu da terceira via foi um achado do levantamento que eu não esperava: **a dimensão
não delimita nada no dado.** Quatro das dezessete — Economia, Transportes, Corrupção e Dados
Históricos — têm uma única fonte efetiva e nenhum script consolidador; o arquivo no nível da
dimensão é uma cópia manual do arquivo da subpasta. Outras três (Educação, Segurança, Finanças) têm
consolidador que só faz um `full_join` de duas tabelas. E a mesma fonte atravessa fronteiras
temáticas: o SIM é extraído em Saúde e em Segurança, o IDEB aparece em três lugares diferentes.

A dimensão é um agrupamento temático imposto sobre fontes que têm chaves, periodicidades e
granularidades distintas. É uma categoria útil para *navegar* e péssima para *processar*.

Na prática, a estrutura fica assim:

```
dados/fonte/03_meio_ambiente/s2id_desastres.parquet
dados/fonte/03_meio_ambiente/snis_saneamento.parquet
dados/fonte/03_meio_ambiente/prodes_desmatamento.parquet
dados/fonte/03_meio_ambiente/adapta_riscos.parquet

dados/dimensao/03_meio_ambiente.parquet   # gerado a partir das quatro acima
```

A tabela de dimensão é sempre gerada a partir das de fonte, nunca o contrário, por uma função
`mape_consolidar_dimensao()`. E a documentação dela declara explicitamente que quatro fontes com
coberturas diferentes foram unidas — informação que hoje é invisível para quem baixa a base.

Aplicando aos dois casos difíceis: em Saúde, migram três fontes (SI-PNI, e-Gestor e IEPS) e as três
mortas ficam de fora. Os oito conceitos duplicados são resolvidos na camada de fonte, com nomes
distintos, e a tabela de dimensão carrega os dois — porque, como mostrei na seção 1.2, eles são
medições genuinamente diferentes, não versões concorrentes de um número só.

## 3.2 O que fazer com os municípios que mudam ao longo do tempo

**Recomendo manter o produto cartesiano de 5.570 municípios por 33 anos, mas acrescentar uma coluna
`flag_municipio_instalado` e passar a reportar os códigos que não existem no diretório em vez de
descartá-los silenciosamente.**

O diretório é um retrato dos 5.570 municípios de hoje, mas o painel começa em 1991, quando existiam
cerca de 4.491. Mojuí dos Campos foi criado em 2013. O pipeline atual finge que os 5.570 sempre
existiram, e não há como distinguir um vazio causado por "o município ainda não existia" de um
vazio causado por "a fonte não cobre esse município".

Respeitar o ano de instalação e produzir um painel desbalanceado seria mais correto do ponto de
vista conceitual, mas quebraria todo consumidor que espera 5.570 linhas por ano. A coluna de flag
preserva o formato e torna a distinção explícita e verificável, ao custo de uma coluna e de uma
pequena tabela com o ano de instalação de cada município.

A parte mais importante desta decisão, porém, é o tratamento dos códigos órfãos. Hoje eles somem: a
junção usa `left_join` contra a lista de municípios, e o que não casa desaparece sem contagem, sem
log e sem aviso. Passam a ser reportados por uma função de validação que grava um relatório e
falha se o volume ultrapassar um limiar declarado. Caso a caso:

Os **27 códigos de UF** que aparecem na Segurança (`1100000`, `1200000`, até `5300000`) não são
municípios e vão para uma tabela separada, em nível de UF. Os **43 pseudo-códigos sub-municipais do
Rio de Janeiro** são reagregados para o código `3304557`, o que corrige a subestimação de 97% na
mortalidade daqueles três anos. Os **27 `muncode` fora do diretório** nos dados históricos são
municípios extintos e vão para uma tabela de linhagem, com chave própria. E as **42 linhas da
população e 81 do RH com identificador nulo** são eliminadas na origem, já que são linhas fantasma
de planilha, com a contagem registrada no relatório.

Desmembramentos e fusões ficam **fora de escopo** nesta rodada, registrados como pendência
conhecida. Construir Áreas Mínimas Comparáveis de forma consistente é um projeto próprio, e a
dimensão 16 já traz `amc1920` como chave alternativa para quem precisar. O que a documentação
precisa dizer, e hoje não diz, é que séries longas atravessam fronteiras territoriais que mudaram.

## 3.3 Guardar o dado observado ou o painel expandido?

**Recomendo que as tabelas canônicas guardem apenas o que foi observado, com uma coluna
`ano_ref_<fonte>` registrando o ano da medição original. A expansão passa a ser uma função.**

Os sete trechos de expansão da seção 2.4 fazem, no fundo, a mesma coisa: pegam uma ou duas
observações e as repetem para preencher um intervalo de anos. Guardar isso significa guardar a
mesma linha vinte vezes e chamar o resultado de painel.

O efeito no tamanho das tabelas é grande:

| Caso | Linhas hoje | Linhas canônicas | Redução |
|---|---|---|---|
| Sociedade (IVS de 2000 e 2010) | 111.300 | 11.140 | 90% |
| AdaptaBrasil (retrato de 2015) | 61.270 | 5.570 | 91% |
| Educação (IDEB bienal) | 111.388 | 55.694 | 50% |
| Transportes (adesões à tarifa zero) | 183.814 | cerca de 1.700 | 99% |
| Habitação (contratos do MCMV) | 94.832 | só município-ano com contrato | cerca de 40% |

Quem quiser o painel cheio continua tendo acesso a ele, chamando `mape_expandir_painel()`, que
sempre cria uma coluna `flag_imputado_<variável>` e preserva o ano de referência original. A
diferença é que agora existe também o caminho inverso: pela primeira vez alguém consegue olhar
apenas para as medições reais.

Esta decisão resolve de quebra dois defeitos que hoje parecem independentes. O preenchimento de
27.850 zeros na Educação e a cobertura fictícia de 100% em Transportes deixam de ser efeitos
colaterais de um intervalo de índices e passam a ser uma escolha declarada, registrada no campo
`regra_preenchimento_temporal` da documentação da tabela, com justificativa obrigatória.

## 3.4 Guardar valores nominais ou deflacionados?

**Recomendo que o valor canônico seja o nominal, e que a deflação seja aplicada por função, gerando
uma coluna adicional.**

Como descrevi na seção 1.4, oito scripts aplicam o deflator e sobrescrevem a coluna original com o
mesmo nome. Isso tem três consequências que se somam. O valor corrente não existe mais em lugar
nenhum do repositório — recuperá-lo exige reextrair a fonte. Atualizar a base para uma nova base de
deflação mudaria retroativamente números que já foram publicados no artigo e no blog. E nada, em
nenhum campo de metadado, registra que a operação aconteceu: a palavra "IPCA" não aparece no
documento mestre de metadados.

A alternativa de guardar só o nominal seria conceitualmente mais limpa, mas empurraria para cada
consumidor o trabalho de deflacionar, o que é uma regressão de usabilidade.

A convenção de nomes fica assim: `<variável>_brl_nominal` para o canônico, sempre presente, no valor
corrente do ano da observação, e `<variável>_brl2023` para o derivado, com o ano-base escrito no
próprio nome. O ano-base vive num único lugar, `config/parametros.yml`, e o campo
`ano_base_deflator` da documentação é gerado a partir dele. Trocar a base de deflação passa a ser
editar uma linha e regerar.

Isso corrige também o deflator ancorado no ano errado na Corrupção, porque a função recebe
explicitamente qual coluna de data usar como referência, em vez de assumir.

## 3.5 O que acontece com a base larga de 451 colunas

**Recomendo que ela continue existindo, mas como artefato derivado, gerado por função e publicado
como anexo de release. Ela deixa de ser a fonte de verdade e deixa de ser versionada no git.**

Há bons argumentos para matá-la: metade das células é vazia e ela ocupa 431 MB. Mas ela tem três
consumidores de código e um artigo publicado, e eliminá-la agora quebraria tudo isso em troca de
nada. Como artefato gerado, ela custa um comando e continua disponível para quem prefere trabalhar
assim.

```r
mape_montar_base_larga(dimensoes = NULL, ano = 1991:2023)   # NULL significa todas
```

As dezessete flags `dimensao_*` deixam de existir como colunas. A justificativa é acumulativa:
elas nascem todas dentro do arquivo de junção e não nos scripts de dimensão, são codificadas como
`1` ou `NA` (nunca `0`, o que impede somá-las diretamente), três delas têm o nome errado
(`dimensao_identificao`, `dimensao_assistencia_direitos_humanos`, `dimensao_historica`), e nenhum
consumidor as usa — confirmei por busca em todos os scripts.

No lugar delas entra uma função `mape_cobertura()`, que devolve uma tabela de dimensão por ano com
o número de municípios cobertos e o percentual, calculada a partir da presença real nas tabelas de
fonte. Quem precisar das flags na base larga pode pedir `mape_montar_base_larga(flags = TRUE)`, e
elas voltam com nome correto e codificadas como `0` e `1`.

## 3.6 Como uma pessoa de fora obtém uma tabela

**Recomendo as três camadas em conjunto: repositório, releases do GitHub e um pacote R leve.** Você
já decidiu que o GitHub é suficiente e que não é preciso depósito citável com DOI, então descarto
Zenodo e OSF.

No **repositório** ficam as tabelas de fonte e de dimensão em Parquet, sempre que couberem no
limiar de tamanho da seção 10, mais todo o dicionário. Custo operacional zero, porque é o que já
existe hoje.

Nos **releases do GitHub** fica um arquivo por tabela, mais a base larga, mais um `SHA256SUMS.txt`.
O custo é um comando por publicação, automatizável.

O **pacote R** é o que torna o objetivo de acesso modular real. É a camada mais cara — um pacote a
manter — mas sem ela "baixar só meio ambiente" continua significando "saber navegar a estrutura de
diretórios do ETL".

As assinaturas que proponho:

```r
mape_ler(tabela, versao = "latest", fonte = FALSE)
```

Recebe `"meio_ambiente"` para uma dimensão, ou `"03_meio_ambiente/snis_saneamento"` com
`fonte = TRUE` para uma fonte específica. Baixa do release, guarda em cache local e aplica os tipos
declarados no dicionário.

```r
mape_juntar(tabelas, by = c("id_municipio", "ano"), tipo = "full")
```

Esta é a função que precisa ser cuidadosa, porque é onde as granularidades incompatíveis da seção
2.3 se encontram. Ela valida a cardinalidade antes de juntar e **recusa** combinações que
produziriam resultado enganoso. Se alguém pedir os dados históricos, que não têm coluna de ano, ela
exige que a junção seja explicitamente por município e avisa que os valores serão replicados em
todos os anos. Se alguém pedir a geolocalização, ela exige que a versão da malha seja especificada.
Se alguém pedir a Corrupção, que cobre 0,8% do painel, ela avisa quantos vazios serão gerados. O
resultado vem com um atributo `mape_relatorio` contendo a contagem de linhas antes e depois de cada
junção.

```r
mape_dicionario(tabela = NULL)   # o dicionário como data.frame
mape_cobertura()                 # substitui as flags dimensao_*
```

Vale deixar claro na primeira tela do README uma coisa que hoje não está dita em lugar nenhum:
**quem apenas consome os dados nunca precisa de credencial do Google Cloud.** A autenticação só é
necessária para quem vai atualizar uma fonte que vem do BigQuery.

## 3.7 Os tipos das chaves

**Confirmo `id_municipio` como texto de sete dígitos e fixo `ano` como inteiro.**

O `CLAUDE.md` já declara `id_municipio` como texto, e a decisão está certa por dois motivos. O
primeiro é preservar zeros à esquerda em qualquer conversão que passe por numérico. O segundo, mais
conceitual, é que código não é quantidade — nada deveria jamais somar ou tirar média de um
identificador municipal.

O `ano` é o problema maior. Hoje ele aparece como `numeric`, `character`, `integer` e `integer64`
conforme a dimensão, e a junção geral compensa isso com doze conversões `as.character(ano)`
espalhadas pelo arquivo. Uma dessas junções, a terceira, funciona sem conversão nenhuma — e funciona
por acidente. O arquivo do PIB foi gravado em `.xlsx`, e a leitura devolve `ano` como texto porque o
`integer64` original foi serializado como string. Se alguém regravar aquele arquivo com o ano como
número, a junção quebra.

O `integer64` merece um aviso próprio porque é uma armadilha ativa e silenciosa. Em
`populacao.RData`, chamar `as.numeric(ano)` devolve `9.83e-321`. Em `instituicoes.RData`, `sort()` e
`range()` sobre `ano` devolvem lixo, sem erro. A função de normalização de chaves converte
`integer64` para `integer` explicitamente, sempre.

Falta resolver a convivência com o `geobr`. Os consumidores fazem
`left_join(muni_sf, by = c("id_municipio" = "code_muni"))`, e isso funciona hoje por coincidência: o
CSV entrega o identificador como inteiro e o `geobr` também usa inteiro; no `.RDa` ele é texto. Em
vez de resolver deixando o tipo ambíguo, proponho uma função explícita:

```r
mape_para_geobr(x)   # devolve x com id_municipio como inteiro, pronto para o join
```

## 3.8 Formato de armazenamento

**Recomendo Parquet como formato canônico, CSV comprimido como formato de exportação, e a
eliminação completa do `.xlsx` do pipeline.**

O `.xlsx` precisa sair por três razões independentes. Ele não preserva tipos. Ele é ineficiente —
`meio_ambiente.xlsx` ocupa 65,7 MB contra 10,1 MB do `.RData` equivalente. E, o mais grave, o
pipeline atual *depende* de um acidente de serialização do `.xlsx` para funcionar, como descrevi na
decisão anterior.

O `.RData` preserva tipos e comprime bem, mas só serve ao R, é opaco (não dá para inspecionar sem
carregar) e o `load()` injeta nomes no ambiente em vez de devolver um objeto.

O CSV não preserva tipos e é onde nasce a coluna fantasma. Ele continua sendo útil como formato de
troca, mas não pode ser canônico.

O Parquet preserva tipos, comprime melhor que todos os outros e é lido por R (via `arrow`), Python e
Stata.

Uma consequência prática que precisa estar no plano de QA: **os quatro formatos publicados hoje não
são equivalentes entre si.** O CSV ganha a coluna sem nome e converte `id_municipio`, `ano`,
`id_municipio_6` e `ddd` de texto para inteiro; o `.RDa` mantém texto. Qualquer tutorial escrito para
um formato quebra no outro. Por isso a seção 11 inclui um teste que relê cada arquivo exportado e
compara o schema com o canônico.

## 3.9 Quais tabelas vão existir

Em todas elas, `id_municipio` é texto de sete dígitos e `ano` é inteiro.

### A espinha

| Tabela | Chave | Granularidade | Linhas |
|---|---|---|---|
| `00_diretorios/municipios` | `id_municipio` | transversal | 5.570 |
| `00_diretorios/municipios_ano` | `id_municipio, ano` | esqueleto do painel, com `flag_municipio_instalado` | 183.810 |
| `00_diretorios/geolocalizacao` | `id_municipio, versao_malha` | por versão de malha, não por ano | 11.139 |
| `00_diretorios/linhagem_historica` | `id_municipio_historico` | municípios extintos e AMC | cerca de 5.600 |

O diretório passa a ser o **único dono** das chaves e do bloco territorial. Nenhuma tabela de fonte
replica as 26 colunas cadastrais. Essa regra sozinha elimina as dez cópias de `diretorios.xlsx` e os
três cortes por índice na junção, porque não haverá mais nada a cortar.

### As tabelas de fonte

Uma por fonte viva. As mortas da seção 2.5 não migram.

| Dimensão | Tabelas | Chave | Observação |
|---|---|---|---|
| 02 populacao | `ibge_populacao`, `censo_religiao` | `id_municipio, ano` / `id_municipio, ano_ref_censo` | |
| 03 meio_ambiente | `s2id_desastres`, `snis_saneamento`, `prodes_desmatamento`, `adapta_riscos` | `id_municipio, ano`; o AdaptaBrasil usa `ano_ref_adapta = 2015` | |
| 04 economia | `ibge_pib` | `id_municipio, ano` | |
| 05 sociedade | `ipea_ivs` | `id_municipio, ano_ref_ivs` | 11.140 linhas |
| 06 financas | `siconfi_receitas`, `cgu_emendas` | `id_municipio, ano` | 222 chaves duplicadas a resolver na origem |
| 07 recursos_humanos | `munic_rh` | `id_municipio, ano` | |
| 01 assistencia_dh | `cadunico`, `disque100`, `munic_dh` | `id_municipio, ano` | `cadunico` já migrado |
| 08 energia_internet | `anatel_banda_larga`, `anatel_telefonia_movel`, `lpt_domicilios`, `censo_eletricidade` | `id_municipio, ano` | |
| 09 educacao | `inep_ideb`, `inep_censo_superior` | `id_municipio, ano_ref_ideb` | só anos ímpares |
| 10 saude | `pni_imunizacoes`, `egestor_atencao_basica`, `ieps_indicadores` | `id_municipio, ano` | |
| 11 transportes | `mobilidados_tarifas`, `tarifa_zero_eventos` | `id_municipio, ano` / `id_municipio` | 27 municípios; eventos |
| 12 habitacao | `mcmv_fgts_contratos` | `id_municipio, ano` | só a faixa FGTS; ver 3.10 |
| 13 seguranca | `sim_obitos`, `fbsp_ocorrencias` | `id_municipio, ano` | FBSP cobre 27 municípios |
| 14 corrupcao | `cgu_fiscalizacao` | `id_municipio, ano` | 1.516 linhas |
| 15 dados_historicos | `hist_kustov_pardelli`, `hist_linhagem_ibge` | `id_municipio`, sem ano | |
| 16 eleicoes | `tse_prefeito`, `tse_camara` | `id_municipio, ano_ref_eleicao` | |

### As tabelas que não são municipais

Hoje esses dados estão escondidos dentro de tabelas municipais, e é por isso que ninguém percebe que
eles existem.

| Tabela | Chave | De onde vem hoje |
|---|---|---|
| `uf/fbsp_ocorrencias_uf` | `sigla_uf, ano` | os 27 códigos de UF disfarçados de município na Segurança |
| `uf/tse_governadores` | `sigla_uf, ano_ref_eleicao` | as 7 variáveis replicadas em todos os municípios do estado |

## 3.10 Escopo declarado: a Habitação cobre só o MCMV/FGTS

Como a faixa subsidiada do MCMV não existe no repositório — o arquivo que deveria contê-la é byte a
byte idêntico ao do FGTS —, a dimensão passa a **declarar explicitamente** o que cobre, em vez de
deixar o escopo implícito num nome genérico.

Na prática isso significa três coisas. A tabela de fonte se chama `mcmv_fgts_contratos`, e não
`mcmv_financiado`. As colunas ganham o prefixo `mcmv_fgts_`, de modo que `val_contratado` vira
`mcmv_fgts_valor_contratado_brl_nominal` — hoje o nome genérico sugere que a coluna cobre o programa
inteiro. E a documentação da tabela registra a ausência da faixa OGU/FAR como limitação conhecida,
no campo `observacoes`, em vez de deixar quem usa descobrir sozinho.

A faixa subsidiada fica registrada como pendência. Recuperá-la é obter uma fonte nova, pelo
procedimento da seção 8.2, e não parte desta migração.

## 3.11 Quem é dono de cada indicador compartilhado

A regra é simples: cada indicador tem exatamente uma tabela dona, e quem mais precisar dele faz a
junção.

O caso testemunha é a **população**, e ele vale ser contado por inteiro porque mostra como um
problema de propriedade vira um problema de reprodutibilidade. A população é produzida duas vezes: a
consulta em `pib_municipal.R:85-98` é cópia literal da consulta em `populacao_brasileira.R:12-25`. A
mesma tabela do BigQuery é faturada duas vezes, e as duas séries resultantes são idênticas em 100%
das 127.786 linhas comparáveis. A cópia que vem junto do PIB serve para calcular `pib_per_capita` e
é descartada logo depois, em `municipalityBR.qmd:97`. O resultado é que **`pib_per_capita` não é
reproduzível a partir da base publicada**: o denominador usado não está lá.

Com dono único, a população passa a pertencer a `02_populacao/ibge_populacao`, e o PIB per capita é
calculado por junção explícita, com o denominador visível.

Os demais casos: o bloco territorial inteiro (`sigla_uf`, `nome_municipio`, hierarquias) pertence a
`00_diretorios` — hoje a versão publicada de `sigla_uf` vem do IEPS. Os óbitos do SIM pertencem a
`13_seguranca/sim_obitos`, e a extração paralela na Saúde é descartada. A área do município pertence
a `00_diretorios`, e não a um arquivo de download manual cuja coluna tem o ano embutido no nome
(`AR_MUN_2022`). E `ano_eleicao` pertence a `16_eleicoes`, sendo hoje definido em três lugares, um
deles um script de análise que o sobrescreve com outra regra.

---

# 4. Árvore de diretórios e convenção de nomes

## 4.1 O que fazer com a convenção que já está commitada

A árvore nova já tem uma convenção em uso, documentada no `CLAUDE.md` e materializada em quinze
arquivos rastreados. Avaliei cada item dela contra os objetivos.

**Mantenho** a estrutura `NN_<dimensao>/NN_<fonte>/`, o snake_case sem acento com prefixo numérico, o
uso de `here()` a partir da raiz e a chamada `get_billing_id()`. São escolhas boas.

**Ajusto** três coisas. A pasta `processed/` dentro de cada fonte espalha os dados publicáveis por
quarenta diretórios, o que obriga quem só quer um arquivo a entender a estrutura interna do ETL —
proponho separar código de dado, como explico em 4.4. A saída passa de CSV para Parquet, pelas razões
da decisão 3.8. E `get_billing_id()`, embora resolva a configuração, não registra *qual* projeto e
*qual* conta geraram cada extração, então acrescento uma camada de proveniência na seção 5.

**Mudo** duas. O nome de script `script.R` sai, pelo que argumento em 4.2. O sufixo `_i`/`_d` é
generalizado para um vocabulário maior, pelo que argumento em 6.2.

**Restrinjo** a política de commitar dados brutos e processados, na seção 10.

Vale registrar que a convenção **já é violada pelo próprio código commitado**. O
`00_diretorios/R/script.R` grava com caminho relativo nu (`save(diretorios, file = "processed/diretorios.RData")`
e `write.xlsx(diretorios, "processed/diretorios.xlsx")`), sem `here()`, e produz `.RData` e `.xlsx`
em vez de CSV. Corrigir isso são duas linhas.

A violação mais cara é a do CadÚnico, e ela é conceitual: como os nomes de coluna vêm prontos do
arquivo bruto, o script não implementa a convenção que aparenta implementar. Corrigir exige escrever
o `rename()` explícito — que precisa passar a existir de qualquer forma, porque sem ele não há nada
garantindo o padrão na próxima fonte.

## 4.2 O nome dos scripts

**Recomendo nomear os scripts pelo que eles fazem, abandonando o `script.R` único.**

O argumento a favor do `script.R` é real: o caminho já identifica a fonte, e não é preciso decidir um
nome a cada arquivo. Mas ele tem três custos que se acumulam conforme o projeto cresce.

O primeiro é que `grep` deixa de funcionar como ferramenta de navegação — procurar por `script.R`
casa com tudo. O segundo é que quarenta abas do editor passam a se chamar "script.R", e a única
forma de distingui-las é ler o caminho completo na barra de título. O terceiro, e decisivo dado que
você escolheu `targets`, é que cada alvo do orquestrador precisaria repetir o caminho inteiro para
se referir a um script.

Não vale a pena comparar com o legado, que simplesmente não tem padrão: convivem lá
`municipalityBR.qmd`, `renomear_variaveis.R`, `analise nota técnica.R` (com espaço e acento) e
`codigo templos por municipio.R`.

O padrão que proponho é `<verbo>_<objeto>.R`, com o verbo saindo de um vocabulário fechado de cinco
opções:

- `extrair_` obtém o dado bruto da fonte, seja por BigQuery, download ou leitura de `raw/`;
- `tratar_` limpa, renomeia, tipa e valida, produzindo a tabela de fonte;
- `consolidar_` junta fontes para produzir a tabela de dimensão;
- `montar_` gera artefatos derivados, como a base larga;
- `validar_` roda as checagens de qualidade.

Na prática: `extrair_cadunico.R`, `tratar_cadunico.R`, `consolidar_assistencia_social_dh.R`,
`montar_base_larga.R`.

## 4.3 O vocabulário de dimensões

Hoje existem **quatro grafias concorrentes** para os nomes das dimensões: uma na planilha de
metadados (`Corrupção e Transparência`, `Dados históricos`, `Transporte`), outra no dicionário
(`Corrupção`, `História`, `Transportes`), outra nas pastas do legado
(`15 Corrupção e Transparência - Códigos e Dados`) e uma quarta na árvore nova, que além de grafia
diferente usa **numeração diferente** — no legado a Identificação é a 1 e a Assistência Social é a 8,
enquanto na árvore nova são `00` e `01`.

Um único vocabulário passa a governar, ao mesmo tempo, o nome da pasta, o nome do script, o nome da
tabela publicada e o campo `dimensao` da documentação. Ele vive em `dicionario/dimensoes.csv` e é
**lido pelo código**, nunca redigitado.

| Slug | Rótulo publicado | Nº no legado |
|---|---|---|
| `00_diretorios` | Identificação e diretórios | 1 |
| `01_assistencia_social_dh` | Assistência Social e Direitos Humanos | 8 |
| `02_populacao` | População | 2 |
| `03_meio_ambiente` | Meio Ambiente | 3 |
| `04_economia` | Economia | 4 |
| `05_sociedade` | Sociedade | 5 |
| `06_financas` | Finanças Municipais | 6 |
| `07_recursos_humanos` | Recursos Humanos | 7 |
| `08_energia_internet` | Energia e Internet | 9 |
| `09_educacao` | Educação | 10 |
| `10_saude` | Saúde | 11 |
| `11_transportes` | Transportes | 12 |
| `12_habitacao` | Habitação | 13 |
| `13_seguranca` | Segurança | 14 |
| `14_corrupcao` | Corrupção e Transparência | 15 |
| `15_dados_historicos` | Dados Históricos | 16 |
| `16_eleicoes` | Eleições | 17 |

A renumeração adotada na árvore nova é **definitiva**, com uma única correção:
`01_assistencia_social_direitos_humanos` encurta para `01_assistencia_social_dh`, porque o nome atual
tem 38 caracteres e aparece em todo caminho de arquivo. O custo é renomear uma pasta commitada e
ajustar dois caminhos `here()` no script do CadÚnico.

Uma observação de escopo que precisa de decisão sua: a dimensão 13 se chama "Habitação e Zoneamento"
e não contém nenhum dado de zoneamento. Deixei o rótulo como "Habitação" na tabela acima, mas isso é
uma decisão sua, não minha.

## 4.4 A árvore alvo

```
MAPEmunicipios-ETL/
├── MAPEmunicipios.Rproj          # âncora do here() — exige editar o .gitignore
├── _targets.R                    # o grafo de dependências
├── renv.lock
├── config/
│   └── parametros.yml            # base do deflator, anos do painel, limiares de QA
├── R/                            # funções comuns, sem efeito colateral
│   ├── bigquery.R  deflacao.R  chaves.R  io.R  sentinelas.R
│   └── joins.R     proveniencia.R  painel.R  dicionario.R
├── dicionario/                   # a fonte de verdade da documentação
│   ├── dimensoes.csv  tabelas.csv  variaveis.csv  conceitos.csv
│   ├── deprecacao.csv
│   └── proveniencia.csv          # gerado
├── fontes/                       # o código do ETL, uma pasta por fonte
│   └── 03_meio_ambiente/
│       └── snis_saneamento/
│           ├── R/extrair_snis.R
│           ├── R/tratar_snis.R
│           ├── raw/              # não versionado
│           ├── MANIFESTO.yml     # origem, versão, checksum
│           └── README.md         # gerado a partir do dicionário
├── dados/
│   ├── fonte/<dimensao>/<fonte>.parquet
│   ├── dimensao/<dimensao>.parquet
│   └── derivado/base_larga.parquet    # não versionado
├── tools/hooks/                  # hooks versionados; instalar.sh os copia para .git/hooks
├── analise/                      # separado do ETL, nunca roda no pipeline
├── plano/
└── mape_municipios/              # o legado, ignorado pelo git
```

Duas separações nessa árvore não são cosméticas.

A primeira é entre `fontes/` (código) e `dados/` (dado). Hoje o `processed/` mora dentro da pasta da
fonte, o que significa que encontrar um arquivo publicado exige conhecer a organização interna do
ETL.

A segunda é `analise/` fora do pipeline. São cerca de 400 KB de código de análise e replicação hoje
dentro da árvore de ETL que consultam o BigQuery se alguém rodar por engano. Separá-los fisicamente
é pré-requisito, não faxina.

---

# 5. A camada de funções comuns

Estas funções vivem em `R/`, não têm efeito colateral e são testadas com `testthat`. Cada uma
elimina uma classe inteira de defeito, e por isso listo ao lado de cada uma o que ela resolve.

### Acesso ao BigQuery

```r
mape_billing_id()
```

Resolve o projeto de faturamento em cascata: primeiro a variável `MAPE_GCP_BILLING` do `.Renviron`,
depois `config/parametros.yml`, depois `get_billing_id()`. Se nenhum resolver, emite um erro que
diz o que fazer. Isso elimina os quatro projetos escritos no código.

```r
mape_query(sql, fonte, .cache = TRUE)
```

Executa a consulta e registra a proveniência: qual projeto, qual conta, quando, quantos bytes foram
faturados e o hash do SQL, tudo em `dicionario/proveniencia.csv`. Esta é a parte que
`get_billing_id()` sozinho não cobre — ele resolve a configuração, mas não deixa registro de quem
gerou cada extração, e hoje **nenhuma data de extração existe em lugar nenhum do projeto**.

### Deflação

```r
mape_deflacionar(x, cols, data_ref, base = mape_param("deflator_base"))
```

Cria colunas novas com sufixo `_brl<ano>` e nunca sobrescreve o valor nominal. O argumento
`data_ref` é explícito, o que corrige o caso da Corrupção, onde o deflator usa o ano da fiscalização
quando deveria usar o ano do repasse. Elimina as oito ocorrências da constante `"12/2023"`.

### Chaves e tipos

```r
mape_normalizar_chaves(x, id = "id_municipio", ano = "ano")
```

Converte `id_municipio` para texto de sete dígitos com zeros à esquerda e `ano` para inteiro,
tratando `integer64` explicitamente. É aplicada **na saída de cada fonte**, e não na entrada de cada
junção — que é a diferença entre uma regra e doze remendos.

```r
mape_id7_de_id6(x, col)
```

Recupera o código de sete dígitos a partir do de seis, via diretório. É o padrão que o CadÚnico já
usa, agora com relatório de não-casados em vez de produzir `NA` em silêncio.

```r
mape_validar_dominio_chave(x, reportar = TRUE)
mape_para_geobr(x)
```

A primeira faz `anti_join` contra o diretório e **reporta** os órfãos. A segunda resolve a
dependência de tipo no join externo com o `geobr`.

### Leitura e escrita

```r
mape_escrever_tabela(x, tabela, formatos = c("parquet", "csv.gz"))
mape_ler_tabela(tabela, aplicar_tipos = TRUE)
```

A função de escrita valida contra o dicionário antes de gravar, garante `row.names = FALSE` e grava
o schema junto. Se o schema divergir do declarado, ela falha em vez de gravar.

### Valores sentinela

```r
mape_tratar_sentinelas(x, mapa = mape_param("sentinelas"))
```

Converte `"NaoDisponivel"`, `"Ignorado"`, `"-"`, string vazia e `-999` para `NA`. Isso resolve o caso
das duas colunas irmãs do AdaptaBrasil, em que `indice_risco_seca` é numérica e
`indice_risco_inundacoes_enxurradas` é texto porque carrega um sentinela textual — hoje o consumidor
remenda isso à mão no próprio script de análise.

### Junções

```r
mape_join(x, y, by, tipo = c("left","full","inner"),
          relationship = "one-to-one", esperado_linhas = NULL)
```

Declara a cardinalidade esperada, confere a contagem de linhas antes e depois, e reporta órfãos dos
dois lados. Falha se a cardinalidade declarada for violada. Nenhuma das dezesseis junções atuais
declara nada disso, e não há um único `stopifnot` no arquivo de junção.

### Painel

```r
mape_esqueleto_painel(anos = mape_param("anos_painel"))
mape_expandir_painel(x, de = "ano_ref_censo", para = anos,
                     metodo = c("replicar", "carry_forward"))
```

Estas duas substituem as sete cópias descritas na seção 1.4. A de expansão sempre cria
`flag_imputado_<variável>` e preserva a coluna de ano de referência.

### Dicionário

```r
mape_aplicar_renomeacao(x, tabela)
mape_validar_schema(x, tabela)
mape_gerar_documentacao(tabela)
```

São as funções que fazem o dicionário funcionar como entrada do pipeline: renomear a partir dele,
validar contra ele e gerar a documentação publicada a partir dele.

---

# 6. Nomenclatura e harmonização de colunas

## 6.1 O padrão

```
[<prefixo_fonte>_]<conceito>[_<qualificador>]_<sufixo_tipo>
```

Tudo em snake_case, sem acento, sem ponto, em ASCII e minúsculo. Sem abreviação inventada:
`cob_ab` vira `cobertura_atencao_basica_pct`, e `tx_mort_csap` vira
`taxa_mortalidade_csap_p100k`.

O **prefixo de fonte é obrigatório** quando mais de uma fonte mede o mesmo conceito — os casos são
`pni_` contra `ieps_` na Saúde, `sim_` contra `fbsp_` na Segurança, e `anatel_bl_` contra
`anatel_tm_` em Energia e Internet. Quando a fonte é única, o prefixo é opcional.

Alguns nomes ficam **reservados** e não podem ser usados como nome de variável em nenhuma tabela:
`id_municipio`, `ano`, `sigla_uf`, `nome_municipio` e o restante do bloco territorial. Eles
pertencem ao diretório, e só ele os publica.

A regra mais importante desse conjunto é que **`ano` só existe como chave do painel**. Todo outro
ano vira `ano_ref_<fonte>`. Hoje convivem seis colunas de ano sem escopo nenhum: `ano`, `ano_censo`,
`ano_avs`, `ano_ideb`, `ano_inicio` e `ano_eleicao`.

Dois prefixos ficam banidos. `total_` é usado em sete dimensões para coisas sem relação entre si —
contagem de desastres, valores em reais, número de instituições, óbitos, eleitores aptos. E
`quantidade_` é usado tanto para infraestrutura de saneamento quanto para ocorrências criminais.

## 6.2 Como isso se reconcilia com a convenção já commitada

A árvore nova usa prefixo de fonte com sufixo `_i` ou `_d`, como em
`cadun_qtd_familias_atualizadas_i`. Três perguntas precisam de resposta explícita.

**Prefixo ou sufixo de fonte?** Mantenho o **prefixo**. O motivo é prático: o prefixo agrupa
alfabeticamente na saída de `names()`, no autocompletar do editor e no dicionário. O caso mais forte
é Energia e Internet, onde dez das doze colunas são homônimas entre banda larga e telefonia móvel —
com prefixo, `anatel_bl_*` e `anatel_tm_*` ficam em blocos contíguos; com sufixo, ficariam
intercalados.

**Manter, generalizar ou abandonar o sufixo `_i`/`_d`?** **Generalizar.** O `_i`, para contagem
inteira, funciona bem e fica. O `_d`, descrito como "taxa ou derivada", é ambíguo por dois motivos:
ele mistura escala com proveniência, e não distingue uma proporção de 0 a 1 de um percentual de 0 a
100. Essa indistinção é exatamente o erro que hoje produz
`proporcao_cobertura_estrategia_saude_familia` numa escala de 0 a 100 e `pct_votos_eleito` numa
escala de 0 a 1, na mesma base.

O vocabulário fechado que proponho:

| Sufixo | Significado | Substitui |
|---|---|---|
| `_i` | contagem inteira | `_i`, mantido |
| `_prop` | razão de 0 a 1 | parte de `_d`, `proporcao_*`, `prop_*` |
| `_pct` | percentual de 0 a 100 | parte de `_d`, `pct_*`, `proporcao_*` |
| `_p100k` | por 100 mil habitantes | `tx_*` |
| `_p1k` | por mil habitantes | — |
| `_brl_nominal` / `_brl2023` | valor corrente / deflacionado | valores sem marca nenhuma |
| `_km`, `_km2`, `_ha` | unidades físicas | `extensao_*`, `area_*` |
| `_idx` | índice adimensional | `indice_*` |
| `_cat` | categórica | — |
| `flag_` (prefixo) | booleano 0/1 | `capital_uf`, `amazonia_legal` |

Hoje convivem oito prefixos concorrentes para grandezas relativas — `proporcao_`, `prop_`, `pct_`,
`taxa_`, `razao_`, `cob_`, `media_` e `indice_` — sem nenhuma correspondência com a escala real dos
valores. A vantagem do sufixo sobre o prefixo, neste caso específico, é que ele é **verificável por
teste automático**: dá para conferir que toda coluna terminada em `_pct` está entre 0 e 100 e toda
`_prop` entre 0 e 1.

Quanto à convivência com os campos `unidade` e `escala` do dicionário: o sufixo é a forma curta e
verificável, e o dicionário é a forma completa e autoritativa. A validação confere que os dois
concordam, e uma divergência entre eles interrompe a publicação.

**Quanto custa renomear o `cadunico.csv` já commitado?** Pouco. São dez colunas, e oito delas já
estão corretas sob o padrão novo, porque o `_i` é mantido. Mudam duas:
`cadun_taxa_atualizacao_cadastral_d` e `cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_d`, que
passam a terminar em `_pct` — olhei os valores (57,82 e 64,54 na primeira linha) e são percentuais de
0 a 100, não proporções. A mudança é um `rename()` no script, que precisa passar a existir de
qualquer forma.

## 6.3 O glossário de conceitos

O glossário vive em `dicionario/conceitos.csv`, com os campos `conceito`, `nome_canonico`,
`unidade`, `escala`, `dono` e `definicao`. Ele é o que permite decidir que dois nomes diferentes
descrevem a mesma coisa. Um extrato:

| Conceito | Nome canônico | Unidade | Dono |
|---|---|---|---|
| Código do município | `id_municipio` | texto de 7 dígitos | `00_diretorios` |
| População residente | `populacao_residente_i` | pessoas | `02_populacao` |
| População atendida por saneamento | `snis_populacao_atendida_<servico>_i` | pessoas | `03_meio_ambiente` |
| Área do município | `area_municipio_km2` | km² | `00_diretorios` |
| PIB | `pib_brl_nominal` e `pib_brl2023` | reais | `04_economia` |
| Cobertura vacinal | `pni_cobertura_<imuno>_pct` | percentual | `10_saude` |
| Óbitos | `sim_obitos_<recorte>_i` | contagem | `13_seguranca` |
| Ocorrências criminais | `fbsp_ocorrencias_<crime>_i` | contagem | `13_seguranca` |
| Ano da medição original | `ano_ref_<fonte>` | ano | cada tabela de fonte |

A distinção entre população residente e população atendida é o caso testemunha do glossário. Hoje a
coluna `populacao`, que é a população do município, convive com `populacao_urbana`,
`populacao_atendida_agua` e `populacao_atentida_esgoto`, que vêm do SNIS e medem população atendida
por um serviço. Nada nos nomes indica que são coisas diferentes.

## 6.4 Como resolver os oito pares da Saúde

Aqui é preciso cuidado, porque a premissa herdada estava errada. Os oito pares não estão em escalas
diferentes: ambos estão em percentual de 0 a 100. A diferença real é que o IEPS trunca os valores em
100 e o SI-PNI não trunca.

Para cinco imunobiológicos — BCG, pentavalente, poliomielite, hepatite A e tríplice viral primeira
dose — o canônico é a série do SI-PNI, `pni_cobertura_<imuno>_pct`, por ser a fonte primária e cobrir
1994 a 2021 nos 5.570 municípios. A série do IEPS é **mantida** ao lado, como
`ieps_cobertura_<imuno>_pct`, e a documentação registra que ela é truncada.

Para a **hepatite B**, os dois **não podem ser fundidos**: o indicador do IEPS mede apenas crianças
até 30 dias de vida, e a correlação entre as duas séries é de 0,061. Os nomes passam a ser
`pni_cobertura_hepatite_b_pct` e `ieps_cobertura_hepatite_b_ate_30d_pct`, deixando a diferença
visível no próprio nome.

Para atenção básica e Estratégia Saúde da Família, as duas séries vêm da mesma fonte primária (o
e-Gestor do Ministério da Saúde) com agregações diferentes, e ficam como
`cobertura_atencao_basica_pct` e `ieps_cobertura_atencao_basica_pct`.

Separadamente, o valor de 13.050% em `pni_cobertura_bcg_pct` vira uma regra declarada no dicionário
(`dominio_valido: [0, 200]`), com as violações reportadas no relatório de qualidade em vez de
silenciadas ou apagadas.

## 6.5 Onde a renomeação acontece

Dentro do script `tratar_<fonte>.R`, imediatamente depois da leitura do arquivo bruto e antes de
qualquer junção. Nunca por posição, nunca no fim do pipeline, nunca durante a junção.

```r
bruto |>
  janitor::clean_names() |>                       # normaliza caixa: ANO, Ano e ano
  mape_aplicar_renomeacao("snis_saneamento") |>   # a partir do dicionário
  mape_normalizar_chaves() |>
  mape_tratar_sentinelas() |>
  mape_validar_schema("snis_saneamento") |>
  mape_escrever_tabela("snis_saneamento")
```

O `clean_names()` na primeira linha resolve uma colisão real: há fontes em que o mesmo arquivo bruto
traz `Ano` e `ano` como colunas distintas, e outras em que o cabeçalho vem inteiramente em
maiúsculas.

Fixar a renomeação nesse ponto elimina, de uma vez, o vetor posicional de 451 nomes e os três blocos
de limpeza de colisão (`nome.x`, `nome.y`, `NOME_MUNICIPIO`) que hoje moram cinco junções depois de
onde as colisões nasceram.

## 6.6 O que fazer com os nomes públicos que já existem

Como você confirmou que o uso é interno e que dá para renomear, a política fica direta.

**Os erros de digitação são corrigidos.** `populacao_atentida_esgoto` vira
`snis_populacao_atendida_esgoto_i`; `total_institucoes` vira `censup_instituicoes_i`;
`proporcao_mortes_intenvencao_policial_x_mortes_violentas_intencionais` vira
`fbsp_prop_mortes_intervencao_policial_sobre_mvi_prop`; e `dimensao_identificao` simplesmente deixa
de existir, junto com as outras dezesseis flags.

**Os nomes que mentem também são corrigidos, e estes importam mais que os erros de digitação**,
porque um nome mal escrito confunde uma vez e um nome enganoso induz a erro sempre.
`total_receitas_fundeb` vira `siconfi_deducao_fundeb_brl_nominal`, porque é uma dedução.
`proporcao_votos_nulos_prefeitura` vira `eleicoes_votos_brancos_prefeito_pct`, porque contém brancos.
`sigla_uf_nome` vira `nome_uf`, porque o prefixo `sigla_` está num campo que guarda o nome por
extenso. E `id` vira `adapta_id_indicador`.

**Não haverá camada de compatibilidade em tempo de execução.** No lugar dela entra
`dicionario/deprecacao.csv`, com os campos `nome_antigo`, `nome_novo`, `tabela`, `versao_remocao` e
`motivo`. É documentação e insumo do teste de paridade, não código a manter.

Os três scripts de análise migram com um `rename()` gerado a partir dessa tabela. São cerca de
quarenta nomes em quatro arquivos.

O levantamento catalogou **292 nomes problemáticos**, dos quais 30 estão entre os efetivamente
consumidos. A tabela completa entra em `dicionario/deprecacao.csv` durante a Fase 2.
