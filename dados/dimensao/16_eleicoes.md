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
| Licença | a verificar |
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
| Cobertura declarada pela fonte | 2000-2020 |
| **Cobertura observada na tabela** | **2000-2023** |
| Células vazias | 3.7% |
| Regra de preenchimento temporal | `carry_forward` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `tse_eleitores_aptos_prefeitura_i` | double | eleitores | Total eleitores aptos disputa majoritária municipal (prefeitura) | 0.0% |
| `tse_comparecimento_prefeitura_i` | double | eleitores | Total comparecimento prefeitura | 0.0% |
| `comparecimento_prefeito_pct` | double | percentual | Proporção comparecimento prefeitura | 0.0% |
| `proporcao_votos_brancos_prefeito_pct` | double | percentual | Proporção Votos Nulos Prefeitura | 0.0% |
| `proporcao_votos_nulos_prefeito_pct` | double | percentual | Proporção Votos Brancos Prefeitura | 0.0% |
| `turno_i` | double | turno | Turno da eleição | 0.0% |
| `nep_prefeitura_idx` | double | indice | Número efetivo de partidos - eleições prefeitura (Laakso e Taagepera 1979)  | 0.0% |
| `fracionalizacao_prefeitura_idx` | double | indice de 0 a 1 | Fracionalização Prefeitura (Rae 1971) | 0.0% |
| `tse_eleitores_aptos_camara_i` | double | eleitores | Total eleitores aptos disputa proporcional municipal (Câmara de Vereadores) | 0.0% |
| `tse_comparecimento_camara_i` | double | eleitores | Total comparecimento Câmara de Vereadores | 0.0% |
| `comparecimento_camara_pct` | double | percentual | Proporção comparecimento Câmara de Vereadores | 0.0% |
| `tse_votos_brancos_camara_pct` | double | % | Proporção Votos Brancos Câmara de Vereadores | 0.0% |
| `tse_votos_nulos_camara_pct` | double | % | Proporção Votos Nulos Câmara de Vereadores | 0.0% |
| `nep_camara_idx` | double | indice | Número efetivo de partidos - eleições Câmara de Vereadores | 0.0% |
| `fracionalizacao_camara_idx` | double | indice de 0 a 1 | Fracionalização Câmara de Vereadores | 0.0% |
| `ano_ref_eleicao` | double | ano | — | 0.0% |
| `nome_urna_prefeito_eleito` | character | texto | Nome do prefeito eleito | 1.8% |
| `sigla_partido_prefeito_eleito` | character | texto | Partido do prefeito eleito | 1.8% |
| `numero_tse_partido_prefeito_eleito` | double | numero de legenda | Número do partido do prefeito eleito | 1.8% |
| `votos_prefeito_eleito_prop` | double | proporcao | % votos prefeito eleito | 1.8% |
| `partido_segundo_colocado_cat` | character | sigla | Partido do segundo colocado | 5.4% |
| `numero_tse_partido_segundo_colocado` | double | numero de legenda | Nº do partido do segundo colocado | 5.4% |
| `votos_segundo_colocado_prefeito_prop` | double | proporcao | % Votos do segundo colocado | 5.4% |
| `tse_margem_votos_i` | double | votos | Diferença de votos entre prefeito eleito e segundo colocado | 5.4% |
| `margem_prop` | double | proporcao | Diferença entre % de votos de eleitos | 5.4% |
| `partido_governador_eleito_cat` | character | sigla | Sigla Partido Governador Eleito | 10.1% |
| `sigla_partido_governador_segundo_colocado` | character | sigla | Sigla do partido do candidato a governador que ficou em segundo lugar na eleição estadual, atribuída ao município. | 10.1% |
| `coligacao_governador_eleito_cat` | character | texto | — | 10.1% |
| `coligacao_governador_segundo_lugar_cat` | character | texto | — | 10.1% |
| `nome_urna_governador_eleito` | character | texto | Nome de urna do governador eleito no estado do município. | 10.1% |
| `nome_urna_governador_segundo_lugar` | character | texto | Nome de urna do candidato a governador que ficou em segundo lugar no estado do município. | 10.1% |
| `votos_governador_eleito_pct` | double | % | Percentual de votos válidos obtidos pelo governador eleito no município, e não no estado. | 10.1% |
| `tse_votos_governador_segundo_lugar_pct` | double | % | — | 10.1% |
| `flag_alinhamento_partidario_governador` | double | booleano | Prefeito é do mesmo partido que governador? | 10.1% |

