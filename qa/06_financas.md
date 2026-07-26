# QA — 06_financas

Gerado em 2026-07-26 15:28:00.

## Resumo

- linhas: 180.023
- colunas: 39
- células vazias (todas as colunas): 68.04%

## Checagens

Checagens executadas: 12.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| chave_unica | aviso | 222 chave(s) duplicada(s), 235 linha(s) excedente(s) | 222 chaves duplicadas / 235 linhas excedentes, HERDADAS DA FONTE E MANTIDAS DE PROPOSITO. As emendas parlamentares do SICONFI sao associadas ao municipio por NOME, sem UF, e ha 222 pares municipio-ano em que dois municipios homonimos de UFs diferentes colidem. Deduplicar escolheria arbitrariamente um dos dois e apagaria a evidencia; separar exigiria a UF, que a fonte nao publica. A decisao registrada e publicar as duas linhas e declarar a duplicata. Ver CLAUDE.md, secao 'Armadilhas conhecidas'. Quem monta a base larga tem de passar deduplicar = TRUE e assumir a escolha. |
| schema | aviso | siconfi_receitas_proprias_sobre_receitas_brutas_prop: 4 valor(es) fora de [0,1]. | problema da variável siconfi_receitas_proprias_sobre_receitas_brutas_prop: Escala 0-1 sem sufixo; denominador e total_receitas, que tem dupla contagem |
| schema | informativo | (tabela): 31 de 34 coluna(s) numérica(s) sem `dominio_valido` declarado (91%): a checagem de faixa não olhou essas. | — sem justificativa — |
| descricao_repetida | aviso | siconfi_deducao_transferencias_constitucionais_brl2023: descrição igual à de `impostos_liquidos_brl2023` (tabela 04_economia) | problema da variável siconfi_deducao_transferencias_constitucionais_brl2023: Tambem e uma DEDUCAO (siconfi.R:95, estagio == 'Deducoes - Transferencias Constitucionais'), nao a transferencia recebida |
| descricao_repetida | aviso | siconfi_deducao_outras_brl2023: descrição igual à de `valor_adicionado_bruto_brl2023` (tabela 04_economia) | problema da variável siconfi_deducao_outras_brl2023: Nome hibrido 'receitas' + 'deducoes'; e so deducao (siconfi.R:96) |
| descricao_repetida | aviso | siconfi_receitas_brutas_brl2023: descrição igual à de `valor_adicionado_agropecuaria_brl2023` (tabela 04_economia) | problema da variável siconfi_receitas_brutas_brl2023: Sem prefixo de fonte nem marca de deflacao (deflacionada em siconfi.R:119-122) |
| descricao_repetida | aviso | siconfi_receitas_realizadas_brl2023: descrição igual à de `valor_adicionado_industria_brl2023` (tabela 04_economia) | problema da variável siconfi_receitas_realizadas_brl2023: Idem |
| descricao_repetida | aviso | siconfi_receitas_proprias_brl2023: descrição igual à de `valor_adicionado_servicos_brl2023` (tabela 04_economia) | problema da variável siconfi_receitas_proprias_brl2023: Idem; a regra de 'receita propria' esta so no case_when de siconfi.R:59 |
| descricao_repetida | aviso | siconfi_receitas_proprias_realizadas_brl_nominal: descrição igual à de `valor_adicionado_administracao_publica_brl2023` (tabela 04_economia) | problema da variável siconfi_receitas_proprias_realizadas_brl_nominal: UNICA coluna monetaria de financas que NAO entra no across de deflacao (siconfi.R:119-122): fica em reais nominais entre irmas deflacionadas para 12/2023, com nome indistinguivel |

## Defeitos declarados no dicionário

Estes 12 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (siconfi_deducao_fundeb_brl2023) O NOME MENTE: e a DEDUCAO do FUNDEB, nao uma receita (siconfi.R:94, sum(valor[deducao_fundeb == 1])). Esta entre as colunas consumidas por scripts/artigo
- (siconfi_deducao_transferencias_constitucionais_brl2023) Tambem e uma DEDUCAO (siconfi.R:95, estagio == 'Deducoes - Transferencias Constitucionais'), nao a transferencia recebida
- (siconfi_deducao_outras_brl2023) Nome hibrido 'receitas' + 'deducoes'; e so deducao (siconfi.R:96)
- (siconfi_receitas_brutas_brl2023) Sem prefixo de fonte nem marca de deflacao (deflacionada em siconfi.R:119-122)
- (siconfi_receitas_realizadas_brl2023) Idem
- (siconfi_receitas_proprias_brl2023) Idem; a regra de 'receita propria' esta so no case_when de siconfi.R:59
- (siconfi_receitas_proprias_realizadas_brl_nominal) UNICA coluna monetaria de financas que NAO entra no across de deflacao (siconfi.R:119-122): fica em reais nominais entre irmas deflacionadas para 12/2023, com nome indistinguivel
- (siconfi_receitas_proprias_sobre_receitas_brutas_prop) Escala 0-1 sem sufixo; denominador e total_receitas, que tem dupla contagem
- (siconfi_receitas_proprias_realizadas_sobre_realizadas_prop) Idem, escala 0-1 sem sufixo
- (emendas_localidade_gasto_cat) PUBLICADO e generico; e o texto livre 'Municipio - UF' da CGU usado como chave de pareamento (Emendas/script.R:40)
- (emendas_localidade_gasto_secundaria_cat) PUBLICADO com sufixo numerico sem significado; e localidade_gasto sem a UF e em minusculas (script.R:61-62)
- (emendas_tipo_cat) PUBLICADO, mas constante apos o filtro tipo_emenda == 'Emenda Individual - Transferencias' (script.R:53) - coluna sem variancia

