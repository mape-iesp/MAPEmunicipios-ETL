# Meio ambiente: desastres, saneamento, desmatamento e risco climático

**Slug:** `03_meio_ambiente`  
**Camada:** dimensao  
**Dimensão:** 03_meio_ambiente

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Reúne quatro fontes com coberturas muito diferentes: desastres do Atlas S2iD, saneamento do SNIS, desmatamento do PRODES e índices de risco e capacidade adaptativa do AdaptaBrasil.

## Procedência

| | |
|---|---|
| Fonte original | SEDEC/MIDR e CEPED/UFSC, SNIS, INPE e MCTI |
| Fonte da extração | Base dos Dados e downloads manuais |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | Dado publico federal. Uso livre com citacao da fonte, nos termos da Lei de Acesso a Informacao (Lei 12.527/2011) e do Decreto 8.777/2016 (Politica de Dados Abertos do Executivo Federal). Verificado em 26/07/2026. Combina SEDEC/MIDR, CEPED/UFSC, SNIS, INPE e MCTI — todas publicas. |
| Periodicidade da fonte | anual, com exceções |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 183.810 |
| Colunas | 77 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 1991-2023 |
| **Cobertura observada na tabela** | **1991-2023** |
| Células vazias (colunas de conteúdo, sem as chaves) | 37.07% |
| Regra de preenchimento temporal | `valor_unico_replicado` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `s2id_desastres_i` | double | contagem | Total desastres município ano | 0.0% |
| `s2id_pessoas_afetadas_desastre_i` | double | contagem | Total pessoas afetadas desastres município ano | 0.0% |
| `s2id_danos_materiais_brl2023` | double | BRL de dezembro de 2023 | Total danos materiais desastres município ano | 0.0% |
| `s2id_prejuizos_publicos_brl2023` | double | BRL de dezembro de 2023 | Total prejuízos públicos desastres município ano (valor deflacionado para dezembro de 2023) | 0.0% |
| `s2id_prejuizos_privados_brl2023` | double | BRL de dezembro de 2023 | Total prejuízos privados desastres município ano (valor deflacionado para dezembro de 2023) | 0.0% |
| `s2id_desastres_climatologicos_i` | double | contagem | Total desastres climatológicos município ano | 0.0% |
| `s2id_pessoas_afetadas_climatologicos_i` | double | pessoas | Total pessoas afetadas desastres climatológicos município ano | 0.0% |
| `s2id_danos_materiais_climatologicos_brl2023` | double | BRL de dezembro de 2023 | Total danos materiais desastres climatológicos município ano | 0.0% |
| `s2id_prejuizos_publicos_climatologicos_brl2023` | double | BRL de dezembro de 2023 | Total prejuízos públicos desastres climatológicos município ano (valor deflacionado para dezembro de 2023) | 0.0% |
| `s2id_prejuizos_privados_climatologicos_brl2023` | double | BRL de dezembro de 2023 | Total prejuízos privados desastres climatológicos município ano (valor deflacionado para dezembro de 2023) | 0.0% |
| `s2id_desastres_hidrologicos_i` | double | contagem | Total desastres hidrológicos município ano | 0.0% |
| `s2id_pessoas_afetadas_hidrologicos_i` | double | pessoas | Total pessoas afetadas desastres hidrológicos município ano | 0.0% |
| `s2id_danos_materiais_hidrologicos_brl2023` | double | BRL de dezembro de 2023 | Total danos materiais desastres hidrológicos município ano | 0.0% |
| `s2id_prejuizos_publicos_hidrologicos_brl2023` | double | BRL de dezembro de 2023 | Total prejuízos públicos desastres hidrológicos município ano (valor deflacionado para dezembro de 2023) | 0.0% |
| `s2id_prejuizos_privados_hidrologicos_brl2023` | double | BRL de dezembro de 2023 | Total prejuízos privados desastres hidrológicos município ano (valor deflacionado para dezembro de 2023) | 0.0% |
| `s2id_desastres_meteorologicos_i` | double | contagem | Total desastres meteorológicos município ano | 0.0% |
| `s2id_pessoas_afetadas_meteorologicos_i` | double | pessoas | Total pessoas afetadas desastres meteorológicos município ano | 0.0% |
| `s2id_danos_materiais_meteorologicos_brl2023` | double | BRL de dezembro de 2023 | Total danos materiais desastres meteorológicos município ano | 0.0% |
| `s2id_prejuizos_publicos_meteorologicos_brl2023` | double | BRL de dezembro de 2023 | Total prejuízos públicos desastres meteorológicos município ano (valor deflacionado para dezembro de 2023) | 0.0% |
| `s2id_prejuizos_privados_meteorologicos_brl2023` | double | BRL de dezembro de 2023 | Total prejuízos privados desastres meteorológicos município ano (valor deflacionado para dezembro de 2023) | 0.0% |
| `s2id_desastres_outros_i` | double | contagem | Total desastres outros município ano | 0.0% |
| `s2id_pessoas_afetadas_outros_i` | double | pessoas | Total pessoas afetadas desastres outros  município ano | 0.0% |
| `s2id_danos_materiais_outros_brl2023` | double | BRL de dezembro de 2023 | Total danos materiais desastres outros  município ano | 0.0% |
| `s2id_prejuizos_publicos_outros_brl2023` | double | BRL de dezembro de 2023 | Total prejuízos públicos desastres outros  município ano (valor deflacionado para dezembro de 2023) | 0.0% |
| `s2id_prejuizos_privados_outros_brl2023` | double | BRL de dezembro de 2023 | Total prejuízos privados desastres outros  município ano (valor deflacionado para dezembro de 2023) | 0.0% |
| `snis_populacao_atendida_agua_i` | double | contagem | AG001 - População total atendida com abastecimento de água | 45.9% |
| `snis_populacao_atendida_esgoto_i` | double | contagem | ES001 - População total atendida com esgotamento sanitário | 77.1% |
| `snis_populacao_urbana_i` | double | contagem | População urbana do município do ano de referência (Fonte: IBGE) | 38.1% |
| `snis_populacao_urbana_residente_area_atendida_agua_i` | double | contagem | G06A - População urbana residente do(s) município(s) com abastecimento de água | 38.2% |
| `snis_populacao_urbana_atendida_esgoto_i` | double | contagem | G06B - População urbana residente do(s) município(s) com esgotamento sanitário | 79.4% |
| `snis_extensao_rede_agua_km` | double | km | AG005 - Extensão da rede de água | 46.2% |
| `snis_extensao_rede_esgoto_km` | double | km | ES004 - Extensão da rede de esgotos | 77.0% |
| `snis_sedes_municipais_atendidas_agua_i` | double | contagem | GE008 - Quantidade de Sedes municipais atendidas com abastecimento de água | 37.3% |
| `snis_sedes_municipais_atendidas_esgoto_i` | double | contagem | GE009 - Quantidade de Sedes municipais atendidas com esgotamento sanitário | 76.2% |
| `snis_ligacoes_agua_i` | double | contagem | AG021 - Quantidade de ligações totais de água | 47.7% |
| `snis_ligacoes_esgoto_i` | double | contagem | ES009 - Quantidade de ligações totais de esgotos | 77.6% |
| `snis_empregados_prestador_i` | double | contagem | FN026 - Quantidade total de empregados próprios | 46.2% |
| `snis_despesa_pessoal_prestador_brl2023` | double | BRL de dezembro de 2023 | FN010 - Despesa com pessoal próprio | 46.8% |
| `snis_arrecadacao_prestador_brl2023` | double | BRL de dezembro de 2023 | FN006 - Arrecadação total (deflacionado para dezembro de 2023)  | 46.5% |
| `snis_investimento_agua_fonte_municipio_brl2023` | double | BRL de dezembro de 2023 | FN042 - Investimento realizado em abastecimento de água pelo(s) município(s) | 75.2% |
| `snis_investimento_agua_fonte_estado_brl2023` | double | BRL de dezembro de 2023 | FN052 - Investimento realizado em abastecimento de água pelo estado | 73.1% |
| `snis_investimento_agua_fonte_prestador_brl2023` | double | BRL de dezembro de 2023 | FN023 - Investimento realizado em abastecimento de água pelo prestador de serviços | 52.3% |
| `snis_investimento_esgoto_fonte_municipio_brl2023` | double | BRL de dezembro de 2023 | FN043 - Investimento realizado em esgotamento sanitário pelo(s) município(s) | 75.2% |
| `snis_investimento_esgoto_fonte_estado_brl2023` | double | BRL de dezembro de 2023 | FN053 - Investimento realizado em esgotamento sanitário pelo estado | 73.2% |
| `snis_investimento_esgoto_fonte_prestador_brl2023` | double | BRL de dezembro de 2023 | FN024 - Investimento realizado em esgotamento sanitário pelo prestador de serviços | 53.1% |
| `snis_indice_atendimento_total_agua_pct` | double | percentual | IN055_AE - Índice de atendimento total de água | 47.7% |
| `snis_indice_atendimento_esgoto_sobre_populacao_agua_pct` | double | percentual | Índice de atendimento urbano de esgoto referido aos municípios atendidos com esgoto | 77.9% |
| `area_municipio_km2` | double | km2 | Área total do município em km² conforme dados do IBGE | 30.3% |
| `area_desmatada_municipio_km2` | double | km2 | Área total desmatado do município em km², todos os biomas | 30.3% |
| `area_desmatada_bioma_amazonia_km2` | double | km2 | Área total desmatado do município em km², bioma Amazônia | 30.3% |
| `area_desmatada_bioma_caatinga_km2` | double | km2 | Área total desmatado do município em km², bioma Caatinga | 30.3% |
| `area_desmatada_bioma_cerrado_km2` | double | km2 | Área total desmatado do município em km², bioma Cerrado | 30.3% |
| `area_desmatada_bioma_mata_atlantica_km2` | double | km2 | Área total desmatado do município em km², bioma Mata Atlântica | 30.3% |
| `area_desmatada_bioma_pampa_km2` | double | km2 | Área total desmatado do município em km², bioma Pampa | 30.3% |
| `area_desmatada_bioma_pantanal_km2` | double | km2 | Área total desmatado do município em km², bioma Pantanal | 30.3% |
| `area_desmatada_sobre_area_municipio_razao` | double | razao | Área desmatada acumulada dividida pela área do município. Passa de 1 em alguns casos porque numerador e denominador vêm de fontes diferentes (PRODES e IBGE), com recortes territoriais que não coincidem exatamente. | 30.3% |
| `area_desmatada_municipio_lag1_km2` | double | km2 | Área total desmatado do município em km² (defasagem de um ano) | 33.3% |
| `variacao_area_desmatada_pct` | double | percentual | Taxa de crescimento anual da area desmatada do municipio, em PERCENTUAL: ((area_desmatada_municipio_km2 - area_desmatada_municipio_lag1_km2) / area_desmatada_municipio_lag1_km2) * 100. NAO e uma area. Confirmado em 122.503 linhas com residuo maximo de 5,8e-11 contra a formula. O dominio nao tem teto porque um municipio que sai de 0,1 km2 desmatado para 11,8 km2 tem crescimento de 11.700%. | 33.4% |
| `adapta_id_indicador` | double | identificador | Identificador interno do município na base do AdaptaBrasil. Não é o código do IBGE e não serve como chave; existe para rastrear a linha até o arquivo de origem. | 66.7% |
| `adapta_capacidade_investimento_idx` | double | indice | Capacidade de investimento público municipal e renda da população - investimentos em políticas de adaptação e em populações socioeconomicamente vulneráveis  | 66.7% |
| `adapta_capacidade_investimento_cat` | character | classe | Capacidade de investimento público municipal e renda da população - investimentos em políticas de adaptação e em populações socioeconomicamente vulneráveis (CLASSE) | 66.7% |
| `adapta_capacidade_adaptacao_inundacoes_idx` | double | indice | Índice de capacidade adaptativa para inundações, enxurradas e alagamentos  | 66.7% |
| `adapta_capacidade_adaptacao_inundacoes_cat` | character | classe | Índice de capacidade adaptativa para inundações, enxurradas e alagamentos  (CLASSE) | 66.7% |
| `adapta_risco_inundacoes_idx` | double | indice | Índice de Risco para inundações, enxurradas e alagamentos  | 66.7% |
| `adapta_risco_inundacoes_cat` | character | classe | Índice de Risco para inundações, enxurradas e alagamentos (CLASSE) | 66.7% |
| `adapta_vulnerabilidade_inundacoes_idx` | double | indice | Índice de vulnerabilidade para inundações, enxurradas e alagamentos | 66.7% |
| `adapta_vulnerabilidade_inundacoes_cat` | character | classe | Índice de vulnerabilidade para inundações, enxurradas e alagamentos (CLASSE) | 66.7% |
| `adapta_adesao_cidades_resilientes_idx` | double | indice | Adesão ao Programa Cidades Resilientes  | 66.7% |
| `adapta_adesao_cidades_resilientes_cat` | character | classe | Adesão ao Programa Cidades Resilientes (CLASSE) | 66.7% |
| `adapta_capacidade_recursos_hidricos_idx` | double | indice | Índice de capacidade adaptativa - recursos hídricos | 66.7% |
| `adapta_capacidade_recursos_hidricos_cat` | character | classe | Índice de capacidade adaptativa - recursos hídricos (CLASSE) | 66.7% |
| `adapta_risco_seca_idx` | double | indice | Índice de risco de impacto para seca | 66.7% |
| `adapta_risco_seca_cat` | character | classe | Índice de risco de impacto para seca (CLASSE) | 66.7% |
| `adapta_vulnerabilidade_seca_idx` | double | indice | Índice de vulnerabilidade - seca  | 66.7% |
| `adapta_vulnerabilidade_seca_cat` | character | classe | Índice de vulnerabilidade - seca (CLASSE) | 66.7% |

