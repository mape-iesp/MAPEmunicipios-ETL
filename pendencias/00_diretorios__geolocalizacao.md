# Geolocalização não migra nesta etapa

**Fonte:** `00_diretorios/geolocalizacao`  
**Registrado em:** 2026-07-26

## O que impede

O script produz um geojson de 105 MB, um shapefile de 38 MB e um .RData de 32 MB, e nada disso entra na base publicada: a junção lê apenas diretorios.xlsx. Além disso, o .RData de 30,7 MB na pasta não é gerado pelo script — o save() só existe no .Rhistory.

## Evidência

1 Identificação - Códigos e Dados/geolocalizacao.R

## O que se perde

Nada em relação ao publicado. A geometria municipal continua disponível pelo pacote geobr, que é o que os consumidores já usam.

## O que seria preciso para recuperar

A granularidade real é municipio x versao_malha, e não municipio x ano — a coluna chamada ano guarda a versão da malha cartográfica. Se for migrada, precisa de tabela própria com essa chave, e o arquivo passa do limiar de 20 MB, indo para release em vez do repositório.

