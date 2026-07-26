# Paridade — 15_dados_historicos

Gerado em 2026-07-26 20:11:28.
Referência: `base_municipios_brasileiros.RDa`  
sha256: `a6f350ecf3090a7439eb680d732b9c40b34dfb79f25b4fe6e9be284cab07b336`

Colunas comparadas: 8. Diferenças não explicadas: 0.

| coluna | classe | descrição |
|---|---|---|
| `(conjunto de chaves)` | a_correcao_reivindicada | 27 chave(s) só no publicado e 6 só na referência, de 5592 e 5571. 'Zero diferenças não explicadas' não cobre linha que não existe dos dois lados. 27 codigos so no publicado, nenhum deles presente no diretorio de municipios: sao municipios EXTINTOS ou com codigo alterado desde a coleta historica de Kustov & Pardelli (ver a justificativa de dominio_chave em qa/justificativas.csv). 6 so na referencia. A tabela e transversal e a comparacao e por id_municipio. Medido em 26/07/2026, achados 25, 66 e 67. |
| `ln.pc.receita1920.sd` | b_renomeacao | renomeada para 'receita_tributaria_1920_norm_idx' |
| `ln.admpub.1920.sd` | b_renomeacao | renomeada para 'servidores_administracao_publica_1920_norm_idx' |
| `ln.forcapub.1920.sd` | b_renomeacao | renomeada para 'servidores_forca_publica_1920_norm_idx' |
| `ln.rail1920.sd` | b_renomeacao | renomeada para 'redes_ferroviarias_1920_norm_idx' |
| `amc1920` | b_renomeacao | renomeada para 'id_amc_1920' |
| `ln.dist.coast.sd` | b_renomeacao | renomeada para 'distancia_litoral_norm_idx' |
| `ln.dist.capital.sd` | b_renomeacao | renomeada para 'distancia_capital_estadual_norm_idx' |
| `estimativa_ano_fundacao` | b_renomeacao | renomeada para 'ano_ref_fundacao_estimado' |
| `estimativa_ano_fundacao` | a_correcao_reivindicada | 54 de 5619 valores diferem: 54 municipios do Tocantins tem duas linhas na base de Kustov & Pardelli — uma sob Goias (pre-1988) e outra sob Tocantins (pos-1988), porque o estado foi criado pela Constituicao de 1988 — e a comparacao por id_municipio (a chave desta tabela transversal) casa a linha publicada com uma das duas. As duas sao observacoes historicas distintas do mesmo territorio e sao mantidas de proposito; ver qa/erros_aceitos.csv. Reivindicado em 26/07/2026, achados 25 e a chave duplicada intencional. |

