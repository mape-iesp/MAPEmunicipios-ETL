# Fechamento do ETL

Este documento cobre a etapa que fechou a distância entre "a migração acabou" e
"o ETL está pronto". A migração terminou em 26 de julho de 2026 com as dezesseis
dimensões publicadas e zero diferenças não explicadas no teste de paridade — e
com sete funções prometidas no plano que não existiam, uma decisão de desenho
que não tinha sido aplicada, e 120 variáveis esperando revisão humana.

---

## O estado final

| | antes | depois |
|---|---|---|
| Tabelas publicadas | 19 | **26** (16 dimensão, 10 fonte) |
| Funções do plano implementadas | 45 de 52 | **52 de 52** |
| Variáveis pendentes de revisão | 120 de 434 | **0 de 431** |
| Erros de qualidade | 2 | 2 (os mesmos, herdados) |
| Avisos de qualidade | 20 | 23, todos justificados |
| Diferenças não explicadas na paridade | 0 | **0** |
| Testes | 82 | **154** |

---

## A decisão 3.3, finalmente aplicada

O plano determina que as tabelas canônicas guardem **o que foi observado**, e
não o painel expandido. A migração não aplicou isso, porque ela precisava
publicar o mesmo objeto que o legado produzia para que a paridade fosse
comparável. O resultado é que sete blocos de coluna cuja granularidade nativa
não é município-ano ficaram dentro de dimensões, replicados.

Agora eles são tabelas de fonte próprias:

| fonte | linhas antes | depois | redução | por quê |
|---|---:|---:|---:|---|
| `03_meio_ambiente/adaptabrasil` | 183.810 | 5.570 | 97,0% | retrato único de 2015 |
| `05_sociedade/atlas_ivs` | 111.300 | 11.130 | 90,0% | censos de 2000 e 2010 |
| `09_educacao/ideb` | 111.388 | 55.694 | 50,0% | divulgação bienal |
| `09_educacao/censup` | 111.388 | 10.642 | 90,4% | zero-fill fora de 2009-2023 |
| `11_transportes/tarifa_zero` | 183.814 | 578 | 99,7% | zero-fill do painel inteiro |
| `11_transportes/tarifas` | 183.814 | 351 | 99,8% | levantamento de 27 municípios |
| `12_habitacao/mcmv_fgts` | 94.832 | 11.153 | 88,2% | município-ano com contrato |

**980.346 linhas viram 95.118.** Noventa por cento do que estava guardado era a
mesma medição repetida para preencher o painel.

As dimensões continuam sendo o painel e continuam idênticas ao que passou na
paridade. A fonte é o dado; a dimensão é a apresentação dele no painel. Quem
quiser saber quantos municípios foram medidos lê a fonte; quem quiser a série lê
a dimensão. O pipeline antigo só oferecia a segunda, e por isso a resposta à
primeira pergunta era sempre "5.570, todos os anos".

### A trava que impede a compactação de destruir dado

`mape_compactar_painel()` tem três métodos, e o do meio é o perigoso. O método
`constante` colapsa um retrato replicado numa linha só — e se o valor **não** for
constante, colapsar apagaria medição de verdade.

Por isso ele confere antes, e falha:

```
Error: O método 'constante' assume que o valor não muda ao longo dos anos,
e ele muda em: risco_idx.
Isso não é replicação de um retrato único — use outro método.
```

O teste que garante isso é o mais importante do arquivo, porque é o único que
protege contra perda silenciosa.

---

## A harmonização de nomes

Duzentas e trinta e nove colunas mudaram de nome. Setenta e nove tinham prefixo
genérico (`total_`, `quantidade_`) e cento e sessenta estavam fora do vocabulário
de sufixos ou usavam abreviação inventada.

O prefixo genérico não é problema estético. A base tinha `total_receitas` e
`siconfi_receitas_brutas_brl2023` lado a lado, medindo coisas parecidas, com
nomes que não permitiam saber qual era qual. Agora a primeira é
`siconfi_receitas_totais_brl2023`, e a comparação fica possível.

As abreviações eram piores. `cob_vac_bcg`, `tx_mort_aj_oms`,
`desp_tot_saude_pc_mun`, `n_leitouti_nsus` — nomes que exigem consultar o
dicionário para cada leitura. Viraram `ieps_cobertura_vacinal_bcg_pct`,
`ieps_taxa_mortalidade_padronizada_oms_p100k`,
`ieps_despesa_saude_total_per_capita_brl_nominal` e `ieps_leitos_uti_nao_sus_i`.

