# QA — 13_seguranca

Gerado em 2026-07-26 23:01:05.

## Resumo

- linhas: 132.907
- colunas: 66
- células vazias (todas as colunas): 40.9%

## Checagens

Checagens executadas: 20.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| dominio_chave | aviso | 70 código(s) fora do diretório em 352 linha(s) (0.265%). Exemplos: 1100000, 1200000, 1300000, 1400000, 1500000 | 70 codigos nao municipais em 352 linhas (0,265%), MANTIDOS de proposito e agora MARCADOS pela coluna flag_codigo_nao_municipal. Composicao medida: 27 codigos de UF terminados em 00000 ('municipio ignorado' do SIM), 30 pseudo-codigos 3345xxx do Rio, 11 pseudo-codigos 3580xxx de Sao Paulo e 2 avulsos. Eles carregam 18.543 homicidios, e por isso a metrica de 0,265% das linhas engana: os 30 do Rio concentram 6.639 homicidios em 1996-1998 contra 269 publicados no proprio municipio do Rio, o que deixa a serie municipal carioca 96,1% subestimada naqueles anos. Descartar as linhas apagaria o dado; reagrega-las nos municipios de destino reduz linhas e muda valores publicados, e por isso depende do responsavel. Ate la ficam publicadas e marcadas. Grupos 12 e 13 da auditoria. |
| schema | informativo | (tabela): 1 de 63 coluna(s) numérica(s) sem `dominio_valido` declarado (2%): a checagem de faixa não olhou essas. | — sem justificativa — |
| zero_inflacao | aviso | sim_obitos_homicidio_preta_i: 1 ano(s) com 99% ou mais de zeros exatos (1996), enquanto 22 ano(s) têm dado. Ano inteiro zerado costuma ser vazio publicado como zero, e o valor certo para 'não medido' é NA. | O campo raca/cor do SIM tem preenchimento muito baixo em 1996, o primeiro ano da serie: a variavel so se torna de preenchimento consistente a partir de 1998-2000. O ano de 1996 sai 100% zero nas colunas de homicidio por raca/cor porque a informacao nao foi coletada, e nao porque nao houve obitos naquele recorte. Descarte 1996 em qualquer analise por raca/cor. |
| zero_inflacao | aviso | sim_obitos_homicidio_parda_i: 1 ano(s) com 99% ou mais de zeros exatos (1996), enquanto 23 ano(s) têm dado. Ano inteiro zerado costuma ser vazio publicado como zero, e o valor certo para 'não medido' é NA. | O campo raca/cor do SIM tem preenchimento muito baixo em 1996, o primeiro ano da serie: a variavel so se torna de preenchimento consistente a partir de 1998-2000. O ano de 1996 sai 100% zero nas colunas de homicidio por raca/cor porque a informacao nao foi coletada, e nao porque nao houve obitos naquele recorte. Descarte 1996 em qualquer analise por raca/cor. |
| zero_inflacao | aviso | sim_obitos_homicidio_branca_domicilio_i: 1 ano(s) com 99% ou mais de zeros exatos (1996), enquanto 20 ano(s) têm dado. Ano inteiro zerado costuma ser vazio publicado como zero, e o valor certo para 'não medido' é NA. | O campo raca/cor do SIM tem preenchimento muito baixo em 1996, o primeiro ano da serie: a variavel so se torna de preenchimento consistente a partir de 1998-2000. O ano de 1996 sai 100% zero nas colunas de homicidio por raca/cor porque a informacao nao foi coletada, e nao porque nao houve obitos naquele recorte. Descarte 1996 em qualquer analise por raca/cor. |
| zero_inflacao | aviso | sim_obitos_homicidio_parda_domicilio_i: 1 ano(s) com 99% ou mais de zeros exatos (1996), enquanto 19 ano(s) têm dado. Ano inteiro zerado costuma ser vazio publicado como zero, e o valor certo para 'não medido' é NA. | O campo raca/cor do SIM tem preenchimento muito baixo em 1996, o primeiro ano da serie: a variavel so se torna de preenchimento consistente a partir de 1998-2000. O ano de 1996 sai 100% zero nas colunas de homicidio por raca/cor porque a informacao nao foi coletada, e nao porque nao houve obitos naquele recorte. Descarte 1996 em qualquer analise por raca/cor. |
| licenca | aviso | licenca = 'A VERIFICAR — mistura o SIM/DATASUS (publico federal, uso livre com citacao) com o Anuario Brasileiro de Seguranca Publica, do Forum Brasileiro de Seguranca Publica, que e associacao privada. O Anuario e publicado sob CC BY-NC-ND em algumas edicoes, o que e INCOMPATIVEL com a redistribuicao sob CC BY 4.0 que o release faz. As colunas fbsp_* precisam de verificacao.': a tabela não declara sob que licença é publicada, e o release a distribui como CC BY 4.0. | As colunas fbsp_* vem do Anuario Brasileiro de Seguranca Publica, do Forum Brasileiro de Seguranca Publica, associacao privada. Algumas edicoes do Anuario saem sob CC BY-NC-ND, que e INCOMPATIVEL com a redistribuicao sob CC BY 4.0 que o release faz — o NC proibe uso comercial e o ND proibe obra derivada, e uma tabela derivada e exatamente uma obra derivada. Esta e a pendencia de licenca mais grave das tres. Grupo 45. |
| continuidade_painel | aviso | o último ano (2021) tem 27 linha(s), 0.5% da mediana dos anos anteriores (5.565). Série temporal calculada sobre a tabela quebra no último ponto. | O ultimo ano (2021) tem 27 linhas contra 5.565 dos anteriores. As 27 sao os codigos de UF terminados em 00000 ('municipio ignorado' do SIM) — ver flag_codigo_nao_municipal. O SIM municipal termina em 2020 nesta extracao, e 2021 so trouxe as linhas agregadas por UF. Grupos 12 e 49. Filtre flag_codigo_nao_municipal == 0 e a serie termina em 2020, que e o fim real. |

## Defeitos declarados no dicionário

Estes 14 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

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
- (flag_codigo_nao_municipal) Coluna criada em 26/07/2026 pela rodada de correcao da auditoria (grupos 12 e 13), para tornar visiveis linhas que antes so apareciam num aviso de QA de 0,265% — numero que esconde 18.543 homicidios.

