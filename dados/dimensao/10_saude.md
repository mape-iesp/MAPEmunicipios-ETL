# Saúde: cobertura vacinal, atenção básica e indicadores IEPS

**Slug:** `10_saude`  
**Camada:** dimensao  
**Dimensão:** 10_saude

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Cobertura vacinal por imunobiológico (SI-PNI), cobertura da atenção básica e da Estratégia Saúde da Família (e-Gestor), e indicadores de mortalidade, hospitalização e despesa do IEPS.

## Procedência

| | |
|---|---|
| Fonte original | Ministério da Saúde (SI-PNI, e-Gestor) e IEPS |
| Fonte da extração | Base dos Dados e IEPS Data |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | a verificar |
| Periodicidade da fonte | anual |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 149.144 |
| Colunas | 65 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 1994-2021 |
| **Cobertura observada na tabela** | **1994-2021** |
| Células vazias | 68.1% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `pni_cobertura_vacinal_agregada_pct` | double | % | Percentual da cobertura total de vacinação da população alvo da política | 0.0% |
| `pni_cobertura_bcg_pct` | double | % | Percentual da cobertura de vacinação da população alvo da política BCG | 0.0% |
| `pni_cobertura_dtp_pct` | double | % | Percentual da cobertura de vacinação da população alvo da política DTP | 18.7% |
| `pni_cobertura_dtpa_gestante_pct` | double | % | Percentual da cobertura de vacinação da população alvo da política DTPA Gestante | 70.1% |
| `pni_cobertura_febre_amarela_pct` | double | % | Percentual da cobertura de vacinação da população alvo da política Febre Amarela | 0.0% |
| `pni_cobertura_haemophilus_influenzae_b_pct` | double | % | Percentual da cobertura de vacinação da população alvo da política Influenza B | 68.6% |
| `pni_cobertura_hepatite_a_pct` | double | % | Percentual da cobertura de vacinação da população alvo da política Hepatite A | 70.1% |
| `pni_cobertura_hepatite_b_pct` | double | % | Percentual da cobertura de vacinação da população alvo da política Hepatite B | 0.0% |
| `pni_cobertura_penta_pct` | double | % | Percentual da cobertura de vacinação da população alvo da política Penta | 62.7% |
| `pni_cobertura_poliomielite_pct` | double | % | Percentual da cobertura de vacinação da população alvo da política Poliomelite | 0.0% |
| `pni_cobertura_poliomielite_reforco_4a_pct` | double | % | Percentual da cobertura de vacinação da população alvo da política Poliomielite 4 Anos | 81.3% |
| `pni_cobertura_sarampo_pct` | double | % | Percentual da cobertura de vacinação da população alvo da política Sarampo | 67.2% |
| `pni_cobertura_tetra_viral_pct` | double | % | Percentual da cobertura de vacinação da população alvo da política Tetra Viral | 66.4% |
| `pni_cobertura_triplice_bacteriana_pct` | double | % | Percentual da cobertura de vacinação da população alvo da política Tríplice Bacteriana | 66.4% |
| `pni_cobertura_triplice_viral_dose1_pct` | double | % | Percentual da cobertura de vacinação da população alvo da política Tríplice Viral D1 | 14.3% |
| `pni_cobertura_triplice_viral_d2_pct` | double | % | Percentual da cobertura de vacinação da população alvo da política Tríplice Viral D2 | 66.4% |
| `cobertura_esf_pct` | double | percentual | Proporção da população coberta pela Estratégia Saúde da Família | 47.7% |
| `cobertura_atencao_basica_pct` | double | percentual | Proporção da população coberta pela atenção básica | 47.7% |
| `ieps_cobertura_atencao_basica_pct` | double | percentual | Cobertura da Atenção Básica (%) | 77.6% |
| `ieps_cobertura_acs_pct` | double | percentual | Cobertura de Agentes Comunitários de Saúde (%) | 77.6% |
| `ieps_cobertura_esf_pct` | double | percentual | Cobertura de Estratégia de Saúde da Família (%) | 77.6% |
| `ieps_cobertura_vacinal_bcg_pct` | double | % | Cobertura Vacinal de BCG (%) | 77.6% |
| `ieps_cobertura_vacinal_rotavirus_pct` | double | % | Cobertura Vacinal de Rotavírus Humano (%) | 77.6% |
| `ieps_cobertura_vacinal_meningococo_c_pct` | double | % | Cobertura Vacinal de Meningococo C (%) | 77.6% |
| `ieps_cobertura_vacinal_pneumococica_pct` | double | % | Cobertura Vacinal de Pneumocócica (%) | 77.6% |
| `ieps_cobertura_vacinal_poliomielite_pct` | double | % | Cobertura Vacinal de Poliomielite (%) | 77.6% |
| `ieps_cobertura_vacinal_triplice_viral_dose1_pct` | double | % | Cobertura Vacinal de Tríplice Viral (1ª Dose) (%) | 77.6% |
| `ieps_cobertura_vacinal_pentavalente_pct` | double | % | Cobertura Vacinal de Pentavalente (%) | 81.3% |
| `ieps_cobertura_hepatite_b_ate_30d_pct` | double | percentual | Cobertura Vacinal de Hepatite B em crianças até 30 dias (%) | 85.1% |
| `ieps_cobertura_vacinal_hepatite_a_pct` | double | % | Cobertura Vacinal de Hepatite A (%) | 85.1% |
| `ieps_prenatal_adequado_pct` | double | % | Nascidos Vivos com Pré-Natal Adequado (%) | 86.9% |
| `ieps_prenatal_nenhuma_consulta_pct` | double | % | Nascidos Vivos com Nenhuma Consulta Pré-Natal (%) | 79.4% |
| `ieps_prenatal_1_a_6_consultas_pct` | double | % | Nascidos Vivos com 1 a 6 Consultas Pré-Natal (%) | 79.4% |
| `ieps_prenatal_7_ou_mais_consultas_pct` | double | % | Nascidos Vivos com 7 ou Mais Consultas Pré-Natal (%) | 79.4% |
| `ieps_taxa_mortalidade_p100k` | double | por 100 mil hab. | Mortalidade Bruta (por 100.000 Hab.) | 79.4% |
| `ieps_taxa_mortalidade_csap_p100k` | double | por 100 mil hab. | Mortalidade Bruta por Condições Sensíveis a Atenção Primária (por 100.000 Hab.) | 79.4% |
| `ieps_taxa_mortalidade_evitavel_p100k` | double | por 100 mil hab. | Mortalidade Bruta por Causas Evitáveis (por 100.000 Hab.) | 79.4% |
| `ieps_obitos_causas_mal_definidas_pct` | double | percentual | Mortalidade Bruta por Causas Mal Definidas (%) | 79.4% |
| `ieps_taxa_mortalidade_padronizada_oms_p100k` | double | por 100 mil habitantes | Mortalidade Ajustada (OMS, por 100.000 Hab.) | 79.4% |
| `ieps_taxa_mortalidade_csap_padronizada_oms_p100k` | double | por 100 mil habitantes | Mortalidade Ajustada por Condições Sensíveis à Atenção Primária (OMS, por 100.000 Hab.) | 79.4% |
| `ieps_taxa_mortalidade_evitavel_padronizada_oms_p100k` | double | por 100 mil habitantes | Mortalidade Ajustada por Causas Evitáveis (OMS, por 100.000 Hab.) | 79.4% |
| `ieps_taxa_mortalidade_padronizada_censo_p100k` | double | por 100 mil habitantes | Mortalidade Ajustada (Censo 2010, por 100.000 Hab.) | 79.4% |
| `ieps_taxa_mortalidade_csap_padronizada_censo_p100k` | double | por 100 mil hab. | Mortalidade Ajustada por Condições Sensíveis à Atenção Primária (Censo, por 100.000 Hab.) | 79.4% |
| `ieps_taxa_mortalidade_evitavel_padronizada_censo_p100k` | double | por 100 mil habitantes | Mortalidade Ajustada por Causas Evitáveis (Censo, por 100.000 Hab.) | 79.4% |
| `ieps_taxa_hospitalizacao_p100k` | double | por 100 mil hab. | Hospitalizações (por 100.000 Hab.) | 77.6% |
| `ieps_taxa_hospitalizacao_csap_p100k` | double | por 100 mil hab. | Hospitalizações por Condições Sensíveis à Atenção Primária (por 100.000 Hab.) | 77.6% |
| `ieps_leitos_sus_p100k` | double | por 100 mil habitantes | Leitos SUS (por 100.000 Hab.) | 77.6% |
| `ieps_leitos_uti_sus_p100k` | double | por 100 mil habitantes | Leitos de UTI SUS (por 100.000 Hab.) | 77.6% |
| `ieps_medicos_p1k` | double | por mil habitantes | Médicos (por 1.000 Hab.) | 77.6% |
| `ieps_enfermeiros_p1k` | double | por mil habitantes | Enfermeiros (por 1.000 Hab.) | 77.6% |
| `ieps_medicos_carga_horaria_p1k` | double | por mil habitantes | Médicos (Padronizados por Carga Horária, por 1.000 Hab.) | 77.6% |
| `ieps_enfermeiros_carga_horaria_p1k` | double | por mil habitantes | Enfermeiros (Padronizados por Carga Horária, por 1.000 Hab.) | 77.6% |
| `ieps_leitos_nao_sus_i` | double | leitos | Número de Leitos Não-SUS | 77.6% |
| `ieps_leitos_uti_nao_sus_i` | double | leitos | Número de Leitos de UTI Não-SUS | 77.6% |
| `ieps_leitos_nao_sus_p100k` | double | por 100 mil habitantes | Leitos Não-SUS (por 100.000 Hab.) | 77.6% |
| `ieps_leitos_uti_nao_sus_p100k` | double | por 100 mil habitantes | Leitos de UTI Não-SUS (por 100.000 Hab.) | 77.6% |
| `ieps_cobertura_plano_privado_pct` | double | percentual | Cobertura de Planos de Saúde (%) | 77.6% |
| `ieps_despesa_saude_sobre_receita_propria_pct` | double | percentual | Participação da Receita Própria Municipal Aplicada em Saúde - EC 29 (%) | 77.7% |
| `ieps_despesa_saude_total_per_capita_brl_nominal` | double | BRL correntes do ano | Despesa Total com Saúde Sob Responsabilidade do Município (por Hab., R$) | 77.7% |
| `ieps_despesa_saude_recursos_proprios_per_capita_brl_nominal` | double | BRL correntes do ano | Despesa em Saúde Utilizando Recursos Próprios do Município (por Hab., R$) | 77.7% |
| `ieps_despesa_saude_total_per_capita_brl2023` | double | BRL de dezembro de 2023 | Despesa Total com Saúde Sob Responsabilidade do Município (por Hab., R$ de 2021) | 77.7% |
| `ieps_despesa_saude_recursos_proprios_per_capita_brl2023` | double | BRL de dezembro de 2023 | Despesa em Saúde Utilizando Recursos Próprios do Município (por Hab., R$ de 2021) | 77.7% |
| `gasto_bolsa_familia_per_capita_brl2023` | double | R$ | Gasto com o Programa Bolsa Família (por Hab., R$ de 2021) | 77.6% |

