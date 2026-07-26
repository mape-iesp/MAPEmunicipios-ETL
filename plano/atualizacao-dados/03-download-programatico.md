# 3. As fontes de download manual: como cada uma vira código

Nove fontes publicadas dependem hoje de alguém baixar um arquivo à mão. Cinco delas não têm nem o
arquivo: o manifesto existe, `arquivo_local` e `sha256` estão em branco, e o bruto original nunca
esteve neste repositório.

Este capítulo dá, para cada uma, o degrau-alvo da escada (§ 1.1), o que se sabe da origem **e o que
precisa ser descoberto**. As URLs abaixo são as que estão registradas em `MANIFESTO.yml` ou em
`dicionario/tabelas.csv` — nenhuma foi verificada contra a rede nesta análise. Verificá-las é a
primeira tarefa de cada frente.

## 3.1 O que a infraestrutura já resolve, e o que falta nela

`mape_baixar(url, fonte, arquivo, versao_fonte)` baixa, nomeia de forma estável, calcula o sha256 e
escreve tudo no manifesto. É o suficiente para o degrau 3. O que ele **não** faz, e que alguma
fonte vai exigir:

- **Não repete por edição.** Fontes publicadas em um arquivo por ano (MUNIC, Disque 100) precisam de
  um laço sobre edições, com um arquivo e um sha por edição. Hoje o manifesto guarda um
  `arquivo_local` só — para essas fontes, guarde uma lista, ou um manifesto por edição.
- **Não tem *retry*, *timeout* nem *user-agent*.** Usa `utils::download.file()`. Portais do governo
  caem; a extração precisa falhar alto, não pela metade.
- **Não faz POST nem sessão.** Portal que exige formulário está fora do alcance dele.

Se a extensão for necessária, ela vai em `R/ingestao.R`, ao lado de `mape_baixar()`, com teste — e
não copiada dentro de um `extrair_*.R`.

## 3.2 Fonte por fonte

### `05_sociedade/atlas_ivs` — sobe para o degrau 1

**A mais fácil, e por isso a primeira.** O Ipea publica o Atlas da Vulnerabilidade Social em
`ivs.ipea.gov.br`, mas o diagnóstico do legado registra `br_ipea_avs.municipio` na Base dos Dados.
**Se a tabela existir e bater, esta fonte deixa de ser download manual** e passa a ser BigQuery, com
todo o freio e todo o registro que isso traz.

- Alvo: **degrau 1**. Confirmar `br_ipea_avs.municipio` pela § 2.1.
- A decidir: a fonte é censitária (2000, 2010). O **Censo 2022** é uma edição nova — e uma edição
  nova de fonte censitária é `ano_ref` novo, não ano de painel (§ 1.7).

### `12_habitacao/mcmv_fgts` — prioridade alta, porque destrava um achado

- URL registrada: `https://www.gov.br/cidades/pt-br/acesso-a-informacao/dados-abertos`
- Alvo: **degrau 3** (HTTP em portal de dados abertos), degrau 2 se houver API.
- Por que é prioritária: o **achado 16** está aberto por falta desta planilha.
  `mcmv_valor_contratado_brl2023` atribui R$ 205,8 bilhões a um município-ano, e a assinatura é de um
  `gsub` de separador decimal aplicado na ordem errada. O relatório final é explícito sobre o
  procedimento: pôr a planilha em `raw/`, registrar o sha256, **reescrever a conversão de texto para
  numérico com parser explícito de locale**, e rodar `tools/validar_tudo.R`, onde o domínio
  `[0, 5000000000]` já dispara.
- Lembrete de escopo: a faixa subsidiada com OGU **não existe** no repositório e não é recuperável
  daqui (`pendencias/12_habitacao__mcmv_ogu.md`).

### `01_.../cadunico` — refazer a extração, não só baixar

- URLs registradas: `https://wiki-sagi.mds.gov.br/home/DS/Cad/I/IN004` (documentação do indicador) e
  `https://aplicacoes.mds.gov.br/sagi/vis/data3/` (aplicação de dados).