A coluna `vazios` acima é medida **nesta** tabela. Já os campos calculados do dicionário (`pct_na`, `minimo`, `maximo`, `n_distintos`) são medidos na tabela em que a variável é observada, que para 17 destas colunas é outra: `adapta_id_indicador` (03_meio_ambiente/adaptabrasil), `adapta_capacidade_investimento_idx` (03_meio_ambiente/adaptabrasil), `adapta_capacidade_investimento_cat` (03_meio_ambiente/adaptabrasil), `adapta_capacidade_adaptacao_inundacoes_idx` (03_meio_ambiente/adaptabrasil), `adapta_capacidade_adaptacao_inundacoes_cat` (03_meio_ambiente/adaptabrasil), `adapta_risco_inundacoes_idx` (03_meio_ambiente/adaptabrasil), `adapta_risco_inundacoes_cat` (03_meio_ambiente/adaptabrasil), `adapta_vulnerabilidade_inundacoes_idx` (03_meio_ambiente/adaptabrasil), `adapta_vulnerabilidade_inundacoes_cat` (03_meio_ambiente/adaptabrasil), `adapta_adesao_cidades_resilientes_idx` (03_meio_ambiente/adaptabrasil), `adapta_adesao_cidades_resilientes_cat` (03_meio_ambiente/adaptabrasil), `adapta_capacidade_recursos_hidricos_idx` (03_meio_ambiente/adaptabrasil), `adapta_capacidade_recursos_hidricos_cat` (03_meio_ambiente/adaptabrasil), `adapta_risco_seca_idx` (03_meio_ambiente/adaptabrasil), `adapta_risco_seca_cat` (03_meio_ambiente/adaptabrasil), `adapta_vulnerabilidade_seca_idx` (03_meio_ambiente/adaptabrasil), `adapta_vulnerabilidade_seca_cat` (03_meio_ambiente/adaptabrasil). Os dois números podem divergir muito, e divergem por desenho: a fonte guarda o observado e a dimensão o painel expandido.

