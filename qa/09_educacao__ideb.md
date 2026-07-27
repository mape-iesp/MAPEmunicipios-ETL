# QA — 09_educacao/ideb

Gerado em 2026-07-26 21:35:33.

## Resumo

- linhas: 55.694
- colunas: 26
- células vazias (todas as colunas): 30.3%

## Checagens

Checagens executadas: 20.

| checagem | gravidade | descrição | justificativa |
|---|---|---|---|
| schema | informativo | (tabela): 24 de 24 coluna(s) numérica(s) sem `dominio_valido` declarado (100%): a checagem de faixa não olhou essas. | — sem justificativa — |

## Defeitos declarados no dicionário

Estes 12 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (ideb_nota_municipio_idx) Media NAO PONDERADA de todas as linhas do municipio, incluindo as tres redes; convive com media_ideb_rede_* sem hierarquia explicita no nome
- (saeb_nota_padronizada_municipio_idx) PROVENIENCIA, nao valor: a coluna e proficiencia do SAEB de verdade, mas NAO vem de uma extracao do SAEB — vem da coluna nota_saeb_media_padronizada da tabela do IDEB. A extracao do SAEB nunca foi implementada nesta arvore, e o unico bloco ativo daquele script e sintaticamente invalido. O valor esta correto e na escala de 0 a 10 do IDEB; o que nao existe e caminho proprio de atualizacao. Achado 63 da auditoria de 26/07/2026, escopo corrigido na mesma data.
- (ideb_meta_projetada_municipio_idx) 'projecao' de que indicador nao esta no nome: e a META do IDEB (mesma familia: _fundamental, _medio, _anos_finais, _anos_iniciais, _rede_*)
- (saeb_nota_fundamental_idx) PROVENIENCIA, nao valor: a coluna e proficiencia do SAEB de verdade, mas NAO vem de uma extracao do SAEB — vem da coluna nota_saeb_media_padronizada da tabela do IDEB. A extracao do SAEB nunca foi implementada nesta arvore, e o unico bloco ativo daquele script e sintaticamente invalido. O valor esta correto e na escala de 0 a 10 do IDEB; o que nao existe e caminho proprio de atualizacao. Achado 63 da auditoria de 26/07/2026, escopo corrigido na mesma data.
- (saeb_nota_medio_idx) PROVENIENCIA, nao valor: a coluna e proficiencia do SAEB de verdade, mas NAO vem de uma extracao do SAEB — vem da coluna nota_saeb_media_padronizada da tabela do IDEB. A extracao do SAEB nunca foi implementada nesta arvore, e o unico bloco ativo daquele script e sintaticamente invalido. O valor esta correto e na escala de 0 a 10 do IDEB; o que nao existe e caminho proprio de atualizacao. Achado 63 da auditoria de 26/07/2026, escopo corrigido na mesma data.
- (ideb_nota_ef_anos_finais_idx) 'anos' aqui significa SERIES escolares, no meio de uma base cuja chave temporal tambem se chama ano
- (ideb_nota_ef_anos_iniciais_idx) Idem; e um recorte que se SOBREPOE a media_ideb_fundamental sem prefixo que indique o eixo de corte
- (saeb_nota_anos_finais_idx) PROVENIENCIA, nao valor: a coluna e proficiencia do SAEB de verdade, mas NAO vem de uma extracao do SAEB — vem da coluna nota_saeb_media_padronizada da tabela do IDEB. A extracao do SAEB nunca foi implementada nesta arvore, e o unico bloco ativo daquele script e sintaticamente invalido. O valor esta correto e na escala de 0 a 10 do IDEB; o que nao existe e caminho proprio de atualizacao. Achado 63 da auditoria de 26/07/2026, escopo corrigido na mesma data.
- (saeb_nota_anos_iniciais_idx) PROVENIENCIA, nao valor: a coluna e proficiencia do SAEB de verdade, mas NAO vem de uma extracao do SAEB — vem da coluna nota_saeb_media_padronizada da tabela do IDEB. A extracao do SAEB nunca foi implementada nesta arvore, e o unico bloco ativo daquele script e sintaticamente invalido. O valor esta correto e na escala de 0 a 10 do IDEB; o que nao existe e caminho proprio de atualizacao. Achado 63 da auditoria de 26/07/2026, escopo corrigido na mesma data.
- (saeb_nota_rede_estadual_idx) PROVENIENCIA, nao valor: a coluna e proficiencia do SAEB de verdade, mas NAO vem de uma extracao do SAEB — vem da coluna nota_saeb_media_padronizada da tabela do IDEB. A extracao do SAEB nunca foi implementada nesta arvore, e o unico bloco ativo daquele script e sintaticamente invalido. O valor esta correto e na escala de 0 a 10 do IDEB; o que nao existe e caminho proprio de atualizacao. Achado 63 da auditoria de 26/07/2026, escopo corrigido na mesma data.
- (saeb_nota_rede_municipal_idx) PROVENIENCIA, nao valor: a coluna e proficiencia do SAEB de verdade, mas NAO vem de uma extracao do SAEB — vem da coluna nota_saeb_media_padronizada da tabela do IDEB. A extracao do SAEB nunca foi implementada nesta arvore, e o unico bloco ativo daquele script e sintaticamente invalido. O valor esta correto e na escala de 0 a 10 do IDEB; o que nao existe e caminho proprio de atualizacao. Achado 63 da auditoria de 26/07/2026, escopo corrigido na mesma data.
- (saeb_nota_rede_federal_idx) PROVENIENCIA, nao valor: a coluna e proficiencia do SAEB de verdade, mas NAO vem de uma extracao do SAEB — vem da coluna nota_saeb_media_padronizada da tabela do IDEB. A extracao do SAEB nunca foi implementada nesta arvore, e o unico bloco ativo daquele script e sintaticamente invalido. O valor esta correto e na escala de 0 a 10 do IDEB; o que nao existe e caminho proprio de atualizacao. Achado 63 da auditoria de 26/07/2026, escopo corrigido na mesma data.