- Alvo: **degrau 2 ou 3**. Verificar se a aplicação do SAGI expõe endpoint estável.
- O trabalho não é baixar: é **reconstruir os dois passos que hoje vêm embutidos no arquivo**. A
  origem publica série **mensal** com código de **6 dígitos**. O que está em `raw/` é o retrato de
  dezembro, com 7 dígitos, já convertido pelo pipeline legado.
  1. Filtrar dezembro (ou decidir publicar a série mensal na camada de fonte, que é o que § 1.7
     recomenda — a fonte guarda o observado).
  2. `mape_id7_de_id6()` para a chave.
- Aceitação extra: a nova extração tem de reproduzir as 50.130 linhas × 5.570 municípios publicadas
  para 2015-2023, ou explicar a diferença antes de gravar.

### `01_.../disque100` — um leitor por edição

- URL registrada: `https://www.gov.br/mdh/pt-br/ouvidoria/dados-do-disque-100`
- Alvo: **degrau 3**, com laço por edição.
- O manifesto declara `automatizavel: nao`, e a razão está escrita nele: *"o portal publica os dados
  em planilhas anuais separadas, com layout que muda entre edições"*. O download é automatizável; o
  **parsing** é que não é uniforme.
- Padrão a seguir: baixar todas as edições programaticamente, e escrever um leitor por edição com o
  mapeamento de colunas **por nome**, nunca por posição. O mapeamento por posição é a causa direta do
  defeito de `administracao_indireta` na MUNIC.

### `03_meio_ambiente/adaptabrasil`

- URL registrada: `https://adaptabrasil.mcti.gov.br/`; o manifesto declara `automatizavel: sim`.
- Alvo: **degrau 2**. Verificar se o portal expõe API — o campo `automatizavel: sim` sugere que
  alguém já avaliou que sim, mas nada no repositório registra o endpoint.
- Natureza: retrato único de 2015, replicado de 2010 a 2020 na dimensão sem marcador de linha. Se a
  extração passar a trazer edições novas, **a expansão precisa marcar o que replicou** — a guarda
  existe em `R/painel.R` e é `mape_expandir_painel()` quem a aciona.

### `11_transportes/tarifa_zero`

- URL registrada: `https://tarifazero.org/`; `automatizavel: parcial`.
- Alvo: **degrau 3**, se houver arquivo publicado; degrau 5 caso contrário.
- Duas ressalvas antes de mexer: a **licença não é declarada** pelo Observatório (fica `A VERIFICAR`),
  e a tabela publicada **já vem expandida** — 578 linhas para 106 municípios, 81,7% de
  *carry-forward* (achado 33, aberto). A decisão de desenho vem antes da extração: ou a fonte guarda
  106 linhas (uma por evento) e a expansão passa para a dimensão, ou ela é assumidamente de duração
  de evento e a documentação para de usá-la como exemplo de "o observado".

### `11_transportes/tarifas` — degrau 5, e está certo assim

Levantamento próprio do MAPE a partir de decretos municipais, coletados um a um. **Não há fonte a
montante: o MAPE é a fonte.** 351 linhas, 27 municípios, 2005-2017.

O que fazer não é automatizar: é **registrar o procedimento de coleta** no `README.md` da fonte, pôr
a planilha de trabalho em `raw/` com sha256, e declarar a periodicidade real. Automatizar isto seria
raspar 27 diários oficiais municipais — custo alto, fragilidade alta, e a alternativa honesta é
dizer que a atualização é humana.

### `07_recursos_humanos` (MUNIC) — a maior das manuais

Doze arquivos `.xlsx`, um por edição, 194 MB, hoje sem URL, sem código de download, sem data e sem
checksum. Faltam as edições de **2010, 2016 e 2022**.

- Alvo: **degrau 3**. O IBGE publica a MUNIC em servidor de arquivos com caminho previsível por
  edição — confirmar o padrão e escrever o laço.
- Alternativa a investigar: a MUNIC pode estar espelhada na Base dos Dados. Se estiver, sobe para o
  degrau 1 e o problema de *parsing* some junto.
