# PIB municipal e valor adicionado

**Slug:** `04_economia`  
**Camada:** dimensao  
**Dimensão:** 04_economia

<!-- Este arquivo é GERADO por mape_gerar_documentacao(). Não edite à mão:
     o conteúdo vem de dicionario/tabelas.csv, dicionario/variaveis.csv e
     da medição do próprio arquivo publicado. -->

Produto Interno Bruto municipal, valor adicionado por setor e indicadores derivados, do Sistema de Contas Regionais do IBGE.

## Procedência

| | |
|---|---|
| Fonte original | IBGE — Contas Regionais |
| Fonte da extração | Base dos Dados |
| Link | não informado |
| Método de acesso | `arquivo_local` |
| Licença | Dado publico federal. Uso livre com citacao da fonte, nos termos da Lei de Acesso a Informacao (Lei 12.527/2011) e do Decreto 8.777/2016 (Politica de Dados Abertos do Executivo Federal). Verificado em 26/07/2026. |
| Periodicidade da fonte | anual |
| Script de ingestão | `tools/migracao/migrar_dimensoes.R` |

## O que a tabela contém

| | |
|---|---|
| Linhas | 127.786 |
| Colunas | 19 |
| Municípios distintos | 5.570 de 5.570 (100%) |
| Chave primária | `id_municipio, ano` |
| Granularidade | municipio x ano |
| Cobertura declarada pela fonte | 1999-2021 |
| **Cobertura observada na tabela** | **1999-2021** |
| Células vazias (colunas de conteúdo, sem as chaves) | 0% |
| Regra de preenchimento temporal | `nenhuma` |

## Variáveis

| variável | tipo | unidade | descrição | vazios |
|---|---|---|---|---|
| `pib_brl2023` | double | BRL de dezembro de 2023 | PIB municipal (deflacionado dez/23) | 0.0% |
| `impostos_liquidos_brl2023` | double | BRL de dezembro de 2023 | Impostos, líquidos de subsídios, sobre produtos a preços correntes (deflacionado dez/23) | 0.0% |
| `valor_adicionado_bruto_brl2023` | double | BRL de dezembro de 2023 | Valor adicionado bruto a preços correntes total (deflacionado dez/23) | 0.0% |
| `valor_adicionado_agropecuaria_brl2023` | double | BRL de dezembro de 2023 | Valor adicionado bruto a preços correntes da agropecuária (deflacionado dez/23) | 0.0% |
| `valor_adicionado_industria_brl2023` | double | BRL de dezembro de 2023 | Valor adicionado bruto a preços correntes da indústria (deflacionado dez/23) | 0.0% |
| `valor_adicionado_servicos_brl2023` | double | BRL de dezembro de 2023 | Valor adicionado bruto a preços correntes dos serviços, exclusive administração, defesa, educação e saúde públicas e seguridade social (deflacionado dez/23) | 0.0% |
| `valor_adicionado_administracao_publica_brl2023` | double | BRL de dezembro de 2023 | Valor adicionado bruto a preços correntes da administração, defesa, educação e saúde públicas e seguridade social (deflacionado dez/23) | 0.0% |
| `sigla_uf_nome` | character | texto | Nome da unidade da federacao por extenso, publicado dentro de 04_economia. O nome da coluna MENTE: o prefixo sigla_ promete a sigla de duas letras e o conteudo e o nome completo. A coluna viola a regra de dono unico do bloco territorial — quem e dono de nome de UF e 00_diretorios/municipios, na coluna nome_uf, e esta aqui a duplica. Mantida publicada porque removar coluna de tabela publicada exige decisao do responsavel; ate la, PREFIRA nome_uf do diretorio. | 0.0% |
| `pib_per_capita_brl2023` | double | BRL de dezembro de 2023 | Produto Interno Bruto a preços correntes (deflacionado dez/23), dividido pela população estimada | 0.0% |
| `impostos_sobre_pib_prop` | double | proporcao | Impostos liquidos sobre o PIB municipal, como proporcao de 0 a 1. Imune a quebra de nivel do PIB (achado 1), porque o fator cancela no quociente: max dif  de 2,8e-17 contra impostos/pib. | 0.0% |
| `participacao_va_administracao_publica_prop` | double | proporcao | Divisão entre VA ADESPSS e VA geral | 0.0% |
| `participacao_va_industria_prop` | double | proporcao | Divisão entre VA Indústria e VA geral | 0.0% |
| `participacao_va_agropecuaria_prop` | double | proporcao | Divisão entre VA Agropecuária e VA geral | 0.0% |
| `participacao_va_servicos_prop` | double | proporcao | Divisão entre VA Serviços e VA geral | 0.0% |
| `log10_pib_idx` | double | adimensional | Logaritmo DECIMAL (base 10) de o PIB municipal. Adimensional: e uma transformacao de escala, nao um valor monetario. Verificado contra log10() com desvio maximo de 1,8e-15. | 0.0% |
| `log10_pib_per_capita_idx` | double | adimensional | Logaritmo DECIMAL (base 10) de o PIB per capita municipal. Adimensional: e uma transformacao de escala, nao um valor monetario. Verificado contra log10() com desvio maximo de 1,8e-15. | 0.0% |
| `log10_valor_adicionado_bruto_idx` | double | adimensional | Logaritmo DECIMAL (base 10) de o valor adicionado bruto municipal. Adimensional: e uma transformacao de escala, nao um valor monetario. Verificado contra log10() com desvio maximo de 1,8e-15. | 0.0% |

