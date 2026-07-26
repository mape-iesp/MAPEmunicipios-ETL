# PIB municipal e valor adicionado

**Slug:** `04_economia`  
**Camada:** dimensao  
**Dimensão:** 04_economia

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Produto Interno Bruto municipal, valor adicionado por setor e indicadores derivados, do Sistema de Contas Regionais do IBGE.

## Procedência

| | |
|---|---|
| Fonte original | IBGE — Contas Regionais |
| Fonte da extração | Base dos Dados |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | a verificar |
| Periodicidade da fonte | anual |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 127.786 |
| Colunas | 19 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 1999-2021 |
| **Cobertura observada na tabela** | **1999-2021** |
| Células vazias | 0% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `pib_brl2023` | integer | BRL de dezembro de 2023 | PIB municipal (deflacionado dez/23) | 0.0% |
| `impostos_liquidos_brl2023` | integer | BRL de dezembro de 2023 | Impostos, líquidos de subsídios, sobre produtos a preços correntes (deflacionado dez/23) | 0.0% |
| `valor_adicionado_bruto_brl2023` | integer | BRL de dezembro de 2023 | Valor adicionado bruto a preços correntes total (deflacionado dez/23) | 0.0% |
| `valor_adicionado_agropecuaria_brl2023` | integer | BRL de dezembro de 2023 | Valor adicionado bruto a preços correntes da agropecuária (deflacionado dez/23) | 0.0% |
| `valor_adicionado_industria_brl2023` | integer | BRL de dezembro de 2023 | Valor adicionado bruto a preços correntes da indústria (deflacionado dez/23) | 0.0% |
| `valor_adicionado_servicos_brl2023` | integer | BRL de dezembro de 2023 | Valor adicionado bruto a preços correntes dos serviços, exclusive administração, defesa, educação e saúde públicas e seguridade social (deflacionado dez/23) | 0.0% |
| `valor_adicionado_administracao_publica_brl2023` | integer | BRL de dezembro de 2023 | Valor adicionado bruto a preços correntes da administração, defesa, educação e saúde públicas e seguridade social (deflacionado dez/23) | 0.0% |
| `sigla_uf_nome` | character | texto | Nome da Unidade da Federação | 0.0% |
| `pib_per_capita_brl2023` | double | R$ | Produto Interno Bruto a preços correntes (deflacionado dez/23), dividido pela população estimada | 0.0% |
| `razao_impostos_sobre_pib_prop` | double | proporcao | Divisão entre impostos líquidos e PIB | 0.0% |
| `participacao_va_administracao_publica_prop` | double | proporcao | Divisão entre VA ADESPSS e VA geral | 0.0% |
| `participacao_va_industria_prop` | double | proporcao | Divisão entre VA Indústria e VA geral | 0.0% |
| `participacao_va_agropecuaria_prop` | double | proporcao | Divisão entre VA Agropecuária e VA geral | 0.0% |
| `participacao_va_servicos_prop` | double | proporcao | Divisão entre VA Serviços e VA geral | 0.0% |
| `ln_pib_brl2023` | double | R$ | PIB em log10 | 0.0% |
| `ln_pib_per_capita_brl2023` | double | R$ | PIB per capita em log10 | 0.0% |
| `ln_valor_adicionado_bruto_brl2023` | double | R$ | VA em log10 | 0.0% |

## Ressalvas

A coluna `populacao` que acompanhava esta fonte foi DESCARTADA: ela é uma segunda extração da mesma tabela do IBGE já publicada em 02_populacao, idêntica em 100% das linhas comparáveis, e a duplicação faz a mesma consulta ser faturada duas vezes. CONSEQUÊNCIA CONHECIDA: pib_per_capita foi calculado com esse denominador, que o legado descarta depois da junção. Isso torna a coluna não reproduzível a partir da base publicada. Ao reextrair, o cálculo deve passar a usar 02_populacao explicitamente. Os valores monetários já vêm deflacionados para dezembro de 2023, e a série nominal não existe no repositório.

**`pib_brl2023`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`impostos_liquidos_brl2023`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`valor_adicionado_bruto_brl2023`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`valor_adicionado_agropecuaria_brl2023`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`valor_adicionado_industria_brl2023`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`valor_adicionado_servicos_brl2023`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`valor_adicionado_administracao_publica_brl2023`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`sigla_uf_nome`** — Prefixo sigla_ mas o conteudo e o NOME da UF por extenso. PUBLICADO (posicao 122); duplica nome_uf

**`pib_per_capita_brl2023`** — Sem unidade; o denominador (populacao da propria dim 4) foi REMOVIDO da base em municipalityBR.qmd:97, tornando o indicador nao reproduzivel

**`razao_impostos_sobre_pib_prop`** — E uma razao, mas o nome parece uma justaposicao de dois indicadores

**`participacao_va_administracao_publica_prop`** — 'dependencia' sem denominador explicito (participacao do VA da administracao publica no VA total); 'adm' abreviado enquanto as irmas nao sao

**`participacao_va_industria_prop`** — 'dependencia' sem denominador explicito

**`participacao_va_agropecuaria_prop`** — Idem; 'agro' abreviado enquanto va_agropecuaria nao e

**`participacao_va_servicos_prop`** — 'dependencia' sem denominador explicito

**`ln_pib_brl2023`** — Transformacao no nome sem dizer a base (e logaritmo natural)

**`ln_pib_per_capita_brl2023`** — Idem; e uma das colunas consumidas por scripts/artigo

**`ln_valor_adicionado_bruto_brl2023`** — Idem; e o log de va, cujo nome curto ja e ambiguo

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("04_economia")
x <- mape_ler("04_economia", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 01:47 por `mape_gerar_documentacao()`._

