# QA — 08_energia_internet

Gerado em 2026-07-26 20:52:26.

## Resumo

- linhas: 111.288
- colunas: 12
- células vazias (todas as colunas): 41.71%

## Checagens

Checagens executadas: 19.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| schema | informativo | (tabela): 8 de 10 coluna(s) numérica(s) sem `dominio_valido` declarado (80%): a checagem de faixa não olhou essas. | — sem justificativa — |
| invariancia_temporal | aviso | lpt_domicilios_atendidos_acumulado_i: idêntica em 100% dos municípios entre os anos medidos, enquanto as colunas irmãs variam. Provavelmente é uma medição só, replicada — e a variação entre os anos é sempre zero por construção. | problema da variável lpt_domicilios_atendidos_acumulado_i: Faixa de anos embutida no nome da coluna |
| invariancia_temporal | aviso | censo_cobertura_eletricidade_2000_pct: idêntica em 100% dos municípios entre os anos medidos, enquanto as colunas irmãs variam. Provavelmente é uma medição só, replicada — e a variação entre os anos é sempre zero por construção. | problema da variável censo_cobertura_eletricidade_2000_pct: O ano fica no nome porque a coluna é um retrato censitário replicado no painel, e não uma série. |
| invariancia_temporal | aviso | censo_cobertura_eletricidade_2010_pct: idêntica em 100% dos municípios entre os anos medidos, enquanto as colunas irmãs variam. Provavelmente é uma medição só, replicada — e a variação entre os anos é sempre zero por construção. | problema da variável censo_cobertura_eletricidade_2010_pct: O ano fica no nome porque a coluna é um retrato censitário replicado no painel, e não uma série. |

## Defeitos declarados no dicionário

Estes 10 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (anatel_bl_densidade_p100dom) Sem unidade no nome (acessos por 100 domicilios)
- (anatel_bl_densidade_capital_uf_p100dom) O sufixo _capital designa a CAPITAL DA UF mas le-se como per capita
- (anatel_bl_densidade_sobre_capital_uf_razao) Escala inconsistente: percentual no intermediario (bandalarga.R:79) e razao pura na dimensao (energia_internet.R:17)
- (anatel_tm_densidade_p100dom) Sem unidade no nome
- (anatel_tm_densidade_capital_uf_p100dom) Idem: _capital = capital da UF, nao per capita
- (anatel_tm_densidade_sobre_capital_uf_razao) Mesma inconsistencia de escala (telefonia.R:74 vs energia_internet.R:29)
- (lpt_domicilios_atendidos_i) Sufixo '_ano' ambiguo (e o fluxo do ano) num painel cuja chave ja e ano
- (lpt_domicilios_atendidos_acumulado_i) Faixa de anos embutida no nome da coluna
- (censo_cobertura_eletricidade_2000_pct) O ano fica no nome porque a coluna é um retrato censitário replicado no painel, e não uma série.
- (censo_cobertura_eletricidade_2010_pct) O ano fica no nome porque a coluna é um retrato censitário replicado no painel, e não uma série.

