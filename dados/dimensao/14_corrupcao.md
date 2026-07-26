# Fiscalização da CGU em entes federativos

**Slug:** `14_corrupcao`  
**Camada:** dimensao  
**Dimensão:** 14_corrupcao

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Ações de fiscalização da Controladoria-Geral da União em municípios sorteados, com montante fiscalizado e proporção de falhas graves.

## Procedência

| | |
|---|---|
| Fonte original | Controladoria-Geral da União |
| Fonte da extração | microdados do Programa de Fiscalização em Entes Federativos |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | A VERIFICAR — a base deriva de Kustov & Pardelli (2024), material de replicacao academico, construido sobre os sorteios de auditoria da CGU. O dado da CGU e publico federal; a COMPILACAO e dos autores e a licenca de redistribuicao depende do repositorio de replicacao. Precisa de verificacao e da citacao dos autores. |
| Periodicidade da fonte | eventual |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 1.516 |
| Colunas | 8 |
| Municípios distintos | 1.352 de 5.570 (24.3%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 2006-2018 |
| **Cobertura observada na tabela** | **2006-2018** |
| Células vazias (colunas de conteúdo, sem as chaves) | 0.01% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `cgu_constatacoes_i` | double | contagem | Total de ações fiscalizadas nos municípios | 0.0% |
| `cgu_constatacoes_falha_grave_i` | double | contagem | Total de falhas graves nas ações fiscalizadas nos municípios | 0.0% |
| `cgu_montante_fiscalizado_brl2023` | double | BRL de dezembro de 2023 | Montante de recursos fiscalizados (deflacionados para dezembro de 2023) | 0.0% |
| `cgu_montante_fiscalizado_com_falha_grave_brl2023` | double | BRL de dezembro de 2023 | Montante de recursos fiscalizados classificados como falhas graves (deflacionados para dezembro de 2023) | 0.0% |
| `cgu_constatacoes_falha_grave_sobre_total_prop` | double | proporcao | Proporção de falhas graves em relação ao total de ações fiscalizadas | 0.0% |
| `cgu_montante_falha_grave_sobre_fiscalizado_prop` | double | proporcao | Proporção do montante fiscalizado como falha grave em relação ao montante fiscalizado | 0.1% |

## Ressalvas

GRANULARIDADE REAL É EVENTO, NÃO PAINEL. O programa audita municípios SORTEADOS, e o dado bruto é uma tabela de constatações dentro de ordens de serviço dentro de ciclos de sorteio. A agregação para município-ano produz 1.516 linhas, que na base larga ocupavam 180.285 — ou seja, 99,2% de células vazias. É o caso que justifica sozinho publicar tabelas separadas. DEFEITO NÃO CORRIGIDO: montante_fiscalizado é atributo da ordem de serviço e é somado uma vez por constatação, inflando o valor em 4,87 vezes na mediana e até 34,2 vezes. total_acao conta constatações (82.664) e não ações de fiscalização (22.713). DEFEITO NÃO CORRIGIDO: o deflator usa o ano da fiscalização quando deveria usar o ano do repasse, que existe no bruto e é ignorado.

**`cgu_constatacoes_i`** — Nome generico E semanticamente errado: conta CONSTATACOES, nao acoes; alem disso 'acao' e o nome de outra coluna do proprio bruto (cgu$acao = acao orcamentaria)

**`cgu_constatacoes_falha_grave_i`** — Sem prefixo de fonte; 'falha grave' e vocabulario interno da CGU nao definido na base

**`cgu_montante_fiscalizado_brl2023`** — Sem prefixo, sem unidade e sem indicacao de que esta deflacionado a 12/2023

**`cgu_montante_fiscalizado_com_falha_grave_brl2023`** — Ambiguo entre 'montante fiscalizado onde houve falha grave' e 'montante da falha grave' - e o primeiro, com dupla contagem

**`cgu_constatacoes_falha_grave_sobre_total_prop`** — Nao diz o denominador (constatacoes, incluindo as do tipo 'Informacao'); sem sufixo de escala

**`cgu_montante_falha_grave_sobre_fiscalizado_prop`** — O NOME MENTE: prefixo montante_ sugere valor monetario, mas o conteudo e uma PROPORCAO 0-1 (cgu.R:23). Congelado na base publicada, posicao 406 de renomear_variaveis.R:149

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("14_corrupcao")
x <- mape_ler("14_corrupcao", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 20:38 por `mape_gerar_documentacao()`._

