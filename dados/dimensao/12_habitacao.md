# Minha Casa Minha Vida — faixa financiada com FGTS

**Slug:** `12_habitacao`  
**Camada:** dimensao  
**Dimensão:** 12_habitacao

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Unidades habitacionais contratadas e valores do programa Minha Casa Minha Vida, restrito à faixa financiada com recursos do FGTS.

## Procedência

| | |
|---|---|
| Fonte original | Ministério das Cidades / Caixa |
| Fonte da extração | arquivo local sem URL registrada |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | Dado publico federal. Uso livre com citacao da fonte, nos termos da Lei de Acesso a Informacao (Lei 12.527/2011) e do Decreto 8.777/2016 (Politica de Dados Abertos do Executivo Federal). Verificado em 26/07/2026. |
| Periodicidade da fonte | eventual |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 94.832 |
| Colunas | 8 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 2007-2024 |
| **Cobertura observada na tabela** | **2007-2024** |
| Células vazias (colunas de conteúdo, sem as chaves) | 0% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `mcmv_unidades_contratadas_i` | double | unidades habitacionais | Unidades habitacionais contratadas no ano, na faixa do Minha Casa Minha Vida financiada com recursos do FGTS. | 0.0% |
| `mcmv_unidades_entregues_coorte_i` | double | contagem | Quantidade Unidades Habitacionais Entregues por ano no município | 0.0% |
| `mcmv_unidades_vigentes_em_20240930_i` | double | contagem | Quantidade Unidades Habitacionais Em construção  por ano no município | 0.0% |
| `mcmv_unidades_distratadas_em_20240930_i` | double | contagem | Quantidade Unidades Distratadas por ano no município | 0.0% |
| `mcmv_valor_contratado_brl2023` | double | BRL de dezembro de 2023 | Valor contratado no MCMV, por ano por município | 0.0% |
| `mcmv_valor_desembolsado_brl2023` | double | BRL de dezembro de 2023 | Valor desembolsado no MCMV, por ano por município | 0.0% |

## Ressalvas

ESCOPO: cobre APENAS a faixa financiada com FGTS. A faixa subsidiada com recursos do OGU não existe no repositório — o arquivo que deveria contê-la é byte a byte idêntico ao do FGTS. DEFEITO GRAVE NÃO CORRIGIDO NESTA MIGRAÇÃO: os valores monetários estão inflados em até cem vezes por um gsub aninhado na ordem errada, que remove o ponto decimal que ele mesmo acabou de criar. Corrigir exige reprocessar a fonte, o que está fora do escopo desta etapa; ver pendencias/. O painel começa em 2007, dois anos antes da criação do programa. DEFEITO ABERTO (auditoria 26/07/2026, achados 15 e 16): 83.679 das 94.832 linhas (88,2%) tem TODAS as colunas de conteudo iguais a zero — sao preenchimento do esqueleto do painel, e nao observacao. A tabela representa 'sem dado' de dois jeitos contraditorios: zero nas linhas fabricadas e NA em outras. E as duas colunas monetarias tem defeito de ESCALA em parte das celulas, com maximo de R$ 205,8 bilhoes num municipio-ano. A regra_preenchimento_temporal declarada nao descreve o zero-fill, e a cobertura_temporal_da_fonte declarada (2007-2019) contradiz a observada (2007-2024).

**`mcmv_unidades_contratadas_i`** — Sigla 'uh' (unidades habitacionais) opaca, sem prefixo de fonte nem de programa (MCMV/FGTS)

**`mcmv_unidades_entregues_coorte_i`** — Nao diz se sao entregues acumuladas ou no ano; na pratica e a soma dos contratos assinados no ano (entregues de coorte)

**`mcmv_unidades_vigentes_em_20240930_i`** — 'vigente' e um ESTOQUE medido na data_referencia (30/09/2024) imputado ao ano de assinatura - estoque tratado como fluxo

**`mcmv_unidades_distratadas_em_20240930_i`** — Mesmo problema de estoque-vs-fluxo

**`mcmv_valor_contratado_brl2023`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 16): ESCALA ERRADA em parte das celulas. O maximo publicado atribui a um unico municipio-ano R$ 205,8 bilhoes nesta coluna, o que e fisicamente impossivel para contratos do MCMV. A assinatura (mediana de cerca de R$ 3 milhoes, com picos em 10x e 100x sobre ela) indica um gsub de separador decimal/milhar aplicado na ordem errada sobre texto, na conversao para numerico. A correcao exige a planilha original, que NAO esta no repositorio: fontes/12_habitacao/mcmv_fgts/ nao tem raw/, e versionar o bruto e pre-requisito de qualquer conserto. O dominio_valido foi preenchido — estava vazio, e por isso a checagem de dominio nao tinha o que testar — com um teto de R$ 5 bilhoes por municipio-ano. NAO agregue esta coluna sem inspecionar a cauda.

**`mcmv_valor_desembolsado_brl2023`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 16): ESCALA ERRADA em parte das celulas. O maximo publicado atribui a um unico municipio-ano R$ 350,8 bilhoes nesta coluna, o que e fisicamente impossivel para contratos do MCMV. A assinatura (mediana de cerca de R$ 3 milhoes, com picos em 10x e 100x sobre ela) indica um gsub de separador decimal/milhar aplicado na ordem errada sobre texto, na conversao para numerico. A correcao exige a planilha original, que NAO esta no repositorio: fontes/12_habitacao/mcmv_fgts/ nao tem raw/, e versionar o bruto e pre-requisito de qualquer conserto. O dominio_valido foi preenchido — estava vazio, e por isso a checagem de dominio nao tinha o que testar — com um teto de R$ 5 bilhoes por municipio-ano. NAO agregue esta coluna sem inspecionar a cauda.

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("12_habitacao")
x <- mape_ler("12_habitacao", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 18:49 por `mape_gerar_documentacao()`._