## Ressalvas

QUATRO FONTES COM COBERTURAS QUE MAL SE SOBREPÕEM: o Atlas de Desastres vai de 1991 a 2023, o SNIS de 1995 a 2022, o PRODES de 2000 a 2022, e o AdaptaBrasil é um RETRATO ÚNICO DE 2015 replicado sobre 2010-2020. As dezesseis colunas do AdaptaBrasil chegam ao artefato com nomes AB1.1 a AB9.2 e só recebem nome legível no renomeio posicional da etapa 3 do legado. O mapeamento foi reconstruído e gravado em tools/migracao/mapa_renomeio_posicional.csv. DOIS INDICADORES PERDIDOS POR JUNÇÃO MAL ESPECIFICADA: oito indicadores do AdaptaBrasil são de 2015 e dois são de 2016; a junção inclui o ano na chave, o consolidador filtra ano == 2015, e os dois de 2016 somem — não por decisão, mas por consequência. indice_risco_seca é numérica e indice_risco_inundacoes_enxurradas é texto, vindas da mesma fonte e do mesmo bloco, porque a segunda usa o sentinela textual NaoDisponivel. O tratamento de sentinelas recupera o tipo. DEFEITO ABERTO (auditoria 26/07/2026, achado 29): 3.843 linhas de municipio-ano ANTERIORES a instalacao do municipio estao publicadas com zero em vez de ausentes — cerca de 97.000 celulas so nesta dimensao. O esqueleto do painel e um retangulo municipio x ano completo, e o diretorio nao publica ano_instalacao, entao a guarda que R/painel.R ja preve (incluir_flag_instalado) e codigo morto por falta do insumo. Acrescentar ano_instalacao ao diretorio e o pre-requisito.