### Quatro erros que apareceram no caminho

Conferir cada faixa de valores contra o nome que a coluna carrega encontrou
coisas que ninguém tinha visto.

**`proporcao_votos_brancos_camara_vereadores` vai de 0 a 19,45**, e a irmã de
votos nulos vai a 55,41. São percentuais com nome de proporção. É o mesmo erro
do `margem_pct` já corrigido na migração, na direção oposta.

**As seis colunas `ln_*_1920_z` dos dados históricos vão de 0 a 1 exatos.** Isso
exclui z-score, que é centrado em zero e não tem limite superior: é normalização
min-max. O nome mentia duas vezes, no `ln_` e no `_z`. Viraram `*_norm_idx`.

**`tx_med` e `tx_enf` são por mil habitantes**, como a descrição do IEPS sempre
disse e como o máximo observado (27,7 médicos) confirma. A unidade declarada
dizia "por 100 mil".

**`turno` é constante igual a 1** em todas as 133.496 linhas. A base só traz
primeiro turno. Ficou registrada como coluna sem variação, em vez de sugerir que
existe segundo turno.

Nenhum desses quatro seria encontrado por inspeção visual. Os quatro apareceram
porque a checagem de coerência entre sufixo e escala é executável.

---

## As sete funções que faltavam

| função | o que faz |
|---|---|
| `mape_ler()` | aceita `"saúde"`, `"meio ambiente"`, `"educacao/ideb"`; filtra por ano, UF, município |
| `mape_juntar()` | confere a cardinalidade antes e recusa junções enganosas |
| `mape_cobertura()` | substitui as flags `dimensao_*`, medindo presença de valor |
| `mape_derivadas()` | oito indicadores, cada um declarando de que colunas depende |
| `mape_gerar_documentacao()` | README por tabela, com os números medidos |
| `mape_baixar()` | download com `sha256` registrado no manifesto |
| `mape_nova_fonte()` | esqueleto completo de uma fonte nova |

Mais três que não estavam no plano e se mostraram necessárias:
`mape_compactar_painel()`, `mape_recalcular_campos()` e
`mape_tabelas_publicadas()`.

### O que `mape_juntar()` recusa

Ela para em três situações, e cada uma corresponde a um defeito real do pipeline
antigo:

```
Não dá para juntar assim:
  - 06_financas: 222 chave(s) duplicada(s) em id_municipio+ano, 235 linha(s) excedente(s)

Juntar mesmo assim multiplicaria linhas ou replicaria valores sem registro,
que é o defeito estrutural do pipeline antigo.
```

O legado juntava, a chave duplicada multiplicava as linhas, e um `distinct()`
cego no fim apagava a evidência.

### O que `mape_derivadas()` recusa

Ela nomeia a coluna ausente em vez de devolver `NA`:

```
Faltam colunas para calcular taxa_homicidios_p100k:
  sim_obitos_homicidio_i
  populacao_residente_i

Uma coluna que sumiu do dado é um indicador que mudou de definição, não um NA.
Confira dicionario/deprecacao.csv: ela pode ter sido renomeada.
```

O caso que justifica o catálogo é o PIB per capita. O denominador veio de uma
segunda extração da população, feita junto com o PIB e descartada logo depois de
dividir; agora ele é explícito, e `insumos = TRUE` devolve as duas colunas junto.

> **Errata de 26/07/2026 (auditoria, achado 62).** Este parágrafo afirmava que a
> coluna **não é reproduzível a partir da base publicada** e que "quem quisesse
> conferir não conseguiria". As duas frases são **falsas**, e foram medidas:
> `pib_brl2023 / populacao_residente_i` (de `02_populacao`) reproduz
> `pib_per_capita_brl2023` em **127.786 de 127.786 linhas**, com desvio absoluto
> máximo de 7,28e-12 e relativo de 2,17e-16 — a precisão da máquina. O
> denominador não estar *dentro* de `04_economia` é decisão de dono único
> (população pertence a `02_populacao`), e isso é coisa diferente de não ser
> reproduzível.


---

## A documentação que não desatualiza

Vinte e seis arquivos gerados, mais o índice em `dicionario/README.md`. Nenhum é
escrito à mão.

