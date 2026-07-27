# QA — 05_sociedade

Gerado em 2026-07-26 21:35:27.

## Resumo

- linhas: 111.300
- colunas: 10
- células vazias (todas as colunas): 0.01%

## Checagens

Checagens executadas: 20.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| schema | informativo | (tabela): 1 de 7 coluna(s) numérica(s) sem `dominio_valido` declarado (14%): a checagem de faixa não olhou essas. | — sem justificativa — |
| invariancia_temporal | aviso | vulnerabilidade_socioeconomica_pct: idêntica em 100% dos municípios entre os anos medidos, enquanto as colunas irmãs variam. Provavelmente é uma medição só, replicada — e a variação entre os anos é sempre zero por construção. | DEFEITO CONFIRMADO, grupo 14 da auditoria: e UMA medicao publicada como se fossem os censos de 2000 e 2010. Medido: valor identico nos dois anos em 5.565 de 5.565 municipios, enquanto a coluna irma ivs_idx e identica em 1 municipio so. A variacao entre censos e sempre exatamente zero, e nao deve ser interpretada. O defeito vem da base do legado e recupera-lo exige reextrair o Atlas do IVS do Ipea separando 2000 de 2010 — a paridade contra o legado nao ajuda, porque o legado ja traz o defeito. |

## Defeitos declarados no dicionário

Estes 1 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (ano_ref_ivs) Sigla opaca (AVS = Atlas da Vulnerabilidade Social); e o ano censitario 2000/2010 replicado sobre 1996-2015 em sociedade.R