## Ressalvas

OITO CONCEITOS MEDIDOS DUAS VEZES, por SI-PNI e por IEPS. As duas séries são mantidas, porque não são versões concorrentes do mesmo número: o IEPS trunca em 100 e o SI-PNI não. E no caso da hepatite B elas medem populações DIFERENTES — o IEPS cobre só crianças até 30 dias —, com correlação de 0,061 entre as duas. A cobertura do SI-PNI chega a 13.050% por erro de denominador na população-alvo; os valores são mantidos e o domínio declarado. PERDA CONHECIDA: o arquivo do IEPS consumido tem 33.420 linhas contra 66.840 do bruto — metade da fonte se perde antes de chegar aqui. As fontes SIA, SIM e SINAN têm script e nenhuma saída; ver pendencias/.

**`pni_cobertura_vacinal_agregada_pct`** — A fonte nao trunca a cobertura em 100%. O denominador e a populacao-alvo estimada, subestimada em municipios pequenos e em campanhas com publico flutuante. O maximo observado nesta coluna e 51175%. Os valores foram mantidos como a fonte publica; a validacao emite aviso a cada execucao para que o defeito nao vire paisagem.

**`pni_cobertura_bcg_pct`** — A fonte nao trunca a cobertura em 100%. O denominador e a populacao-alvo estimada, subestimada em municipios pequenos e em campanhas com publico flutuante. O maximo observado nesta coluna e 13050%. Os valores foram mantidos como a fonte publica; a validacao emite aviso a cada execucao para que o defeito nao vire paisagem.

