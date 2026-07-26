# Finanças municipais: receitas orçamentárias e emendas parlamentares

**Slug:** `06_financas`  
**Camada:** dimensao  
**Dimensão:** 06_financas

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Receitas orçamentárias municipais do SICONFI e valores de emendas parlamentares por função orçamentária, da CGU.

## Procedência

| | |
|---|---|
| Fonte original | Tesouro Nacional (SICONFI) e Controladoria-Geral da União |
| Fonte da extração | Base dos Dados e Portal da Transparência |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | Dado publico federal. Uso livre com citacao da fonte, nos termos da Lei de Acesso a Informacao (Lei 12.527/2011) e do Decreto 8.777/2016 (Politica de Dados Abertos do Executivo Federal). Verificado em 26/07/2026. |
| Periodicidade da fonte | anual |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 180.023 |
| Colunas | 39 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 1989-2024 |
| **Cobertura observada na tabela** | **1989-2024** |
| Células vazias (colunas de conteúdo, sem as chaves) | 71.72% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `siconfi_receitas_totais_brl2023` | double | BRL de dezembro de 2023 | Total de receitas municipais, considerando todos os estágios (deflacionado dez/23) | 0.3% |
| `siconfi_deducao_fundeb_brl2023` | double | BRL de dezembro de 2023 | DEDUCAO da receita bruta municipal referente a parcela destinada ao FUNDEB (Fundo de Manutencao e Desenvolvimento da Educacao Basica). E uma deducao, nao uma receita: entra subtraindo da receita bruta para chegar a receita liquida. Fonte: SICONFI/Tesouro Nacional. Deflacionado para dez/2023. | 0.3% |
| `siconfi_deducao_transferencias_constitucionais_brl2023` | double | BRL de dezembro de 2023 | DEDUCAO da receita bruta municipal referente as transferencias constitucionais repassadas a outros entes. E uma deducao, nao uma receita. Fonte: SICONFI/Tesouro Nacional. Deflacionado para dez/2023. | 0.3% |
| `siconfi_deducao_outras_brl2023` | double | BRL de dezembro de 2023 | DEMAIS DEDUCOES da receita bruta municipal, alem do FUNDEB e das transferencias constitucionais — restituicoes, descontos concedidos e retificacoes. Fonte: SICONFI/Tesouro Nacional. Deflacionado para dez/2023. | 0.3% |
| `siconfi_receitas_brutas_brl2023` | double | BRL de dezembro de 2023 | Receita orcamentaria BRUTA do municipio, antes das deducoes de FUNDEB, transferencias constitucionais e demais. Fonte: SICONFI/Tesouro Nacional. Deflacionado para dez/2023. ATENCAO: herda o defeito de agregacao descrito no campo problema — soma estagios da receita e a hierarquia de contas. | 0.3% |
| `siconfi_receitas_realizadas_brl2023` | double | BRL de dezembro de 2023 | Receita orcamentaria EFETIVAMENTE REALIZADA (arrecadada) pelo municipio no exercicio, por oposicao a prevista. Fonte: SICONFI/Tesouro Nacional. Deflacionado para dez/2023. ATENCAO: ver o campo problema — a coluna e 96,95% zero e so tem dado em 2013. | 0.3% |
| `siconfi_receitas_proprias_brl2023` | double | BRL de dezembro de 2023 | Receita PROPRIA do municipio: a parcela arrecadada por tributacao e exploracao do patrimonio proprio, excluidas as transferencias de outros entes. E o indicador usual de autonomia fiscal municipal. Fonte: SICONFI/Tesouro Nacional. Deflacionado para dez/2023. ATENCAO: ver o campo problema — buraco de 2018-2021. | 0.3% |
| `siconfi_receitas_proprias_realizadas_brl_nominal` | double | BRL correntes do ano | Receita propria EFETIVAMENTE REALIZADA (arrecadada) pelo municipio no exercicio. Valor NOMINAL, em reais correntes do ano — NAO deflacionado, como o sufixo _brl_nominal declara. Fonte: SICONFI/Tesouro Nacional. ATENCAO: ver o campo problema — a coluna e 96,97% zero e so tem dado em 2013. | 0.3% |
| `siconfi_receitas_proprias_sobre_receitas_brutas_prop` | double | proporcao | Receitas próprias sobre receitas brutas. Quatro município-ano têm valor negativo, o que vem de estorno lançado na receita na origem do SICONFI. | 0.3% |
| `siconfi_receitas_proprias_realizadas_sobre_realizadas_prop` | double | proporcao | Razão Receitas Próprias em relação ao total de receitas realizadas | 97.0% |
| `emendas_localidade_gasto_cat` | character | texto | Localidade de execucao do gasto declarada na emenda parlamentar, como texto livre vindo do SICONFI. Nao e codigo IBGE: e o nome do municipio ou da localidade como digitado na peca orcamentaria, e e por esse nome, sem UF, que a emenda foi associada ao municipio — a causa das 222 chaves duplicadas desta tabela. | 94.6% |
| `emendas_localidade_gasto_secundaria_cat` | character | texto | Segunda localidade de execucao declarada na mesma emenda, quando a emenda nomeia mais de uma. Mesmo formato e mesma limitacao de emendas_localidade_gasto_cat: texto livre, sem UF. | 94.6% |
| `emendas_tipo_cat` | character | texto | Tipo de emenda igual a individual | 94.6% |
| `emendas_valor_total_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas no município | 94.6% |
| `emendas_valor_agricultura_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Agricultura | 94.6% |
| `emendas_valor_comercio_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Comércio e serviços | 94.6% |
| `emendas_valor_desporto_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Desporto e lazer | 94.6% |
| `emendas_valor_saude_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Saúde | 94.6% |
| `emendas_valor_urbanismo_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Urbanismo | 94.6% |
| `emendas_valor_organizacao_agraria_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Organização agrária | 94.6% |
| `emendas_valor_assistencia_social_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Assistência social | 94.6% |
| `emendas_valor_educacao_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Educação | 94.6% |
| `emendas_valor_direitos_cidadania_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Direitos da cidadania | 94.6% |
| `emendas_valor_defesa_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Defesa nacional | 94.6% |
| `emendas_valor_ciencia_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Ciência e Tecnologia | 94.6% |
| `emendas_valor_cultura_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Cultura | 94.6% |
| `emendas_valor_industria_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Indústria | 94.6% |
| `emendas_valor_seguranca_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Segurança pública | 94.6% |
| `emendas_valor_gestao_ambiental_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Gestão ambiental | 94.6% |
| `emendas_valor_habitacao_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Habitação | 94.6% |
| `emendas_valor_administracao_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Administração | 94.6% |
| `emendas_valor_saneamento_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Saneamento | 94.6% |
| `emendas_valor_trabalho_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Trabalho | 94.6% |
| `emendas_valor_transporte_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Transporte | 94.6% |
| `emendas_valor_previdencia_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Previdência social | 94.6% |
| `emendas_valor_encargos_especiais_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Encargos especiais | 94.6% |
| `emendas_valor_multiplo_brl2023` | double | BRL de dezembro de 2023 | Valor de emendas pagas na função Múltiplo | 94.6% |

## Ressalvas

CHAVE DUPLICADA NA ORIGEM: 222 pares município-ano aparecem mais de uma vez, com 235 linhas excedentes. A causa provável é a junção entre receitas e emendas, feita sem verificação de cardinalidade, combinada com o fato de as emendas serem associadas ao município POR NOME, sem UF — 1.067 de 11.649 linhas têm UF divergente, e o próprio comentário do script legado admite o problema. As 24 colunas de emendas chegam ao artefato com nomes em Title Case e com acento, gerados por pivot_wider (Comércio.e.serviços, Ciência.e.Tecnologia). Elas colidem com os NOMES DAS PRÓPRIAS DIMENSÕES do painel. O mapeamento para valor_emendas_* foi reconstruído e gravado. A receita própria é classificada por expressão regular sobre texto livre, procurando IPTU, ITBI e ISS no nome da conta. total_receitas_fundeb MEDE A DEDUÇÃO do FUNDEB, não uma receita. Os valores já vêm deflacionados para dezembro de 2023, sem sufixo. DEFEITO ABERTO (auditoria 26/07/2026, achados 3, 4 e 5): tres classes de defeito nas colunas de receita. (a) siconfi_receitas_totais_brl2023 e siconfi_receitas_brutas_brl2023 somam os tres estagios da receita E a hierarquia de contas, ficando inflados em cerca de uma ordem de grandeza — o maximo publicado e R$ 2,59 trilhoes num unico municipio-ano. (b) Seis colunas publicam vazio como zero, cerca de 792.000 celulas, porque sum() sobre subconjunto vazio devolve 0 e nao NA; siconfi_receitas_realizadas_brl2023 e 96,95% zero e so tem dado em 2013. (c) siconfi_receitas_proprias_brl2023 tem um buraco de quatro anos, 2018-2021, com 99,1% de zeros. A cobertura_temporal_da_fonte e a regra_preenchimento_temporal declaradas valem para a tabela e NAO para essas colunas — use o campo calculado janela_efetiva de cada uma.

**`siconfi_receitas_totais_brl2023`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 3): INUTILIZAVEL EM NIVEL. A agregacao soma os tres estagios da receita do SICONFI (Previsao Inicial, Previsao Atualizada, Receitas Realizadas) E a hierarquia de contas, publicando totais e subtotais somados. Atribui a Sao Paulo R$ 791,8 bilhoes em 2023 e a Sao Joao de Meriti/RJ R$ 2.590,0 bilhoes no mesmo ano — o maximo publicado da coluna. A soma nacional da R$ 12,24 trilhoes, e a razao receita/PIB municipal sai com mediana 2,0 quando o plausivel e 0,15-0,30. NAO USE como receita municipal, nem em nivel, nem per capita, nem como denominador.

**`siconfi_deducao_fundeb_brl2023`** — O NOME MENTE: e a DEDUCAO do FUNDEB, nao uma receita (siconfi.R:94, sum(valor[deducao_fundeb == 1])). Esta entre as colunas consumidas por scripts/artigo

**`siconfi_deducao_transferencias_constitucionais_brl2023`** — Tambem e uma DEDUCAO (siconfi.R:95, estagio == 'Deducoes - Transferencias Constitucionais'), nao a transferencia recebida

**`siconfi_deducao_outras_brl2023`** — Nome hibrido 'receitas' + 'deducoes'; e so deducao (siconfi.R:96)

**`siconfi_receitas_brutas_brl2023`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 3): INUTILIZAVEL EM NIVEL. A agregacao soma os tres estagios da receita do SICONFI (Previsao Inicial, Previsao Atualizada, Receitas Realizadas) E a hierarquia de contas, publicando totais e subtotais somados. Atribui a Sao Paulo R$ 791,8 bilhoes em 2023 e a Sao Joao de Meriti/RJ R$ 2.590,0 bilhoes no mesmo ano — o maximo publicado da coluna. A soma nacional da R$ 12,24 trilhoes, e a razao receita/PIB municipal sai com mediana 2,0 quando o plausivel e 0,15-0,30. NAO USE como receita municipal, nem em nivel, nem per capita, nem como denominador.

**`siconfi_receitas_realizadas_brl2023`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 4): VAZIO PUBLICADO COMO ZERO. A coluna vale exatamente zero em 96,95% das linhas nao nulas e so tem valor em 2013 (ver o campo calculado janela_efetiva). Nenhuma celula e NA, entao pct_na diz 0,26% e a especificacao afirma completude onde ha buraco. O padrao e o de sum() sobre subconjunto vazio, que devolve 0 e nao NA: o legado calcula sum(valor[estagio == 'Receitas Realizadas']) e, nos layouts do SICONFI em que esse estagio nao e publicado, o subconjunto e vazio. A prova interna esta na propria tabela: a razao derivada, que e 0/0 nessas linhas, sai como NA em 174.541 delas. Qualquer agregacao devolve zero em 34 dos 35 anos.

**`siconfi_receitas_proprias_brl2023`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 5): BURACO DE QUATRO ANOS. A coluna vale exatamente zero em 22.159 das 22.352 linhas nao nulas de 2018 a 2021 (99,1%) e volta ao normal em 2022. O agregado nacional cai de R$ 152,3 bilhoes em 2017 para R$ 0,0 em 2018 e volta a R$ 111,0 bilhoes em 2022, enquanto o denominador (siconfi_receitas_brutas_brl2023) nao tem um unico zero nos mesmos anos. A causa e a classificacao de receita propria por str_detect sobre NOME de conta, que deixa de casar quando o plano de contas muda de versao — o certo seria mapear pelo CODIGO da conta (MSC/PCASP). Uma media 2015-2023 de receita propria municipal sai cerca de 44% menor do que deveria, e sao justamente os anos da pandemia.

**`siconfi_receitas_proprias_realizadas_brl_nominal`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 4): VAZIO PUBLICADO COMO ZERO. A coluna vale exatamente zero em 96,95% das linhas nao nulas e so tem valor em 2013 (ver o campo calculado janela_efetiva). Nenhuma celula e NA, entao pct_na diz 0,26% e a especificacao afirma completude onde ha buraco. O padrao e o de sum() sobre subconjunto vazio, que devolve 0 e nao NA: o legado calcula sum(valor[estagio == 'Receitas Realizadas']) e, nos layouts do SICONFI em que esse estagio nao e publicado, o subconjunto e vazio. A prova interna esta na propria tabela: a razao derivada, que e 0/0 nessas linhas, sai como NA em 174.541 delas. Qualquer agregacao devolve zero em 34 dos 35 anos.

**`siconfi_receitas_proprias_sobre_receitas_brutas_prop`** — Escala 0-1 sem sufixo; denominador e total_receitas, que tem dupla contagem

**`siconfi_receitas_proprias_realizadas_sobre_realizadas_prop`** — Idem, escala 0-1 sem sufixo

**`emendas_localidade_gasto_cat`** — PUBLICADO e generico; e o texto livre 'Municipio - UF' da CGU usado como chave de pareamento (Emendas/script.R:40)

**`emendas_localidade_gasto_secundaria_cat`** — PUBLICADO com sufixo numerico sem significado; e localidade_gasto sem a UF e em minusculas (script.R:61-62)

**`emendas_tipo_cat`** — PUBLICADO, mas constante apos o filtro tipo_emenda == 'Emenda Individual - Transferencias' (script.R:53) - coluna sem variancia

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("06_financas")
x <- mape_ler("06_financas", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 20:38 por `mape_gerar_documentacao()`._

