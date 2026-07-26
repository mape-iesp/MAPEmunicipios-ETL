# QA — 04_economia

Gerado em 2026-07-26 15:10:38.

## Resumo

- linhas: 127.786
- colunas: 19
- células vazias (todas as colunas): 0%

## Checagens

Nenhum problema automático: as 11 checagens executadas passaram.

## Defeitos declarados no dicionário

Estes 17 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (pib_brl2023) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (impostos_liquidos_brl2023) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (valor_adicionado_bruto_brl2023) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (valor_adicionado_agropecuaria_brl2023) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (valor_adicionado_industria_brl2023) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (valor_adicionado_servicos_brl2023) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (valor_adicionado_administracao_publica_brl2023) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (sigla_uf_nome) Prefixo sigla_ mas o conteudo e o NOME da UF por extenso. PUBLICADO (posicao 122); duplica nome_uf
- (pib_per_capita_brl2023) Sem unidade; o denominador (populacao da propria dim 4) foi REMOVIDO da base em municipalityBR.qmd:97, tornando o indicador nao reproduzivel
- (razao_impostos_sobre_pib_prop) E uma razao, mas o nome parece uma justaposicao de dois indicadores
- (participacao_va_administracao_publica_prop) 'dependencia' sem denominador explicito (participacao do VA da administracao publica no VA total); 'adm' abreviado enquanto as irmas nao sao
- (participacao_va_industria_prop) 'dependencia' sem denominador explicito
- (participacao_va_agropecuaria_prop) Idem; 'agro' abreviado enquanto va_agropecuaria nao e
- (participacao_va_servicos_prop) 'dependencia' sem denominador explicito
- (ln_pib_brl2023) Transformacao no nome sem dizer a base (e logaritmo natural)
- (ln_pib_per_capita_brl2023) Idem; e uma das colunas consumidas por scripts/artigo
- (ln_valor_adicionado_bruto_brl2023) Idem; e o log de va, cujo nome curto ja e ambiguo

