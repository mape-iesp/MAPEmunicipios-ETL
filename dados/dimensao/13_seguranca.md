# Mortalidade violenta e ocorrências criminais

**Slug:** `13_seguranca`  
**Camada:** dimensao  
**Dimensão:** 13_seguranca

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Óbitos por causas violentas do SIM/DataSUS e ocorrências criminais registradas do Anuário Brasileiro de Segurança Pública.

## Procedência

| | |
|---|---|
| Fonte original | Ministério da Saúde (SIM) e Fórum Brasileiro de Segurança Pública |
| Fonte da extração | Base dos Dados |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | a verificar |
| Periodicidade da fonte | anual |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 132.907 |
| Colunas | 65 |
| Municípios distintos | 5.640 de 5.570 (101.3%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 1996-2021 |
| **Cobertura observada na tabela** | **1996-2021** |
| Células vazias | 42.8% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `sim_obitos_totais_i` | double | contagem | Total mortalidade município | 0.0% |
| `sim_obitos_homicidio_i` | double | contagem | Total mortalidade município - Foram considerados homicídios os registros cujas causas básicas de morte incluem os códigos dos seguintes intervalos: X85 a X99 e Y00 a Y05 (Cerqueira et al. 2015). | 0.0% |
| `sim_obitos_causa_alcool_i` | double | contagem | Total mortalidade município - Causas associadas a álcool F10 (https://iclinic.com.br/cid/f10/)  | 0.0% |
| `sim_obitos_feminino_i` | double | óbitos | Total mortalidade município - Feminino | 0.0% |
| `sim_obitos_masculino_i` | double | óbitos | Total mortalidade município - Masculino | 0.0% |
| `sim_obitos_homicidio_feminino_i` | double | óbitos | Total mortalidade município - Feminino - Foram considerados homicídios os registros cujas causas básicas de morte incluem os códigos dos seguintes intervalos: X85 a X99 e Y00 a Y05 (Cerqueira et al. 2015). | 0.0% |
| `sim_obitos_homicidio_masculino_i` | double | óbitos | Total mortalidade município - Masculino - Foram considerados homicídios os registros cujas causas básicas de morte incluem os códigos dos seguintes intervalos: X85 a X99 e Y00 a Y05 (Cerqueira et al. 2015). | 0.0% |
| `sim_obitos_alcool_feminino_i` | double | óbitos | Total mortalidade município - Feminino - Causas associadas a álcool F10 (https://iclinic.com.br/cid/f10/)  | 0.0% |
| `sim_obitos_alcool_masculino_i` | double | óbitos | Total mortalidade município - Masculino - Causas associadas a álcool F10 (https://iclinic.com.br/cid/f10/)  | 0.0% |
| `sim_obitos_branca_i` | double | óbitos | Total mortalidade município - Branca | 0.0% |
| `sim_obitos_preta_i` | double | óbitos | Total mortalidade município - Preta | 0.0% |
| `sim_obitos_parda_i` | double | óbitos | Total mortalidade município - Parda | 0.0% |
| `sim_obitos_amarela_i` | double | óbitos | Total mortalidade município - Amarela | 0.0% |
| `sim_obitos_indigena_i` | double | óbitos | Total mortalidade município - Indígena | 0.0% |
| `sim_obitos_preta_feminino_i` | double | óbitos | Total mortalidade município - Preta - Feminino | 0.0% |
| `sim_obitos_parda_feminino_i` | double | óbitos | Total mortalidade município - Parda - Feminino | 0.0% |
| `sim_obitos_branca_feminino_i` | double | óbitos | Total mortalidade município - Branca - Feminino | 0.0% |
| `sim_obitos_amarela_feminino_i` | double | óbitos | Total mortalidade município - Amarela - Feminino | 0.0% |
| `sim_obitos_indigena_feminino_i` | double | óbitos | Total mortalidade município - Indígena - Feminino | 0.0% |
| `sim_obitos_homicidio_branca_i` | double | óbitos | Total mortalidade município - Branca - Homicídio | 0.0% |
| `sim_obitos_homicidio_preta_i` | double | óbitos | Total mortalidade município - Preta - Homicídio | 0.0% |
| `sim_obitos_homicidio_parda_i` | double | óbitos | Total mortalidade município - Parda - Homicídio | 0.0% |
| `sim_obitos_homicidio_amarela_i` | double | óbitos | Total mortalidade município - Amarela - Homicídio | 0.0% |
| `sim_obitos_homicidio_indigena_i` | double | óbitos | Total mortalidade município - Indígena - Homicídio | 0.0% |
| `sim_obitos_ocorridos_no_domicilio_i` | double | contagem | Total mortalidade município - No domicílio | 0.0% |
| `sim_obitos_homicidio_domicilio_i` | double | óbitos | Total mortalidade município - Homicídio - No domicílio | 0.0% |
| `sim_obitos_alcool_domicilio_i` | double | óbitos | Total mortalidade município - No domicílio - Causas relacionadas à álcool | 0.0% |
| `sim_obitos_homicidio_feminino_domicilio_i` | double | óbitos | Total mortalidade município - Homicídio - No domicílio - Feminino | 0.0% |
| `sim_obitos_homicidio_masculino_domicilio_i` | double | óbitos | Total mortalidade município - Homicídio - No domicílio - Masculino | 0.0% |
| `sim_obitos_alcool_feminino_domicilio_i` | double | óbitos | Total mortalidade município - No domicílio - Causas relacionadas à álcool - Feminino | 0.0% |
| `sim_obitos_alcool_masculino_domicilio_i` | double | óbitos | Total mortalidade município - No domicílio - Causas relacionadas à álcool - Masculino | 0.0% |
| `sim_obitos_homicidio_branca_domicilio_i` | double | óbitos | Total mortalidade município - Homicídio - Branca - Domicílio | 0.0% |
| `sim_obitos_homicidio_preta_domicilio_i` | double | óbitos | Total mortalidade município - Homicídio - Preta - Domicílio | 0.0% |
| `sim_obitos_homicidio_parda_domicilio_i` | double | óbitos | Total mortalidade município - Homicídio - Parda - Domicílio | 0.0% |
| `sim_obitos_homicidio_amarela_domicilio_i` | double | óbitos | Total mortalidade município - Homicídio - Amarela - Domicílio | 0.0% |
| `sim_obitos_homicidio_indigena_domicilio_i` | double | óbitos | Total mortalidade município - Homicídio - Indígena - Domicílio | 0.0% |
| `fbsp_mortes_intervencao_policial_civil_fora_de_servico_i` | integer | ocorrências | Quantidade de Mortes decorrentes de intervenções de Policiais Civis fora de serviço | 100.0% |
| `fbsp_feminicidio_i` | double | contagem | Quantidade de Vítimas de Feminicídio | 99.9% |
| `fbsp_mortes_intervencao_policial_militar_fora_de_servico_i` | integer | ocorrências | Quantidade de Mortes decorrentes de intervenções de Policiais Militares fora de serviço | 100.0% |
| `fbsp_furto_veiculos_i` | integer | ocorrências | Quantidade de Veículos Furtados | 99.9% |
| `fbsp_mortes_intervencao_policial_civil_em_servico_i` | integer | ocorrências | Quantidade de Mortes decorrentes de intervenções de Policiais Civis em serviço | 100.0% |
| `fbsp_estupro_i` | integer | ocorrências | Quantidade de Vítimas por Estupro, incluindo as Vítimas de Estupro de Vulnerável | 99.9% |
| `fbsp_mortes_policiais_civis_confronto_em_servico_i` | double | contagem | Quantidade de Policiais Civis mortos em confronto em serviço | 100.0% |
| `fbsp_mortes_intervencao_policial_militar_em_servico_i` | integer | ocorrências | Quantidade de Mortes decorrentes de intervenções de Policiais Militares em serviço | 100.0% |
| `fbsp_mortes_policiais_agregado_i` | double | contagem | Quantidade de Policiais Civis e Militares Mortos em Situação de Confronto | 99.9% |
| `fbsp_mortes_violentas_intencionais_i` | integer | ocorrências | Quantidade de Mortes Violentas Intencionais | 99.9% |
| `fbsp_posse_uso_entorpecente_i` | integer | ocorrências | Quantidade de Posse e Uso de Entorpecentes | 99.9% |
| `fbsp_morte_policiais_militares_fora_de_servico_i` | integer | ocorrências | Quantidade de Policiais Militares mortos em confronto ou por lesão não natural fora de serviço | 100.0% |
| `fbsp_morte_policiais_civis_fora_de_servico_i` | integer | ocorrências | Quantidade de Policiais Civis mortos em confronto ou por lesão não natural fora de serviço | 100.0% |
| `fbsp_latrocinio_i` | integer | ocorrências | Quantidade de Latrocínios | 99.9% |
| `fbsp_porte_ilegal_arma_de_fogo_i` | integer | ocorrências | Quantidade de Ocorrências de Porte Ilegal de Arma de Fogo | 99.9% |
| `fbsp_mortes_intervencao_policial_agregado_i` | double | contagem | Quantidade de Mortes Decorrentes de Intervenção Policial (em serviço e fora de serviço) | 99.9% |
| `fbsp_roubo_e_furto_veiculos_agregado_i` | double | contagem | Quantidade de Veículos Roubados e Furtados | 99.9% |
| `fbsp_posse_ilegal_arma_de_fogo_i` | integer | ocorrências | Quantidade de Ocorrências de Posse Ilegal de Arma de Fogo | 99.9% |
| `fbsp_lesao_corporal_dolosa_violencia_domestica_i` | integer | ocorrências | Quantidade de Vítimas de Lesão Corporal em Violência Doméstica | 99.9% |
| `fbsp_trafico_entorpecente_i` | integer | ocorrências | Quantidade de Ocorrências de Tráfico de Entorpecentes | 99.9% |
| `fbsp_roubo_veiculos_i` | integer | ocorrências | Quantidade de Veículos Roubados | 99.9% |
| `fbsp_lesao_corporal_morte_i` | integer | ocorrências | Quantidade de Lesões Corporais Seguida de Morte | 99.9% |
| `fbsp_mortes_intervencao_policial_sobre_mvi_razao` | double | razao | Mortes decorrentes de intervenção policial divididas pelo total de mortes violentas intencionais. Chega a 37 porque o denominador pode ser muito pequeno em municípios com poucas ocorrências. | 99.9% |
| `fbsp_morte_policiais_militares_confronto_em_servico_i` | integer | ocorrências | Quantidade de Policiais Militares mortos em confronto em serviço | 100.0% |
| `fbsp_posse_e_porte_ilegal_arma_agregado_i` | double | contagem | Quantidade de Ocorrências de Posse Ilegal e Porte Ilegal de Arma de Fogo | 99.9% |
| `fbsp_grupo_municipio_cat` | character | texto | Grupos segundo qualidade estimada dos registros estatísticos oficiais | 99.9% |
| `fbsp_homicidio_doloso_i` | double | contagem | Quantidade de Homicídios Dolosos | 99.9% |

## Ressalvas

COBERTURA MUITO DESIGUAL ENTRE AS DUAS FONTES. O SIM cobre os 5.570 municípios de 1996 a 2019. O Anuário do FBSP cobre 27 municípios (as 26 capitais mais Brasília) de 2016 a 2021, ou seja, 162 linhas: as 26 colunas quantidade_* têm dado em 0,09% do painel. DEFEITO NÃO CORRIGIDO: a mortalidade do Rio de Janeiro entre 1996 e 1998 está subestimada em cerca de 97%, porque o SIM codificou os óbitos do município em 30 pseudo-códigos sub-municipais que a junção descarta. DEFEITO NÃO CORRIGIDO: uma quebra de linha dentro da expressão regular de classificação faz com que nenhum óbito com causa X96 seja contado como homicídio. 27 códigos de UF disfarçados de município existem na fonte e não entram nesta tabela; devem ir para uma tabela em nível de UF.

**`sim_obitos_totais_i`** — Prefixo total_ generico; nao indica a fonte (SIM) nem a granularidade (ocorrencia x residencia)

**`sim_obitos_homicidio_i`** — Sem fonte no nome; sugere equivalencia com quantidade_homicidio_doloso (FBSP), que tem definicao, cobertura e periodo diferentes

**`sim_obitos_causa_alcool_i`** — Sem fonte; e obito com causa basica F10, colocado lado a lado com quantidade_posse_uso_entorpecente (ocorrencia policial) sem distincao

**`sim_obitos_ocorridos_no_domicilio_i`** — '_domicilio' designa local de OCORRENCIA do obito, mas se le como municipio de residencia (36 colunas da familia usam esse sufixo)

**`fbsp_feminicidio_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`fbsp_mortes_policiais_civis_confronto_em_servico_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`fbsp_mortes_policiais_agregado_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`fbsp_mortes_intervencao_policial_agregado_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`fbsp_roubo_e_furto_veiculos_agregado_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`fbsp_mortes_intervencao_policial_sobre_mvi_razao`** — ERRO DE DIGITACAO publicado ('intenvencao' em vez de 'intervencao'), alem de 'x' como separador de razao; anuario.R:35 e renomear_variaveis.R:144

**`fbsp_posse_e_porte_ilegal_arma_agregado_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`fbsp_grupo_municipio_cat`** — PUBLICADO como coluna 399 com nome maximamente generico; e a classificacao Grupo 1..4 do FBSP, sem definicao em lugar nenhum, e colide com o 'grupo' (vulneravel) do Disque 100

**`fbsp_homicidio_doloso_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("13_seguranca")
x <- mape_ler("13_seguranca", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 01:47 por `mape_gerar_documentacao()`._

