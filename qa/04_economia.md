# QA — 04_economia

Gerado em 2026-07-26 15:22:29.

## Resumo

- linhas: 127.786
- colunas: 19
- células vazias (todas as colunas): 0%

## Checagens

Checagens executadas: 12.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| schema | informativo | (tabela): 11 de 16 coluna(s) numérica(s) sem `dominio_valido` declarado (69%): a checagem de faixa não olhou essas. | — sem justificativa — |
| descricao_repetida | aviso | impostos_liquidos_brl2023: descrição igual à de `siconfi_deducao_transferencias_constitucionais_brl2023` (tabela 06_financas) | problema da variável impostos_liquidos_brl2023: Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida. |
| descricao_repetida | aviso | valor_adicionado_bruto_brl2023: descrição igual à de `siconfi_deducao_outras_brl2023` (tabela 06_financas) | problema da variável valor_adicionado_bruto_brl2023: Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida. |
| descricao_repetida | aviso | valor_adicionado_agropecuaria_brl2023: descrição igual à de `siconfi_receitas_brutas_brl2023` (tabela 06_financas) | problema da variável valor_adicionado_agropecuaria_brl2023: Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida. |
| descricao_repetida | aviso | valor_adicionado_industria_brl2023: descrição igual à de `siconfi_receitas_realizadas_brl2023` (tabela 06_financas) | problema da variável valor_adicionado_industria_brl2023: Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida. |
| descricao_repetida | aviso | valor_adicionado_servicos_brl2023: descrição igual à de `siconfi_receitas_proprias_brl2023` (tabela 06_financas) | problema da variável valor_adicionado_servicos_brl2023: Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida. |
| descricao_repetida | aviso | valor_adicionado_administracao_publica_brl2023: descrição igual à de `siconfi_receitas_proprias_realizadas_brl_nominal` (tabela 06_financas) | problema da variável valor_adicionado_administracao_publica_brl2023: Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida. |

## Defeitos declarados no dicionário

Estes 17 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (pib_brl2023) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (impostos_liquidos_brl2023) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (valor_adicionado_bruto_brl2023) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (valor_adicionado_agropecuaria_brl2023) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (valor_adicionado_industria_brl2023) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (valor_adicionado_servicos_brl2023) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (valor_adicionado_administracao_publica_brl2023) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (sigla_uf_nome) DEFEITO ABERTO: prefixo sigla_ com conteudo de nome por extenso, e duplicacao do bloco territorial que pertence a 00_diretorios/municipios. acao = remover foi declarada e NAO executada. Confirmado pelo grupo 51 da auditoria de 26/07/2026.
- (pib_per_capita_brl2023) Sem unidade; o denominador (populacao da propria dim 4) foi REMOVIDO da base em municipalityBR.qmd:97, tornando o indicador nao reproduzivel
- (razao_impostos_sobre_pib_prop) E uma razao, mas o nome parece uma justaposicao de dois indicadores
- (participacao_va_administracao_publica_prop) 'dependencia' sem denominador explicito (participacao do VA da administracao publica no VA total); 'adm' abreviado enquanto as irmas nao sao
- (participacao_va_industria_prop) 'dependencia' sem denominador explicito
- (participacao_va_agropecuaria_prop) Idem; 'agro' abreviado enquanto va_agropecuaria nao e
- (participacao_va_servicos_prop) 'dependencia' sem denominador explicito
- (ln_pib_brl2023) Transformacao no nome sem dizer a base (e logaritmo natural)
- (ln_pib_per_capita_brl2023) Idem; e uma das colunas consumidas por scripts/artigo
- (ln_valor_adicionado_bruto_brl2023) Idem; e o log de va, cujo nome curto ja e ambiguo

