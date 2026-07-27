# Disque 100 — denúncias de violações de direitos humanos

**Slug:** `01_assistencia_social_dh/disque100`  
**Camada:** fonte  
**Dimensão:** 01_assistencia_social_dh

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Contagem anual de violações de direitos humanos denunciadas ao Disque Direitos Humanos, por município, no total e por grupo vulnerável.

## Procedência

| | |
|---|---|
| Fonte original | Ministério dos Direitos Humanos e da Cidadania |
| Fonte da extração | Microdados do Disque 100 |
| Link | não informado |
| Método de acesso | `download_manual` |
| Licença | Dado publico federal. Uso livre com citacao da fonte, nos termos da Lei de Acesso a Informacao (Lei 12.527/2011) e do Decreto 8.777/2016 (Politica de Dados Abertos do Executivo Federal). Verificado em 26/07/2026. |
| Periodicidade da fonte | anual |
| Script de ingestão | `fontes/01_assistencia_social_dh/disque100/R/tratar_disque100.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 59.990 |
| Colunas | 8 |
| Municípios distintos | 5.567 de 5.570 (99.9%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 2011-2023 |
| **Cobertura observada na tabela** | **2011-2023** |
| Células vazias (colunas de conteúdo, sem as chaves) | 0% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `disque100_violacoes_i` | integer | denuncias | Violações de direitos humanos denunciadas ao Disque 100. | 0.0% |
| `disque100_violacoes_crianca_adolescente_i` | integer | denuncias | Denúncias cujo grupo vulnerável é criança ou adolescente. | 0.0% |
| `disque100_violacoes_lgbtq_i` | integer | denuncias | Denúncias cujo grupo vulnerável é a população LGBTQIA+. | 0.0% |
| `disque100_violacoes_pcd_i` | integer | denuncias | Denúncias cujo grupo vulnerável é pessoa com deficiência. | 0.0% |
| `disque100_violacoes_pessoa_idosa_i` | integer | denuncias | Denúncias cujo grupo vulnerável é pessoa idosa. | 0.0% |
| `disque100_violacoes_religiao_i` | integer | denuncias | Denúncias de violação por motivo de religião. | 0.0% |

## Ressalvas

Não há URL, órgão de extração, data ou script de download registrados em nenhum lugar da árvore legada. A procedência precisa ser reconstruída antes de a fonte poder ser atualizada. A contagem é de DENÚNCIAS, não de violações confirmadas, e é sensível à propensão a denunciar — que varia entre municípios e ao longo do tempo.

**`disque100_violacoes_i`** — Generico: nao identifica a fonte (Disque 100) nem o recorte (denuncias de violacao de direitos humanos); colide com contagens de violencia das dims 11 e 14. Alem disso e redundante por construcao (som

**`disque100_violacoes_crianca_adolescente_i`** — Prefixo total_ generico, sem fonte (mesma familia: _lgbtq, _pcd, _pessoa_idosa, _religiao)

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("01_assistencia_social_dh/disque100")
x <- mape_ler("01_assistencia_social_dh/disque100", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 22:10 por `mape_gerar_documentacao()`._

