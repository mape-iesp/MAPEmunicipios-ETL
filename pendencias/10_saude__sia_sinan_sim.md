# Saúde: SIA, SINAN e SIM não migram

**Fonte:** `10_saude/sia_sinan_sim`  
**Registrado em:** 2026-07-26

## O que impede

Os três scripts consultam o BigQuery, geram custo real de faturamento, e terminam em summary() sem gravar nenhuma saída. Nenhuma coluna dessas fontes entra na dimensão Saúde nem na base publicada. O sia_2.R ainda tem um bloco do script de mortalidade colado dentro dele, referenciando um objeto que não existe naquele contexto.

## Evidência

11 Saúde - Códigos e Dados/{SIA/sia.R, SIA/sia_2.R, SINAN/sinan.R, SIM/mortalidade.R}

## O que se perde

Nada em relação ao publicado. O que se perde é o trabalho já feito de escrever as consultas, e o dinheiro gasto nas execuções que não produziram nada.

## O que seria preciso para recuperar

Tratar como fonte NOVA, pelo procedimento da seção 8.2 do plano. O SIM já tem extração viva na dimensão Segurança; antes de reimplementá-lo na Saúde, decidir qual das duas é a canônica — hoje a mesma fonte é extraída duas vezes.

