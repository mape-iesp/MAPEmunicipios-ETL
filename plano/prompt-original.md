# Tarefa: elaborar um PLANO DETALHADO de reestruturação do ETL do MAPEmunicipios

**Você NÃO vai implementar nada nesta sessão.** Sua entrega é um documento de plano, bom o bastante para ser executado incrementalmente depois, por mim ou por outra pessoa, ao longo de várias sessões.

---

## 1. Contexto do projeto

O MAPEmunicipios é um banco de dados de informações municipais brasileiras: 17 dimensões temáticas (identificação, população, meio-ambiente, economia, sociedade, finanças, RH, assistência social/DH, energia e internet, educação, saúde, transportes, habitação, segurança, corrupção, dados históricos, eleições), consolidadas hoje numa **base larga única de 180.285 linhas × 451 colunas** (452 campos no header do CSV, por causa de um `write.csv` sem `row.names = FALSE`), na granularidade município × ano, cobrindo 1991-2023.

O pipeline atual é escrito em **R**. Há **duas árvores de arquivos** e é essencial não confundi-las.

### 1.1 Árvore legada — `mape_municipios/` (~18 GB, NÃO versionada)

```
mape_municipios/
  mape_municipios.Rproj                                   # âncora de here() — ver §5.7
  1 Dimensões Individuais/<n> <Nome> - Códigos e Dados/    # 17 pastas, uma por dimensão
  2 Junção Bases/municipalityBR.qmd                        # 16 joins encadeados, 543 linhas
  3 Renomear e excluir duplicados/renomear_variaveis.R     # renomeio POSICIONAL + distinct(), 203 linhas
  4 Base completa/                                         # SEM CÓDIGO — cópia da etapa 3
  5 Análise Exploratória de Dados/                         # consumidor
  6 Metadados/                                             # 4 planilhas + .docx mestre
  7 Textos Blog/                                           # consumidor
  Textos/                                                  # artigo publicado (.docx/.pdf, 5 versões) +
                                                           # "Tabelas e Quadros.docx" + Figuras 1-5
```

É a **fonte de verdade sobre o que o pipeline faz hoje** — leia à vontade, nada dela deve entrar no git.

**`mape_municipios/` NÃO está no `.gitignore`** (verificado: aparece como `??` em `git status`). Está fora do git por omissão. Um `git add .` distraído versiona 18 GB. Além disso o `.git` do repositório já tem 18 GB (3,2 GB em `objects`, 15 GB em `lost-found`) — passivo existente que §5.8 precisa tratar.

Há **7 arquivos `.Rproj` no legado** (`mape_municipios.Rproj` + `7 Textos Blog/Texto 1 Desastres Ambientais/`, `14 Segurança/`, `17 Eleições/`, `9 Energia e Internet/Luz Para Todos/`, `13 Habitação e Zoneamento/mcmv/`, `8 Assistência Social e DH/CadUnico/`). Cada um desloca a âncora de `here()` conforme onde a sessão for aberta — é a causa raiz do `here()` quebrado no `meio_ambiente.R`.

### 1.2 Árvore nova — `01_dimensoes_individuais/` (versionada, JÁ INICIADA)

**Não está vazia.** O commit `20a3b11` ("Organizando as dimensões individuais") já traz 15 arquivos rastreados, com **duas fontes migradas**:

```
01_dimensoes_individuais/
  00_diretorios/
    R/script.R                   # BigQuery, billing_id = get_billing_id()
    processed/diretorios.xlsx
  01_assistencia_social_direitos_humanos/
    01_CadUnico/
      R/script.R                 # lê raw/2015.txt .. raw/2024.txt
      raw/2015.txt … raw/2024.txt  (10 arquivos, ~660 mil linhas, COMMITADOS)
      processed/cadunico.csv       (COMMITADO)
```

**A convenção já em uso** (documentada em `CLAUDE.md` §"Estrutura nova"):
- pastas `NN_<dimensao>/NN_<fonte>/{R/script.R, raw/, processed/}`;
- **todo script se chama `script.R`** — a identificação vem do caminho;
- snake_case sem acento, com prefixo numérico;
- caminhos via `here()` a partir da raiz do repositório;
- saída em CSV via `rio::export`;
- billing GCP via `billing_id = get_billing_id()`;
- **nomenclatura de colunas com PREFIXO de fonte + SUFIXO de tipo**: `cadun_qtd_familias_atualizadas_i`, `cadun_taxa_atualizacao_cadastral_d` (`_i` = contagem/inteiro, `_d` = taxa/derivada);
- **dados brutos e processados são commitados.**

**Essa convenção tem exceções já commitadas:** `00_diretorios/R/script.R` usa caminho relativo nu (`save(diretorios, file = "processed/diretorios.RData")`, `write.xlsx(diretorios, "processed/diretorios.xlsx")`) e grava `.RData` + `.xlsx` — violando duas das regras acima.

**Trate isso como decisão já tomada, não como campo aberto.** Para cada item dessa convenção, seu plano deve **confirmar, estender ou propor mudança justificada**, e nesse último caso estimar o custo de migrar o que já está commitado. Leia os dois `script.R` antes de propor qualquer estrutura.

### 1.3 O `CLAUDE.md`

Leia-o primeiro: descreve o pipeline legado, o contrato de dados e a convenção da árvore nova. **Mas é ponto de partida, não autoridade.** Pontos a reconciliar:
- diz "~452 colunas" e "vetor posicional de **452** nomes" — verifiquei: o vetor `novos_nomes` tem **451** elementos e a base tem **451** colunas reais;
- afirma que dados brutos e processados **são commitados**, o que conflita com a restrição de tamanho de §8;
- prescreve a convenção da árvore nova que você deve auditar em §5.2.

**Atualizar o `CLAUDE.md` é entregável do plano.** Toda decisão que altere convenção, formato canônico ou contrato de tipos deve listar a alteração correspondente nele.

---

## 2. Os 6 objetivos (respeite todos; não invente outros)

| # | Objetivo |
|---|---|
| **(a)** | **ETL modular**, sem repetição de código e sem passos inúteis. |
| **(b)** | **Cada eixo/dimensão como TABELA SEPARADA**, com acesso modular aos dados pelo usuário final (quem quer só meio-ambiente baixa só meio-ambiente). |
| **(c)** | **Atualização fácil para quem chegar depois** — adicionar um ano novo ou uma fonte nova deve ser um procedimento documentado e curto. |
| **(d)** | **Nomes de script padronizados.** |
| **(e)** | **Documentação sistemática e uniforme por tabela/banco.** |
| **(f)** | **Nomes de coluna harmonizados entre tabelas** quando representam a mesma coisa. |

Tudo o que o plano propuser deve ser rastreável a pelo menos um desses seis. Se algo não serve a nenhum deles, corte.

---

## 3. Inventário factual das dimensões

Resultado de auditoria real do legado (leitura de código e inspeção dos objetos gerados). Use como insumo — **verifique o que for load-bearing** para suas decisões.

### 3.1 Panorama (dimensões 1-6)

| # | Dimensão | Script consolidador | Granularidade / cobertura | Estado |
|---|---|---|---|---|
| 1 | Identificação | **nenhum** | `diretorios`: id_municipio, 5.570×27, sem tempo. `geolocalizacao`: code_muni × versão de malha, 11.139×6 | Duas tabelas independentes nunca consolidadas; geolocalização (167 MB) nunca entra na base final |
| 2 | População | `populacao.R` (75 l.) | id_municipio × ano, 1991-2023, 179.972×9 | Religião só 1996-2015, por imputação (censo repetido 10 anos) |
| 3 | Meio-Ambiente | `meio_ambiente.R` (163 l.) | id_municipio × ano, 1991-2023, 183.810×105 (painel completo) | 27 das 105 colunas são o diretório copiado, removido depois por índice |
| 4 | Economia | **nenhum** | id_municipio × ano, 1999-2021, 127.786×22 | Fonte única (PIB); saída no nível da dimensão é cópia manual da subpasta |
| 5 | Sociedade | `sociedade.R` (40 l.) | id_municipio × ano, 1996-2015, 111.300×10 | Só 2 observações reais por município (censos 2000/2010), expandidas artificialmente para 20 anos |
| 6 | Finanças | `financas_municipais.R` (41 l.) | id_municipio × ano (character), 181.950×65 | Chave não é única: **222 chaves (id, ano) duplicadas / 235 linhas excedentes** |
| 7-17 | RH, Assistência/DH, Energia/Internet, Educação, Saúde, Transportes, Habitação, Segurança, Corrupção, História, Eleições | variados | ver §3.4 | **Inventariar é parte da sua tarefa** |