## Ressalvas

A coluna `populacao` que acompanhava esta fonte foi DESCARTADA: ela é uma segunda extração da mesma tabela do IBGE já publicada em 02_populacao, idêntica em 100% das linhas comparáveis, e a duplicação faz a mesma consulta ser faturada duas vezes. CORRECAO DE 26/07/2026 (auditoria, achado 62): esta secao afirmava que pib_per_capita_brl2023 NAO e reproduzivel a partir da base publicada. E FALSO, e foi verificado: pib_brl2023 / populacao_residente_i (de 02_populacao) reproduz a coluna em 127.786 de 127.786 linhas, com desvio maximo de 7,3e-12 — a precisao da maquina. O denominador nao esta DENTRO de 04_economia por decisao de dono unico (populacao pertence a 02_populacao), e isso e diferente de nao ser reproduzivel. DEFEITO ABERTO (auditoria 26/07/2026, achados 1 e 2): as onze colunas monetarias NAO estao em reais de dezembro de 2023. Sao valores nominais multiplicados por um fator inteiro que muda por bloco de anos (4 em 1999-2000, 3 em 2001-2003, 2 em 2004-2010, 1 de 2011 em diante), confirmado contra basedosdados.br_ibge_pib.municipio. E valor_adicionado_servicos_brl2023 muda de definicao em 2002: de 1999 a 2001 inclui a administracao publica, e a soma das quatro participacoes chega a 1,7908. Ver o campo problema de cada coluna e auditoria/CONSOLIDADO.md.

**`pib_brl2023`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 1): a serie NAO esta em reais de dezembro de 2023. Sao valores nominais em reais correntes multiplicados por um fator INTEIRO que muda por bloco de anos — 4 em 1999-2000, 3 em 2001-2003, 2 em 2004-2010 e 1 de 2011 em diante. Isso produz quedas artificiais de 17,2% em 2001, 24,0% em 2004 e 43,7% em 2011 na soma nacional. CONFIRMADO CONTRA A ORIGEM em 26/07/2026: a consulta a basedosdados.br_ibge_pib.municipio devolve UMA linha por municipio-ano (sem duplicacao la) e a razao publicado/origem e exatamente 3,0000 em 2002-2003, 2,0000 em 2004-2010 e 1,0000 de 2011 em diante. NAO USE em regressao sem efeito fixo de ano, em grafico de serie, em taxa de crescimento acumulada nem em qualquer comparacao antes/depois de 2011: um crescimento real de 12,6% em 2011 aparece como queda de 43,7%. A correcao exige decisao do responsavel pela dimensao — ver auditoria/RELATORIO-FINAL.md.

**`impostos_liquidos_brl2023`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 1): a serie NAO esta em reais de dezembro de 2023. Sao valores nominais em reais correntes multiplicados por um fator INTEIRO que muda por bloco de anos — 4 em 1999-2000, 3 em 2001-2003, 2 em 2004-2010 e 1 de 2011 em diante. Isso produz quedas artificiais de 17,2% em 2001, 24,0% em 2004 e 43,7% em 2011 na soma nacional. CONFIRMADO CONTRA A ORIGEM em 26/07/2026: a consulta a basedosdados.br_ibge_pib.municipio devolve UMA linha por municipio-ano (sem duplicacao la) e a razao publicado/origem e exatamente 3,0000 em 2002-2003, 2,0000 em 2004-2010 e 1,0000 de 2011 em diante. NAO USE em regressao sem efeito fixo de ano, em grafico de serie, em taxa de crescimento acumulada nem em qualquer comparacao antes/depois de 2011: um crescimento real de 12,6% em 2011 aparece como queda de 43,7%. A correcao exige decisao do responsavel pela dimensao — ver auditoria/RELATORIO-FINAL.md.

