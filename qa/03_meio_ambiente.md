# QA — 03_meio_ambiente

Gerado em 2026-07-26 15:22:28.

## Resumo

- linhas: 183.810
- colunas: 77
- células vazias (todas as colunas): 36.11%

## Checagens

Checagens executadas: 12.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| schema | informativo | (tabela): 25 de 67 coluna(s) numérica(s) sem `dominio_valido` declarado (37%): a checagem de faixa não olhou essas. | — sem justificativa — |

## Defeitos declarados no dicionário

Estes 38 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (s2id_desastres_i) Prefixo total_ generico, sem fonte (S2iD/Atlas de Desastres) e sem sufixo de contagem
- (s2id_pessoas_afetadas_desastre_i) Idem; nao diz que e afetadas POR DESASTRE
- (s2id_danos_materiais_brl2023) Valor monetario sem unidade e sem indicacao de deflacao
- (s2id_prejuizos_publicos_brl2023) Valor monetario sem unidade e sem indicacao de deflacao
- (s2id_prejuizos_privados_brl2023) Valor monetario sem unidade e sem indicacao de deflacao
- (s2id_desastres_climatologicos_i) Prefixo total_ generico; a familia tem 20 colunas (5 metricas x 4 tipos) com o mesmo defeito
- (s2id_desastres_hidrologicos_i) Idem
- (s2id_desastres_meteorologicos_i) Idem
- (s2id_desastres_outros_i) 'outros' como categoria residual nao documentada
- (snis_populacao_atendida_agua_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (snis_populacao_atendida_esgoto_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (snis_populacao_urbana_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (snis_populacao_urbana_residente_area_atendida_agua_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (snis_populacao_urbana_atendida_esgoto_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (snis_extensao_rede_agua_km) Sem unidade no nome (km) e sem prefixo de fonte
- (snis_extensao_rede_esgoto_km) Sem unidade no nome (km) e sem prefixo de fonte
- (snis_sedes_municipais_atendidas_agua_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (snis_sedes_municipais_atendidas_esgoto_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (snis_ligacoes_agua_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (snis_ligacoes_esgoto_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (snis_empregados_prestador_i) Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.
- (snis_despesa_pessoal_prestador_brl2023) Generico, sem fonte; e despesa de pessoal do prestador de saneamento e esta deflacionada (saneamento.R:186-190) sem marca no nome
- (snis_arrecadacao_prestador_brl2023) Generico, sem fonte; colide conceitualmente com as receitas do SICONFI (dim 6); deflacionada sem marca
- (snis_investimento_agua_fonte_municipio_brl2023) Deflacionado (saneamento.R:186-190) sem sufixo; 'municipio' aqui e a FONTE do investimento, nao a unidade geografica
- (snis_investimento_agua_fonte_estado_brl2023) Idem: sufixo designa a fonte do recurso e se confunde com recorte geografico
- (snis_investimento_agua_fonte_prestador_brl2023) Idem
- (snis_investimento_esgoto_fonte_municipio_brl2023) Idem
- (snis_investimento_esgoto_fonte_estado_brl2023) Idem
- (snis_investimento_esgoto_fonte_prestador_brl2023) Idem
- (snis_indice_atendimento_total_agua_pct) Sem prefixo de fonte e sem escala (percentual)
- (snis_indice_atendimento_esgoto_sobre_populacao_agua_pct) Nome ilegivel: e o indice de atendimento de esgoto referido a populacao atendida com AGUA. Sem escala
- (area_municipio_km2) Sem unidade (km2); 'total' redundante
- (area_desmatada_municipio_km2) Particulo usado como substantivo, sem unidade (km2) e sem fonte (MapBiomas/PRODES)
- (area_desmatada_bioma_amazonia_km2) Idem; e a parcela desmatada do bioma dentro do municipio, nao o desmatamento do bioma
- (area_desmatada_bioma_caatinga_km2) Idem (mesma familia: cerrado, mata_atlantica, pampa, pantanal)
- (area_desmatada_sobre_area_municipio_razao) Escala 0-1 sem sufixo; denominador (area_total_municipio) so visivel no codigo (desmatamento.R:67)
- (area_desmatada_municipio_lag1_km2) Nome de OPERACAO (lag) em vez de conceito; ordem do lag nao explicita (desmatamento.R:75)
- (variacao_absoluta_area_desmatada_km2) Contradicao interna: 'taxa' e 'abs' (absoluto) no mesmo nome; sem unidade