### 3.2 Fontes por dimensão — método de obtenção e reprodutibilidade

Legenda de `reprodutível`: **sim** = roda de novo sem intervenção; **parcial** = roda, mas trava em credencial/caminho/constante hardcoded; **não** = depende de arquivo local sem código de origem.

| Dim | Fonte | Origem | Método | Anos | Reprod. | Obstáculo principal |
|---|---|---|---|---|---|---|
| 1 | `diretorios` | BD `br_bd_diretorios_brasil.municipio` | BigQuery | atemporal | parcial | `set_billing_id("dados-importacao")` (`diretorios.R:9`); nenhuma data de extração registrada |
| 1 | `geolocalizacao` | IBGE via pacote `geobr` | pacote R | malhas 2010, 2018 | parcial | anos hardcoded; o `.RData` de 30,7 MB na pasta **não é gerado pelo script** (o `save()` só existe em `.Rhistory:504`) |
| 2 | `populacao` | BD `br_ibge_populacao.municipio` | BigQuery | 1991-2022 | parcial | billing hardcoded; `ano`/`populacao` salvos como **integer64** — `as.numeric(ano)` devolve `9.83e-321` |
| 2 | `populacao_2023.xlsx` | IBGE, estimativa 2023 | **arquivo local sem origem** | 2023 | **não** | Nenhum código. O merge com `diretorios.xlsx` foi feito **à mão no Excel** (33 colunas) |
| 2 | `censo_religiao` | Censos 2000/2010 via `censobr` | pacote R | 2000, 2010 | parcial | `cache = FALSE` (`censoBR_religiao.R:71`) força re-download integral; lê **todas** as colunas do Censo 2000 |
| 3 | AdaptaBrasil MCTI | plataforma MCTI | **download manual** | 2015 (8 ind.), 2016 (2 ind.) | **não** | 10 CSVs em pasta cujo nome **termina com espaço**; o script **não grava nada** — `base_adaptabrasil.csv` é órfão; sem URL |
| 3 | Desastres (Atlas/S2iD) | SEDEC/MIDR + CEPED/UFSC | **download manual** | 1991-2023 | **não** | `BD_Atlas_1991_2023_v1.0_2024.04.29.xlsx` (57 MB) hardcoded em `desastres_ambientais.R:7`; sem URL |
| 3 | Saneamento (SNIS) | BD `br_mdr_snis.municipio_agua_esgoto` | BigQuery | 1995-2022 | parcial | query com **133 colunas escritas à mão**, das quais 109 são descartadas |
| 3 | Desmatamento (PRODES) | BD `br_inpe_prodes.municipio_bioma` + áreas IBGE | BigQuery + xlsx manual | 2000-2022 | parcial | `area_total.xlsx` é download manual (URL só num comentário, `desmatamento.R:34`); coluna `AR_MUN_2022` embute o ano |
| 4 | PIB municipal | BD `br_ibge_pib.municipio` + `.municipio_antigo` + `br_ibge_populacao.municipio` | BigQuery (3 queries) | 1999-2021 | parcial | 3ª query é **cópia literal** da query de população da dim. 2 — mesma tabela faturada duas vezes |
| 5 | IVS / Atlas Vulnerabilidade | IPEA via BD `br_ipea_avs.municipio` | BigQuery | 2000, 2010 | parcial | `set_billing_id("municipality-carlos")`; `setwd("G:/Drives compartilhados/...")`; grava `ivs_original.xlsx` (138 MB) e relê — hoje o arquivo dá **erro de unzip** |
| 5 | Templos/Igrejas (CNPJ RF) | CEM-USP NT20 + GitHub terceiro | **arquivo local sem origem** | 1922-2019 | **não** | `df_igrejas_nomes.csv` (48 MB) já vem pré-processado; **nenhum dos 3 scripts salva saída municipal** — nada disso entra em `sociedade.RData` |
| 5 | `estimativas_pop.csv`, `evangelicos_censo2010.csv` | IBGE (inferido) | **arquivo local sem origem** | vários | **não** | CSVs soltos, sem URL, sem data; só alimentam saída por UF que ninguém lê |
| 6 | SICONFI | BD `br_me_siconfi.municipio_receitas_orcamentarias` | BigQuery | 1989-2023 | parcial | baixa 18,5 M linhas (246 MB); receita própria classificada por **regex em texto livre** (`str_detect(conta, "IPTU|ITBI|ISS")`) |
| 6 | Emendas parlamentares | CGU / Portal da Transparência | **download manual** | 2014-2024 | parcial | `Emendas_CGU_8_10_2024.xlsx` hardcoded; **join por nome de município SEM UF** |
| 6 | `diretorios.xlsx` (cópia) | dim. 1 | cópia manual | — | **não** | Mesmo md5 em **9 pastas** diferentes |
| 7-17 | — | — | — | — | — | **A INVENTARIAR POR VOCÊ, no mesmo formato** |

### 3.3 Padrão transversal de obstáculos de atualização

Resolver **estruturalmente**, não caso a caso. Números conferidos por grep sobre `*.R`/`*.qmd` do legado (excluindo `.Rhistory`):

1. **Billing GCP hardcoded em 28 chamadas de `set_billing_id()`, com QUATRO projetos distintos:** `dados-importacao` (24), `base-dos-dados-429117` (`9 Energia e Internet/Internet Móvel/telefonia.R:13`, `.../Banda Larga/bandalarga.R:18`), `municipality-carlos` (`5 Sociedade/IVS/script_sociedade_ivs.R:31`), `dissertacao-de-mestrado-399114` (`12 Transportes/Script_MunicipalityBR.R:29`). Três scripts trazem o comentário `## Substituir para seu projeto` — o problema é conhecido e nunca foi resolvido. Nenhum `.Renviron` nem `config.yml` no legado. **Na árvore nova, `00_diretorios/R/script.R` já usa `billing_id = get_billing_id()` e o `.gitignore` já cobre `.Renviron`** — parte da solução já existe; avalie se basta (resolve configuração, mas não registra QUAL projeto/conta gerou cada extração).
2. **Base de deflação IPCA `"12/2023"` hardcoded em 8 call sites de `ipca()`:** `desastres_ambientais.R:44`, `saneamento.R:191`, `pib_municipal.R:78`, `siconfi.R:122`, `Emendas/script.R:74`, `15 Corrupção/cgu/cgu.R:33`, `12 Transportes/Script_MunicipalityBR.R:58`, `13 Habitação e Zoneamento/habitacao.R:61` (mais 7 comentários com a mesma constante). Mudar em um só produz uma tabela com duas bases de deflação.
3. **Nomes de arquivo com data/versão embutida e hardcoded** (`Emendas_CGU_8_10_2024.xlsx`, `BD_Atlas_1991_2023_v1.0_2024.04.29.xlsx`).
4. **Nenhuma data de extração é registrada em lugar nenhum.** As tabelas da Base dos Dados mudam e o resultado muda em silêncio.
5. **`setwd()` com caminhos Windows de Google Drive compartilhado**, com numeração de pastas obsoleta (`"G:/Drives compartilhados/municipalityBR/7 Sociedade - Códigos e Dados/IVS"` — hoje é a dimensão 5; `"18 Junção Bases"` — hoje é a 2).
6. **Cópias manuais de arquivos entre pastas**, sem código que as produza. `diretorios.xlsx` em 9 pastas (md5 `24e797bd...`); `meio_ambiente.xlsx` e `pib_municipio.xlsx` em 3 cada; ~4,4 GB replicando a base larga em 5 pastas.

