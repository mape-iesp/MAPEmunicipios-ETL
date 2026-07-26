# MUNIC 2023 (suplemento de Direitos Humanos) não migra

**Fonte:** `01_assistencia_social_dh/munic_dh`  
**Registrado em:** 2026-07-26

## O que impede

O script `Munic/munic_DH.R` do legado não roda até o fim. Ele quebra em `library(labelled)`, um pacote que não está instalado nem declarado em lugar nenhum do projeto, e por isso nenhuma coluna desta fonte chega à saída da dimensão.

 Confirmei que a fonte não contribui com nada para a base publicada: as 14 colunas da dimensão 8 vêm todas do Disque 100 (6) e do CadÚnico (8). Migrar uma fonte que não produz coluna nenhuma acrescentaria dado novo à base ao mesmo tempo que o código muda, o que contaminaria o teste de paridade — exatamente o que a seção 12.2 do plano existe para evitar.

## Evidência

`8 Assistência Social e Direitos Humanos - Códigos e Dados/Munic/munic_DH.R` e o arquivo `Munic/Base_MUNIC_2023.xlsx`, que existe na pasta e nunca é lido até o fim.

## O que se perde

Nada se perde em relação ao que está publicado hoje. O que se perde é o potencial: o suplemento de Direitos Humanos da MUNIC 2023 traz dados sobre a estrutura municipal de atendimento, que ninguém chegou a incorporar. Há também um `Base_MUNIC_2019.xlsx` órfão na mesma pasta, que nenhum script abre.

## O que seria preciso para recuperar

Tratar como fonte NOVA, pelo procedimento da seção 8.2 do plano, e não como migração. Instalar `labelled`, ler o script até o fim para descobrir quais variáveis ele pretendia produzir, e registrar a fonte com manifesto próprio. Fica para depois da migração, porque acrescentar colunas novas agora quebraria a paridade.

