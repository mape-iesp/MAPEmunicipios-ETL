# Recursos humanos da administração municipal

**Slug:** `07_recursos_humanos`  
**Camada:** dimensao  
**Dimensão:** 07_recursos_humanos

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Vínculos da administração direta e indireta municipal por tipo (estatutários, CLT, comissionados, estagiários), da pesquisa MUNIC.

## Procedência

| | |
|---|---|
| Fonte original | IBGE — Pesquisa de Informações Básicas Municipais |
| Fonte da extração | arquivos .xlsx da MUNIC, por edição |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | Dado publico federal. Uso livre com citacao da fonte, nos termos da Lei de Acesso a Informacao (Lei 12.527/2011) e do Decreto 8.777/2016 (Politica de Dados Abertos do Executivo Federal). Verificado em 26/07/2026. |
| Periodicidade da fonte | bienal |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 66.824 |
| Colunas | 17 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 2009-2023, faltando 2010, 2016 e 2022 |
| **Cobertura observada na tabela** | **2009-2023** |
| Células vazias (colunas de conteúdo, sem as chaves) | 36.96% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `munic_vinculos_estatutarios_adm_direta_i` | double | contagem | Total de funcionários estatutários administração direta municipal | 0.4% |
| `munic_vinculos_clt_adm_direta_i` | double | contagem | Total de funcionários CLT administração direta municipal | 0.4% |
| `munic_servidores_comissionados_direta_i` | double | servidores | Total de funcionários comissionados administração direta municipal | 0.4% |
| `munic_servidores_estagiarios_direta_i` | double | servidores | Total de funcionários estagiários administração direta municipal | 0.6% |
| `munic_servidores_sem_vinculo_permanente_direta_i` | double | servidores | Total de funcionários sem vínculo permanente administração direta municipal | 0.6% |
| `munic_vinculos_totais_adm_direta_i` | double | contagem | Total de funcionários administração direta municipal | 0.5% |
| `munic_comissionados_adm_direta_prop` | double | proporcao | Proporção de funcionários comissionados em relação ao total de funcionários (administração direta) | 0.6% |
| `munic_existe_administracao_indireta_cat` | character | texto | Possui ou não administração indireta | 0.0% |
| `munic_servidores_estatutarios_indireta_i` | double | servidores | Total de funcionários estatutários administração indireta municipal | 78.7% |
| `munic_servidores_clt_indireta_i` | double | servidores | Total de funcionários CLT administração indireta municipal | 78.7% |
| `munic_servidores_comissionados_indireta_i` | double | servidores | Total de funcionários comissionados administração indireta municipal | 78.7% |
| `munic_servidores_estagiarios_indireta_i` | double | servidores | Total de funcionários estagiários administração indireta municipal | 78.7% |
| `munic_servidores_sem_vinculo_permanente_indireta_i` | double | servidores | Total de funcionários sem vínculo permanente administração indireta municipal | 78.7% |
| `munic_vinculos_totais_adm_indireta_i` | double | contagem | Total de funcionários administração indireta municipal | 78.7% |
| `munic_comissionados_adm_indireta_prop` | double | proporcao | Proporção de funcionários comissionados em relação ao total de funcionários (administração indireta) | 79.0% |

## Ressalvas

DEFEITO CORRIGIDO NA MIGRAÇÃO: a planilha de 2019 traz 80 linhas fantasma, que contêm apenas o caractere '-' e atravessavam o pipeline com id_municipio nulo. Elas são eliminadas aqui. DEFEITO NÃO CORRIGIDO: em 2011 a variável de existência de administração indireta recebeu a coluna do total de funcionários, o que torna essa coluna categórica em onze anos e numérica em 2011. As edições de 2010, 2016 e 2022 nunca foram baixadas.

**`munic_vinculos_estatutarios_adm_direta_i`** — Sem prefixo de fonte, sem sufixo de contagem; 'direta' = administracao direta, colide com qualquer outro uso de direta/indireta

**`munic_vinculos_clt_adm_direta_i`** — Idem (mesma familia: comissionados_direta, estagiarios_direta, sem_vinculo_permanente_direta e os seis analogos _indireta)

**`munic_vinculos_totais_adm_direta_i`** — 'total' sem qualificar que e ESTOQUE de vinculos ativos no ano de referencia da pesquisa Munic

**`munic_comissionados_adm_direta_prop`** — Abreviacao opaca; e uma PROPORCAO 0-1 (comissionados/total) convivendo com contagens na mesma tabela, sem sufixo de escala

**`munic_existe_administracao_indireta_cat`** — Nome sugere booleano; e character com 6 rotulos ('Sim','Nao','Recusa','Nao informou','Nao informado') e, so em 2011, uma CONTAGEM numerica - dois conceitos incompativeis no mesmo nome

**`munic_vinculos_totais_adm_indireta_i`** — Idem

**`munic_comissionados_adm_indireta_prop`** — Idem

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("07_recursos_humanos")
x <- mape_ler("07_recursos_humanos", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 20:38 por `mape_gerar_documentacao()`._