### 3.4 O que você ainda precisa inventariar — com orçamento

Para as dimensões **7 a 17** (RH, Assistência Social e DH, Energia e Internet, Educação, Saúde, Transportes, Habitação, Segurança, Corrupção, História, Eleições), levante: fonte, origem, método de obtenção, cobertura temporal **real** (não a declarada), chave e granularidade, reprodutibilidade, obstáculo de atualização, e os **nomes de coluna que colidem com outras dimensões**.

**Isto é insumo, não entregável final.** Detalhe no nível `arquivo:linha` só onde houver defeito que mude uma decisão de §5. Se faltar espaço, priorize nesta ordem e marque o resto como "inventário pendente" no §2 do plano, listando explicitamente o que falta levantar:

1. **Saúde** — 6 subpastas de fonte (`Atenção Básica`, `IEPS`, `Imunizações`, `SIA`, `SIM`, `SINAN`), duplicação de conceitos já conhecida;
2. **Segurança** — 70 códigos de UF disfarçados de município;
3. **História** (`16 Dados históricos`) — 54 chaves duplicadas, tabela estática, join sem `ano`;
4. **Eleições** — `ano_eleicao` colidindo com definição de consumidor;
5. **Assistência Social e DH** — a fonte CadÚnico **já foi migrada e commitada** na árvore nova; o inventário precisa reconciliar legado × novo;
6. **Corrupção** — 0,8% de cobertura, caso-teste do objetivo (b);
7. demais.

---

## 4. Problemas já diagnosticados (verifique, não confie cegamente)

### 4.1 Defeitos de dados já em produção

| Defeito | Evidência | Efeito medido |
|---|---|---|
| **`sigla_uf` ~81,5% vazia na base final** | `municipalityBR.qmd:423-424` faz `select(-sigla_uf.x, -sigla_uf.y)`, apagando as duas versões boas (diretório 100% preenchida; PIB 127.786 linhas). A sobrevivente veio da **saúde**, que só tem 33.420 não-NA | 146.867 NAs em 180.285 linhas. Consumidor afetado: `5 Análise Exploratória/Desastres.R:65` agrupa por essa coluna |
| **Chave `id_municipio` NA** | `full_join` em d1 (`:46`) e d6 (`:207`); `populacao_brasileira` tem 42 linhas com id NA, `munic_RH` tem 81 | **122 linhas na base PRÉ-dedup** (`2 Junção Bases/base_municipios_brasileiros1.csv`, 182.407 linhas); **13 sobrevivem** no artefato publicado (verificado por contagem direta nos dois CSVs). O `distinct(id_municipio, ano)` colapsa as demais. **Atenção à ordem na migração: remover o `distinct()` antes de eliminar as chaves NA na origem multiplica por ~9 as linhas sem município no artefato publicado.** |
| **2 indicadores do AdaptaBrasil perdidos por join mal especificado** | `AdaptaBR.R:93-95` inclui `ano` na chave do `full_join`, mas 8 indicadores são de 2015 e 2 de 2016 → 11.140 linhas = 5.570 municípios duplicados. `meio_ambiente.R:40` filtra `ano == 2015` e `:45` remove as colunas órfãs | "Investimento per capita em políticas de adaptação" e "nível de implementação do plano municipal de saneamento" são perdidos **por consequência, não por decisão** |
| **Emendas atribuídas ao município errado** | `Emendas/script.R:87-91` faz join só por nome minúsculo, sem UF. O comentário `:85-86` **admite o problema** e nunca foi corrigido | 1.067 de 11.649 linhas com UF divergente. Ex.: 'Alto Paraíso'/RO recebe R$ 308.632 de 'ALTO PARAÍSO - PR' |
| **70 códigos de UF disfarçados de município na segurança** | `seguranca.RData` tem `1100000, 1200000, ...` (códigos de UF com 5 zeros). Como d13 é `left_join`, somem sem aviso | Ou a dimensão agrega UF junto com município, ou há dado sendo jogado fora sem registro |
| **`distinct()` cego mascarando 2.122 linhas** | `renomear_variaveis.R:184-185`. Causa principal: 54 `muncode` duplicados em `dados_historicos`, cujo join sem `ano` (d15, `:482`) **multiplica a série inteira** do município (~1.782 das 2.122 linhas) | Nesta rodada não destruiu dado (verificado); não há garantia para a próxima |
| **Tipos inconsistentes entre variáveis irmãs** | `indice_risco_seca` é numeric; `indice_risco_inundacoes_enxurradas` é **character** (sentinela textual `"NaoDisponivel"`), mesma fonte, mesmo bloco | Consumidor remenda à mão em `analise nota técnica.R:36-37` e `:253` |
| **`rendimento_mensal_media` calculado com a variável errada** | `censoBR_religiao.R:79` usa `mean(P001)` no Censo 2000 — P001 é o **peso** da pessoa, não a renda (compare com `:28`, que usa V6527 em 2010) | Só não afeta o resultado porque a coluna é descartada em `:104-106` |
| **`log10()` sem tratar zeros** | `pib_municipal.R:160-162`, com filtro `>= 0` em `:137` permitindo `pib = 0` | `-Inf` em `log_pib`, `log_pib_per_capita`, `log_valor_adicionado` |
| **Filtro que descarta linhas inteiras em silêncio** | `pib_municipal.R:136-146`: 8 condições `>= 0`; `filter()` também elimina NA | Qualquer município-ano com um único NA/negativo perde **todas** as outras variáveis. Sem contagem, log ou flag |

**Vocabulário de contagem de duplicatas** (use consistentemente): *chaves duplicadas* = `length(unique(k[duplicated(k)]))`; *linhas excedentes* = `sum(duplicated(k))`.

Duplicação de **chaves válidas** existe em 2 dimensões: `financas_municipais` (222 chaves id×ano / 235 linhas excedentes, causadas pelo join por nome sem UF das Emendas) e `dados_historicos` (54 `muncode` repetidos em 5.646 linhas). As "79" duplicatas de `munic_RH` e as "30" de `populacao_brasileira` correspondem cada uma a **uma única chave distinta — a chave NA**; são consequência do defeito de chave NA, não defeito independente.

### 4.2 Mecanismos posicionais (o risco estrutural central)

**Três mecanismos** sustentam o pipeline e podem quebrar em silêncio se qualquer script a montante ganhar ou perder uma coluna:

1. **Cortes por índice numérico:** `municipalityBR.qmd:63` `meio_ambiente[, -c(3:28)]`; `:169` `financas[, -c(13:38)]`; `:228` `dh_as[, -c(3:28)]`; `meio_ambiente.R:89-91` `meio_ambiente[, 29:53] <- lapply(...)`. Os intervalos diferem entre si porque a ordem das colunas difere — não há como escrever um teste genérico.
2. **Renomeio posicional:** `renomear_variaveis.R:13-171` define `novos_nomes` com **451 elementos** (verificado), aplicado com `names(base) <- novos_nomes`. **Só 44 posições mudam de fato** — os outros 407 são reescritos idênticos a si mesmos. `names(x) <- v` só falha se `length(v) != ncol(x)`: se uma dimensão ganhar uma coluna e perder outra, o comprimento continua 451 e **todos** os nomes se deslocam, sem erro.
3. **O dicionário de metadados é posicional:** `6 Metadados/mape_municipios DICIONÁRIO.xlsx` tem 451 linhas cuja ordem é **idêntica** à ordem das colunas da base (`identical(dicionario$Nome_banco, names(base_final))` é `TRUE`). Não há chave de junção — só posição.