**`s2id_desastres_i`** — Prefixo total_ generico, sem fonte (S2iD/Atlas de Desastres) e sem sufixo de contagem

**`s2id_pessoas_afetadas_desastre_i`** — Idem; nao diz que e afetadas POR DESASTRE

**`s2id_danos_materiais_brl2023`** — Valor monetario sem unidade e sem indicacao de deflacao

**`s2id_prejuizos_publicos_brl2023`** — Valor monetario sem unidade e sem indicacao de deflacao

**`s2id_prejuizos_privados_brl2023`** — Valor monetario sem unidade e sem indicacao de deflacao

**`s2id_desastres_climatologicos_i`** — Prefixo total_ generico; a familia tem 20 colunas (5 metricas x 4 tipos) com o mesmo defeito

**`s2id_desastres_hidrologicos_i`** — Idem

**`s2id_desastres_meteorologicos_i`** — Idem

**`s2id_desastres_outros_i`** — 'outros' como categoria residual nao documentada

**`snis_populacao_atendida_agua_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`snis_populacao_atendida_esgoto_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`snis_populacao_urbana_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`snis_populacao_urbana_residente_area_atendida_agua_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`snis_populacao_urbana_atendida_esgoto_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`snis_extensao_rede_agua_km`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 52): parte das celulas esta em METROS e nao em quilometros. O maximo publicado e 4.883.646 km, e a maior rede do pais e da ordem de 25.000 km; 47 celulas passam de 10.000 km. O fator e de 1.000 e afeta blocos identificaveis (Roraima em 1998, Parana em 1996, Fortaleza em 1998, casos avulsos de esgoto). O dominio_valido foi estreitado para que a validacao DISPARE — ele estava [0,Inf], que e estruturalmente incapaz de flagrar qualquer coisa. Corrigir exige dividir as celulas identificadas por 1.000 na camada de FONTE e reivindicar a divergencia em qa/paridade_esperada.csv antes de rodar; muda valor publicado e depende do responsavel.

**`snis_extensao_rede_esgoto_km`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 52): parte das celulas esta em METROS e nao em quilometros. O maximo publicado e 1.791.797 km, e a maior rede do pais e da ordem de 25.000 km; 40 celulas passam de 10.000 km. O fator e de 1.000 e afeta blocos identificaveis (Roraima em 1998, Parana em 1996, Fortaleza em 1998, casos avulsos de esgoto). O dominio_valido foi estreitado para que a validacao DISPARE — ele estava [0,Inf], que e estruturalmente incapaz de flagrar qualquer coisa. Corrigir exige dividir as celulas identificadas por 1.000 na camada de FONTE e reivindicar a divergencia em qa/paridade_esperada.csv antes de rodar; muda valor publicado e depende do responsavel.

**`snis_sedes_municipais_atendidas_agua_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`snis_sedes_municipais_atendidas_esgoto_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`snis_ligacoes_agua_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`snis_ligacoes_esgoto_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`snis_empregados_prestador_i`** — Estava como texto na base publicada, por coerção posicional incompleta na origem. O tipo numérico foi recuperado na migração e a declaração do dicionário, que herdara o erro, foi corrigida.

**`snis_despesa_pessoal_prestador_brl2023`** — Generico, sem fonte; e despesa de pessoal do prestador de saneamento e esta deflacionada (saneamento.R:186-190) sem marca no nome

**`snis_arrecadacao_prestador_brl2023`** — Generico, sem fonte; colide conceitualmente com as receitas do SICONFI (dim 6); deflacionada sem marca

**`snis_investimento_agua_fonte_municipio_brl2023`** — Deflacionado (saneamento.R:186-190) sem sufixo; 'municipio' aqui e a FONTE do investimento, nao a unidade geografica

**`snis_investimento_agua_fonte_estado_brl2023`** — Idem: sufixo designa a fonte do recurso e se confunde com recorte geografico

**`snis_investimento_agua_fonte_prestador_brl2023`** — Idem

**`snis_investimento_esgoto_fonte_municipio_brl2023`** — Idem

**`snis_investimento_esgoto_fonte_estado_brl2023`** — Idem

**`snis_investimento_esgoto_fonte_prestador_brl2023`** — Idem

**`snis_indice_atendimento_total_agua_pct`** — Sem prefixo de fonte e sem escala (percentual)

**`snis_indice_atendimento_esgoto_sobre_populacao_agua_pct`** — Nome ilegivel: e o indice de atendimento de esgoto referido a populacao atendida com AGUA. Sem escala

**`area_municipio_km2`** — Sem unidade (km2); 'total' redundante

**`area_desmatada_municipio_km2`** — Particulo usado como substantivo, sem unidade (km2) e sem fonte (MapBiomas/PRODES)

**`area_desmatada_bioma_amazonia_km2`** — Idem; e a parcela desmatada do bioma dentro do municipio, nao o desmatamento do bioma

**`area_desmatada_bioma_caatinga_km2`** — Idem (mesma familia: cerrado, mata_atlantica, pampa, pantanal)

**`area_desmatada_sobre_area_municipio_razao`** — Escala 0-1 sem sufixo; denominador (area_total_municipio) so visivel no codigo (desmatamento.R:67)

**`area_desmatada_municipio_lag1_km2`** — Nome de OPERACAO (lag) em vez de conceito; ordem do lag nao explicita (desmatamento.R:75)

**`variacao_area_desmatada_pct`** — CORRIGIDO em 26/07/2026 (auditoria, achado 7): a coluna era publicada como variacao_absoluta_area_desmatada_km2, com unidade km2 e escala fisica, sobre um percentual. O maximo publicado, 678.600, afirmava que um municipio desmatara 678.600 km2 a mais num ano — mais de quatro vezes o maior municipio do pais. Em 99,97% das linhas o erro era indetectavel a olho. Os VALORES nunca estiveram errados e vieram intactos do legado; o defeito era exclusivamente o rotulo.

**`adapta_id_indicador`** — Nome maximamente generico (id interno do indicador AdaptaBrasil) que sobrevive ate a base publicada, posicao 97 de renomear_variaveis.R:44

**`adapta_adesao_cidades_resilientes_idx`** — Nome plural que parece uma lista/contagem de cidades; e o indicador de adesao do municipio ao programa (AB6.1)

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("03_meio_ambiente")
x <- mape_ler("03_meio_ambiente", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 21:34 por `mape_gerar_documentacao()`._

