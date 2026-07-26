# QA — 13_seguranca

Gerado em 2026-07-26 15:10:41.

## Resumo

- linhas: 132.907
- colunas: 65
- células vazias (todas as colunas): 41.53%

## Checagens

Checagens executadas: 11.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| dominio_chave | erro | 70 código(s) fora do diretório em 352 linha(s) (0.265%). Exemplos: 1100000, 1200000, 1300000, 1400000, 1500000 [aviso sem justificativa registrada] | — sem justificativa — |

## Defeitos declarados no dicionário

Estes 13 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (sim_obitos_totais_i) Prefixo total_ generico; nao indica a fonte (SIM) nem a granularidade (ocorrencia x residencia)
- (sim_obitos_homicidio_i) Sem fonte no nome; sugere equivalencia com quantidade_homicidio_doloso (FBSP), que tem definicao, cobertura e periodo diferentes
- (sim_obitos_causa_alcool_i) Sem fonte; e obito com causa basica F10, colocado lado a lado com quantidade_posse_uso_entorpecente (ocorrencia policial) sem distincao
- (sim_obitos_ocorridos_no_domicilio_i) '_domicilio' designa local de OCORRENCIA do obito, mas se le como municipio de residencia (36 colunas da familia usam esse sufixo)
- (fbsp_feminicidio_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (fbsp_mortes_policiais_civis_confronto_em_servico_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (fbsp_mortes_policiais_agregado_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (fbsp_mortes_intervencao_policial_agregado_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (fbsp_roubo_e_furto_veiculos_agregado_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (fbsp_mortes_intervencao_policial_sobre_mvi_razao) ERRO DE DIGITACAO publicado ('intenvencao' em vez de 'intervencao'), alem de 'x' como separador de razao; anuario.R:35 e renomear_variaveis.R:144
- (fbsp_posse_e_porte_ilegal_arma_agregado_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (fbsp_grupo_municipio_cat) PUBLICADO como coluna 399 com nome maximamente generico; e a classificacao Grupo 1..4 do FBSP, sem definicao em lugar nenhum, e colide com o 'grupo' (vulneravel) do Disque 100
- (fbsp_homicidio_doloso_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

