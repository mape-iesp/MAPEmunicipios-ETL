# QA — 16_eleicoes

Gerado em 2026-07-26 15:40:53.

## Resumo

- linhas: 133.496
- colunas: 36
- células vazias (todas as colunas): 3.49%

## Checagens

Checagens executadas: 14.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| schema | informativo | (tabela): 7 de 25 coluna(s) numérica(s) sem `dominio_valido` declarado (28%): a checagem de faixa não olhou essas. | — sem justificativa — |

## Defeitos declarados no dicionário

Estes 18 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (tabela) DEFEITO GRAVE: os rótulos de votos brancos e nulos estão TROCADOS.
- (comparecimento_prefeito_pct) Prefixo 'proporcao' com escala 0-100 (16,56 a 99,37) e sufixo de cargo divergente. E uma das colunas consumidas por scripts/artigo
- (tse_votos_brancos_prefeito_pct) CORRIGIDO em 26/07/2026 (auditoria, achado 30): o DADO e o NOME sempre estiveram certos (brancos com mediana 1,26%, nulos com 4,46%); o que estava trocado era o campo descricao, que descrevia esta coluna como 'Proporcao Votos Nulos Prefeitura' e a irma como brancos. O legado gravava o conteudo trocado, por um rename() que passava o mesmo argumento de origem duas vezes, e a migracao consertou o conteudo mas herdou o texto antigo — que passou a descrever um defeito ja resolvido como se fosse o vivo, enquanto o defeito vivo (a descricao invertida) ficava sem registro.
- (tse_votos_nulos_prefeito_pct) CORRIGIDO em 26/07/2026 (auditoria, achado 30): ver o campo problema de tse_votos_brancos_prefeito_pct. A descricao das duas colunas estava trocada entre si no dicionario; o dado nao estava.
- (turno_i) Constante igual a 1 em todas as linhas: a base só traz primeiro turno. Mantida para não quebrar consumidor, mas não informa nada.
- (comparecimento_camara_pct) Mesma inconsistencia de escala (0-100 sob prefixo 'proporcao'). E uma das colunas consumidas por scripts/artigo
- (tse_votos_brancos_camara_pct) Chamada de proporção e medida em percentual: chega a 19,45.
- (tse_votos_nulos_camara_pct) Chamada de proporção e medida em percentual: chega a 55,41.
- (ano_ref_eleicao) Mesmo nome definido em duas dimensoes juntadas na mesma base (dim 17 e dim 7, Script Producao Banco de Dados Municipal.R:1224) e redefinido por consumidor em 5 Analise Exploratoria/Desastres.R:56. E u
- (nome_urna_prefeito_eleito_cat) Guarda NM_URNA_CANDIDATO (nome de urna), nao o nome civil; o dicionario diz apenas 'Nome do prefeito eleito'
- (sigla_partido_prefeito_eleito_cat) Generico: e o partido do PREFEITO eleito, mas nada no nome diz isso; colide com partido_segundo_colocado e sg_partido_governador_eleito
- (numero_tse_partido_prefeito_eleito) E o codigo TSE do partido do prefeito; o tipo integer sugere quantidade e o nome nao distingue de numero_segundo_colocado
- (votos_prefeito_eleito_prop) Sem sufixo de cargo e prefixo pct_ com escala 0-1 (0. Funcoes.Rmd:87), enquanto pct_votos_governador_* esta em 0-100
- (numero_tse_partido_segundo_colocado) Idem: codigo TSE tipado como integer, nome sugere quantidade
- (votos_segundo_colocado_prefeito_prop) Mesmo defeito: pct_ em escala 0-1, sem cargo
- (sigla_partido_governador_segundo_colocado_cat) 'segundo_lugar' contra 'segundo_colocado' para o mesmo conceito na MESMA tabela; prefixo sg_ do TSE preservado
- (votos_governador_eleito_pct) Prefixo pct_ em escala 0-100 (0. Funcoes.Rmd:317), contradizendo pct_votos_eleito no mesmo painel
- (flag_alinhamento_partidario_governador) Flag sem prefixo de tipo; a variante documentada alinhado_coalizao_governador e calculada (2.Criando:152-156) e nunca chega a base

