# IDEB, SAEB e ensino superior

**Slug:** `09_educacao`  
**Camada:** dimensao  
**Dimensão:** 09_educacao

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Notas do IDEB e do SAEB agregadas por município e contagem de instituições de ensino superior.

## Procedência

| | |
|---|---|
| Fonte original | INEP |
| Fonte da extração | Base dos Dados |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | Dado publico federal. Uso livre com citacao da fonte, nos termos da Lei de Acesso a Informacao (Lei 12.527/2011) e do Decreto 8.777/2016 (Politica de Dados Abertos do Executivo Federal). Verificado em 26/07/2026. |
| Periodicidade da fonte | bienal |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 111.388 |
| Colunas | 37 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 2005-2024 |
| **Cobertura observada na tabela** | **2005-2024** |
| Células vazias (colunas de conteúdo, sem as chaves) | 22.51% |
| Regra de preenchimento temporal | `carry_forward` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `ideb_nota_municipio_idx` | double | escore de 0 a 10 | Média IDEB município | 1.4% |
| `saeb_nota_padronizada_municipio_idx` | double | escore padronizado | Média SAEB município | 1.4% |
| `ideb_meta_projetada_municipio_idx` | double | escore de 0 a 10 | Média Projeção IDEB município | 30.4% |
| `ideb_nota_fundamental_idx` | double | escore de 0 a 10 | Nota do IDEB do municipio no ensino fundamental completo (1o ao 9o ano), rede publica, em escore de 0 a 10. O IDEB combina a nota padronizada do SAEB com a taxa de aprovacao; e indicador OBSERVADO, nao meta. | 1.5% |
| `ideb_nota_medio_idx` | double | escore de 0 a 10 | Nota do IDEB do municipio no ensino medio, rede publica, em escore de 0 a 10. Indicador observado. A cobertura municipal do ensino medio e menor que a do fundamental, porque a rede estadual concentra a oferta. | 66.7% |
| `saeb_nota_fundamental_idx` | double | escore de 0 a 10 | Nota media padronizada do SAEB no ensino fundamental completo, rede publica, na escala de 0 a 10 usada na composicao do IDEB. E o componente de PROFICIENCIA do IDEB, sem o fator de aprovacao — por isso difere de ideb_nota_fundamental_idx. | 1.5% |
| `saeb_nota_medio_idx` | double | escore de 0 a 10 | Nota media padronizada do SAEB no ensino medio, rede publica, na escala de 0 a 10 usada na composicao do IDEB. Componente de proficiencia, sem o fator de aprovacao. | 66.7% |
| `ideb_meta_projetada_fundamental_idx` | double | escore de 0 a 10 | Meta do IDEB PROJETADA pelo INEP para o municipio no ensino fundamental completo naquele ano, em escore de 0 a 10. E valor projetado, nao medido: compare com ideb_nota_fundamental_idx para saber se a meta foi atingida. | 30.4% |
| `ideb_meta_projetada_medio_idx` | double | escore de 0 a 10 | Meta do IDEB projetada pelo INEP para o ensino medio naquele ano, em escore de 0 a 10. Valor projetado, nao medido. | 90.5% |
| `ideb_nota_ef_anos_finais_idx` | double | escore de 0 a 10 | Nota do IDEB nos anos finais do ensino fundamental (6o ao 9o ano), rede publica, em escore de 0 a 10. Indicador observado. | 4.5% |
| `ideb_nota_ef_anos_iniciais_idx` | double | escore de 0 a 10 | Nota do IDEB nos anos iniciais do ensino fundamental (1o ao 5o ano), rede publica, em escore de 0 a 10. Indicador observado. E a etapa com melhor cobertura municipal da serie. | 4.3% |
| `saeb_nota_anos_finais_idx` | double | escore de 0 a 10 | Nota media padronizada do SAEB nos anos finais do ensino fundamental (6o ao 9o ano), na escala de 0 a 10 do IDEB. Componente de proficiencia, sem o fator de aprovacao. | 4.5% |
| `saeb_nota_anos_iniciais_idx` | double | escore de 0 a 10 | Nota media padronizada do SAEB nos anos iniciais do ensino fundamental (1o ao 5o ano), na escala de 0 a 10 do IDEB. Componente de proficiencia, sem o fator de aprovacao. | 4.3% |
| `ideb_meta_projetada_anos_finais_idx` | double | escore de 0 a 10 | Meta do IDEB projetada pelo INEP para os anos finais do ensino fundamental naquele ano, em escore de 0 a 10. Valor projetado, nao medido. | 30.9% |
| `ideb_meta_projetada_anos_iniciais_idx` | double | escore de 0 a 10 | Meta do IDEB projetada pelo INEP para os anos iniciais do ensino fundamental naquele ano, em escore de 0 a 10. Valor projetado, nao medido. | 31.4% |
| `ideb_nota_rede_estadual_idx` | double | escore de 0 a 10 | Nota do IDEB das escolas da rede ESTADUAL localizadas no municipio, em escore de 0 a 10. Recorte por rede, nao por etapa: agrega as etapas avaliadas naquela rede. | 14.8% |
| `ideb_nota_rede_municipal_idx` | double | escore de 0 a 10 | Nota do IDEB das escolas da rede MUNICIPAL do municipio, em escore de 0 a 10. E o recorte mais proximo da gestao municipal, e por isso o mais usado em analise de politica educacional local. | 9.3% |
| `ideb_nota_rede_federal_idx` | double | escore de 0 a 10 | Nota do IDEB das escolas da rede FEDERAL localizadas no municipio, em escore de 0 a 10. Cobertura muito baixa: so os municipios que sediam institutos federais e colegios de aplicacao tem valor. | 98.7% |
| `saeb_nota_rede_estadual_idx` | double | escore de 0 a 10 | Nota media padronizada do SAEB das escolas da rede estadual localizadas no municipio, na escala de 0 a 10 do IDEB. Componente de proficiencia. | 14.8% |
| `saeb_nota_rede_municipal_idx` | double | escore de 0 a 10 | Nota media padronizada do SAEB das escolas da rede municipal, na escala de 0 a 10 do IDEB. Componente de proficiencia. | 9.3% |
| `saeb_nota_rede_federal_idx` | double | escore de 0 a 10 | Nota media padronizada do SAEB das escolas da rede federal localizadas no municipio, na escala de 0 a 10 do IDEB. Componente de proficiencia, com a mesma cobertura baixa de ideb_nota_rede_federal_idx. | 98.7% |
| `ideb_meta_projetada_rede_estadual_idx` | double | escore de 0 a 10 | Meta do IDEB projetada pelo INEP para a rede estadual no municipio naquele ano, em escore de 0 a 10. Valor projetado, nao medido. | 37.4% |
| `ideb_meta_projetada_rede_municipal_idx` | double | escore de 0 a 10 | Meta do IDEB projetada pelo INEP para a rede municipal naquele ano, em escore de 0 a 10. Valor projetado, nao medido. | 35.3% |
| `ideb_meta_projetada_rede_federal_idx` | double | escore de 0 a 10 | Meta do IDEB projetada pelo INEP para a rede federal no municipio naquele ano, em escore de 0 a 10. Valor projetado, nao medido. | 99.3% |
| `ano_ref_ideb` | double | codigo | Ano de realização do IDEB | 0.0% |
| `censup_instituicoes_ensino_superior_i` | double | contagem | Total de Instituições de Ensino Superior | 0.0% |
| `censup_ies_federais_i` | double | contagem | Total de Instituições de Ensino Superior Públicas Federais | 0.0% |
| `censup_ies_estaduais_i` | double | instituições | Total de Instituições de Ensino Superior Públicas Estaduais | 0.0% |
| `censup_ies_municipais_i` | double | instituições | Total de Instituições de Ensino Superior Públicas Municipais | 0.0% |
| `censup_ies_privadas_com_fins_lucrativos_i` | double | instituições | Total de Instituições de Ensino Superior Privadas com fins lucrativos | 0.0% |
| `censup_ies_privadas_sem_fins_lucrativos_i` | double | instituições | Total de Instituições de Ensino Superior Privadas sem fins lucrativos | 0.0% |
| `censup_ies_privadas_particulares_i` | double | instituições | Total de Instituições de Ensino Superior Privadas Particulares | 0.0% |
| `censup_ies_especiais_i` | double | instituições | Total de Instituições de Ensino Superior Especiais | 0.0% |
| `censup_ies_privadas_comunitarias_i` | double | instituições | Total de Instituições de Ensino Superior Privadas Comunitárias | 0.0% |
| `censup_ies_privadas_confessionais_i` | double | instituições | Total de Instituições de Ensino Superior Privadas Confessionais | 0.0% |