**`valor_adicionado_bruto_brl2023`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 1): a serie NAO esta em reais de dezembro de 2023. Sao valores nominais em reais correntes multiplicados por um fator INTEIRO que muda por bloco de anos — 4 em 1999-2000, 3 em 2001-2003, 2 em 2004-2010 e 1 de 2011 em diante. Isso produz quedas artificiais de 17,2% em 2001, 24,0% em 2004 e 43,7% em 2011 na soma nacional. CONFIRMADO CONTRA A ORIGEM em 26/07/2026: a consulta a basedosdados.br_ibge_pib.municipio devolve UMA linha por municipio-ano (sem duplicacao la) e a razao publicado/origem e exatamente 3,0000 em 2002-2003, 2,0000 em 2004-2010 e 1,0000 de 2011 em diante. NAO USE em regressao sem efeito fixo de ano, em grafico de serie, em taxa de crescimento acumulada nem em qualquer comparacao antes/depois de 2011: um crescimento real de 12,6% em 2011 aparece como queda de 43,7%. A correcao exige decisao do responsavel pela dimensao — ver auditoria/RELATORIO-FINAL.md.

**`valor_adicionado_agropecuaria_brl2023`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 1): a serie NAO esta em reais de dezembro de 2023. Sao valores nominais em reais correntes multiplicados por um fator INTEIRO que muda por bloco de anos — 4 em 1999-2000, 3 em 2001-2003, 2 em 2004-2010 e 1 de 2011 em diante. Isso produz quedas artificiais de 17,2% em 2001, 24,0% em 2004 e 43,7% em 2011 na soma nacional. CONFIRMADO CONTRA A ORIGEM em 26/07/2026: a consulta a basedosdados.br_ibge_pib.municipio devolve UMA linha por municipio-ano (sem duplicacao la) e a razao publicado/origem e exatamente 3,0000 em 2002-2003, 2,0000 em 2004-2010 e 1,0000 de 2011 em diante. NAO USE em regressao sem efeito fixo de ano, em grafico de serie, em taxa de crescimento acumulada nem em qualquer comparacao antes/depois de 2011: um crescimento real de 12,6% em 2011 aparece como queda de 43,7%. A correcao exige decisao do responsavel pela dimensao — ver auditoria/RELATORIO-FINAL.md.

**`valor_adicionado_industria_brl2023`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 1): a serie NAO esta em reais de dezembro de 2023. Sao valores nominais em reais correntes multiplicados por um fator INTEIRO que muda por bloco de anos — 4 em 1999-2000, 3 em 2001-2003, 2 em 2004-2010 e 1 de 2011 em diante. Isso produz quedas artificiais de 17,2% em 2001, 24,0% em 2004 e 43,7% em 2011 na soma nacional. CONFIRMADO CONTRA A ORIGEM em 26/07/2026: a consulta a basedosdados.br_ibge_pib.municipio devolve UMA linha por municipio-ano (sem duplicacao la) e a razao publicado/origem e exatamente 3,0000 em 2002-2003, 2,0000 em 2004-2010 e 1,0000 de 2011 em diante. NAO USE em regressao sem efeito fixo de ano, em grafico de serie, em taxa de crescimento acumulada nem em qualquer comparacao antes/depois de 2011: um crescimento real de 12,6% em 2011 aparece como queda de 43,7%. A correcao exige decisao do responsavel pela dimensao — ver auditoria/RELATORIO-FINAL.md.