**`pni_cobertura_dtp_pct`** — A fonte nao trunca a cobertura em 100%. O denominador e a populacao-alvo estimada, subestimada em municipios pequenos e em campanhas com publico flutuante. O maximo observado nesta coluna e 2900%. Os valores foram mantidos como a fonte publica; a validacao emite aviso a cada execucao para que o defeito nao vire paisagem.

**`pni_cobertura_dtpa_gestante_pct`** — A fonte nao trunca a cobertura em 100%. O denominador e a populacao-alvo estimada, subestimada em municipios pequenos e em campanhas com publico flutuante. O maximo observado nesta coluna e 10350%. Os valores foram mantidos como a fonte publica; a validacao emite aviso a cada execucao para que o defeito nao vire paisagem.

**`pni_cobertura_febre_amarela_pct`** — A fonte nao trunca a cobertura em 100%. O denominador e a populacao-alvo estimada, subestimada em municipios pequenos e em campanhas com publico flutuante. O maximo observado nesta coluna e 10100%. Os valores foram mantidos como a fonte publica; a validacao emite aviso a cada execucao para que o defeito nao vire paisagem.

**`pni_cobertura_haemophilus_influenzae_b_pct`** — A fonte nao trunca a cobertura em 100%. O denominador e a populacao-alvo estimada, subestimada em municipios pequenos e em campanhas com publico flutuante. O maximo observado nesta coluna e 1500%. Os valores foram mantidos como a fonte publica; a validacao emite aviso a cada execucao para que o defeito nao vire paisagem.

