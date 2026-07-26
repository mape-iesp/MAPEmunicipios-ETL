# Paridade — 04_economia

Gerado em 2026-07-26 20:09:43.
Referência: `base_municipios_brasileiros.RDa`  
sha256: `a6f350ecf3090a7439eb680d732b9c40b34dfb79f25b4fe6e9be284cab07b336`

Colunas comparadas: 17. Diferenças não explicadas: 0.

| coluna | classe | descrição |
|---|---|---|
| `(conjunto de chaves)` | a_correcao_reivindicada | 0 chave(s) só no publicado e 52499 só na referência, de 127786 e 180285. 'Zero diferenças não explicadas' não cobre linha que não existe dos dois lados. Nenhuma chave so no publicado. 52.499 so na referencia: a dimensao cobre 1999-2021 em 127.786 linhas. A referencia e um painel unico de 180.285 linhas cobrindo 1991-2023; chave presente so nela e assimetria de janela, nao perda. Medido em 26/07/2026, achados 66 e 67. |
| `pib` | b_renomeacao | renomeada para 'pib_brl2023' |
| `impostos_liquidos` | b_renomeacao | renomeada para 'impostos_liquidos_brl2023' |
| `va` | b_renomeacao | renomeada para 'valor_adicionado_bruto_brl2023' |
| `va_agropecuaria` | b_renomeacao | renomeada para 'valor_adicionado_agropecuaria_brl2023' |
| `va_industria` | b_renomeacao | renomeada para 'valor_adicionado_industria_brl2023' |
| `va_servicos` | b_renomeacao | renomeada para 'valor_adicionado_servicos_brl2023' |
| `va_adespss` | b_renomeacao | renomeada para 'valor_adicionado_administracao_publica_brl2023' |
| `pib_per_capita` | b_renomeacao | renomeada para 'pib_per_capita_brl2023' |
| `impostos_pib` | b_renomeacao | renomeada para 'impostos_sobre_pib_prop' |
| `dependencia_adm` | b_renomeacao | renomeada para 'participacao_va_administracao_publica_prop' |
| `dependencia_industria` | b_renomeacao | renomeada para 'participacao_va_industria_prop' |
| `dependencia_agro` | b_renomeacao | renomeada para 'participacao_va_agropecuaria_prop' |
| `dependencia_servicos` | b_renomeacao | renomeada para 'participacao_va_servicos_prop' |
| `log_pib` | b_renomeacao | renomeada para 'log10_pib_idx' |
| `log_pib_per_capita` | b_renomeacao | renomeada para 'log10_pib_per_capita_idx' |
| `log_valor_adicionado` | b_renomeacao | renomeada para 'log10_valor_adicionado_bruto_idx' |
| `populacao` | a_correcao_reivindicada | presente na referência e ausente da tabela publicada: Coluna removida de propósito: é uma segunda extração da mesma tabela do IBGE já publicada em 02_populacao, idêntica em 100% das linhas comparáveis. A duplicação fazia a mesma consulta ser faturada duas vezes. |
| `id_municipio_nome` | a_correcao_reivindicada | presente na referência e ausente da tabela publicada: Coluna removida de propósito: é o nome do município com prefixo id_, redundante com nome_municipio de 00_diretorios. |

