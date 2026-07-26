# Paridade — 07_recursos_humanos

Gerado em 2026-07-26 20:10:10.
Referência: `base_municipios_brasileiros.RDa`  
sha256: `a6f350ecf3090a7439eb680d732b9c40b34dfb79f25b4fe6e9be284cab07b336`

Colunas comparadas: 15. Diferenças não explicadas: 0.

| coluna | classe | descrição |
|---|---|---|
| `(conjunto de chaves)` | a_correcao_reivindicada | 0 chave(s) só no publicado e 113461 só na referência, de 66824 e 180285. 'Zero diferenças não explicadas' não cobre linha que não existe dos dois lados. Nenhuma chave so no publicado. As 113.461 so na referencia sao assimetria de janela e de periodicidade: a MUNIC e bienal e cobre 2009-2023 (66.824 linhas), enquanto a referencia e um painel anual unico de 180.285 linhas cobrindo 1991-2023. Medido em 26/07/2026, achados 66 e 67. |
| `estatutarios_direta` | b_renomeacao | renomeada para 'munic_vinculos_estatutarios_adm_direta_i' |
| `clt_direta` | b_renomeacao | renomeada para 'munic_vinculos_clt_adm_direta_i' |
| `comissionados_direta` | b_renomeacao | renomeada para 'munic_servidores_comissionados_direta_i' |
| `estagiarios_direta` | b_renomeacao | renomeada para 'munic_servidores_estagiarios_direta_i' |
| `sem_vinculo_permanente_direta` | b_renomeacao | renomeada para 'munic_servidores_sem_vinculo_permanente_direta_i' |
| `total_funcionarios_direta` | b_renomeacao | renomeada para 'munic_vinculos_totais_adm_direta_i' |
| `comiss_direta` | b_renomeacao | renomeada para 'munic_comissionados_adm_direta_prop' |
| `administracao_indireta` | b_renomeacao | renomeada para 'munic_existe_administracao_indireta_cat' |
| `administracao_indireta` | a_correcao_reivindicada | 5 célula(s) tinham valor e viraram NA, 0 eram NA e ganharam valor, de 66824: 81 linhas com id_municipio nulo eliminadas na origem. São as 80 linhas fantasma da planilha MUNIC de 2019, que contêm apenas o caractere '-', mais uma linha de 2011. |
| `estatutarios_indireta` | b_renomeacao | renomeada para 'munic_servidores_estatutarios_indireta_i' |
| `clt_indireta` | b_renomeacao | renomeada para 'munic_servidores_clt_indireta_i' |
| `comissionados_indireta` | b_renomeacao | renomeada para 'munic_servidores_comissionados_indireta_i' |
| `estagiarios_indireta` | b_renomeacao | renomeada para 'munic_servidores_estagiarios_indireta_i' |
| `sem_vinculo_permanente_indireta` | b_renomeacao | renomeada para 'munic_servidores_sem_vinculo_permanente_indireta_i' |
| `total_funcionarios_indireta` | b_renomeacao | renomeada para 'munic_vinculos_totais_adm_indireta_i' |
| `comiss_indireta` | b_renomeacao | renomeada para 'munic_comissionados_adm_indireta_prop' |