**`pni_cobertura_hepatite_a_pct`** — A fonte nao trunca a cobertura em 100%. O denominador e a populacao-alvo estimada, subestimada em municipios pequenos e em campanhas com publico flutuante. O maximo observado nesta coluna e 8150%. Os valores foram mantidos como a fonte publica; a validacao emite aviso a cada execucao para que o defeito nao vire paisagem.

**`pni_cobertura_hepatite_b_pct`** — A fonte nao trunca a cobertura em 100%. O denominador e a populacao-alvo estimada, subestimada em municipios pequenos e em campanhas com publico flutuante. O maximo observado nesta coluna e 12500%. Os valores foram mantidos como a fonte publica; a validacao emite aviso a cada execucao para que o defeito nao vire paisagem.

**`pni_cobertura_penta_pct`** — A fonte nao trunca a cobertura em 100%. O denominador e a populacao-alvo estimada, subestimada em municipios pequenos e em campanhas com publico flutuante. O maximo observado nesta coluna e 12500%. Os valores foram mantidos como a fonte publica; a validacao emite aviso a cada execucao para que o defeito nao vire paisagem.

**`pni_cobertura_poliomielite_pct`** — A fonte nao trunca a cobertura em 100%. O denominador e a populacao-alvo estimada, subestimada em municipios pequenos e em campanhas com publico flutuante. O maximo observado nesta coluna e 11250%. Os valores foram mantidos como a fonte publica; a validacao emite aviso a cada execucao para que o defeito nao vire paisagem.

**`pni_cobertura_poliomielite_reforco_4a_pct`** — A fonte nao trunca a cobertura em 100%. O denominador e a populacao-alvo estimada, subestimada em municipios pequenos e em campanhas com publico flutuante. O maximo observado nesta coluna e 341.67%. Os valores foram mantidos como a fonte publica; a validacao emite aviso a cada execucao para que o defeito nao vire paisagem.

**`pni_cobertura_sarampo_pct`** — A fonte nao trunca a cobertura em 100%. O denominador e a populacao-alvo estimada, subestimada em municipios pequenos e em campanhas com publico flutuante. O maximo observado nesta coluna e 2600%. Os valores foram mantidos como a fonte publica; a validacao emite aviso a cada execucao para que o defeito nao vire paisagem.

**`pni_cobertura_tetra_viral_pct`** — A fonte nao trunca a cobertura em 100%. O denominador e a populacao-alvo estimada, subestimada em municipios pequenos e em campanhas com publico flutuante. O maximo observado nesta coluna e 7250%. Os valores foram mantidos como a fonte publica; a validacao emite aviso a cada execucao para que o defeito nao vire paisagem.

**`pni_cobertura_triplice_bacteriana_pct`** — A fonte nao trunca a cobertura em 100%. O denominador e a populacao-alvo estimada, subestimada em municipios pequenos e em campanhas com publico flutuante. O maximo observado nesta coluna e 9000%. Os valores foram mantidos como a fonte publica; a validacao emite aviso a cada execucao para que o defeito nao vire paisagem.

