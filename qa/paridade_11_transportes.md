# Paridade — 11_transportes

Gerado em 2026-07-26 20:10:57.
Referência: `base_municipios_brasileiros.RDa`  
sha256: `a6f350ecf3090a7439eb680d732b9c40b34dfb79f25b4fe6e9be284cab07b336`

Colunas comparadas: 5. Diferenças não explicadas: 0.

| coluna | classe | descrição |
|---|---|---|
| `(conjunto de chaves)` | a_correcao_reivindicada | 3542 chave(s) só no publicado e 13 só na referência, de 183814 e 180285. 'Zero diferenças não explicadas' não cobre linha que não existe dos dois lados. 3.542 chaves so no publicado, em 1.083 municipios validos, nos anos 1991-2010 e 2024. O ano de 2024 e posterior a referencia; as demais sao linhas que o esqueleto do painel cria para municipio-ano anterior a instalacao do municipio, o defeito declarado do achado 29. 13 so na referencia sao linhas fantasma com id_municipio nulo. Medido em 26/07/2026, achados 29, 66 e 67. |
| `ano_inicio` | b_renomeacao | renomeada para 'ano_ref_inicio_tarifa_zero' |
| `adota_tarifa_zero` | b_renomeacao | renomeada para 'flag_adota_tarifa_zero' |
| `comprometimento_renda_domesticas_negras` | b_renomeacao | renomeada para 'comprometimento_tarifa_sobre_renda_domesticas_negras_prop' |
| `comprometimento_salario_minimo` | b_renomeacao | renomeada para 'comprometimento_tarifa_sobre_salario_minimo_prop' |
| `tarifas` | b_renomeacao | renomeada para 'tarifa_onibus_urbano_brl2023' |
| `municipio_tarifa_zero` | a_correcao_reivindicada | presente na referência e ausente da tabela publicada: Coluna removida de propósito: é o nome do município, redundante com nome_municipio de 00_diretorios, e estava preenchida em apenas 102 linhas. O bloco territorial passa a existir só no diretório. |