### 4.3 A cadeia de 16 joins

`2 Junção Bases/municipalityBR.qmd` (543 linhas) encadeia 16 joins (6 `full_join`, 11 `left_join`) sobre um objeto que cresce até 182.407 × 451:

- **d1 (`:46`)** junta `diretorios` (5.570 linhas, **sem `ano`**) com `populacao` só por `id_municipio` → replica 26 colunas cadastrais em cada ano (~33× por município).
- **d15 (`:482`)** junta `dados_historicos` por `id_municipio = muncode`, **sem `ano`** → multiplica a série temporal.
- **12 coerções `as.character(ano)` espalhadas** (`:75, 139, 166, 198, 225, 258, 285, 316, 347, 378, 410, 441, 509`), porque cada `.RData` de origem tipa `ano` diferente: numeric, integer, integer64, character. **d3 (`:115`) é o único sem coerção — funciona por acidente**, porque `read.xlsx("pib_municipio.xlsx")` devolve `ano` como character (o integer64 foi serializado como texto). Se o arquivo de PIB for regravado com `ano` numérico, d3 quebra.
- **A limpeza de colisões está no bloco errado:** `:486-492` resolve `nome.x`/`nome.y` (nascidos em d10) e `NOME_MUNICIPIO` (nascido em d8), cinco joins depois.
- **Nenhum join declara `relationship=`**; nenhum `stopifnot`, nenhum teste de cardinalidade, nenhuma contagem de linhas antes/depois. Há 17 `names()`, 13 `str()` e 9 `summary()` cujo output ninguém lê.
- **A ordem dos joins é semanticamente relevante e não documentada** — mudá-la muda quais colunas ganham sufixo `.x`/`.y` e qual versão sobrevive.

### 4.4 Passos inúteis e duplicação de código

- **A etapa 4 "Base completa" não tem código nenhum.** É a etapa 3 re-executada (o `.Rhistory:343-512` mostra: carregar a base **já renomeada**, colar o mesmo vetor de nomes, aplicar de novo, salvar) e o resultado copiado. Arquivos com tamanho byte-idêntico aos da etapa 3.
- **`script_sociedade_ivs.R:137-143`** grava `ivs_original.xlsx` (138 MB) e imediatamente relê o mesmo arquivo. Hoje o arquivo dá erro de unzip — o passo está quebrado.
- **`pib_municipal.R:13-28` e `:37-52`**: duas queries de 15 linhas idênticas exceto pelo nome da tabela no `FROM`.
- **`pib_municipal.R:85-98`**: cópia literal da query de `populacao_brasileira.R:12-25`. A mesma tabela é faturada duas vezes e o resultado é descartado em `municipalityBR.qmd:97` depois de servir só para calcular `pib_per_capita` — as duas populações são **idênticas em 100% das 127.786 linhas comparáveis**.
- **`AdaptaBR.R:8-66`**: dez blocos `read.csv()` quase idênticos; `:74-83` dez `rename()` idênticos; `:90` usa `get(paste0("adaptabr_", i))` para recuperar objetos por nome montado em string.
- **`Templos/`**: o mesmo bloco de classificação de ~310 linhas existe em **três arquivos**; `codigo templos por municipio.R:113-205` cria 93 variáveis uma a uma seguidas de um `ifelse` com 93 condições encadeadas, com bugs de copiar-colar dentro dele (`igreja6` duas vezes, `:215-216`).
- **`desastres_ambientais.R:55-93`**: cinco blocos de 5 linhas idênticos, variando só o literal do grupo. Um grupo novo (`Geofísico`, `Biológico`) some da agregação sem aviso.
- **Os dois `.qmd` do blog** (`Desastres Ambientais no Brasil.qmd` e `... -- formato postagem.qmd`) têm **todo o código R duplicado** — o diff é só front-matter YAML e espaços em branco.
- **Debug deixado nos scripts de produção:** 18 chamadas em `meio_ambiente.R` (163 linhas), 12 em `desmatamento.R` (117), 9 em `desastres_ambientais.R` (107), 9 em `pib_municipal.R` (190), 8 em `populacao.R` (75). Mais 6 blocos `ggplot` exploratórios dentro de `pib_municipal.R` e ~200 linhas de mapas em `codigo_aberto_classificacao.R:4855-5062`.
- **`library()` no meio do script**, depois do uso: `saneamento.R:182`, `desastres_ambientais.R:21`, `pib_municipal.R:70`, `censoBR_religiao.R:120`.
- **Data frames de diagnóstico congelados no script de produção:** `desmatamento.R:87-108` cria quatro objetos nunca usados.

> Contagens de linha de script são indicativas. O que é load-bearing são as referências `arquivo:linha`, que foram conferidas uma a uma.

### 4.5 Nomes de coluna não harmonizados

**Quatro nomes para a chave de município** dentro da dimensão 3 sozinha: `id_municipio`, `Cod_IBGE_Mun`, `geocod_ibge`, `CD_MUN`. Traduzidos ad hoc dentro de cada join.

**Quatro representações de UF:** `sigla_uf`, `nome_uf`, `sigla_uf_nome` (que é o **nome** por extenso, apesar do prefixo `sigla_`), `NM_UF`.

**Três grafias para nome de município:** `nome_municipio`, `id_municipio_nome`, `NOME_MUNICIPIO`.

**Duas convenções paralelas dentro da dimensão Saúde**, para os mesmos oito conceitos, de duas fontes fundidas a montante (SI-PNI e IEPS) — e em escalas diferentes (proporção 0-1 vs percentual 0-100):

| Conceito | Nome A | Nome B |
|---|---|---|
| cobertura BCG | `cobertura_bcg` | `cob_vac_bcg` |
| pentavalente | `cobertura_penta` | `cob_vac_penta` |
| poliomielite | `cobertura_poliomielite` | `cob_vac_polio` |
| hepatite B | `cobertura_hepatite_b` | `cob_vac_hepb` |
| hepatite A | `cobertura_hepatite_a` | `cob_vac_hepa` |
| tríplice viral D1 | `cobertura_triplice_viral_d1` | `cob_vac_tvd1` |
| atenção básica | `proporcao_cobertura_total_atencao_basica` | `cob_ab` |
| estratégia saúde da família | `proporcao_cobertura_estrategia_saude_familia` | `cob_esf` |

**Seis colunas de "ano" sem prefixo de escopo:** `ano` (chave), `ano_censo`, `ano_avs`, `ano_ideb`, `ano_inicio`, `ano_eleicao`. E `Desastres.R:55-64` **sobrescreve `ano_eleicao`** com definição diferente (janela de 4 anos vs ano do pleito), em silêncio.

**Nomes genéricos perigosos na base final:** `id` (é o id interno do AdaptaBrasil), `grupo`, `turno`, `va`, `va_adespss`.

**Nomes com pontos, quebrando o snake_case:** `AB1.1`...`AB9.2` (renomeados só na etapa 3, posicionalmente), `ln.pc.receita1920.sd`, `ln.admpub.1920.sd`, `ln.dist.coast.sd`, e as colunas de emendas em Title Case com acentos (`Comércio.e.serviços`, `Ciência.e.Tecnologia`).

**Erros de digitação petrificados** e já publicados: `dimensao_identificao`, `populacao_atentida_esgoto`, `total_institucoes`, `proporcao_mortes_intenvencao_policial_x_mortes_violentas_intencionais`.

**Colisão semântica:** `populacao` (dim. 2) convive com `populacao_urbana`, `populacao_atendida_agua`, `populacao_atentida_esgoto` (SNIS, dim. 3) — nada distingue "população do município" de "população atendida por serviço".

**Um `ano` que não é ano:** `geolocalizacao.R:31-33` cria uma coluna `ano` que significa "versão da malha cartográfica".

