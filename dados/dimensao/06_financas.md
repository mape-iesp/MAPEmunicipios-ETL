# Finanças municipais: receitas orçamentárias e emendas parlamentares

**Slug:** `06_financas`  
**Camada:** dimensao  
**Dimensão:** 06_financas

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Receitas orçamentárias municipais do SICONFI e valores de emendas parlamentares por função orçamentária, da CGU.

## Procedência

| | |
|---|---|
| Fonte original | Tesouro Nacional (SICONFI) e Controladoria-Geral da União |
| Fonte da extração | Base dos Dados e Portal da Transparência |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | a verificar |
| Periodicidade da fonte | anual |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 180.023 |
| Colunas | 39 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 1989-2024 |
| **Cobertura observada na tabela** | **1989-2024** |
| Células vazias | 71.7% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `siconfi_receitas_totais_brl2023` | double | BRL de dezembro de 2023 | Total de receitas municipais, considerando todos os estágios (deflacionado dez/23) | 0.3% |
| `siconfi_deducao_fundeb_brl2023` | double | R$ | Produto Interno Bruto a preços correntes (deflacionado dez/23) | 0.3% |
| `siconfi_deducao_transferencias_constitucionais_brl2023` | double | R$ | Impostos, líquidos de subsídios, sobre produtos a preços correntes (deflacionado dez/23) | 0.3% |
| `siconfi_deducao_outras_brl2023` | double | R$ | Valor adicionado bruto a preços correntes total (deflacionado dez/23) | 0.3% |
| `siconfi_receitas_brutas_brl2023` | double | R$ | Valor adicionado bruto a preços correntes da agropecuária (deflacionado dez/23) | 0.3% |
| `siconfi_receitas_realizadas_brl2023` | double | R$ | Valor adicionado bruto a preços correntes da indústria (deflacionado dez/23) | 0.3% |
| `siconfi_receitas_proprias_brl2023` | double | R$ | Valor adicionado bruto a preços correntes dos serviços, exclusive administração, defesa, educação e saúde públicas e seguridade social (deflacionado dez/23) | 0.3% |
| `siconfi_receitas_proprias_realizadas_brl_nominal` | double | R$ | Valor adicionado bruto a preços correntes da administração, defesa, educação e saúde públicas e seguridade social (deflacionado dez/23) | 0.3% |
| `siconfi_receitas_proprias_sobre_receitas_brutas_prop` | double | proporcao | Receitas próprias sobre receitas brutas. Quatro município-ano têm valor negativo, o que vem de estorno lançado na receita na origem do SICONFI. | 0.3% |
| `siconfi_receitas_proprias_realizadas_sobre_realizadas_prop` | double | proporcao | Razão Receitas Próprias em relação ao total de receitas realizadas | 97.0% |
| `emendas_localidade_gasto_cat` | character | texto | — | 94.6% |
| `emendas_localidade_gasto_secundaria_cat` | character | texto | — | 94.6% |
| `emendas_tipo_cat` | character | texto | Tipo de emenda igual a individual | 94.6% |
| `emendas_valor_total_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas no município | 94.6% |
| `emendas_valor_agricultura_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Agricultura | 94.6% |
| `emendas_valor_comercio_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Comércio e serviços | 94.6% |
| `emendas_valor_desporto_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Desporto e lazer | 94.6% |
| `emendas_valor_saude_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Saúde | 94.6% |
| `emendas_valor_urbanismo_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Urbanismo | 94.6% |
| `emendas_valor_organizacao_agraria_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Organização agrária | 94.6% |
| `emendas_valor_assistencia_social_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Assistência social | 94.6% |
| `emendas_valor_educacao_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Educação | 94.6% |
| `emendas_valor_direitos_cidadania_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Direitos da cidadania | 94.6% |
| `emendas_valor_defesa_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Defesa nacional | 94.6% |
| `emendas_valor_ciencia_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Ciência e Tecnologia | 94.6% |
| `emendas_valor_cultura_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Cultura | 94.6% |
| `emendas_valor_industria_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Indústria | 94.6% |
| `emendas_valor_seguranca_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Segurança pública | 94.6% |
| `emendas_valor_gestao_ambiental_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Gestão ambiental | 94.6% |
| `emendas_valor_habitacao_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Habitação | 94.6% |
| `emendas_valor_administracao_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Administração | 94.6% |
| `emendas_valor_saneamento_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Saneamento | 94.6% |
| `emendas_valor_trabalho_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Trabalho | 94.6% |
| `emendas_valor_transporte_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Transporte | 94.6% |
| `emendas_valor_previdencia_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Previdência social | 94.6% |
| `emendas_valor_encargos_especiais_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Encargos especiais | 94.6% |
| `emendas_valor_multiplo_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Múltiplo | 94.6% |

