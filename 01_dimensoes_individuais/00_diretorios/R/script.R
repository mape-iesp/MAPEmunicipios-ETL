
library(basedosdados)
library(tidyverse)
library(openxlsx)

### Selecionar o projeto 

# Defina o seu projeto no Google Cloud
billing_id = get_billing_id()

### Compilar os dados


# Para carregar o dado direto no R
query <- "
SELECT
    dados.id_municipio as id_municipio,
    dados.id_municipio_6 as id_municipio_6,
    dados.id_municipio_tse as id_municipio_tse,
    dados.id_municipio_rf as id_municipio_rf,
    dados.id_municipio_bcb as id_municipio_bcb,
    dados.nome as nome,
    dados.capital_uf as capital_uf,
    dados.id_comarca as id_comarca,
    dados.id_regiao_saude as id_regiao_saude,
    dados.nome_regiao_saude as nome_regiao_saude,
    dados.id_regiao_imediata as id_regiao_imediata,
    dados.nome_regiao_imediata as nome_regiao_imediata,
    dados.id_regiao_intermediaria as id_regiao_intermediaria,
    dados.nome_regiao_intermediaria as nome_regiao_intermediaria,
    dados.id_microrregiao as id_microrregiao,
    dados.nome_microrregiao as nome_microrregiao,
    dados.id_mesorregiao as id_mesorregiao,
    dados.nome_mesorregiao as nome_mesorregiao,
    dados.id_regiao_metropolitana as id_regiao_metropolitana,
    dados.nome_regiao_metropolitana as nome_regiao_metropolitana,
    dados.ddd as ddd,
    dados.id_uf as id_uf,
    dados.sigla_uf as sigla_uf,
    dados.nome_uf as nome_uf,
    dados.nome_regiao as nome_regiao,
    dados.amazonia_legal as amazonia_legal,
    dados.centroide as centroide
FROM `basedosdados.br_bd_diretorios_brasil.municipio` AS dados
"

diretorios <- read_sql(query, billing_project_id = billing_id)

### Exportar database

save(diretorios, file = "processed/diretorios.RData")

write.xlsx(diretorios, "processed/diretorios.xlsx")



