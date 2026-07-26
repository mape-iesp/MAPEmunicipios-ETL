# Paridade — 02_populacao

Gerado em 2026-07-26 20:09:00.
Referência: `base_municipios_brasileiros.RDa`  
sha256: `a6f350ecf3090a7439eb680d732b9c40b34dfb79f25b4fe6e9be284cab07b336`

Colunas comparadas: 8. Diferenças não explicadas: 0.

| coluna | classe | descrição |
|---|---|---|
| `(conjunto de chaves)` | a_correcao_reivindicada | 0 chave(s) só no publicado e 355 só na referência, de 179930 e 180285. 'Zero diferenças não explicadas' não cobre linha que não existe dos dois lados. Nenhuma chave so no publicado. As 355 so na referencia se decompoem em duas partes, ambas medidas: 13 sao linhas fantasma com id_municipio nulo, eliminadas na origem; as outras 342 sao 92 municipios que ESTAO na dimensao publicada, faltando anos anteriores a criacao deles (58 municipios sem 1996-2000, cujo primeiro ano publicado e 2001, 2004 ou 2006) ou sem estimativa naquele ano (30 sem 2023). A referencia preenchia o retangulo municipio x ano completo e fabricava linha para municipio que ainda nao existia; o publicado nao. Medido em 26/07/2026, achados 66 e 67. |
| `populacao` | b_renomeacao | renomeada para 'populacao_residente_i' |
| `prop_catolicos` | b_renomeacao | renomeada para 'censo_catolicos_prop' |
| `prop_evangelicos_pentecostais` | b_renomeacao | renomeada para 'censo_evangelicos_pentecostais_prop' |
| `prop_evangelicos_missao` | b_renomeacao | renomeada para 'censo_evangelicos_missao_prop' |
| `prop_espiritas` | b_renomeacao | renomeada para 'censo_espiritas_prop' |
| `prop_matriz_africana` | b_renomeacao | renomeada para 'censo_matriz_africana_prop' |
| `ano_censo` | b_renomeacao | renomeada para 'ano_ref_censo_religiao' |

