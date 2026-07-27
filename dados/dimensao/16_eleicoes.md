# Eleições municipais e alinhamento político

**Slug:** `16_eleicoes`  
**Camada:** dimensao  
**Dimensão:** 16_eleicoes

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Resultados das eleições municipais: comparecimento, votos por candidato eleito e segundo colocado, concentração partidária e alinhamento com o governo estadual.

## Procedência

| | |
|---|---|
| Fonte original | Tribunal Superior Eleitoral |
| Fonte da extração | Base dos Dados e pacotes de acesso ao TSE |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | Dado publico federal. Uso livre com citacao da fonte, nos termos da Lei de Acesso a Informacao (Lei 12.527/2011) e do Decreto 8.777/2016 (Politica de Dados Abertos do Executivo Federal). Verificado em 26/07/2026. |
| Periodicidade da fonte | quadrienal |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 133.496 |
| Colunas | 36 |
| Municípios distintos | 5.568 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 2000-2023 |
| **Cobertura observada na tabela** | **2000-2023** |
| Células vazias (colunas de conteúdo, sem as chaves) | 3.69% |
| Regra de preenchimento temporal | `carry_forward` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `tse_eleitores_aptos_prefeitura_i` | double | eleitores | Total eleitores aptos disputa majoritária municipal (prefeitura) | 0.0% |
| `tse_comparecimento_prefeitura_i` | double | eleitores | Total comparecimento prefeitura | 0.0% |
| `comparecimento_prefeito_pct` | double | percentual | Proporção comparecimento prefeitura | 0.0% |
| `tse_votos_brancos_prefeito_pct` | double | percentual | Percentual de votos BRANCOS para prefeito no municipio, sobre o total de votos do pleito municipal. Mediana 1,26%, e correlacao de 0,52 com tse_votos_brancos_camara_pct — o dado e o nome correspondem. | 0.0% |
| `tse_votos_nulos_prefeito_pct` | double | percentual | Percentual de votos NULOS para prefeito no municipio, sobre o total de votos do pleito municipal. Mediana 4,46%, coerente com a serie de nulos da camara (2,76%) e distinta da de brancos. | 0.0% |
| `turno_i` | integer | turno | Turno da eleição | 0.0% |
| `nep_prefeitura_idx` | double | indice | Número efetivo de partidos - eleições prefeitura (Laakso e Taagepera 1979)  | 0.0% |
| `fracionalizacao_prefeitura_idx` | double | indice de 0 a 1 | Fracionalização Prefeitura (Rae 1971) | 0.0% |
| `tse_eleitores_aptos_camara_i` | double | eleitores | Total eleitores aptos disputa proporcional municipal (Câmara de Vereadores) | 0.0% |
| `tse_comparecimento_camara_i` | double | eleitores | Total comparecimento Câmara de Vereadores | 0.0% |
| `comparecimento_camara_pct` | double | percentual | Proporção comparecimento Câmara de Vereadores | 0.0% |
| `tse_votos_brancos_camara_pct` | double | percentual | Proporção Votos Brancos Câmara de Vereadores | 0.0% |
| `tse_votos_nulos_camara_pct` | double | percentual | Proporção Votos Nulos Câmara de Vereadores | 0.0% |
| `nep_camara_idx` | double | indice | Número efetivo de partidos - eleições Câmara de Vereadores | 0.0% |
| `fracionalizacao_camara_idx` | double | indice de 0 a 1 | Fracionalização Câmara de Vereadores | 0.0% |
| `ano_ref_eleicao` | double | ano | Ano do pleito a que a linha se refere. Distinto de `ano`, que e a chave do painel: um mandato eleito em 2016 aparece nos anos 2017 a 2020 do painel, todos com ano_ref_eleicao = 2016. | 0.0% |
| `nome_urna_prefeito_eleito_cat` | character | texto | Nome do prefeito eleito | 1.8% |
| `sigla_partido_prefeito_eleito_cat` | character | texto | Partido do prefeito eleito | 1.8% |
| `numero_tse_partido_prefeito_eleito` | double | numero de legenda | Número do partido do prefeito eleito | 1.8% |
| `votos_prefeito_eleito_prop` | double | proporcao | % votos prefeito eleito | 1.8% |
| `partido_segundo_colocado_cat` | character | sigla | Partido do segundo colocado | 5.4% |
| `numero_tse_partido_segundo_colocado` | double | numero de legenda | Nº do partido do segundo colocado | 5.4% |
| `votos_segundo_colocado_prefeito_prop` | double | proporcao | % Votos do segundo colocado | 5.4% |
| `tse_margem_votos_i` | double | votos | Diferença de votos entre prefeito eleito e segundo colocado | 5.4% |
| `margem_prop` | double | proporcao | Diferença entre % de votos de eleitos | 5.4% |
| `partido_governador_eleito_cat` | character | sigla | Sigla Partido Governador Eleito | 10.1% |
| `sigla_partido_governador_segundo_colocado_cat` | character | sigla | Sigla do partido do candidato a governador que ficou em segundo lugar na eleição estadual, atribuída ao município. | 10.1% |
| `coligacao_governador_eleito_cat` | character | texto | Composicao da coligacao do governador eleito na UF do municipio, como lista de siglas partidarias em texto livre, no formato do TSE. Nao e vocabulario fechado: a grafia varia entre pleitos. | 10.1% |
| `coligacao_governador_segundo_lugar_cat` | character | texto | Composicao da coligacao do candidato a governador que ficou em segundo lugar na UF do municipio, como lista de siglas partidarias em texto livre, no formato do TSE. | 10.1% |
| `nome_urna_governador_eleito_cat` | character | texto | Nome de urna do governador eleito no estado do município. | 10.1% |
| `nome_urna_governador_segundo_lugar_cat` | character | texto | Nome de urna do candidato a governador que ficou em segundo lugar no estado do município. | 10.1% |
| `votos_governador_eleito_pct` | double | percentual | Percentual de votos válidos obtidos pelo governador eleito no município, e não no estado. | 10.1% |
| `tse_votos_governador_segundo_lugar_pct` | double | percentual | Percentual de votos do candidato a governador que ficou em segundo lugar, apurados NESTE municipio, sobre o total de votos validos do municipio para o cargo de governador. O denominador e municipal, nao estadual. | 10.1% |
| `flag_alinhamento_partidario_governador` | double | booleano | Prefeito é do mesmo partido que governador? | 10.1% |

