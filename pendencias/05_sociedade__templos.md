# Sociedade: Templos não migra

**Fonte:** `05_sociedade/templos`  
**Registrado em:** 2026-07-26

## O que impede

Três scripts somando 196 KB e 56 MB de dados, incluindo um CSV de 50 MB. Nenhum deles grava saída municipal. Uma busca por templo e igreja em todos os .R, .Rmd e .qmd fora da própria pasta retorna zero ocorrências.

## Evidência

5 Sociedade - Códigos e Dados/Templos/{Dados Igrejas.R, codigo templos por municipio.R, codigo_aberto_classificacao.R}

## O que se perde

Nada em relação ao publicado. A fonte agregada disponível é por UF, não por município.

## O que seria preciso para recuperar

Tratar como fonte nova. O bloco de classificação de ~310 linhas existe em três arquivos, com erros de copiar-e-colar dentro dele, e precisaria ser reescrito como função antes de qualquer coisa.