**`valor_adicionado_servicos_brl2023`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 1): a serie NAO esta em reais de dezembro de 2023. Sao valores nominais em reais correntes multiplicados por um fator INTEIRO que muda por bloco de anos — 4 em 1999-2000, 3 em 2001-2003, 2 em 2004-2010 e 1 de 2011 em diante. Isso produz quedas artificiais de 17,2% em 2001, 24,0% em 2004 e 43,7% em 2011 na soma nacional. CONFIRMADO CONTRA A ORIGEM em 26/07/2026: a consulta a basedosdados.br_ibge_pib.municipio devolve UMA linha por municipio-ano (sem duplicacao la) e a razao publicado/origem e exatamente 3,0000 em 2002-2003, 2,0000 em 2004-2010 e 1,0000 de 2011 em diante. NAO USE em regressao sem efeito fixo de ano, em grafico de serie, em taxa de crescimento acumulada nem em qualquer comparacao antes/depois de 2011: um crescimento real de 12,6% em 2011 aparece como queda de 43,7%. A correcao exige decisao do responsavel pela dimensao — ver auditoria/RELATORIO-FINAL.md. DEFEITO ABERTO (auditoria 26/07/2026, achado 2): de 1999 a 2001 esta coluna INCLUI a administracao publica, que e publicada de novo em valor_adicionado_administracao_publica_brl2023. Nessas 16.574 linhas (13% da tabela) somar os quatro setores dupla-conta o setor publico. De 2002 em diante o 'exclusive administracao publica' passa a valer. A identidade PIB = VAB + impostos liquidos fecha com mediana 1,0000 nos 23 anos, o que descarta a leitura alternativa de que o VAB e que excluiria a administracao publica antes de 2002.

**`valor_adicionado_administracao_publica_brl2023`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 1): a serie NAO esta em reais de dezembro de 2023. Sao valores nominais em reais correntes multiplicados por um fator INTEIRO que muda por bloco de anos — 4 em 1999-2000, 3 em 2001-2003, 2 em 2004-2010 e 1 de 2011 em diante. Isso produz quedas artificiais de 17,2% em 2001, 24,0% em 2004 e 43,7% em 2011 na soma nacional. CONFIRMADO CONTRA A ORIGEM em 26/07/2026: a consulta a basedosdados.br_ibge_pib.municipio devolve UMA linha por municipio-ano (sem duplicacao la) e a razao publicado/origem e exatamente 3,0000 em 2002-2003, 2,0000 em 2004-2010 e 1,0000 de 2011 em diante. NAO USE em regressao sem efeito fixo de ano, em grafico de serie, em taxa de crescimento acumulada nem em qualquer comparacao antes/depois de 2011: um crescimento real de 12,6% em 2011 aparece como queda de 43,7%. A correcao exige decisao do responsavel pela dimensao — ver auditoria/RELATORIO-FINAL.md.

**`sigla_uf_nome`** — DEFEITO ABERTO: prefixo sigla_ com conteudo de nome por extenso, e duplicacao do bloco territorial que pertence a 00_diretorios/municipios. acao = remover foi declarada e NAO executada. Confirmado pelo grupo 51 da auditoria de 26/07/2026.

**`pib_per_capita_brl2023`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 1): a serie NAO esta em reais de dezembro de 2023. Sao valores nominais em reais correntes multiplicados por um fator INTEIRO que muda por bloco de anos — 4 em 1999-2000, 3 em 2001-2003, 2 em 2004-2010 e 1 de 2011 em diante. Isso produz quedas artificiais de 17,2% em 2001, 24,0% em 2004 e 43,7% em 2011 na soma nacional. CONFIRMADO CONTRA A ORIGEM em 26/07/2026: a consulta a basedosdados.br_ibge_pib.municipio devolve UMA linha por municipio-ano (sem duplicacao la) e a razao publicado/origem e exatamente 3,0000 em 2002-2003, 2,0000 em 2004-2010 e 1,0000 de 2011 em diante. NAO USE em regressao sem efeito fixo de ano, em grafico de serie, em taxa de crescimento acumulada nem em qualquer comparacao antes/depois de 2011: um crescimento real de 12,6% em 2011 aparece como queda de 43,7%. A correcao exige decisao do responsavel pela dimensao — ver auditoria/RELATORIO-FINAL.md.

**`impostos_sobre_pib_prop`** — CORRIGIDO em 26/07/2026 (auditoria, achado 102): publicada como razao_impostos_sobre_pib_prop. O prefixo razao_ foi ACRESCENTADO na harmonizacao (nome antigo impostos_pib), introduzindo no inicio do nome um dos prefixos de grandeza relativa que plano/01 manda eliminar. O sufixo _prop ja carrega a escala.

**`participacao_va_administracao_publica_prop`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 2): MUDA DE SIGNIFICADO EM 2002. Em 1999-2001 a soma das quatro participacoes tem mediana 1,2561 e maximo 1,7908, porque valor_adicionado_servicos_brl2023 inclui a administracao publica naqueles anos; de 2002 em diante a soma e exatamente 1,0000. Um estudo de terciarizacao municipal 1999-2021 ve um colapso de 33 pontos percentuais em 2002 que e puramente definicional, e nao economico. As 16.574 linhas de 1999-2001 nao devem ser comparadas com as demais.