## Ressalvas

CHAVE DUPLICADA NA ORIGEM: 222 pares município-ano aparecem mais de uma vez, com 235 linhas excedentes. A causa provável é a junção entre receitas e emendas, feita sem verificação de cardinalidade, combinada com o fato de as emendas serem associadas ao município POR NOME, sem UF — 1.067 de 11.649 linhas têm UF divergente, e o próprio comentário do script legado admite o problema. As 24 colunas de emendas chegam ao artefato com nomes em Title Case e com acento, gerados por pivot_wider (Comércio.e.serviços, Ciência.e.Tecnologia). Elas colidem com os NOMES DAS PRÓPRIAS DIMENSÕES do painel. O mapeamento para valor_emendas_* foi reconstruído e gravado. A receita própria é classificada por expressão regular sobre texto livre, procurando IPTU, ITBI e ISS no nome da conta. total_receitas_fundeb MEDE A DEDUÇÃO do FUNDEB, não uma receita. Os valores já vêm deflacionados para dezembro de 2023, sem sufixo.

**`siconfi_deducao_fundeb_brl2023`** — O NOME MENTE: e a DEDUCAO do FUNDEB, nao uma receita (siconfi.R:94, sum(valor[deducao_fundeb == 1])). Esta entre as colunas consumidas por scripts/artigo

**`siconfi_deducao_transferencias_constitucionais_brl2023`** — Tambem e uma DEDUCAO (siconfi.R:95, estagio == 'Deducoes - Transferencias Constitucionais'), nao a transferencia recebida

**`siconfi_deducao_outras_brl2023`** — Nome hibrido 'receitas' + 'deducoes'; e so deducao (siconfi.R:96)

**`siconfi_receitas_brutas_brl2023`** — Sem prefixo de fonte nem marca de deflacao (deflacionada em siconfi.R:119-122)

**`siconfi_receitas_realizadas_brl2023`** — Idem

**`siconfi_receitas_proprias_brl2023`** — Idem; a regra de 'receita propria' esta so no case_when de siconfi.R:59

**`siconfi_receitas_proprias_realizadas_brl_nominal`** — UNICA coluna monetaria de financas que NAO entra no across de deflacao (siconfi.R:119-122): fica em reais nominais entre irmas deflacionadas para 12/2023, com nome indistinguivel

**`siconfi_receitas_proprias_sobre_receitas_brutas_prop`** — Escala 0-1 sem sufixo; denominador e total_receitas, que tem dupla contagem

**`siconfi_receitas_proprias_realizadas_sobre_realizadas_prop`** — Idem, escala 0-1 sem sufixo

**`emendas_localidade_gasto_cat`** — PUBLICADO e generico; e o texto livre 'Municipio - UF' da CGU usado como chave de pareamento (Emendas/script.R:40)

**`emendas_localidade_gasto_secundaria_cat`** — PUBLICADO com sufixo numerico sem significado; e localidade_gasto sem a UF e em minusculas (script.R:61-62)

**`emendas_tipo_cat`** — PUBLICADO, mas constante apos o filtro tipo_emenda == 'Emenda Individual - Transferencias' (script.R:53) - coluna sem variancia

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("06_financas")
x <- mape_ler("06_financas", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 01:47 por `mape_gerar_documentacao()`._