A garantia é mecânica, e a razão para ela é empírica: é exatamente nos campos
que deveriam ser calculados que os números da documentação antiga não fechavam.
A soma de `Total Variáveis` dava 533 contra 451 reais. O artigo declarava 182.407
observações contra 180.285 — e esse número não é aleatório: é a contagem **antes**
da deduplicação, o que mostra que alguém contou na etapa errada do pipeline e
nunca mais reconferiu.

Nenhum dos dois é descuido. São o resultado inevitável de um número que precisa
ser reescrito à mão toda vez que o dado muda. `mape_recalcular_campos()` elimina
a classe inteira: os campos que ela preenche não são editáveis, porque são
medidos a cada execução.

A documentação de cada tabela separa **cobertura declarada pela fonte** de
**cobertura observada na tabela**. Só essa separação já resolve dois casos reais:
o Censo da Educação Superior, declarado como 1995-2023 e entregando 2009-2023, e
o Anuário do FBSP, declarado sem ressalva e cobrindo 27 municípios.

---

## O dicionário, fechado

De 120 variáveis pendentes de revisão para **zero**, em 431.

- **24 tinham `tipo_real = character`** porque a medição foi feita antes da
  recuperação de tipo da migração. O campo estava certo quando foi escrito e
  ficou errado depois — que é precisamente o motivo de campo calculado não poder
  ser digitado.
- **38 tinham escala marcada como incerta.** Todas foram conferidas contra a
  faixa observada durante a harmonização de sufixos; o que faltava era registrar
  que a conferência aconteceu.
- **34 estavam sem descrição.** Foram escritas.
- **Três eram resíduo do bloco territorial** (`nm_uf`, `id_municipio_nome`,
  `municipio_tarifa_zero`) dentro de dimensões que não são donas dele. Saíram.

As dezesseis coberturas vacinais do SI-PNI ganharam domínio `[0,100]` declarado
com a ressalva por escrito. Elas passam de 100% — uma chega a 51.175% — porque a
fonte calcula sobre uma população-alvo estimada e não trunca. Os valores foram
mantidos como a fonte publica; corrigi-los exigiria decidir o denominador certo,
o que é pesquisa e não limpeza de dado.

---

## A janela do painel

Ampliada de 1991-2023 para **1989-2024**, depois que a validação apontou dado
real fora dela em cinco tabelas. As Finanças trazem 8.583 linhas de 1989 e 1990;
Energia e Internet, Educação, Transportes e Habitação chegam a 2024.

Manter a janela antiga obrigaria a descartar dado medido ou a conviver com um
aviso permanente. Aviso permanente vira paisagem.

Isso quebrou um teste que fixava `c(1991, 2023)` em vez de ler do arquivo de
configuração. O teste foi corrigido para ler, com o motivo registrado no
comentário — um teste que duplica uma constante é um teste que falha quando a
constante muda de propósito.

---

## O release

`tools/publicar_release.R` monta a pasta que vira um release do GitHub. É o
único ponto de contato entre este repositório e o pacote R.

Ele leva três coisas, e a terceira faz diferença: uma tabela por arquivo (Parquet
e csv.gz), **o dicionário inteiro**, e um `SHA256SUMS.txt` com um `manifesto.json`.

O dicionário vai junto de propósito. Sem ele, uma variável nova só apareceria
para quem usa o pacote depois de uma nova versão do pacote. Com ele, aparece no
dia seguinte à publicação do release.

O release `v1.0.0` está montado em `dist/` — 26 tabelas, 61 arquivos, 137,6 MB —
e **não foi publicado**. Publicar é uma ação externa e irreversível num
repositório da organização; o comando está impresso ao fim do script.

---

## O que continua aberto

**A primeira reextração nunca aconteceu.** Os `extrair_*.R` estão escritos e
nunca rodaram. A primeira execução de cada um é o primeiro teste real do
procedimento de atualização, e é onde vão aparecer as diferenças entre o que a
fonte publicava em 2024 e o que ela publica agora.

Vale ligar um alerta de orçamento no projeto do Google Cloud antes disso. Durante
toda a reestruturação o custo foi zero, porque nada foi reextraído.

**Duas chaves duplicadas persistem**, e as duas exigem reprocessar a fonte —
trabalho de extração, não de reestruturação. São o único bloqueio real que
sobrou.

**Três licenças precisam de verificação**: IEPS Data, Anuário do FBSP e o pacote
de replicação de Kustov & Pardelli, que não tem sequer DOI registrado.

**Seis fontes não migraram**, cada uma com diagnóstico em `pendencias/`. Nenhuma
contribui com coluna alguma para a base publicada.