**`participacao_va_industria_prop`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 2): MUDA DE SIGNIFICADO EM 2002. Em 1999-2001 a soma das quatro participacoes tem mediana 1,2561 e maximo 1,7908, porque valor_adicionado_servicos_brl2023 inclui a administracao publica naqueles anos; de 2002 em diante a soma e exatamente 1,0000. Um estudo de terciarizacao municipal 1999-2021 ve um colapso de 33 pontos percentuais em 2002 que e puramente definicional, e nao economico. As 16.574 linhas de 1999-2001 nao devem ser comparadas com as demais.

**`participacao_va_agropecuaria_prop`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 2): MUDA DE SIGNIFICADO EM 2002. Em 1999-2001 a soma das quatro participacoes tem mediana 1,2561 e maximo 1,7908, porque valor_adicionado_servicos_brl2023 inclui a administracao publica naqueles anos; de 2002 em diante a soma e exatamente 1,0000. Um estudo de terciarizacao municipal 1999-2021 ve um colapso de 33 pontos percentuais em 2002 que e puramente definicional, e nao economico. As 16.574 linhas de 1999-2001 nao devem ser comparadas com as demais.

**`participacao_va_servicos_prop`** — DEFEITO ABERTO (auditoria 26/07/2026, achado 2): MUDA DE SIGNIFICADO EM 2002. Em 1999-2001 a soma das quatro participacoes tem mediana 1,2561 e maximo 1,7908, porque valor_adicionado_servicos_brl2023 inclui a administracao publica naqueles anos; de 2002 em diante a soma e exatamente 1,0000. Um estudo de terciarizacao municipal 1999-2021 ve um colapso de 33 pontos percentuais em 2002 que e puramente definicional, e nao economico. As 16.574 linhas de 1999-2001 nao devem ser comparadas com as demais.

**`log10_pib_idx`** — CORRIGIDO em 26/07/2026 (auditoria, achado 48): publicada como ln_*_brl2023, com unidade R$ e escala monetaria. O prefixo ln_ prometia logaritmo natural e o conteudo e log10, e o sufixo _brl2023 prometia reais de dezembro de 2023 sobre um numero sem unidade. O campo problema anterior afirmava a base errada ('e logaritmo natural'), contradizendo a descricao da mesma linha. Herda a quebra de nivel do PIB — ver o achado 1. HERDA O DEFEITO DO ACHADO 1: e o log10 de uma coluna contaminada pelo fator de bloco, entao a serie tem degraus de log10(2) e log10(3) em 2004 e 2011.

**`log10_pib_per_capita_idx`** — CORRIGIDO em 26/07/2026 (auditoria, achado 48): publicada como ln_*_brl2023, com unidade R$ e escala monetaria. O prefixo ln_ prometia logaritmo natural e o conteudo e log10, e o sufixo _brl2023 prometia reais de dezembro de 2023 sobre um numero sem unidade. O campo problema anterior afirmava a base errada ('e logaritmo natural'), contradizendo a descricao da mesma linha. Herda a quebra de nivel do PIB — ver o achado 1. HERDA O DEFEITO DO ACHADO 1: e o log10 de uma coluna contaminada pelo fator de bloco, entao a serie tem degraus de log10(2) e log10(3) em 2004 e 2011.

**`log10_valor_adicionado_bruto_idx`** — CORRIGIDO em 26/07/2026 (auditoria, achado 48): publicada como ln_*_brl2023, com unidade R$ e escala monetaria. O prefixo ln_ prometia logaritmo natural e o conteudo e log10, e o sufixo _brl2023 prometia reais de dezembro de 2023 sobre um numero sem unidade. O campo problema anterior afirmava a base errada ('e logaritmo natural'), contradizendo a descricao da mesma linha. Herda a quebra de nivel do PIB — ver o achado 1. HERDA O DEFEITO DO ACHADO 1: e o log10 de uma coluna contaminada pelo fator de bloco, entao a serie tem degraus de log10(2) e log10(3) em 2004 e 2011.

## Como ler esta tabela

```r
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f, encoding = "UTF-8")

x <- mape_ler("04_economia")
x <- mape_ler("04_economia", territorio = TRUE)   # com nome do município e UF
```

_Gerado em 2026-07-26 21:35 por `mape_gerar_documentacao()`._

