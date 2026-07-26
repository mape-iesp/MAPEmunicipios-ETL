# Habitação: faixa subsidiada do MCMV não existe

**Fonte:** `12_habitacao/mcmv_ogu`  
**Registrado em:** 2026-07-26

## O que impede

O arquivo subsdiado_ogu.csv é byte a byte idêntico ao financiado_fgts_detalhado.csv (mesmo md5). A faixa subsidiada com recursos do OGU, que é a de interesse social, nunca chegou ao repositório. O objeto ainda é lido pelo consolidador e nunca usado, o que dá a impressão de que ela está lá.

## Evidência

13 Habitação e Zoneamento - Códigos e Dados/mcmv/0_dados/subsdiado_ogu.csv

## O que se perde

Metade do programa. A dimensão cobre apenas a faixa financiada com FGTS, e isso agora está declarado no nome da tabela e nas observações.

## O que seria preciso para recuperar

Obter a fonte do zero, como fonte nova. Decisão do usuário registrada: documentar a ausência e seguir com o FGTS.

