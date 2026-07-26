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
| Licença | a verificar |
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
| Cobertura declarada pela fonte | 2007-2019 |
| **Cobertura observada na tabela** | **2007-2024** |
| Células vazias | 0% |
| Regra de preenchimento temporal | `nenhuma` |

## Ressalvas

ESCOPO: cobre APENAS a faixa financiada com FGTS. A faixa subsidiada com recursos do OGU não existe no repositório — o arquivo que deveria contê-la é byte a byte idêntico ao do FGTS. DEFEITO GRAVE NÃO CORRIGIDO NESTA MIGRAÇÃO: os valores monetários estão inflados em até cem vezes por um gsub aninhado na ordem errada, que remove o ponto decimal que ele mesmo acabou de criar. Corrigir exige reprocessar a fonte, o que está fora do escopo desta etapa; ver pendencias/. O painel começa em 2007, dois anos antes da criação do programa.

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("12_habitacao")
x <- mape_ler("12_habitacao", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 01:47 por `mape_gerar_documentacao()`._