### 4.6 Estado da documentação existente

Em `6 Metadados/`:

- **`mape_municipios DICIONÁRIO.xlsx`** — 451×5 (`Nome_original`, `Nome_banco`, `Dimensão`, `Descrição`, `Operacionalização`). **Bate 1-a-1 e na mesma ordem com as colunas da base** — único artefato validado contra o dado real, logo a **semente natural do novo dicionário**. Mas: 51 variáveis sem descrição, 75 sem tipo, e o campo de tipo mistura vocabulários (`NUM`=309, `STRING`=40, `FLOAT64`=15, `INT64`=11, `GEOGRAPHY`=1) com erros verificáveis (`prefeito_eleito` e `partido` declarados `NUM`, são character).
- **`mape_municipios METADADOS Bases.xlsx`** — 32 bases × 11 campos (`Responsável`, `Dimensão`, `Nome Base`, `Descrição`, `Escopo Temporal`, `Nome arquivo`, `Total Variáveis`, `Fonte Original`, `Fonte Extração`, `Link`, `Observações`). **`Fonte Original`, `Fonte Extração` e `Link` têm zero NAs** — a procedência está documentada, isso é ativo real. Mas em texto livre e já divergente do artigo publicado (Disque-100 com duas atribuições diferentes).
- **`mape_municipios METADADOS Variáveis Original.xlsx`** — 526 linhas no nível da fonte. Cruza com o dicionário final em só **371 dos 451** nomes. Um indicador tem dois **U+200B** invisíveis no início.
- **`Dicionário Variáveis.xlsx`** — template **100% vazio** (451 nomes, todas as outras colunas NA). É o único que prevê `Fonte Original`/`Fonte Extração` **por variável** — alguém desenhou o schema-alvo e nunca preencheu.
- **`mape_municipios_ Banco de dados ... METADADOS.docx`** — documento mestre por Dimensão > Base > tabela.
- **`mape_municipios/Textos/`** — quarto artefato de documentação: o artigo publicado (`Banco de dados Informações Municipais CGU.pdf/.docx` e 4 outras versões), `Tabelas e Quadros.docx`, `Figura 1-5.png`.

**Erros concretos:** 8 descrições duplicadas por copiar-colar do bloco de PIB para o de SICONFI, afetando 16 variáveis — `total_receitas_fundeb` está documentada como "Produto Interno Bruto a preços correntes".

**O que NÃO existe em lugar nenhum:** licença, periodicidade de atualização da fonte, data de extração, chave primária/granularidade, unidade de medida em campo próprio, escala, ano-base do deflator em campo próprio, regra de imputação temporal (só em prosa no artigo), e qual **base** originou cada variável (só a dimensão — e Meio-Ambiente tem 4 bases, Saúde 6 subpastas de fonte, Energia/Internet 3).

**Contagens que não fecham:** soma de `Total Variáveis` = 533 vs 451 reais (Energia e Internet: 31 documentadas vs 10 reais; Educação: 25 vs 35 — invertido). O artigo declara 182.407 observações vs 180.285 reais. Cobertura temporal anunciada é a **da fonte**, não a do dado incorporado: 5 bases anunciam 2024 num painel que termina em 2023.

**Vocabulário de dimensão não controlado, agora com QUATRO grafias:** planilha de metadados (`Corrupção e Transparência`, `Dados históricos`, `Transporte`) vs dicionário (`Corrupção`, `História`, `Transportes`) vs pasta legada (`15 Corrupção e Transparência - Códigos e Dados`) vs **pasta da árvore nova, com numeração diferente** (`00_diretorios`, `01_assistencia_social_direitos_humanos` — enquanto no legado Identificação é a 1 e Assistência Social é a 8).

### 4.7 Quem consome a base hoje (não pode quebrar)

**Três consumidores de código**, todos com a mesma porta de entrada — `import("base_municipios_brasileiros.csv")` com **caminho relativo** e uma cópia física de 431 MB do CSV na própria pasta:

1. `5 Análise Exploratória de Dados/Desastres.R:19`
2. `5 Análise Exploratória de Dados/analise nota técnica.R:22`
3. `7 Textos Blog/Texto 1 Desastres Ambientais/Desastres Ambientais no Brasil.qmd:45` (e o gêmeo duplicado, `:57`)

Todos carregam `library(here)` e **nunca usam `here()`**.

**Dois consumidores de números:** o artigo em `mape_municipios/Textos/` e `Tabelas e Quadros.docx`, que publicam contagens de variáveis/observações já hoje divergentes do dado real. O plano de migração precisa dizer o que acontece com esses números publicados quando as contagens mudarem.

**Colunas efetivamente consumidas (~40, de 6 dimensões):** `id_municipio`, `nome_municipio`, `nome_uf`, `nome_regiao`, `sigla_uf`, `centroide`, `ano`, `populacao`, `pib`, `pib_per_capita`, `log_pib_per_capita`, `total_desastres`, `total_desastres_climatologicos/_hidrologicos/_meteorologicos`, `total_pessoas_afetadas`, `total_danos_materiais`, `total_prejuizos_publicos`, `total_prejuizos_privados`, `indice_risco_inundacoes_enxurradas`, `indice_risco_seca`, `extensao_rede_esgoto`, `populacao_urbana_atendida_esgoto`, `indice_atendimento_esgoto_agua`, `ivs`, `idhm`, `cob_ab`, `tx_mort_csap`, `tx_mort_csap_aj_cens`, `tx_hosp`, `proporcao_cobertura_estrategia_saude_familia`, `gasto_pbf_pc_def`, `total_receitas_fundeb`, `proporcao_comparecimento_prefeitura`, `proporcao_comparecimento_camara_vereadores`, `ano_eleicao`.

**Derivadas que os consumidores recriam à mão:** `total_prejuizos`, `total_desastres_per_capita`, `total_prejuizos_pib`, `total_pessoas_afetadas_per_capita`, `total_danos_materiais_per_capita`, `idhm_100`, `log_gasto_pbf_pc_def`.

**Dependência frágil:** o join externo com `geobr` (`left_join(muni_sf, by = c("id_municipio" = "code_muni"))`) funciona **por acidente**, porque o CSV entrega `id_municipio` como integer e o geobr também. No `.RDa` é character.

**Nenhum consumidor usa as 17 flags `dimensao_*`.**

### 4.8 A justificativa quantitativa do objetivo (b)

A base final tem 180.285 × 451 = 81.308.535 células, das quais **≈40,8 milhões são vazias (~50%)**. (A contagem exata varia ~70 mil células conforme se trate ou não string vazia como NA em colunas character — se o plano usar isso como baseline de QA, defina a convenção.)

Cobertura por dimensão (linhas não-NA / 180.285): transportes 100% · história 100% · população 99,8% · identificação 99,8% · meio-ambiente 99,8% · finanças 94,8% · saúde 82,7% · eleições 74,0% · segurança 73,5% · economia 70,9% · sociedade 61,7% · educação 58,7% · energia/internet 58,6% · habitação 52,5% · assistência/DH 40,2% · RH 37,1% · **corrupção 0,8%**.

**A dimensão Corrupção ocupa 180.285 linhas para entregar 1.516.**

**Os 4 formatos publicados não são equivalentes:** o CSV ganha uma coluna fantasma `V1` (falta `row.names = FALSE`) e converte `id_municipio`, `ano`, `id_municipio_6` e `ddd` de character para integer; o `.RDa` mantém character. Qualquer tutorial escrito para um formato quebra no outro. O mesmo objeto está fisicamente copiado em 5 pastas (~4,4 GB).

---

## 5. Escopo do plano que você deve produzir

Seja concreto: nomes reais de tabelas, colunas, arquivos e funções. "Definir um padrão de nomes" sem dizer qual é o padrão não é executável.

### 5.1 Modelo de dados alvo

