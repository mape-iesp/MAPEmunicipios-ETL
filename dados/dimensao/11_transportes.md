# Tarifas de transporte público e tarifa zero

**Slug:** `11_transportes`  
**Camada:** dimensao  
**Dimensão:** 11_transportes

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Tarifa de ônibus e comprometimento de renda com transporte público (Mobilidados), e adoção de política de tarifa zero.

## Procedência

| | |
|---|---|
| Fonte original | Mobilidados/ITDP e levantamento Daniel Santini |
| Fonte da extração | Base dos Dados e planilha colaborativa |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | A VERIFICAR — combina o Mobilidados/ITDP (Instituto de Politicas de Transporte e Desenvolvimento, organizacao privada) com levantamentos abertos. Ver as licencas das fontes. |
| Periodicidade da fonte | eventual |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 183.814 |
| Colunas | 7 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 1991-2024 |
| **Cobertura observada na tabela** | **1991-2024** |
| Células vazias (colunas de conteúdo, sem as chaves) | 79.88% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `ano_ref_inicio_tarifa_zero` | double | ano | Ano início Tarifa Zero | 99.9% |
| `flag_adota_tarifa_zero` | double | 0 ou 1 | Adota Tarifa Zero | 0.0% |
| `comprometimento_tarifa_sobre_renda_domesticas_negras_prop` | double | proporcao | Comprometimento da renda para trabalhadoras domésticas negras | 99.9% |
| `comprometimento_tarifa_sobre_salario_minimo_prop` | double | proporcao | Comprometimento da renda de um salário mínimo | 99.8% |
| `tarifa_onibus_urbano_brl2023` | double | BRL de dezembro de 2023 | Tarifa de transporte público para 26 capitais e Distrito Federal | 99.8% |

A coluna `vazios` acima é medida **nesta** tabela. Já os campos calculados do dicionário (`pct_na`, `minimo`, `maximo`, `n_distintos`) são medidos na tabela em que a variável é observada, que para 5 destas colunas é outra: `ano_ref_inicio_tarifa_zero` (11_transportes/tarifa_zero), `flag_adota_tarifa_zero` (11_transportes/tarifa_zero), `comprometimento_tarifa_sobre_renda_domesticas_negras_prop` (11_transportes/tarifas), `comprometimento_tarifa_sobre_salario_minimo_prop` (11_transportes/tarifas), `tarifa_onibus_urbano_brl2023` (11_transportes/tarifas). Os dois números podem divergir muito, e divergem por desenho: a fonte guarda o observado e a dimensão o painel expandido.

## Ressalvas

A COBERTURA DE 100% NA BASE PUBLICADA É ARTEFATO. A fonte Mobilidados cobre 27 municípios; o restante do painel é esqueleto com valor imputado por soma acumulada. DEFEITO CONHECIDO: os cinco municípios que adotaram a tarifa zero e depois a encerraram (entre eles Palmas e Paulínia) aparecem com zero em TODOS os anos, inclusive naqueles em que a política estava em vigor, porque a aba de encerrados da planilha nunca é lida. A tarifa já vem deflacionada para dezembro de 2023, sem sufixo.

**`ano_ref_inicio_tarifa_zero`** — Ano de referência, não chave do painel: por isso o prefixo ano_ref_.

**`comprometimento_tarifa_sobre_renda_domesticas_negras_prop`** — Sem escala no nome (fracao 0-1)

**`comprometimento_tarifa_sobre_salario_minimo_prop`** — Sem 'renda' e sem escala no nome (fracao 0-1); denominador so no nome parcialmente

**`tarifa_onibus_urbano_brl2023`** — Plural generico, sem unidade (R$), sem dizer que e passagem de onibus urbano e sem marca de deflacao - e o MESMO NOME em duas escalas (nominal x 12/2023)

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("11_transportes")
x <- mape_ler("11_transportes", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 21:35 por `mape_gerar_documentacao()`._