## Ressalvas

O IDEB é BIENAL e o painel anual é construído replicando cada edição para o ano seguinte: 55.694 das 111.388 linhas carregam valores duplicados do ano ímpar anterior, e a única pista é comparar ano com ano_ideb. DEFEITO CONHECIDO: as colunas do Censo da Educação Superior tiveram NA trocado por zero por índice posicional, fabricando 27.850 linhas que afirmam ZERO instituições quando o correto seria ausência de dado. As colunas media_saeb_* NÃO vêm do SAEB: a extração do SAEB nunca foi implementada, e o único bloco ativo do script é sintaticamente inválido.

**`ideb_nota_municipio_idx`** — Media NAO PONDERADA de todas as linhas do municipio, incluindo as tres redes; convive com media_ideb_rede_* sem hierarquia explicita no nome

**`saeb_nota_padronizada_municipio_idx`** — Atribui a fonte SAEB a um dado que vem da coluna nota_saeb_media_padronizada da tabela do IDEB (mesma familia: _fundamental, _medio, _anos_finais, _anos_iniciais, _rede_*)

**`ideb_meta_projetada_municipio_idx`** — 'projecao' de que indicador nao esta no nome: e a META do IDEB (mesma familia: _fundamental, _medio, _anos_finais, _anos_iniciais, _rede_*)

**`ideb_nota_ef_anos_finais_idx`** — 'anos' aqui significa SERIES escolares, no meio de uma base cuja chave temporal tambem se chama ano

**`ideb_nota_ef_anos_iniciais_idx`** — Idem; e um recorte que se SOBREPOE a media_ideb_fundamental sem prefixo que indique o eixo de corte

**`ano_ref_ideb`** — Ano da EDICAO da avaliacao (impares 2005-2023, numeric) convivendo com ano do painel (character); nada no nome indica que e a chave que distingue medicao de valor replicado

**`censup_instituicoes_ensino_superior_i`** — ERRO DE DIGITACAO publicado (falta o 'i' de instituicoes) enquanto as nove colunas irmas escrevem certo; origem censo_educacao_superior.R:53, congelado em renomear_variaveis.R:93

**`censup_ies_federais_i`** — 'instituicoes' de que nao esta no nome (sao IES do Censo da Educacao Superior); prefixo total_ generico. Mesma familia: _estaduais, _municipais, _especial, _privada_com_fins_lucrativos, _privada_sem_f

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("09_educacao")
x <- mape_ler("09_educacao", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 18:49 por `mape_gerar_documentacao()`._