**Decisões estruturais que o plano PRECISA tomar** (para cada uma: alternativas, prós, contras, recomendação — não decida por omissão):

1. **Tabela publicada por DIMENSÃO ou por FONTE?** A árvore nova já publica por fonte (`01_CadUnico/processed/cadunico.csv`, uma de várias fontes da dimensão 8), enquanto o objetivo (b) fala em "eixo/dimensão". Consolidar por dimensão recria em miniatura o problema da base larga (NAs, colisão de nomes); publicar por fonte contraria a letra do objetivo (b). Considere a híbrida (fonte = camada canônica, dimensão = derivada documentada). Use como casos-teste **Meio-Ambiente** (4 fontes, coberturas 2015 / 1991-2023 / 1995-2022 / 2000-2022) e **Saúde** (6 fontes, 8 conceitos duplicados). Diga qual delas o usuário final baixa e como a outra é gerada.

2. **Municípios ao longo do tempo.** O diretório é um snapshot de 5.570 municípios, mas o painel começa em 1991, quando havia ~4.491; Mojuí dos Campos foi criado em 2013. A espinha é o produto cartesiano cheio ou respeita o ano de instalação? Como se distingue "NA porque o município não existia" de "NA porque a fonte não cobre"? O que fazer com códigos fora do diretório (70 códigos de UF na segurança, 27 `muncode` na história, 42 `id_municipio` NA na população) e com desmembramentos/fusões. Se a decisão for "ignorar por ora", diga isso e registre como known issue.

3. **Armazenar observado ou expandido?** Três casos de expansão artificial documentados (religião do censo replicada 10 anos; IVS 2000/2010 → 1996-2015; AdaptaBrasil 2015 → 2010-2020). A tabela canônica guarda só as linhas observadas (sociedade: 11.130 em vez de 111.300), com expansão on demand por função documentada, ou guarda o painel expandido com coluna-flag de imputação? Aplique a decisão aos três casos e diga o efeito no tamanho de cada tabela.

4. **Nominal vs deflacionado.** Hoje as tabelas guardam **apenas** o valor deflacionado a 12/2023, o que significa que atualizar a base muda retroativamente números já publicados no artigo e no blog, e que o valor nominal é irrecuperável. Decida se o canônico é nominal (deflação aplicada por função na leitura/derivação) ou já deflacionado; se recomendar ambos, defina a convenção de nome (`<var>` vs `<var>_def`) e o campo de documentação que registra a base.

5. **Destino da base larga de 451 colunas.** Continua a existir? Como artefato derivado, view, função de conveniência, ou não existe mais? Se continuar, como é gerada e o que acontece com as 17 flags `dimensao_*`? Se não, qual o caminho de migração para os consumidores?

6. **Interface de consumo (segunda metade do objetivo b).** Como uma pessoa de fora obtém **uma** tabela: (i) arquivos em `processed/` commitados no repo (é o que existe hoje); (ii) release/tag do GitHub com um arquivo por tabela; (iii) pacote R leve com `mape_ler("meio_ambiente")` / `mape_juntar(c("meio_ambiente","economia"))`; (iv) depósito citável (Zenodo/OSF) com DOI. Custo operacional de cada uma e recomendação. Se propuser a função de junção, defina sua assinatura e o que ela faz com granularidades diferentes.

7. **Contrato de tipos.** Tipo de `id_municipio` (character de 7 dígitos? integer?) e de `ano`, e como isso convive com o join externo com `geobr` que os consumidores fazem. O `CLAUDE.md` já declara `id_municipio` como character — confirme ou mude com justificativa.

8. **Formato canônico de armazenamento e formatos de export.** Considere que xlsx não preserva tipos, que o pipeline atual depende de um acidente de serialização xlsx para funcionar, e que a árvore nova já adotou CSV via `rio::export` (que também não preserva tipos).

Além disso, defina: **quais tabelas existirão**, com nome definitivo, chave primária, granularidade e cardinalidade esperada — com atenção aos casos que não são `id_municipio × ano` (identificação estática, geolocalização por versão de malha, história estática, corrupção esparsa, e qualquer coisa em nível de UF hoje escondida dentro de tabela municipal); **onde vivem os dados cadastrais** e qual tabela tem autoridade sobre eles; e **quem é "dono" de cada indicador compartilhado** — `populacao` é o caso testemunha (produzida por duas dimensões, com derivadas calculadas a montante a partir da cópia que depois é descartada).

### 5.2 Árvore de diretórios alvo e convenção de nomes

**Ponto de partida obrigatório: a convenção descrita em §1.2 já existe e está commitada.** Sua tarefa é auditá-la contra os 6 objetivos, apontar onde o código já commitado a viola, e propor manter, estender ou alterar — com o custo de migrar os 15 arquivos já commitados.

Cobrir:

- **Nome de script (objetivo d).** Hoje todo script se chama `script.R`, com identificação pelo caminho. Avalie contra nomear pelo conteúdo (`ingest_cadunico.R`, `consolidar_assistencia_social.R`, `montar_painel.R`), considerando impacto em `grep`, abas do editor e referência num orquestrador. Compare também com o legado, que não tem padrão nenhum (`municipalityBR.qmd`, `renomear_variaveis.R`, `analise nota técnica.R` com espaço e acento, `codigo templos por municipio.R`, `Desastres.R`).
- **Vocabulário controlado de dimensão** (slug + rótulo pt-BR) governando simultaneamente nome de pasta, de script, de tabela publicada e o campo `dimensao` da documentação. Precisa reconciliar as **quatro** grafias de §4.6, incluindo a renumeração já adotada na árvore nova — diga se ela é definitiva.
- Estrutura de pastas completa: scripts de ingestão por fonte, consolidação por dimensão, funções comuns, dicionário/metadados, dados intermediários, dados publicados, documentação, consumidores.

### 5.3 Camada de funções comuns

Especifique **quais funções existirão, com assinatura**. No mínimo:

- acesso ao BigQuery/basedosdados com billing configurável — **elimina 28 hardcodes em 4 projetos GCP**; avalie se `get_billing_id()` (já em uso na árvore nova) basta e o que acrescentar para registrar qual projeto/conta gerou cada extração;
- deflação por IPCA com ano-base **único e centralizado** — elimina 8 call sites de `"12/2023"`;
- normalização de chaves e tipos (`id_municipio`, `ano`), aplicada **na saída de cada dimensão**, não na entrada de cada join;
- leitura/escrita padronizada de tabelas (com `row.names = FALSE` garantido e schema validado);
- tratamento de valores sentinela (`"NaoDisponivel"`, `"Ignorado"`, `-999`) → NA;
- join validado com checagem de cardinalidade e relatório de chaves órfãs;
- registro de proveniência (data de extração, versão da fonte, URL);
- recuperação do código de 7 dígitos a partir do de 6 (padrão já usado no CadÚnico);
- aplicação do mapa de renomeação a partir do dicionário.

### 5.4 Padrão de nomenclatura de colunas e harmonização

- **O padrão em si**: snake_case, sem acentos, sem pontos, sem abreviação ad hoc, prefixo de escopo para nomes genéricos, regra para nomes reservados (`ano`, `id_municipio`), regra para fontes concorrentes do mesmo conceito.
- **Reconcilie com a convenção já commitada**, que usa **PREFIXO de fonte + SUFIXO de tipo** (`cadun_qtd_familias_atualizadas_i`, `cadun_taxa_atualizacao_cadastral_d`). Avalie explicitamente: (i) prefixo vs sufixo de fonte; (ii) manter, generalizar ou abandonar o sufixo `_i`/`_d` — se manter, defina o vocabulário fechado completo e como convive com os campos `unidade`/`escala` do dicionário; (iii) custo de renomear `cadunico.csv`, já commitado.
- **Um glossário de conceitos canônicos** (conceito → nome_canônico → unidade → escala), com o dicionário por tabela apontando para ele. É o que permite decidir que `cob_esf` e `proporcao_cobertura_estrategia_saude_familia` são o mesmo conceito em escalas diferentes.
- **Onde a renomeação acontece**: dentro de cada script de fonte, logo após a leitura, antes de qualquer junção — nunca posicionalmente no fim.
- **Política para os nomes públicos já existentes**, incluindo os com erro de digitação (`populacao_atentida_esgoto`, `dimensao_identificao`, `total_institucoes`, `intenvencao`). Há figuras publicadas. Corrigir com tabela de deprecação `nome_antigo → nome_novo`? Manter alias? Congelar os ~40 nomes consumidos? Alternativas com recomendação.

