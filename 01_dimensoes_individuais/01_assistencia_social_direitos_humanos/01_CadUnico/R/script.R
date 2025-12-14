
library(tidyverse)
library(dplyr)
library(here)
library(readr)
library(rio)
library(stringr)
library(tidyr)
library(purrr)

options (scipen = 999)

## Puxando bases CadUnico

# Definir o caminho da pasta onde estão os arquivos
caminho_pasta <- here(
  "01_dimensoes_individuais", 
  "01_assistencia_social_direitos_humanos", 
  "01_CadUnico", 
  "raw"
)

print(caminho_pasta)

# Listar todos os arquivos .txt na pasta
arquivos <- list.files(path = caminho_pasta, pattern = "\\.txt$", full.names = TRUE)

# Ler e combinar todos os arquivos em um único dataframe usando purrr::map
cadunico <- arquivos %>%
  map(~ read_delim(.x, delim = ",")) %>% # Ler cada arquivo como um dataframe
  bind_rows()                           # Combinar todos os dataframes em um só

# Visualizar as primeiras linhas do dataframe combinado
head(cadunico)

## Formatando base

cadunico <- cadunico %>%
  filter(str_detect(anomes_s, '12$')) %>%
  mutate(ano = substr(anomes_s, 1, 4)) %>%
  select(-anomes_s) %>%
  select(codigo_ibge, ano, everything()) %>%
  rename(codigo_ibge_6_dig = codigo_ibge) 

## Codigos do IBGE estão com apenas 6 digitos no original (sem código verificador), 
# então precisamos achar o outro digito

caminho_diretorios <- here(
  "01_dimensoes_individuais",
  "00_diretorios", 
  "processed",
  "diretorios.xlsx"
)

diretorios <- readxl::read_excel(caminho_diretorios)

diretorios <- diretorios %>%
  select(id_municipio, id_municipio_6) %>%
  mutate(id_municipio_6 = as.numeric(id_municipio_6))

cadunico_final <- cadunico %>%
  left_join(
    diretorios,
    by = c("codigo_ibge_6_dig" = "id_municipio_6")
  ) %>%
  select(-codigo_ibge_6_dig) %>%
  select(id_municipio, ano, everything())

caminho_export <- here(
  "01_dimensoes_individuais", 
  "01_assistencia_social_direitos_humanos", 
  "01_CadUnico", 
  "processed"
)

export(cadunico_final, here(caminho_export, "cadunico.csv"))
