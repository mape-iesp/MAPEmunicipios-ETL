# Assistência Social e Direitos Humanos (dimensão consolidada)

**Slug:** `01_assistencia_social_dh`  
**Camada:** dimensao  
**Dimensão:** 01_assistencia_social_dh

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Tabela de dimensão, gerada pela junção das tabelas de fonte cadunico e disque100.

## Procedência

| | |
|---|---|
| Fonte original | MDS/SAGI e MDHC |
| Fonte da extração | derivada das tabelas de fonte desta dimensão |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | Dado publico federal. Uso livre com citacao da fonte, nos termos da Lei de Acesso a Informacao (Lei 12.527/2011) e do Decreto 8.777/2016 (Politica de Dados Abertos do Executivo Federal). Verificado em 26/07/2026. |
| Periodicidade da fonte | anual |
| Script de ingestão | `R/dimensao.R (mape_consolidar_dimensao)` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 67.406 |
| Colunas | 16 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 2011-2023 |
| **Cobertura observada na tabela** | **2011-2023** |
| Células vazias (colunas de conteúdo, sem as chaves) | 29.99% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `cadun_qtd_familias_atualizadas_i` | integer | familias | Famílias inscritas no CadÚnico com dados atualizados (última alteração de campos sensíveis há menos de 24 meses). | 25.6% |
| `cadun_qtd_familias_atualizadas_pobreza_pbf_i` | integer | familias | Famílias atualizadas na faixa de pobreza do Bolsa Família. | 66.9% |
| `cadun_qtd_familias_atualizadas_baixa_renda_i` | integer | familias | Famílias atualizadas na faixa de baixa renda. | 66.9% |
| `cadun_qtd_familias_atualizadas_rfpc_ate_meio_sm_i` | integer | familias | Famílias atualizadas com renda familiar per capita de até meio salário mínimo. | 25.6% |
| `cadun_qtd_familias_atualizadas_rfpc_acima_meio_sm_i` | integer | familias | Famílias atualizadas com renda familiar per capita acima de meio salário mínimo. | 66.9% |
| `cadun_qtd_familias_atualizadas_renda_zero_i` | integer | familias | Famílias atualizadas com renda declarada igual a zero. | 50.4% |
| `cadun_taxa_atualizacao_cadastral_pct` | double | percentual | Taxa de Atualização Cadastral: cadastros atualizados sobre o total de cadastros do município. Componente do Índice de Gestão Descentralizada do Bolsa Família. | 25.6% |
| `cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_pct` | double | percentual | Taxa de Atualização Cadastral restrita às famílias com renda per capita de até meio salário mínimo. | 25.6% |
| `disque100_violacoes_i` | integer | denuncias | Violações de direitos humanos denunciadas ao Disque 100. | 11.0% |
| `disque100_violacoes_crianca_adolescente_i` | integer | denuncias | Denúncias cujo grupo vulnerável é criança ou adolescente. | 11.0% |
| `disque100_violacoes_lgbtq_i` | integer | denuncias | Denúncias cujo grupo vulnerável é a população LGBTQIA+. | 11.0% |
| `disque100_violacoes_pcd_i` | integer | denuncias | Denúncias cujo grupo vulnerável é pessoa com deficiência. | 11.0% |
| `disque100_violacoes_pessoa_idosa_i` | integer | denuncias | Denúncias cujo grupo vulnerável é pessoa idosa. | 11.0% |
| `disque100_violacoes_religiao_i` | integer | denuncias | Denúncias de violação por motivo de religião. | 11.0% |

A coluna `vazios` acima é medida **nesta** tabela. Já os campos calculados do dicionário (`pct_na`, `minimo`, `maximo`, `n_distintos`) são medidos na tabela em que a variável é observada, que para 14 destas colunas é outra: `cadun_qtd_familias_atualizadas_i` (01_assistencia_social_dh/cadunico), `cadun_qtd_familias_atualizadas_pobreza_pbf_i` (01_assistencia_social_dh/cadunico), `cadun_qtd_familias_atualizadas_baixa_renda_i` (01_assistencia_social_dh/cadunico), `cadun_qtd_familias_atualizadas_rfpc_ate_meio_sm_i` (01_assistencia_social_dh/cadunico), `cadun_qtd_familias_atualizadas_rfpc_acima_meio_sm_i` (01_assistencia_social_dh/cadunico), `cadun_qtd_familias_atualizadas_renda_zero_i` (01_assistencia_social_dh/cadunico), `cadun_taxa_atualizacao_cadastral_pct` (01_assistencia_social_dh/cadunico), `cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_pct` (01_assistencia_social_dh/cadunico), `disque100_violacoes_i` (01_assistencia_social_dh/disque100), `disque100_violacoes_crianca_adolescente_i` (01_assistencia_social_dh/disque100), `disque100_violacoes_lgbtq_i` (01_assistencia_social_dh/disque100), `disque100_violacoes_pcd_i` (01_assistencia_social_dh/disque100), `disque100_violacoes_pessoa_idosa_i` (01_assistencia_social_dh/disque100), `disque100_violacoes_religiao_i` (01_assistencia_social_dh/disque100). Os dois números podem divergir muito, e divergem por desenho: a fonte guarda o observado e a dimensão o painel expandido.

## Ressalvas

Tabela DERIVADA. A camada canônica é a fonte; esta é gerada e republicada a cada execução.

**`disque100_violacoes_i`** — Generico: nao identifica a fonte (Disque 100) nem o recorte (denuncias de violacao de direitos humanos); colide com contagens de violencia das dims 11 e 14. Alem disso e redundante por construcao (som

**`disque100_violacoes_crianca_adolescente_i`** — Prefixo total_ generico, sem fonte (mesma familia: _lgbtq, _pcd, _pessoa_idosa, _religiao)

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("01_assistencia_social_dh")
x <- mape_ler("01_assistencia_social_dh", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 22:10 por `mape_gerar_documentacao()`._