- **O defeito a não repetir:** o mapeamento de colunas é feito por posição (`A1` a `A65`), e os
  deslocamentos mudam entre 2011 e 2014 sem explicação. Foi assim que
  `administracao_indireta` virou numérica em 2011 (304 valores distintos) e categórica nos outros
  onze anos. Mapeie por nome de coluna, com asserção.
- Segundo defeito a não repetir: o `id_municipio` da MUNIC não vem do diretório, vem de um `merge`
  com a tabela de população, e o código original é descartado no `select` final. Qualquer par
  município-ano ausente da população **perde o identificador em silêncio**.

### `10_saude` (IEPS) e `06_financas` (emendas da CGU) e `14_corrupcao` (CGU)

Três fontes de portal, com o mesmo desenho de solução e prioridades diferentes:

| fonte | onde | alvo | ressalva |
|---|---|---|---|
| IEPS Data | portal do IEPS | degrau 3 | licença `A VERIFICAR` — organização privada, sem licença aberta explícita. **Resolver antes de republicar.** O legado tinha `setwd()` para um Google Drive do Windows |
| Emendas (CGU) | Portal da Transparência | degrau 2/3 | o plano original já a classificava como automatizável, por ter URL estável. Nome de arquivo com data embutida (`Emendas_CGU_8_10_2024.xlsx`) — a data vai para o manifesto, não para o nome |
| Fiscalização (CGU) | dados abertos da CGU | degrau 3 | granularidade nativa é **evento** (constatação → ordem de serviço → ciclo de sorteio). Agregar para município-ano é derivação, e pertence à dimensão |

### `03_meio_ambiente` — Atlas de Desastres, SNIS, PRODES

- **SNIS** e **PRODES** têm candidatos na Base dos Dados (`br_mdr_snis.municipio_agua_esgoto`,
  `br_inpe_prodes.municipio_bioma`): tentar o degrau 1 primeiro.
- **Atlas de Desastres** (SEDEC/MIDR + CEPED/UFSC) era classificado como automatizável por ter URL
  estável. Degrau 3, com a versão no manifesto (`BD_Atlas_1991_2023_v1.0_2024.04.29.xlsx` é
  exatamente o nome que o plano original manda parar de usar).

### `08_energia_internet` — o caso da dependência fora do CRAN

Quatro fontes: banda larga (Anatel/SCM), telefonia móvel (Anatel), Luz Para Todos e cobertura de
eletricidade dos censos.

- Anatel: procurar na Base dos Dados; degrau 1 se existir.
- **Luz Para Todos depende de `munifacil`, que não está no CRAN** e não está no `renv.lock`. Ou se
  encontra a fonte primária, ou a dependência entra por decisão registrada (§ 1.8).
- **Cobertura de eletricidade dos censos**: CSV local cujo DOI, no Harvard Dataverse, aparece só na
  planilha de metadados e nunca no código. O Dataverse tem API de download por DOI — este é um
  candidato claro a subir para o degrau 2, e a recuperar a procedência de uma vez.

### `15_dados_historicos` — não é automatizável, e a decisão é outra

Ver § 0.5. Sem pacote de replicação público e com a planilha do IBGE distribuída em CD-ROM, o
caminho não é técnico. As opções são: escrever aos autores, congelar a tabela e declarar isso no
`observacoes`, ou aposentá-la. **Não gaste tempo de engenharia aqui antes de a decisão existir.**

## 3.3 Critério de aceitação de uma fonte de download

Igual ao da § 2.6, com duas diferenças:

- **`MANIFESTO.yml` completo**: `url` (ou `indisponivel` com justificativa), `orgao`, `licenca`,
  `arquivo_local`, `versao_fonte`, `data_download`, `baixado_por`, `sha256` e `automatizavel`
  reavaliado — o campo hoje descreve a intenção do plano, não o que foi feito.
- **Se ficou no degrau 5**, o `README.md` da fonte traz o procedimento manual passo a passo, na forma
  em que um operador sem contexto o executa: onde clicar, que filtros marcar, com que nome salvar.
  A frase que resume a regra: *não vale escrever raspador frágil para substituir cinco linhas de
  instrução — mas as cinco linhas têm de existir.*