### 5.5 Contrato de documentação (objetivo e)

Defina o **template obrigatório**, em dois níveis:

- **Por tabela/base:** partindo dos 11 campos de `METADADOS Bases.xlsx` (que funcionam e devem ser preservados), acrescente: licença e URL da licença, periodicidade de atualização da fonte, data da última extração, data da última atualização da fonte, chave primária, granularidade, método de acesso (vocabulário fechado), caminho do script de ingestão, citação recomendada, regra de preenchimento temporal (nenhuma / carry-forward / valor único replicado) com justificativa.
- **Por variável:** partindo do `DICIONÁRIO.xlsx` (única semente validada contra o dado real), acrescente: tabela de origem, nome na fonte, conceito canônico, unidade, escala, ano-base do deflator, tipo com **vocabulário fechado**.
- **Distinga campos digitados de campos gerados.** `total_variaveis`, `n_linhas`, `cobertura_temporal_na_tabela`, `% de NA por coluna` e o tipo real **não devem ser digitados** — é justamente onde os números não fecham (533 vs 451; 182.407 vs 180.285; 5 bases anunciando 2024 num painel que acaba em 2023). Separe `cobertura_temporal_da_fonte` (declarada) de `cobertura_temporal_na_tabela` (calculada).
- **Licença dos DADOS.** O repositório tem `LICENSE` MIT, que cobre código, não dados. Recomende a licença dos dados publicados (e note que ela pode ser condicionada pelas licenças das fontes).
- **Qual é a fonte de verdade e a direção do fluxo.** O dicionário deve ser **entrada** do pipeline (renomear, validar tipos, gerar documentação), não subproduto posicional. Diga em que formato vive (CSV? YAML?) e como é versionado.
- **Como a documentação é publicada** (página por tabela? README por pasta? site?) e como se garante que não desatualize.
- **Auditoria explícita de descrições** — não só migração. As 8 descrições duplicadas PIB→SICONFI precisam ser corrigidas, e a validação automática deve sinalizar descrições idênticas entre variáveis de tabelas diferentes.
- **O `CLAUDE.md` é artefato de documentação de primeira classe.** Liste o que muda nele; "CLAUDE.md atualizado" entra na checklist de pronto de cada fase.

### 5.6 Estratégia de atualização (objetivo c)

Procedimento passo a passo, do ponto de vista de quem chega sem contexto, para três cenários:

1. **Adicionar um ano novo a uma fonte existente** (ex.: PIB 2022 quando o IBGE publicar; SNIS 2023).
2. **Adicionar uma fonte nova a uma dimensão existente.**
3. **Adicionar uma dimensão nova.**

Cada um deve dizer: quais arquivos tocar, o que rodar, o que validar, o que atualizar na documentação. E precisa resolver estruturalmente os obstáculos de §3.3: credencial GCP, ano-base de deflação, nomes de arquivo com data embutida, registro de data de extração, downloads manuais sem URL.

Para as fontes de **download manual sem origem no código** (AdaptaBrasil, Atlas de Desastres, Emendas CGU, `populacao_2023.xlsx`, `area_total.xlsx`, `df_igrejas_nomes.csv`, `estimativas_pop.csv`, `evangelicos_censo2010.csv`), proponha tratamento explícito: onde o arquivo bruto vive, como se registra proveniência e versão, e se é viável automatizar o download.

Trate o caso especial de **`populacao_2023.xlsx`**, cujo merge com o diretório foi feito à mão no Excel: ou o merge é reescrito em código, ou a fonte é substituída. Diga qual.

### 5.7 Orquestração, dependências e reprodutibilidade de ambiente

- Como as etapas se encadeiam e como se declara o grafo de dependências (`targets`? `Makefile`? script mestre numerado?) — alternativas e recomendação, considerando que o público é de pesquisadores em R, não engenheiros de dados.
- Como se roda **uma dimensão/fonte só** sem rodar tudo (pré-requisito do objetivo c).
- Como se elimina todo `setwd()` e todo caminho relativo nu — incluindo o `00_diretorios/R/script.R`, que já viola isso.
- **Âncora determinística do `here()`.** A raiz do repositório não tem `.Rproj`, então `here()` ancora no `.git`; mas há 7 `.Rproj` no legado que deslocam a âncora conforme onde a sessão for aberta. Note que `.gitignore` contém `*.Rproj`, então propor um `.Rproj` na raiz exige alterar o `.gitignore`.
- **Reprodutibilidade de ambiente:** hoje não há `renv`. Recomende, considerando o custo de manutenção.
- Como as credenciais GCP são fornecidas sem entrar no git (`.Renviron` já está no `.gitignore`).

### 5.8 Política de versionamento de dados

**Ponto de partida real:** o commit `20a3b11` **já commitou** `raw/` (10 `.txt`, ~660 mil linhas) e `processed/cadunico.csv`, e o `CLAUDE.md` declara isso como política vigente. Sua recomendação deve dizer explicitamente se mantém, restringe (só `processed/`? só até N MB?) ou reverte — e, se reverter, qual o custo (o histórico já contém os arquivos).

Cobrir também:

- **Proteger o legado:** incluir `mape_municipios/` no `.gitignore` deve ser o primeiro item da fase 0.
- **O passivo existente:** `.git` tem 18 GB (3,2 GB em `objects`, 15 GB em `lost-found`). Diga o que fazer com isso.
- O que vai para o git e o que não vai: dados brutos, intermediários, publicados, dicionário, metadados — considerando que a base larga tem 431 MB em CSV, há shapefiles de 167 MB que nunca entraram na base final, e `ivs_original.xlsx` tem 138 MB e está corrompido.
- Se propuser armazenamento externo (Git LFS, release do GitHub, bucket, Zenodo, OSF), diga o custo operacional e como afeta quem só quer baixar uma tabela.
- Como se versiona a **publicação** dos dados (tags? hash? campo de versão na documentação?).

### 5.9 Validação e QA

Checagens mínimas **por tabela**, executáveis, antes de publicar:

- unicidade da chave primária (hoje: `financas_municipais` 222 chaves / 235 linhas excedentes; `dados_historicos` 54 `muncode`);
- ausência de chave NA (hoje 122 linhas pré-dedup, 13 sobreviventes no publicado);
- domínio da chave validado contra a tabela de municípios, com **anti_join reportado, não descartado** (70 códigos de UF na segurança; 27 `muncode` fora do diretório na história);
- tipos conforme o dicionário;
- faixa de anos declarada vs observada;
- cobertura de municípios;
- nomes reservados e linter de nomes de coluna;
- ausência de valores sentinela não convertidos;
- equivalência entre formatos de export (reler cada export e comparar schema com o canônico).

Diga **qual ferramenta** (`pointblank`? `assertr`? `stopifnot` puro? `testthat`?), **onde os resultados aparecem**, e a regra: teste que falha bloqueia a publicação ou só avisa?

**Teste de paridade legado × novo (critério de aceitação global).** Especifique um procedimento reexecutável que reconstrói a base larga a partir das tabelas modulares e a compara com `4 Base completa/base_municipios_brasileiros.RDa` coluna a coluna, produzindo um relatório de diferenças classificadas em:
- **(a) esperadas e desejadas** — correções de bug, listadas a priori: linhas com `id_municipio` NA removidas, `sigla_uf` reconstituída, 2 indicadores do AdaptaBrasil recuperados, duplicatas de `dados_historicos`/`financas` resolvidas na origem;
- **(b) esperadas e neutras** — renomeações;
- **(c) NÃO explicadas** — bloqueiam a promoção da dimensão.

