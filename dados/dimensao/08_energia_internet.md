# Energia elétrica e acesso à internet

**Slug:** `08_energia_internet`  
**Camada:** dimensao  
**Dimensão:** 08_energia_internet

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Densidade de acessos de banda larga fixa e de telefonia móvel, e cobertura de eletricidade.

## Procedência

| | |
|---|---|
| Fonte original | Anatel e IBGE |
| Fonte da extração | Base dos Dados e arquivos locais |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | Dado publico federal. Uso livre com citacao da fonte, nos termos da Lei de Acesso a Informacao (Lei 12.527/2011) e do Decreto 8.777/2016 (Politica de Dados Abertos do Executivo Federal). Verificado em 26/07/2026. |
| Periodicidade da fonte | anual |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 111.288 |
| Colunas | 12 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 2004-2024 |
| **Cobertura observada na tabela** | **2004-2024** |
| Células vazias (colunas de conteúdo, sem as chaves) | 50.06% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `anatel_bl_densidade_p100dom` | double | acessos por 100 domicilios | Média anual de densidade banda larga nos municípios (acesso por 100 domicílios) | 10.2% |
| `anatel_bl_densidade_capital_uf_p100dom` | double | acessos por 100 domicilios | Média anual de densidade banda larga na capital da UF (acesso por 100 domicílios) | 10.2% |
| `anatel_bl_densidade_sobre_capital_uf_razao` | double | razao | Densidade de acessos de banda larga do município dividida pela densidade da capital da UF. Passa de 1 quando o município tem mais acessos por domicílio que a capital. | 10.2% |
| `anatel_tm_densidade_p100dom` | double | acessos por 100 domicilios | Média anual de densidade telefonia móvel nos municípios (acesso por 100 domicílios) | 70.0% |
| `anatel_tm_densidade_capital_uf_p100dom` | double | acessos por 100 domicilios | Média anual de densidade telefonia móvel na capital da UF (acesso por 100 domicílios) | 70.0% |
| `anatel_tm_densidade_sobre_capital_uf_razao` | double | razao | Densidade de acessos de telefonia móvel do município dividida pela densidade da capital da UF. | 70.0% |
| `lpt_domicilios_atendidos_i` | double | contagem | Domicílios atendidos pelo Luz para Todos | 65.0% |
| `lpt_domicilios_atendidos_acumulado_i` | double | contagem | Total de domicílios atendidos pelo Luz para Todos desde o início do programa até 2020 | 65.0% |
| `censo_cobertura_eletricidade_2000_pct` | double | percentual | % de casas com acesso à eletricidade em 2000 | 65.0% |
| `censo_cobertura_eletricidade_2010_pct` | double | percentual | % de casas com acesso à eletricidade em 2010 | 65.0% |

## Ressalvas

Dez das doze colunas desta dimensão eram homônimas entre banda larga e telefonia móvel no legado, distinguíveis apenas pelo arquivo de origem. Os prefixos anatel_bl_ e anatel_tm_ resolvem isso. Os metadados declaram 31 variáveis; a tabela entrega 10.

**`anatel_bl_densidade_p100dom`** — Sem unidade no nome (acessos por 100 domicilios)

**`anatel_bl_densidade_capital_uf_p100dom`** — O sufixo _capital designa a CAPITAL DA UF mas le-se como per capita

**`anatel_bl_densidade_sobre_capital_uf_razao`** — Escala inconsistente: percentual no intermediario (bandalarga.R:79) e razao pura na dimensao (energia_internet.R:17)

**`anatel_tm_densidade_p100dom`** — Sem unidade no nome

**`anatel_tm_densidade_capital_uf_p100dom`** — Idem: _capital = capital da UF, nao per capita

**`anatel_tm_densidade_sobre_capital_uf_razao`** — Mesma inconsistencia de escala (telefonia.R:74 vs energia_internet.R:29)

**`lpt_domicilios_atendidos_i`** — Sufixo '_ano' ambiguo (e o fluxo do ano) num painel cuja chave ja e ano

**`lpt_domicilios_atendidos_acumulado_i`** — Faixa de anos embutida no nome da coluna

**`censo_cobertura_eletricidade_2000_pct`** — O ano fica no nome porque a coluna é um retrato censitário replicado no painel, e não uma série.

**`censo_cobertura_eletricidade_2010_pct`** — O ano fica no nome porque a coluna é um retrato censitário replicado no painel, e não uma série.

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("08_energia_internet")
x <- mape_ler("08_energia_internet", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 18:49 por `mape_gerar_documentacao()`._

