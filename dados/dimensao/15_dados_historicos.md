# Dados históricos municipais (1872-1920)

**Slug:** `15_dados_historicos`  
**Camada:** dimensao  
**Dimensão:** 15_dados_historicos

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Indicadores históricos de capacidade estatal e geografia, de Kustov e Pardelli (2024), mais o ano estimado de fundação a partir da linhagem de municípios do IBGE. Corte TRANSVERSAL, sem dimensão temporal.

## Procedência

| | |
|---|---|
| Fonte original | Kustov e Pardelli (2024) e IBGE |
| Fonte da extração | pacote de replicação do artigo e planilha de linhagem |
| Link | <https://doi.org/10.1016/j.worlddev.2024.106625> |
| Método de acesso | `arquivo_local` |
| Licença | a verificar |
| Periodicidade da fonte | eventual |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 5.646 |
| Colunas | 9 |
| Municípios distintos | 5.592 de 5.570 (100.4%) |
| Chave primária | `id_municipio` |
| Granularidade | municipio (transversal, sem ano) |
| Cobertura declarada pela fonte | 1872-1920 (transversal) |
| **Cobertura observada na tabela** | **sem dimensão temporal** |
| Células vazias | 1.3% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `receita_tributaria_1920_norm_idx` | double | indice normalizado de 0 a 1 | Valor de Receita tributária em 1923 em log e estandardizado (0-1) | 1.5% |
| `servidores_administracao_publica_1920_norm_idx` | double | indice normalizado de 0 a 1 | Valor do número de funcionários na administração pública em 1920 em log e estandardizado (0-1) | 1.5% |
| `servidores_forca_publica_1920_norm_idx` | double | indice normalizado de 0 a 1 | Valor do Número de funcionários da Força Pública em 1920 em log e estandardizado (0-1) | 1.5% |
| `redes_ferroviarias_1920_norm_idx` | double | indice normalizado de 0 a 1 | Valor do número de redes ferroviárias em 1920 em log e estandardizado (0-1) | 1.5% |
| `id_amc_1920` | character | texto | Área mínima comparável 1920 | 1.5% |
| `distancia_litoral_norm_idx` | double | indice normalizado de 0 a 1 | Valor da distância do município em relação à costa em log e estandardizado (0-1) | 1.5% |
| `distancia_capital_estadual_norm_idx` | double | indice normalizado de 0 a 1 | Valor da distância do município em relação à capital em log e estandardizado (0-1) | 1.5% |
| `ano_ref_fundacao_estimado` | double | ano | Estimativa de ano fundação intercenso. Ou seja, se o município não existia no Censo de 2000 e passa a ser contado em 2010, o valor é 2010. | 0.0% |

## Ressalvas

TABELA ESTÁTICA. No legado ela é juntada ao painel APENAS por município, sem ano, o que replica os mesmos valores em todos os 33 anos da série. Aqui ela é publicada com a granularidade real, e mape_consolidar_dimensao se recusa a juntá-la automaticamente ao painel — juntar sem ano é justamente o defeito que multiplica a série no legado. CHAVE DUPLICADA: 54 municípios aparecem duas vezes, todos do Tocantins, porque a planilha de linhagem traz o registro anterior e o posterior a 1988. No legado o distinct final mantém a PRIMEIRA ocorrência, que é a antiga, atribuindo ano de fundação errado a esses 54 municípios (o 1700400, por exemplo, fica com 1960 em vez de 1991). As duplicatas são MANTIDAS aqui, para que o problema fique visível em vez de ser resolvido por escolha arbitrária. 27 códigos não existem no diretório atual: são municípios extintos. O passo original -> atualizado da planilha do IBGE é edição manual em Excel sem registro, e é dentro dele que as duplicatas nascem. O pacote de replicação de Kustov e Pardelli NÃO é público: o artigo tem DOI, mas nem a página dos autores nem o Harvard Dataverse disponibilizam os dados. A fonte é citável e não reobtenível.

**`receita_tributaria_1920_norm_idx`** — O nome antigo prometia log e z-score. Os valores vão de 0 a 1 exatos, o que é normalização min-max: um z-score é centrado em zero e não tem limite superior.

**`servidores_administracao_publica_1920_norm_idx`** — O nome antigo prometia log e z-score. Os valores vão de 0 a 1 exatos, o que é normalização min-max: um z-score é centrado em zero e não tem limite superior.

**`servidores_forca_publica_1920_norm_idx`** — O nome antigo prometia log e z-score. Os valores vão de 0 a 1 exatos, o que é normalização min-max: um z-score é centrado em zero e não tem limite superior.

**`redes_ferroviarias_1920_norm_idx`** — O nome antigo prometia log e z-score. Os valores vão de 0 a 1 exatos, o que é normalização min-max: um z-score é centrado em zero e não tem limite superior.

**`id_amc_1920`** — Sem separador entre conceito e ano, sem prefixo id_; e chave estrangeira para uma malha (952 AMCs, formato '17AMC2097003') que nao existe em nenhuma outra tabela da base

**`distancia_litoral_norm_idx`** — O nome antigo prometia log e z-score. Os valores vão de 0 a 1 exatos, o que é normalização min-max: um z-score é centrado em zero e não tem limite superior.

**`distancia_capital_estadual_norm_idx`** — O nome antigo prometia log e z-score. Os valores vão de 0 a 1 exatos, o que é normalização min-max: um z-score é centrado em zero e não tem limite superior.

**`ano_ref_fundacao_estimado`** — Colide semanticamente com a coluna 'ano' da chave do painel; e a segunda coluna de ano com significado incompativel na base larga

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("15_dados_historicos")
x <- mape_ler("15_dados_historicos", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 01:47 por `mape_gerar_documentacao()`._