### 5.10 Plano de migração incremental em fases

- **Fases nomeadas**, com ordem de ataque justificada. Considere começar pela infraestrutura (funções comuns, dicionário, validação) ou por uma dimensão-piloto — argumente.
- **Qual dimensão é o piloto** e por quê. Candidatas: Economia (fonte única, simples), Identificação (é a espinha e **já está parcialmente migrada**), Assistência Social/DH (**já tem uma fonte migrada** — o CadÚnico —, então serve de teste da convenção existente), Meio-Ambiente (a mais complexa, valida o desenho).
- **Critério de "pronto" por dimensão** — checklist objetiva: script padronizado ✓, chave validada ✓, colunas harmonizadas ✓, dicionário preenchido ✓, metadados completos ✓, tabela publicada ✓, testes passando ✓, sem debug no script ✓, `CLAUDE.md` atualizado ✓.
- **Como legado e novo coexistem** durante a migração, e quando o legado é aposentado.
- **Quando e como os consumidores migram** — os 3 de código e os 2 de números (artigo e `Tabelas e Quadros.docx`) — sem quebrar figuras já publicadas.
- **Estimativa de esforço relativo** por fase (ordem de grandeza basta).

### 5.11 Riscos e o que NÃO fazer

- Riscos concretos, com mitigação. Inclua a **ordem de correção do defeito de chave NA**: remover o `distinct()` antes de eliminar as chaves NA na origem piora o artefato publicado de 13 para 122 linhas fantasma.
- **Fora de escopo ou desaconselhado** — inclusive tentações razoáveis a resistir (reescrever tudo de uma vez, trocar de linguagem, corrigir todos os erros de dados antes de estruturar o pipeline, migrar as análises junto com o ETL).
- O que fazer com os **bugs de dados já em produção** (§4.1): corrigir agora, depois, ou documentar como known issues? Alguns mudam números já publicados — trate explicitamente.

---

## 6. Método de trabalho

1. **Leia antes de propor.** Comece pelo `CLAUDE.md` e pelos dois `script.R` da árvore nova. Depois explore o legado: leia os scripts, confirme os diagnósticos centrais às suas decisões. O inventário acima é ponto de partida, não evangelho — se algo estiver errado, corrija e registre a correção no §1 do plano.

2. **NÃO EXECUTE NENHUM SCRIPT LEGADO.** Vários fazem `read_sql()` no BigQuery (o do SICONFI baixa 18,5 milhões de linhas) e geram **custo real de faturamento** na conta GCP; outros fazem `setwd()` e gravam arquivos. Verificação é por **leitura de código** e, quando indispensável, inspeção pontual com `nrow`/`names`/`str`/`head`. **Nunca carregue na íntegra** `base_municipios_brasileiros.csv` (431 MB), `base_municipios_brasileiros1.csv` (436 MB), `ivs_original.xlsx` (138 MB, corrompido), `receitas_orcamentarias.RData` (246 MB) ou `geolocalizacao.geojson` (100 MB). Se um diagnóstico só puder ser confirmado por execução cara, registre-o como "não verificado" em vez de executar.

3. **Complete o inventário das dimensões 7 a 17** respeitando o orçamento e a prioridade de §3.4. Melhor um inventário parcial honesto, com o pendente listado, do que um inventário raso em tudo.

4. **Em toda decisão estrutural — sobretudo as irreversíveis — apresente alternativas com prós, contras e recomendação justificada.** As oito de §5.1 são obrigatórias, mais: convenção de nomes de script, ferramenta de orquestração, política de versionamento de dados, tratamento dos nomes públicos com erro de digitação, licença dos dados.

5. **Pergunte apenas o que for genuinamente ambíguo** — o que depende de conhecimento que só eu tenho (quem usa a base hoje, se posso quebrar compatibilidade, prazo, quem mais vai mexer no projeto, restrição institucional sobre hospedagem dos dados). Não pergunte o que você pode descobrir lendo o repositório.

6. **NÃO IMPLEMENTE NADA.** Nenhum script novo, nenhuma refatoração, nenhuma migração de arquivo. A única coisa que você escreve é o documento do plano (mais, se necessário, a alteração de `.gitignore` descrita em §7).

7. **Seja específico.** Nomes reais, caminhos reais, assinaturas de função reais. Evite generalidades sobre boas práticas.

---

## 7. Formato de saída

Escreva o plano em **`plano/`**, na raiz do repositório, em português.

> **Atenção:** a linha `docs/` do `.gitignore` (herança do template pkgdown) ignora aquele diretório — por isso o plano **não** vai para `docs/`. Se ainda assim você preferir `docs/`, ajuste o `.gitignore` primeiro (ex.: trocar `docs/` por `/docs/reference/`); essa seria a **única** alteração de código autorizada nesta sessão.

Um arquivo (`plano/00-plano-reestruturacao.md`) ou vários (`plano/00-...md`, `01-...md`, com índice em `plano/README.md`), a seu critério.

Estrutura de seções esperada:

```
# Plano de Reestruturação do ETL do MAPEmunicipios

0.  Sumário executivo                      # o que muda, em ~20 linhas
1.  Diagnóstico consolidado                # o que verifiquei, o que corrigi do inventário,
                                           # o que ficou "não verificado"
2.  Inventário das 17 dimensões            # incluindo dims 7-17; pendências explicitadas
3.  Modelo de dados alvo                   # com as 8 decisões estruturais de §5.1
4.  Árvore de diretórios e convenção de nomes
5.  Camada de funções comuns
6.  Nomenclatura e harmonização de colunas
7.  Contrato de documentação
8.  Estratégia de atualização
9.  Orquestração e reprodutibilidade
10. Versionamento de dados
11. Validação e QA                         # incluindo o teste de paridade legado × novo
12. Plano de migração em fases
13. Riscos e o que não fazer
14. Alterações necessárias no CLAUDE.md
15. Decisões em aberto                     # o que preciso responder antes de começar
```

Ao final da sessão, na sua resposta (não no arquivo), liste em poucas linhas: onde o plano está, quais decisões estruturais você recomendou, e quais perguntas precisam da minha resposta antes de a execução começar.

---

## 8. Restrições reais

- **A linguagem é R.** Não proponha migrar para Python, dbt, SQL puro ou outra coisa. O público são pesquisadores que trabalham em R.
- **O legado (`mape_municipios/`, 18 GB) não deve ser commitado** — e hoje **nada impede**: não está no `.gitignore`, aparece como untracked. Leia à vontade, não versione.
- **Os dados brutos são grandes** e o precedente já commitado é "commitar tudo". Isso condiciona a política de versionamento — trate como restrição, não como detalhe.
- **`basedosdados` exige autenticação GCP com BigQuery faturado.** Quem for atualizar precisa de conta própria; o plano tem que tornar isso configurável e documentado. Diga também o que acontece com quem **não** tem BigQuery faturado e só quer **consumir** as tabelas publicadas.
- **Não há `renv`** hoje. Se recomendar, considere o custo de manutenção.
- **Há consumidores que não podem quebrar:** dois scripts de EDA, um post de blog já publicado (dependentes de ~40 nomes de coluna e de um CSV lido com caminho relativo) e um artigo publicado que declara contagens da base.
- **Preserve o que já funciona.** Especialmente: o `DICIONÁRIO.xlsx` alinhado 1-a-1 com a base; os campos `Fonte Original`/`Fonte Extração`/`Link` dos metadados por base, 100% preenchidos; e o que já está commitado na árvore nova (mudar exige justificativa e estimativa de custo).