## Ressalvas

O PAINEL ANUAL NÃO TEM DADO ANUAL: é carry-forward puro. O valor do ano da eleição é replicado nos três anos seguintes do mandato. DEFEITO GRAVE: os rótulos de votos brancos e nulos estão TROCADOS. A coluna chamada proporcao_votos_nulos_prefeitura contém votos BRANCOS, por causa de um rename() que passa o mesmo argumento de origem duas vezes. O dicionário e a planilha de variáveis documentam as duas ao contrário do conteúdo, então concordam entre si e discordam do dado. ESCALAS INCOMPATÍVEIS na mesma tabela: pct_votos_eleito está em 0-1 e pct_votos_governador_eleito está em 0-100. Sete variáveis de governador são, na verdade, UF x ano replicadas em todos os municípios do estado. 1,28 GB de microdados do TSE de 2022 e 2024 estão em disco e não são referenciados por nenhum script; a série para em 2020. ATUALIZACAO DE 26/07/2026 (auditoria, achado 63): esta secao usava nomes de coluna que ja nao existem. Os nomes atuais sao tse_votos_brancos_prefeito_pct e tse_votos_nulos_prefeito_pct (renomeados em 26/07/2026, ver deprecacao.csv). E a afirmacao de que os rotulos de brancos e nulos estao TROCADOS no dado e FALSA hoje: o dado e os nomes correspondem (brancos com mediana 1,26%, nulos com 4,46%, e correlacao de 0,52 entre brancos-prefeito e brancos-camara contra 0,11 com nulos-camara). O que estava trocado era a DESCRICAO das duas no dicionario, e foi corrigido. O par votos_prefeito_eleito_prop / votos_governador_eleito_pct continua em escalas diferentes, e esse alerta continua valendo.