**`pni_cobertura_triplice_viral_dose1_pct`** — A fonte nao trunca a cobertura em 100%. O denominador e a populacao-alvo estimada, subestimada em municipios pequenos e em campanhas com publico flutuante. O maximo observado nesta coluna e 9550%. Os valores foram mantidos como a fonte publica; a validacao emite aviso a cada execucao para que o defeito nao vire paisagem.

**`pni_cobertura_triplice_viral_d2_pct`** — A fonte nao trunca a cobertura em 100%. O denominador e a populacao-alvo estimada, subestimada em municipios pequenos e em campanhas com publico flutuante. O maximo observado nesta coluna e 7400%. Os valores foram mantidos como a fonte publica; a validacao emite aviso a cada execucao para que o defeito nao vire paisagem.

**`cobertura_esf_pct`** — Prefixo 'proporcao' com escala 0-100 (mediana 99,52, max 100); e uma das colunas consumidas por scripts/artigo

**`cobertura_atencao_basica_pct`** — Mesma inconsistencia: 'proporcao' com escala 0-100 (mediana 100)

**`ieps_cobertura_atencao_basica_pct`** — Abreviacao criptica sem prefixo de fonte (IEPS); redundante com proporcao_cobertura_total_atencao_basica (correlacao 0,916). E uma das colunas consumidas por scripts/artigo

**`ieps_cobertura_acs_pct`** — Abreviacao criptica (agentes comunitarios de saude) sem prefixo de fonte

**`ieps_cobertura_esf_pct`** — Abreviacao criptica; redundante com proporcao_cobertura_estrategia_saude_familia (correlacao 0,940)

**`ieps_cobertura_hepatite_b_ate_30d_pct`** — O nome sugere hepatite B em geral, mas o codebook define 'cobertura em criancas ate 30 dias'; correlacao 0,061 com cobertura_hepatite_b

**`ieps_taxa_mortalidade_p100k`** — Prefixo tx_ sem unidade no nome (e por 100 mil hab.); compete com total_mortalidade da dim 14

**`ieps_taxa_mortalidade_csap_p100k`** — Sigla CSAP (condicoes sensiveis a atencao primaria) nao expandida e sem unidade; e uma das colunas consumidas por scripts/artigo

**`ieps_taxa_mortalidade_evitavel_p100k`** — Abreviacao 'evit' (evitavel) e sem unidade

**`ieps_obitos_causas_mal_definidas_pct`** — Abreviacao 'maldef' (causas mal definidas)

**`ieps_taxa_mortalidade_csap_padronizada_censo_p100k`** — 'aj_cens' = padronizada pela estrutura etaria censitaria; sem unidade. E uma das colunas consumidas por scripts/artigo

**`ieps_taxa_hospitalizacao_p100k`** — Sem unidade no nome; e uma das colunas consumidas por scripts/artigo

**`ieps_taxa_hospitalizacao_csap_p100k`** — Sigla CSAP nao expandida e sem unidade

**`ieps_medicos_p1k`** — A unidade declarada dizia 'por 100 mil habitantes' e estava errada: a descrição da fonte e a faixa observada mostram que é por mil.

**`ieps_enfermeiros_p1k`** — A unidade declarada dizia 'por 100 mil habitantes' e estava errada: a descrição da fonte e a faixa observada mostram que é por mil.

**`ieps_medicos_carga_horaria_p1k`** — A unidade declarada dizia 'por 100 mil habitantes' e estava errada: a descrição da fonte e a faixa observada mostram que é por mil.

**`ieps_enfermeiros_carga_horaria_p1k`** — A unidade declarada dizia 'por 100 mil habitantes' e estava errada: a descrição da fonte e a faixa observada mostram que é por mil.

**`ieps_cobertura_plano_privado_pct`** — Abreviacao criptica; e cobertura de PLANO PRIVADO e se confunde facilmente com cobertura publica

**`ieps_despesa_saude_sobre_receita_propria_pct`** — Tres abreviacoes empilhadas ('desp', 'recp' = receita propria, 'mun'); colide conceitualmente com a dimensao 6 (SICONFI)

**`gasto_bolsa_familia_per_capita_brl2023`** — Conceitualmente pertence a assistencia social e nao a saude; '_def' esconde a base de deflacao; sigla PBF nao expandida. E uma das colunas consumidas por scripts/artigo

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("10_saude")
x <- mape_ler("10_saude", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 01:47 por `mape_gerar_documentacao()`._

