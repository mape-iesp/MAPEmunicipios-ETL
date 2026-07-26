# Paridade — 16_eleicoes

Gerado em 2026-07-26 20:11:42.
Referência: `base_municipios_brasileiros.RDa`  
sha256: `a6f350ecf3090a7439eb680d732b9c40b34dfb79f25b4fe6e9be284cab07b336`

Colunas comparadas: 34. Diferenças não explicadas: 0.

| coluna | classe | descrição |
|---|---|---|
| `(conjunto de chaves)` | a_correcao_reivindicada | 4 chave(s) só no publicado e 46793 só na referência, de 133496 e 180285. 'Zero diferenças não explicadas' não cobre linha que não existe dos dois lados. 4 chaves so no publicado, todas de um unico municipio valido, em 2000-2003. 46.793 so na referencia: a dimensao cobre 2000-2023 em 133.496 linhas. A referencia e um painel unico de 180.285 linhas cobrindo 1991-2023; chave presente so nela e assimetria de janela, nao perda. Medido em 26/07/2026, achados 66 e 67. |
| `total_aptos_prefeitura` | b_renomeacao | renomeada para 'tse_eleitores_aptos_prefeitura_i' |
| `total_comparecimento_prefeitura` | b_renomeacao | renomeada para 'tse_comparecimento_prefeitura_i' |
| `proporcao_comparecimento_prefeitura` | b_renomeacao | renomeada para 'comparecimento_prefeito_pct' |
| `proporcao_votos_nulos_prefeitura` | b_renomeacao | renomeada para 'tse_votos_brancos_prefeito_pct' |
| `proporcao_votos_nulos` | b_renomeacao | renomeada para 'tse_votos_nulos_prefeito_pct' |
| `turno` | b_renomeacao | renomeada para 'turno_i' |
| `nep_prefeitura` | b_renomeacao | renomeada para 'nep_prefeitura_idx' |
| `fracionalizacao_prefeitura` | b_renomeacao | renomeada para 'fracionalizacao_prefeitura_idx' |
| `total_aptos_camara_vereadores` | b_renomeacao | renomeada para 'tse_eleitores_aptos_camara_i' |
| `total_comparecimento_camara_vereadores` | b_renomeacao | renomeada para 'tse_comparecimento_camara_i' |
| `proporcao_comparecimento_camara_vereadores` | b_renomeacao | renomeada para 'comparecimento_camara_pct' |
| `proporcao_votos_brancos_camara_vereadores` | b_renomeacao | renomeada para 'tse_votos_brancos_camara_pct' |
| `proporcao_votos_nulos_camara_vereadores` | b_renomeacao | renomeada para 'tse_votos_nulos_camara_pct' |
| `nep_camara_vereadores` | b_renomeacao | renomeada para 'nep_camara_idx' |
| `fracionalizacao_camara_vereadores` | b_renomeacao | renomeada para 'fracionalizacao_camara_idx' |
| `ano_eleicao` | b_renomeacao | renomeada para 'ano_ref_eleicao' |
| `prefeito_eleito` | b_renomeacao | renomeada para 'nome_urna_prefeito_eleito_cat' |
| `partido` | b_renomeacao | renomeada para 'sigla_partido_prefeito_eleito_cat' |
| `numero_partido` | b_renomeacao | renomeada para 'numero_tse_partido_prefeito_eleito' |
| `pct_votos_eleito` | b_renomeacao | renomeada para 'votos_prefeito_eleito_prop' |
| `partido_segundo_colocado` | b_renomeacao | renomeada para 'partido_segundo_colocado_cat' |
| `partido_segundo_colocado` | a_correcao_reivindicada | 4740 célula(s) tinham valor e viraram NA, 0 eram NA e ganharam valor, de 133492: Sete colunas de governador e de segundo colocado tem celulas que a referencia trazia como STRING VAZIA e a dimensao publica como NA: 11.068 por coluna nas seis de governador, todas em 2000-2001 e em 5.534 municipios, e 4.740 em partido_segundo_colocado. Medido: o valor perdido e a string vazia, nao um partido. E normalizacao de vazio para ausente, nao perda de dado. Medido em 26/07/2026, achados 24 e 67. |
| `numero_segundo_colocado` | b_renomeacao | renomeada para 'numero_tse_partido_segundo_colocado' |
| `pct_votos_segundo_colocado` | b_renomeacao | renomeada para 'votos_segundo_colocado_prefeito_prop' |
| `margem_votos` | b_renomeacao | renomeada para 'tse_margem_votos_i' |
| `margem_pct` | b_renomeacao | renomeada para 'margem_prop' |
| `sg_partido_governador_eleito` | b_renomeacao | renomeada para 'partido_governador_eleito_cat' |
| `sg_partido_governador_eleito` | a_correcao_reivindicada | 11068 célula(s) tinham valor e viraram NA, 0 eram NA e ganharam valor, de 133492: Sete colunas de governador e de segundo colocado tem celulas que a referencia trazia como STRING VAZIA e a dimensao publica como NA: 11.068 por coluna nas seis de governador, todas em 2000-2001 e em 5.534 municipios, e 4.740 em partido_segundo_colocado. Medido: o valor perdido e a string vazia, nao um partido. E normalizacao de vazio para ausente, nao perda de dado. Medido em 26/07/2026, achados 24 e 67. |
| `sg_partido_governador_segundo_lugar` | b_renomeacao | renomeada para 'sigla_partido_governador_segundo_colocado_cat' |
| `sg_partido_governador_segundo_lugar` | a_correcao_reivindicada | 11068 célula(s) tinham valor e viraram NA, 0 eram NA e ganharam valor, de 133492: Sete colunas de governador e de segundo colocado tem celulas que a referencia trazia como STRING VAZIA e a dimensao publica como NA: 11.068 por coluna nas seis de governador, todas em 2000-2001 e em 5.534 municipios, e 4.740 em partido_segundo_colocado. Medido: o valor perdido e a string vazia, nao um partido. E normalizacao de vazio para ausente, nao perda de dado. Medido em 26/07/2026, achados 24 e 67. |
| `composicao_coligacao_governador_eleito` | b_renomeacao | renomeada para 'coligacao_governador_eleito_cat' |
| `composicao_coligacao_governador_eleito` | a_correcao_reivindicada | 11068 célula(s) tinham valor e viraram NA, 0 eram NA e ganharam valor, de 133492: Sete colunas de governador e de segundo colocado tem celulas que a referencia trazia como STRING VAZIA e a dimensao publica como NA: 11.068 por coluna nas seis de governador, todas em 2000-2001 e em 5.534 municipios, e 4.740 em partido_segundo_colocado. Medido: o valor perdido e a string vazia, nao um partido. E normalizacao de vazio para ausente, nao perda de dado. Medido em 26/07/2026, achados 24 e 67. |
| `composicao_coligacao_governador_segundo_lugar` | b_renomeacao | renomeada para 'coligacao_governador_segundo_lugar_cat' |
| `composicao_coligacao_governador_segundo_lugar` | a_correcao_reivindicada | 11068 célula(s) tinham valor e viraram NA, 0 eram NA e ganharam valor, de 133492: Sete colunas de governador e de segundo colocado tem celulas que a referencia trazia como STRING VAZIA e a dimensao publica como NA: 11.068 por coluna nas seis de governador, todas em 2000-2001 e em 5.534 municipios, e 4.740 em partido_segundo_colocado. Medido: o valor perdido e a string vazia, nao um partido. E normalizacao de vazio para ausente, nao perda de dado. Medido em 26/07/2026, achados 24 e 67. |
| `nm_urna_governador_eleito` | b_renomeacao | renomeada para 'nome_urna_governador_eleito_cat' |
| `nm_urna_governador_eleito` | a_correcao_reivindicada | 11068 célula(s) tinham valor e viraram NA, 0 eram NA e ganharam valor, de 133492: Sete colunas de governador e de segundo colocado tem celulas que a referencia trazia como STRING VAZIA e a dimensao publica como NA: 11.068 por coluna nas seis de governador, todas em 2000-2001 e em 5.534 municipios, e 4.740 em partido_segundo_colocado. Medido: o valor perdido e a string vazia, nao um partido. E normalizacao de vazio para ausente, nao perda de dado. Medido em 26/07/2026, achados 24 e 67. |
| `nm_urna_governador_segundo_lugar` | b_renomeacao | renomeada para 'nome_urna_governador_segundo_lugar_cat' |
| `nm_urna_governador_segundo_lugar` | a_correcao_reivindicada | 11068 célula(s) tinham valor e viraram NA, 0 eram NA e ganharam valor, de 133492: Sete colunas de governador e de segundo colocado tem celulas que a referencia trazia como STRING VAZIA e a dimensao publica como NA: 11.068 por coluna nas seis de governador, todas em 2000-2001 e em 5.534 municipios, e 4.740 em partido_segundo_colocado. Medido: o valor perdido e a string vazia, nao um partido. E normalizacao de vazio para ausente, nao perda de dado. Medido em 26/07/2026, achados 24 e 67. |
| `pct_votos_governador_eleito` | b_renomeacao | renomeada para 'votos_governador_eleito_pct' |
| `pct_votos_governador_segundo_lugar` | b_renomeacao | renomeada para 'tse_votos_governador_segundo_lugar_pct' |
| `alinhado_partido_governador` | b_renomeacao | renomeada para 'flag_alinhamento_partidario_governador' |