## Ressalvas

O PAINEL ANUAL NÃO TEM DADO ANUAL: é carry-forward puro. O valor do ano da eleição é replicado nos três anos seguintes do mandato. DEFEITO GRAVE: os rótulos de votos brancos e nulos estão TROCADOS. A coluna chamada proporcao_votos_nulos_prefeitura contém votos BRANCOS, por causa de um rename() que passa o mesmo argumento de origem duas vezes. O dicionário e a planilha de variáveis documentam as duas ao contrário do conteúdo, então concordam entre si e discordam do dado. ESCALAS INCOMPATÍVEIS na mesma tabela: pct_votos_eleito está em 0-1 e pct_votos_governador_eleito está em 0-100. Sete variáveis de governador são, na verdade, UF x ano replicadas em todos os municípios do estado. 1,28 GB de microdados do TSE de 2022 e 2024 estão em disco e não são referenciados por nenhum script; a série para em 2020.

**`comparecimento_prefeito_pct`** — Prefixo 'proporcao' com escala 0-100 (16,56 a 99,37) e sufixo de cargo divergente. E uma das colunas consumidas por scripts/artigo

**`proporcao_votos_brancos_prefeito_pct`** — O NOME NAO CORRESPONDE AO CONTEUDO: contem votos BRANCOS (mediana 1,264), efeito do rename duplicado em eleicoes_municipais.R:337-338. Publicado assim

**`proporcao_votos_nulos_prefeito_pct`** — Unica coluna da dimensao sem sufixo de cargo (e do pleito de prefeito) e carrega o conteudo trocado com a coluna anterior (mediana 4,455 = nulos)

**`turno_i`** — Constante igual a 1 em todas as linhas: a base só traz primeiro turno. Mantida para não quebrar consumidor, mas não informa nada.

**`comparecimento_camara_pct`** — Mesma inconsistencia de escala (0-100 sob prefixo 'proporcao'). E uma das colunas consumidas por scripts/artigo

**`tse_votos_brancos_camara_pct`** — Chamada de proporção e medida em percentual: chega a 19,45.

**`tse_votos_nulos_camara_pct`** — Chamada de proporção e medida em percentual: chega a 55,41.

**`ano_ref_eleicao`** — Mesmo nome definido em duas dimensoes juntadas na mesma base (dim 17 e dim 7, Script Producao Banco de Dados Municipal.R:1224) e redefinido por consumidor em 5 Analise Exploratoria/Desastres.R:56. E u

**`nome_urna_prefeito_eleito`** — Guarda NM_URNA_CANDIDATO (nome de urna), nao o nome civil; o dicionario diz apenas 'Nome do prefeito eleito'

**`sigla_partido_prefeito_eleito`** — Generico: e o partido do PREFEITO eleito, mas nada no nome diz isso; colide com partido_segundo_colocado e sg_partido_governador_eleito

**`numero_tse_partido_prefeito_eleito`** — E o codigo TSE do partido do prefeito; o tipo integer sugere quantidade e o nome nao distingue de numero_segundo_colocado

**`votos_prefeito_eleito_prop`** — Sem sufixo de cargo e prefixo pct_ com escala 0-1 (0. Funcoes.Rmd:87), enquanto pct_votos_governador_* esta em 0-100

**`numero_tse_partido_segundo_colocado`** — Idem: codigo TSE tipado como integer, nome sugere quantidade

**`votos_segundo_colocado_prefeito_prop`** — Mesmo defeito: pct_ em escala 0-1, sem cargo

**`sigla_partido_governador_segundo_colocado`** — 'segundo_lugar' contra 'segundo_colocado' para o mesmo conceito na MESMA tabela; prefixo sg_ do TSE preservado

**`votos_governador_eleito_pct`** — Prefixo pct_ em escala 0-100 (0. Funcoes.Rmd:317), contradizendo pct_votos_eleito no mesmo painel

**`flag_alinhamento_partidario_governador`** — Flag sem prefixo de tipo; a variante documentada alinhado_coalizao_governador e calculada (2.Criando:152-156) e nunca chega a base

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("16_eleicoes")
x <- mape_ler("16_eleicoes", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 01:47 por `mape_gerar_documentacao()`._