**`comparecimento_prefeito_pct`** — Prefixo 'proporcao' com escala 0-100 (16,56 a 99,37) e sufixo de cargo divergente. E uma das colunas consumidas por scripts/artigo

**`tse_votos_brancos_prefeito_pct`** — CORRIGIDO em 26/07/2026 (auditoria, achado 30): o DADO e o NOME sempre estiveram certos (brancos com mediana 1,26%, nulos com 4,46%); o que estava trocado era o campo descricao, que descrevia esta coluna como 'Proporcao Votos Nulos Prefeitura' e a irma como brancos. O legado gravava o conteudo trocado, por um rename() que passava o mesmo argumento de origem duas vezes, e a migracao consertou o conteudo mas herdou o texto antigo — que passou a descrever um defeito ja resolvido como se fosse o vivo, enquanto o defeito vivo (a descricao invertida) ficava sem registro.

**`tse_votos_nulos_prefeito_pct`** — CORRIGIDO em 26/07/2026 (auditoria, achado 30): ver o campo problema de tse_votos_brancos_prefeito_pct. A descricao das duas colunas estava trocada entre si no dicionario; o dado nao estava.

**`turno_i`** — Constante igual a 1 em todas as linhas: a base só traz primeiro turno. Mantida para não quebrar consumidor, mas não informa nada. CORRIGIDO PARCIALMENTE em 26/07/2026 (auditoria, achado 102): o tipo era `double` apesar do sufixo _i de contagem inteira, e passou a `integer`. A coluna continua CONSTANTE igual a 1 em todas as linhas e continua marcada acao = remover — remover coluna de tabela publicada depende do responsavel.

**`comparecimento_camara_pct`** — Mesma inconsistencia de escala (0-100 sob prefixo 'proporcao'). E uma das colunas consumidas por scripts/artigo

**`tse_votos_brancos_camara_pct`** — Chamada de proporção e medida em percentual: chega a 19,45.

**`tse_votos_nulos_camara_pct`** — Chamada de proporção e medida em percentual: chega a 55,41.

**`ano_ref_eleicao`** — Mesmo nome definido em duas dimensoes juntadas na mesma base (dim 17 e dim 7, Script Producao Banco de Dados Municipal.R:1224) e redefinido por consumidor em 5 Analise Exploratoria/Desastres.R:56. E u

**`nome_urna_prefeito_eleito_cat`** — Guarda NM_URNA_CANDIDATO (nome de urna), nao o nome civil; o dicionario diz apenas 'Nome do prefeito eleito'

**`sigla_partido_prefeito_eleito_cat`** — Generico: e o partido do PREFEITO eleito, mas nada no nome diz isso; colide com partido_segundo_colocado e sg_partido_governador_eleito

**`numero_tse_partido_prefeito_eleito`** — E o codigo TSE do partido do prefeito; o tipo integer sugere quantidade e o nome nao distingue de numero_segundo_colocado

**`votos_prefeito_eleito_prop`** — Sem sufixo de cargo e prefixo pct_ com escala 0-1 (0. Funcoes.Rmd:87), enquanto pct_votos_governador_* esta em 0-100

**`numero_tse_partido_segundo_colocado`** — Idem: codigo TSE tipado como integer, nome sugere quantidade

**`votos_segundo_colocado_prefeito_prop`** — Mesmo defeito: pct_ em escala 0-1, sem cargo

**`sigla_partido_governador_segundo_colocado_cat`** — 'segundo_lugar' contra 'segundo_colocado' para o mesmo conceito na MESMA tabela; prefixo sg_ do TSE preservado

**`votos_governador_eleito_pct`** — Prefixo pct_ em escala 0-100 (0. Funcoes.Rmd:317), contradizendo pct_votos_eleito no mesmo painel

**`flag_alinhamento_partidario_governador`** — Flag sem prefixo de tipo; a variante documentada alinhado_coalizao_governador e calculada (2.Criando:152-156) e nunca chega a base

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("16_eleicoes")
x <- mape_ler("16_eleicoes", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 21:35 por `mape_gerar_documentacao()`._

