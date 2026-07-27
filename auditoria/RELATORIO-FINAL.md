# Relatório final da rodada de correção da auditoria

26/07/2026. Os **105 grupos** de `CONSOLIDADO.md` foram trabalhados. Nenhum ficou pendente.

Este é o documento para ler primeiro. O ledger linha a linha está em `CORRECOES.csv`, a análise
de causas em `FECHAMENTO.md`, o estado de partida em `BASELINE.md`, e a verificação mecânica em
`tools/verificar_fechamento.R` — cuja saída está na § 9.

---

## 1. O quadro

| severidade | corrigido | mitigado | não confirmado | total |
|---|---:|---:|---:|---:|
| **CRÍTICO** | 2 | 5 | 0 | **7** |
| **ALTO** | 16 | 9 | 0 | **25** |
| **MÉDIO** | 27 | 5 | 0 | **32** |
| **BAIXO** | 34 | 0 | 6 | **40** |
| **SUSPEITA** | 1 | 0 | 0 | **1** |
| **total** | **80** | **19** | **6** | **105** |

Contado do ledger, não digitado:

```bash
python3 -c "import csv, collections; \
rows = list(csv.DictReader(open('auditoria/CORRECOES.csv', encoding='utf-8'))); \
print(collections.Counter((r['severidade'], r['status']) for r in rows))"
```

**`corrigido`** quer dizer que o defeito não existe mais e a reprodução da auditoria não reproduz
mais. **`mitigado`** quer dizer que o defeito continua no dado, mas agora está declarado no
dicionário, é detectado por uma checagem automática, e chega a quem consome — a correção de fundo
depende de decisão sua ou de insumo que não está neste repositório. **`não confirmado`** são os 6
que a própria verificação adversarial derrubou; conferi a conclusão de cada um e não corrigi
defeito que não existe.

**Errata de 26/07/2026 — este placar já foi 78/19/8, e mudou duas vezes depois.** As três
reverificações adversariais da § 10 devolveram dois grupos da coluna "não confirmado" para a de
corrigido, e nos dois casos porque o argumento que os derrubara respondia à pergunta errada:

- **Grupo 91** (BAIXO), na primeira reverificação. O ledger justificava o "não confirmado" dizendo
  que `dicionario/proveniencia.csv` não existia — e ele passou a existir **por obra desta própria
  rodada de correção**, versionado, empurrado para `origin/main` num repositório público e montado
  em `dist/`, com o identificador do projeto GCP dentro. É a coluna BAIXO que vai de 33 para 34.
- **Grupo 65** (SUSPEITA), depois da terceira. O ledger respondia que a `NOTA-DO-RELEASE.md` vai
  como `--notes-file` e portanto não precisaria de soma. Defensável, mas a observação factual do
  auditor era verdadeira: ela **não estava** coberta pelo `SHA256SUMS.txt`, e não por decisão e sim
  por ordem de execução — o bloco que calcula as somas rodava antes de a nota ser escrita. Um
  defeito de ordem que só não aparecia porque o arquivo afetado tinha uma defesa independente. É a
  única linha SUSPEITA, que vai de "não confirmado" para corrigido.

Nenhum grupo ficou `bloqueado`: onde faltou insumo, a marcação foi possível e é o que `mitigado`
registra.

### O número que resume a rodada

| | baseline | agora |
|---|---:|---:|
| erros de validação sobre as 26 tabelas | 2 | **0** |
| avisos | 25 | **132** |
| avisos **sem justificativa registrada** | 25 | **0** |
| expectativas na suíte | 154 | **564** |
| nomes de checagem em `mape_validar_tabela()` | 10 | **20** |
| caminhos de escrita que rodam as checagens de qualidade | 0 | **todos** |

```bash
Rscript tools/validar_tudo.R --seco                       # TOTAL: 0 erro(s) e 132 aviso(s)
Rscript -e 'testthat::test_dir("tests/testthat")'         # FAIL 0 | PASS 564, em 14 arquivos
grep -oE 'reg\("[a-z_]+"' R/validacao.R | sort -u | wc -l # 20; em 0526316 eram 10
```

Os avisos subiram de 25 para 132 porque **dez checagens novas** olham coisas que ninguém olhava —
os dez nomes saem da diferença entre `R/validacao.R` hoje e em `0526316`: `zero_inflacao`,
`quebra_de_nivel`, `invariancia_temporal`, `continuidade_painel`, `cobertura_temporal`,
`descricao_repetida` (a "checagem 12", anunciada desde o plano e nunca escrita), `licenca`,
`proveniencia`, `exclusividade_territorial` e `faixa_declarada`. Cada um dos 132 tem justificativa
registrada em `qa/justificativas.csv` ou no campo `problema` da variável — e um aviso sem
justificativa agora **vira erro e bloqueia a publicação**, que era a regra declarada em cinco
arquivos e que não existia em código nenhum.

Onde os 132 caem, medido: `zero_inflacao` 46, `schema` 25, `invariancia_temporal` 19,
`faixa_declarada` 11, `quebra_de_nivel` 11, `licenca` 6, `continuidade_painel` 5,
`cobertura_municipios` 4, `chave_unica` 2, `dominio_chave` 2, `exclusividade_territorial` 1.

*Errata de 26/07/2026: este quadro dizia 120 avisos e 413 expectativas, e a § 10 dizia 121 avisos
na mesma página — três números para duas medidas. Os corretos, medidos, são 132 e 564.*

---

## 2. Qual dado publicado mudou

**Nenhuma tabela perdeu linha, coluna, chave ou município.** Verificado tabela a tabela contra
`BASELINE.md` pelo critério 7. Quatro tabelas tiveram colunas **renomeadas** e uma ganhou uma
coluna nova; nenhum valor foi alterado em lugar nenhum.

| tabela | antes | depois | o que mudou |
|---|---|---|---|
| `03_meio_ambiente` | 183.810 × 77 | 183.810 × 77 | 1 renomeação (achado 7) |
| `04_economia` | 127.786 × 19 | 127.786 × 19 | 4 renomeações (48, 102) |
| `10_saude` | 149.144 × 65 | 149.144 × 65 | 3 renomeações (8) |
| `16_eleicoes` | 133.496 × 36 | 133.496 × 36 | 7 renomeações (102) |
| `13_seguranca` | 132.907 × 65 | 132.907 × **66** | coluna nova `flag_codigo_nao_municipal` (12, 13) |

As 15 renomeações estão em `dicionario/deprecacao.csv`, cada uma com o motivo e o número do
achado. As faixas de valor provam que nada foi tocado: `variacao_area_desmatada_pct` continua 0 a
678.600, `log10_pib_idx` 6,72 a 11,95, `tse_votos_nulos_prefeito_pct` 0,37 a 98,09.

A mais consequente é a do achado 7, que era crítico: `variacao_absoluta_area_desmatada_km2`
declarava área em km² sobre uma taxa percentual. O valor máximo publicado, 678.600, afirmava que
um município desmatara quatro vezes a área do maior município do país num ano. Em 99,97% das
linhas o erro era indetectável a olho.

---

## 3. Quais números da documentação mudaram

Todos remedidos, nenhum copiado da auditoria — os dela foram medidos antes das correções.

| onde | dizia | é |
|---|---|---|
| `README.md`, `CLAUDE.md` | base larga com 440 colunas, 16 dimensões | **424** colunas (439 com `flags`), 200.520 linhas, **15** dimensões |
| `README.md` | 2 erros e 23 avisos | **0 erros e 132 avisos**, todos justificados |
| `CLAUDE.md` | 128 pacotes no lockfile | **147** |
| `docs/encerramento-migracao.md`, `docs/decisao-dois-repositorios.md` | 137 pacotes | **147** |
| `CLAUDE.md` | 154 expectativas | **564** |
| `README.md`, `CLAUDE.md` | 431 variáveis | **432** |
| `docs/encerramento-migracao.md` | 183.810 × 440 | **200.520 × 424** |
| `dist/.../NOTA-DO-RELEASE.md` | `NA-NA` nos anos de `15_dados_historicos` | `—` |
| `README.md` | `id_municipio` é texto por causa do zero à esquerda | **falso**: nenhum código de município brasileiro tem zero à esquerda (AC começa em 12, AL em 27, AM em 13). O motivo é que **código não é quantidade** |
| `README.md` | dado bruto **nunca** é versionado | há uma exceção conhecida e decidida: o CadÚnico, no commit `20a3b11` |

`docs/encerramento-migracao.md` ganhou um cabeçalho de datação em vez de ter os números
reescritos um a um: é um registro histórico, e datá-lo é mais honesto que atualizá-lo.

A tabela de errata do `CLAUDE.md` **encolheu de dez linhas para três**, que é o que ela deveria
fazer.

---

## 4. O que ficou aberto, e o comando para retomar

Nada está `bloqueado` no ledger, mas **19 grupos estão `mitigado`** — marcados e detectáveis, com
o defeito ainda no dado. **Sete deles dependem de insumo que não está neste repositório** — 3, 5,
16, 27, 28, 29 e 47 —, e são seis insumos distintos, um por item abaixo. Os outros doze dependem
de decisão sua, e estão na § 5.

*Errata de 26/07/2026: esta seção dizia "três", e listava três itens que cobriam cinco grupos.
Contado no campo `observacao` do ledger e cruzado com o bloco 2 da § 5 do `FECHAMENTO.md`, são
sete os grupos cuja correção de fundo o texto declara impossível aqui. O achado 4 saiu da lista —
a parte estrutural dele foi feita inteira (os campos `pct_zero` e `janela_efetiva`, mais a
checagem de zero-inflação) e o que resta é decisão de valor, não falta de insumo — e entraram os
achados 27, 28 e 47, que estavam sem registro nenhum.*

**(a) A escala de `12_habitacao` (achado 16).** `mcmv_valor_contratado_brl2023` atribui R$ 205,8
bilhões a um município-ano. A assinatura é de um `gsub` de separador decimal aplicado na ordem
errada. Corrigir exige a planilha original, e `fontes/12_habitacao/mcmv_fgts/` não tem `raw/`.

```bash
# quando a planilha existir:
#   1. ponha-a em fontes/12_habitacao/mcmv_fgts/raw/ e registre o sha256 no MANIFESTO.yml
#   2. reescreva a conversão de texto para numérico com parser explícito de locale
#   3. Rscript tools/validar_tudo.R     # o dominio_valido [0,5000000000] já dispara
```

**(b) Os zeros anteriores à instalação do município (achado 29).** A guarda existe em
`R/painel.R` (`incluir_flag_instalado`) e é **código morto por falta de dado**: o diretório não
publica `ano_instalacao`.

```bash
# acrescente ano_instalacao a 00_diretorios/municipios (a informação é do IBGE) e a guarda liga
```

**(c) O SICONFI bruto (achados 3 e 5).** Duas das três classes de defeito de `06_financas` —
receita inflada em uma ordem de grandeza e vazio publicado como zero em 2018-2021 — exigem
reescrever a agregação sobre o dado de origem, que é `download_manual` e não está no repositório.
(A terceira, o achado 4, ficou em decisão sua: ver § 5, item 8.)

**(d) O calendário de vigência das vacinas (achado 27).** `10_saude` publica cobertura vacinal de
0% em município-ano em que a vacina ainda não existia. A correção de fundo pede um
`dicionario/vigencia_vacinas.csv` lido pelo `tratar_*.R` da fonte — e nem o CSV nem o `tratar_*.R`
existem.

**(e) O SIM/DATASUS bruto (achado 47).** `sim_obitos_homicidio_i` de São Paulo descola do FBSP a
partir de 2018 (o escopo é só São Paulo: segui a correção do verificador e retirei o Rio). Decidir
entre defeito de classificação de causa e queda genuína exige o SIM bruto.

**(f) As estimativas do IBGE, e uma checagem que a arquitetura não comporta (achado 28).** Nove
municípios de `02_populacao` têm a série de população **fabricada por extrapolação linear** entre
2013 e 2021 — rampa perfeita, sem ruído —, e o defeito se propaga para `pib_per_capita_brl2023`.
A testemunha independente é o próprio painel: em 2020 os eleitores aptos excedem a população
publicada nesses municípios. O defeito está declarado na `observacoes` de `02_populacao`, mas não
está detectado: a correção sugerida pede uma checagem de coerência **entre dimensões**
(`eleitores <= população`), e `mape_validar_tabela()` valida uma tabela por vez. É a recomendação
que o ledger promete registrar aqui, e que faltava:

```bash
# a checagem entre dimensões não cabe em mape_validar_tabela(); o lugar dela é uma função
# nova, do tipo mape_validar_coerencia_entre_dimensoes(), chamada por tools/validar_tudo.R
# depois do laço. O primeiro caso a codificar, com os nomes que o dicionário publica:
#   16_eleicoes$tse_eleitores_aptos_prefeitura_i <= 02_populacao$populacao_residente_i
# A correção do dado em si depende das estimativas do IBGE, que não estão nesta árvore.
```

E **15 tabelas continuam sem caminho de reconstrução** nesta árvore. `00_diretorios/municipios`
saiu dessa lista nesta rodada (achado 9): o bruto voltou do histórico do git e `tratar_municipios()`
reproduz o Parquet publicado com `all.equal == TRUE`. As outras 15 dependem de reescrever os
produtores, que é trabalho de outra ordem.

---

## 5. O que depende de decisão sua

Onde duas leituras eram defensáveis escolhi a mais conservadora — a que não muda valor publicado,
não remove nada e não amplia escopo, como a § 11 do prompt manda. São estas as decisões que
sobraram, com a minha recomendação:

**1. A série de PIB de `04_economia` (achado 1, crítico).** *Recomendo corrigir, e a evidência
agora é externa.* Consultei a origem: a razão publicado/`br_ibge_pib` é exatamente **3,0000** em
2002-2003, **2,0000** em 2004-2010 e **1,0000** de 2011 em diante, e a origem tem uma linha por
município-ano. Não deixei os valores porque a correção sugerida diz explicitamente "nada disso
deve ser aplicado sem decisão do responsável pela dimensão", e porque ela muda onze colunas.
Duas ressalvas para a decisão: dividir pelo fator restaura a série **nominal**, não `_brl2023` —
ou deflaciona de fato, ou renomeia para `_brl_nominal`; e a origem cobre 2002-2023 enquanto o
publicado cobre 1999-2021, então reextrair também muda a janela. O cache está em
`fontes/04_economia/ibge_pib/raw/`, com sha256 no manifesto.

**2. A licença de `13_seguranca` (achado 45).** *Recomendo resolver antes de publicar o release, e
é a pendência mais séria das três.* O Anuário do FBSP sai, em algumas edições, sob **CC BY-NC-ND**.
O `NC` proíbe uso comercial e o `ND` proíbe obra derivada — e uma tabela derivada é exatamente uma
obra derivada. Redistribuir sob CC BY 4.0, como o release faz, não é uma formalidade pendente: é
uma incompatibilidade. As outras duas (IEPS Data e Kustov & Pardelli) exigem verificação, não
necessariamente mudança.

**3. Reagregar os pseudo-códigos de `13_seguranca` (achados 12, 13).** *Recomendo fazer.* Os 30
códigos `3345xxx` concentram 6.639 homicídios em 1996-1998, contra 269 publicados no próprio
município do Rio — a série carioca está **96,1% subestimada** naqueles anos. Não fiz porque
reagregar reduz linhas e muda valores publicados, e a § 8 proíbe as duas coisas. Marquei com
`flag_codigo_nao_municipal`, e o dado é recuperável por filtro. Depois de reagregar, a soma
nacional por ano tem de permanecer **inalterada** — é redistribuição, não criação.

**4. `sigla_uf_nome` em `04_economia` (achado 51).** *Recomendo remover.* A coluna tem
`acao = "remover"` declarada e não executada, o nome mente (prefixo `sigla_`, conteúdo com o nome
por extenso) e ela duplica o bloco territorial cujo dono é `00_diretorios/municipios`. Não removi
porque a § 8 proíbe remover coluna.

**5. O comentário de `_targets.R:29` (achado 41).** ~~*Recomendo trocar `error = "abridge"` por
`"trim"`.*~~ **RESOLVIDO na reverificação de 26/07/2026**, e por isso deixou de ser decisão sua: o
`error =` passou a ser `"trim"`, que é a semântica que o comentário sempre descreveu. A proibição
de editar `_targets.R` era da § 3 daquele prompt e não do projeto — e trocar uma constante de
`tar_option_set()` não é editar os alvos, que continuam sendo gerados de `dicionario/tabelas.csv`.
`tar_manifest()` segue devolvendo 14 alvos. A parte substantiva — código de saída — está em
`tools/rodar_grafo.R`.


**6. A camada de fonte de `11_transportes/tarifa_zero` (achado 33).** Decisão de desenho que
precede o patch: ou a fonte guarda 106 linhas (uma por evento) e a expansão passa para a dimensão,
ou ela é assumidamente de duração de evento — e nesse caso o README e o `CLAUDE.md` precisam
parar de usá-la como exemplo de "o observado".

**7. Converter para `NA` os zeros fabricados** em `03_meio_ambiente` (~97.000 células),
`12_habitacao` (133.680) e `10_saude`. *Recomendo fazer, um caso por vez, reivindicando as
diferenças em `qa/paridade_esperada.csv` antes de rodar.* São mudanças de valor publicado.

**8. Os zeros de `06_financas` (achado 4).** *Recomendo fazer depois de resolver o achado 3, e não
antes.* `siconfi_receitas_realizadas_brl2023` é zero em **96,9469%** das linhas, com `pct_na` de
0,26% — a assinatura de vazio publicado como zero, e a janela efetiva é de um ano só, 2013-2013.
A parte estrutural foi feita inteira: os campos calculados `pct_zero` e `janela_efetiva` agora
dizem isso, e a checagem `zero_inflacao` acusa sozinha. Converter as células em `NA` muda cerca de
**792.000 células publicadas** e por isso ficou com você. Este item estava listado como "falta de
insumo" na § 4 e não é: o insumo faltante é do achado 3, o daqui é decisão.

**9. Os dois itens do achado 32 que não foram feitos.** O ledger promete registrá-los aqui, e
faltava. A correção sugerida do grupo 32 tinha três frentes; a do meio — `mape_ler()` avisar
quando a tabela pedida tem defeito declarado — está feita. As outras duas não:

- *(a) A seção de defeitos declarados no `README.md`, **gerada dos marcadores** do dicionário.* A
  seção existe (`README.md`, "As tabelas com defeito declarado"), mas é **escrita à mão**: o
  `README.md` não tem produtor, e dar um a ele é decisão de desenho, não patch. Enquanto não
  tiver, essa seção é mais um número em prosa — exatamente a cadeia F do `FECHAMENTO.md` —, e vai
  apodrecer como apodreceram os outros.
- *(c) Embarcar os `qa/*.md` e a lista de defeitos no release.* Feita pela metade, e o que falta é
  decisão sua. `dist/v1.0.0/qa/` já carrega os **26** relatórios regerados (achado 32, segunda
  reverificação) e o `SHA256SUMS.txt` fecha em 115 de 115. O que não existe é um índice de defeitos
  no bundle: quem baixa o release tem de abrir os 26 para saber quais tabelas têm defeito aberto.

---

## 6. A reextração do BigQuery

Rodou, dentro do freio da § 6, e serviu para **confirmar** o achado 1 contra uma fonte
independente — não para reescrever dado.

| | |
|---|---|
| consultas executadas | 2 (a mesma, repetida por um erro meu, ver abaixo) |
| bytes cobrados | **7,54 MiB** |
| teto por consulta | 64 GiB — usei 0,006% dele |
| teto de sessão | 512 GiB |
| custo | **US$ 0,00** (muito abaixo da cota grátis de 1 TiB/mês) |

O livro-caixa está em `qa/custo_bigquery.csv`. O resultado está cacheado em
`fontes/04_economia/ibge_pib/raw/pib_municipio.parquet`, com sha256 no `MANIFESTO.yml`, e
`mape_baixar_cache()` não reconsulta quando o arquivo existe.

**Registro o erro que me custou a segunda consulta**, porque ele é a própria patologia do
repositório: a primeira análise deu resultado sem sentido porque usei `as.numeric()` sobre uma
coluna `integer64` — exatamente a armadilha do achado 35, que eu tinha acabado de corrigir noutro
arquivo. O `CAST(... AS FLOAT64)` no servidor resolveu.

O freio também encontrou um defeito **em si mesmo** antes de qualquer consulta: declarados em
bytes, os tetos (`68719476736`) voltavam do YAML como `NA`, porque o leitor de YAML do R estoura
o int32 em silêncio. Um teto `NA` teria desligado o freio inteiro sem emitir nada. Ficaram em
GiB, com `stopifnot` que recusa `NA` e um teste que trava a decisão.

---

## 7. A reescrita do histórico do git

**Não foi executada, e recomendo não executar.** Registro a divergência porque a § 10 do prompt a
autoriza e instrui.

O que decidiu: a verificação adversarial da própria auditoria mediu que o número de commits
afetados é **3, e não 6** — os outros três eram alcançáveis apenas por
`refs/remotes/origin/plano-reestruturacao-etl`, um ref de rastreamento obsoleto de uma branch que
já não existe no remoto. E o grupo 88 conclui, textualmente, *"nenhuma correção de histórico é
devida; em particular, **não** reescrever o histórico com `git filter-repo`, que quebraria todos
os hashes por um ganho nulo"*. O grupo 72 chega à mesma conclusão para os blobs do CadÚnico, com
análise de custo-benefício própria.

Um identificador de projeto GCP não é credencial: saber o nome de um projeto não dá permissão de
gastar nele, isso depende de IAM. E o CadÚnico versionado são 10,6 MiB de agregado municipal
público, sem dado pessoal.

**O que fiz em vez disso — a árvore, que é o que importa para quem clona hoje:**

- `R/bigquery.R` — os quatro identificadores saíram do comentário de cabeçalho. O diagnóstico que
  justifica `mape_billing_id()` (quatro contas de faturamento, três aparentemente pessoais) está
  lá inteiro, sem os nomes.
- `plano/00-diagnostico-inventario.md`, `plano/02-documentacao-e-atualizacao.md`,
  `plano/prompt-original.md` — 12 ocorrências substituídas por `<projeto-gcp-legado-N>`, com nota
  explicando a redação. O diagnóstico foi preservado.
- O critério 9 de `tools/verificar_fechamento.R` **confere isso a cada execução**, lendo os
  identificadores de `auditoria/VAZAMENTO-GCP.local.md`, que não é versionado — de modo que o
  próprio verificador nunca contém nenhum deles.

**Se você decidir reescrever assim mesmo**, a § 10 do prompt tem o roteiro. O `HEAD` no início
desta rodada era `0526316`; faça o backup espelho antes (`git clone --mirror`), instale
`git-filter-repo` (`brew install git-filter-repo`), e lembre que a reescrita **não resolve
sozinha**: quem já tem clone continua com os objetos, e é preciso pedir ao GitHub a expiração dos
objetos órfãos. Nenhum backup espelho foi criado nesta rodada, porque a fase não foi executada.

---

## 8. Os próximos passos, com os comandos

```bash
# 1. Conferir que a rodada continua fechada (sai com código 1 se não estiver)
Rscript tools/verificar_fechamento.R

# 2. A suíte e a validação, separadamente
Rscript -e 'testthat::test_dir("tests/testthat")'
Rscript tools/validar_tudo.R

# 3. Meta-cobertura: quais funções sobrevivem a virar function(...) NULL
Rscript tools/sweep_mutacao.R                    # todas (lento)
Rscript tools/sweep_mutacao.R mape_deflacionar   # uma só

# 4. O grafo, com código de saída de verdade
Rscript tools/rodar_grafo.R
Rscript tools/recalcular_dicionario.R            # a montante, quando o dado mudar

# 5. Remontar dist/ depois de qualquer mudança de dado ou dicionário
Rscript tools/publicar_release.R v1.0.0
```

**Sobre publicar o release v1.0.0:** ele está montado em `dist/v1.0.0/` e continua **não
publicado**. Não o publique antes de resolver o item 2 da § 5 — a incompatibilidade de licença de
`13_seguranca` —, e considere resolver o item 1 (a série de PIB) antes também: publicar agora
distribui um defeito crítico confirmado contra a origem. O comando está no fim de
`tools/publicar_release.R` e **não** foi executado.

---

## 8-bis. Revisão de completude, e o que ela achou

Depois de os treze critérios passarem, revisei as `Correção sugerida` do
consolidado item a item — porque passar nos critérios e ter feito o que a
auditoria planejou são coisas diferentes. Seis lacunas apareceram, todas
fechadas, e uma delas era séria:

1. **A documentação gerada nunca tinha sido regerada.** Dez grupos (18, 30, 43,
   50, 55, 56, 63, 64, 71, 92) dizem "regerar a documentação depois". Eu havia
   corrigido o dicionário e parado aí — de modo que `06_financas.md` continuava
   mostrando "Produto Interno Bruto" como descrição de uma dedução do FUNDEB, e
   `16_eleicoes.md` continuava com brancos e nulos invertidos. **O `.md` gerado
   é o que o consumidor lê;** corrigir só o dicionário deixava a correção no
   lugar errado. Regerados os 26.
2. **O portão no release** (achado 22, item 5) não existia: `publicar_release.R`
   empacotava sem olhar a validação. Agora recusa erro não reivindicado, e
   testei dos dois lados.
3. **`LICENSE-DADOS`** (achado 45) não existia. Criado e embarcado em `dist/`.
4. **`dominio_valido`** das 45 colunas `_i` de contagem (achado 86), que eu
   havia deixado só com a linha informativa.
5. **`turno_i`** era `double` sob sufixo `_i` (achado 102) — resíduo que o
   verificador levantou e que eu registrei sem aplicar.
6. **"as doze checagens"** ainda no README e em dois documentos datados
   (achado 23, item 3).

Registro isto porque é a mesma patologia que a auditoria descreve: eu havia
declarado corrigidos dez grupos cuja correção estava pela metade, e os treze
critérios não pegaram — nenhum deles olhava o conteúdo dos `.md` gerados. Um
critério que não olha não prova.

---

## 9. A saída de `tools/verificar_fechamento.R`

Executada em **26/07/2026, 23:50**, depois das três reverificações da § 10. São **18 critérios** —
os doze da § 12 de `auditoria/prompt-correcao.md` mais os seis que as reverificações
acrescentaram. A saída abaixo é colada como saiu, sem as duas linhas de `out-of-sync`, que são
ruído esperado do `renv`:

```
==============================================================================
VERIFICACAO DE FECHAMENTO — auditoria/prompt-correcao.md, secao 12
==============================================================================

1.   OK     CORRECOES.csv tem 105 linhas, de 1 a 105, sem furo nem repeticao
          105 linha(s), 105 distinta(s)
2.   OK     nenhuma linha com status = pendente
          0 pendente(s); corrigido=80, mitigado=19, nao-confirmado-pela-auditoria=6
3.   OK     todo corrigido/mitigado tem reproducao antes, depois e commit existente
          99 grupo(s), 0 com campo vazio, 0 sha inexistente
4.   OK     todo bloqueado/nao-reproduz/nao-confirmado tem observacao
          6 grupo(s), 0 sem observacao
5.   OK     a suite passa e tem mais expectativas que o baseline (154)
          PASS 564 (baseline 154), FAIL 0
6.   OK     as 26 tabelas validam sem erro e todo aviso tem justificativa
          26 tabela(s): 0 erro(s), 132 aviso(s), 0 sem justificativa
7.   OK     nenhuma tabela perdeu linha, coluna, chave ou municipio vs BASELINE
          26 tabela(s) conferida(s), nenhuma perda
8.   OK     todo alvo tar_make(...) citado na documentacao EXISTE no grafo
          2 alvo(s) citado(s) na documentacao; todos existem no grafo
9.   OK     nenhum identificador GCP legado em arquivo versionado
          5 identificador(es) conferido(s); 0 com ocorrencia versionada
10.  FALHA  working tree limpo e ha commit citando cada grupo corrigido
          42 arquivo(s) sujo(s); 0 grupo(s) sem commit que os cite
11.  OK     FECHAMENTO.md, BASELINE.md e RELATORIO-FINAL.md existem e estao completos
          os tres, completos
12.  OK     CLAUDE.md descreve o estado atual: numeros conferidos por medicao
          147 pacotes, 432 variaveis, 26 tabelas, 564 expectativas
13.  OK     a documentacao gerada esta em dia com o dicionario e com o dado
          26 documento(s) gerado(s) comparados, todos em dia
14.  OK     a paridade nao tem diferenca nao explicada nem reivindicacao morta
          16 relatorio(s), 0 nao explicadas, todos com sha256 e mais novos que as reivindicacoes
15.  OK     todo renomeio de deprecacao.csv resolve numa coluna publicada
          203 renomeio(s), 203 destino(s) distinto(s), todos resolvem
16.  OK     nenhum documento gerado repete afirmacao que o dado desmente
          4 afirmacao(oes) falsificada(s) conferida(s); nenhuma sobreviveu
17.  OK     o release montado em dist/ nao esta atras da arvore
          91 artefato(s) embarcado(s) conferido(s), todos em dia
18.  OK     este script existe, cobre os dezessete acima e sai com codigo nao zero
          17 criterios verificados acima

------------------------------------------------------------------------------
1 de 18 criterios FALHARAM. A rodada nao esta pronta.
```

**Sobre o critério 10, que é o único a falhar.** Ele exige duas coisas, e só a primeira falha: a
árvore de trabalho tinha **42 arquivos não commitados** no instante da medição — este relatório
entre eles —, e **0 grupos corrigidos sem commit que os cite**. A parte substantiva passa; a que
falha é a higiene de `git status`, que se resolve commitando. Rode de novo depois do commit.

*Errata de 26/07/2026: esta seção colava uma saída de **13** critérios com o placar `78/19/8`,
`PASS 413` e `120 avisos`. Todos esses números estavam obsoletos — as três reverificações da § 10
acrescentaram cinco critérios e mudaram o placar. A saída acima é a corrente, medida.*

---

## 10. As três reverificações adversariais, e o que elas derrubaram

Foram **três**, todas em 26/07/2026, cada uma reexecutando o que a anterior tinha dado por
fechado. O placar de cada uma, com o commit que a fecha:

| rodada | commit | o que reexecutou | derrubou |
|---|---|---|---:|
| 1ª | `7c97b59` (registro em `e360012`) | os 105 grupos, 7 verificadores | **5** não se sustentavam, 23 parciais |
| 2ª | `f57ddb5` | os 28 grupos que a 1ª fechou, 2 verificadores | **6** parciais |
| 3ª | `59562e6` | o que a 2ª fechou | **2**, e os dois eram portões meus |
| — | `047b10a` | reclassificação do achado 65 | placar vai a **80/19/6** |

### A primeira: os 105 contra a árvore

Depois de os treze critérios passarem, os 105 grupos foram reverificados por **sete verificadores
independentes**, cada um com um intervalo exclusivo e instruído a *derrubar* as alegações, não a
confirmá-las. Cada um remediu contra a árvore em vez de acreditar no campo `reproduziu_depois`.

| veredito | grupos |
|---|---:|
| se sustentaram integralmente | **77** |
| parciais | **23** |
| **não se sustentavam** | **5** |

Os cinco: **26, 34, 55, 66 e 91** — todos marcados `corrigido` ou `não confirmado`, todos com
`reproduziu_depois` afirmando que o defeito sumira.

### Por que os treze critérios não pegaram

Nenhum deles olhava o artefato. O código era corrigido, o `.md` publicado continuava com o texto
velho, e o critério media o código. É a mesma frase da § 8-bis, agora aplicada ao próprio
verificador: **um critério que não olha não prova.**

O caso mais sério é o **grupo 91**. O ledger justificava o "não confirmado" dizendo que
`dicionario/proveniencia.csv` não existia — e ele passou a existir **por obra desta rodada de
correção**, versionado, empurrado para `origin/main` num repositório público e montado em `dist/`,
carregando o identificador do projeto GCP que `.Renviron` existe para manter fora da árvore. O
critério 9 passava porque extraía do dossiê apenas os quatro identificadores **legados**, listados
no formato `- \`id\``; o **oficial** aparece lá só em prosa, e nunca entrava na lista conferida.

### O que a primeira rodada consertou

Os 28 grupos foram fechados, e a paridade foi refeita inteira: os 16 relatórios têm sha256 da
referência (era 1), **zero diferenças não explicadas** com toda reivindicação medida, e as 9
reivindicações nominais são alcançáveis (eram 2). Quatro erratas que afirmavam o que o dado
desmente foram reescritas com o medido.

O critério 8 também foi renomeado: intitulava-se "todo comando `tar_make(...)` da documentação
**executa** sem erro" e nunca executou nada — confere pertinência ao grafo, e agora diz isso.

### A segunda: os 28 que a primeira fechou

Dois verificadores adversariais reexecutaram só os 28 grupos que a primeira rodada tinha fechado.
Vinte e dois se sustentaram; **seis estavam parciais — 32, 41, 45, 62, 71 e 96 —, e todos pelo
mesmo motivo de antes**: texto sobrevivente num artefato que ninguém regerou.

O caso que dá o tom é o **32**: os `dist/v1.0.0/qa/*.md` estavam uma geração atrás, diziam
"Checagens executadas: 18" contra 19 e não traziam a checagem de exclusividade territorial — de
modo que quem consumisse o release não veria o aviso. A correção do código estava certa; o
artefato distribuído é que estava velho. Também nesta rodada nasceu a checagem 20,
`faixa_declarada`, que confronta o publicado contra o `[minimo, maximo]` do dicionário.

### A terceira: os dois portões que nasceram quebrados

A terceira rodada derrubou **dois** itens, e **os dois eram meus** — não achados da auditoria, mas
os portões que eu tinha acabado de escrever para vigiá-la. É a rodada mais instrutiva das três,
porque o que ela mostra não é que o dado estava errado: é que **o verificador estava.**

- **Critério 17**, escrito na rodada anterior, tinha metade morta. O `system2("shasum", ...)`
  rodava no diretório do processo R e não em `dist/`, então devolvia "No such file or directory",
  zero linhas `FAILED` — e o critério **passava sempre**. Pior: os 52 arquivos de dado nunca eram
  comparados, porque o bundle achata `dados/dimensao/x.parquet` em `dados/x.parquet` e
  `file.exists()` dava `FALSE`. Hoje confere **91 artefatos**, compara binário por hash, e foi
  provado que morde — corrompendo de propósito um arquivo do bundle.
- **Critério 12** conferia **presença** e não **ausência de contradição**. Bastava o número certo
  aparecer em algum lugar do `CLAUDE.md` para o número errado ao lado ficar invisível. Foi assim
  que "413 expectativas" sobreviveu na linha 104 enquanto a linha 70 já dizia 564, com o portão
  verde. Hoje o padrão é ancorado no contexto e nenhum outro número pode aparecer no mesmo.

O achado substantivo que caiu junto foi o **71**, pela terceira vez no mesmo campo: eu tinha
corrigido a frase do meio e depois a do fim, e a de **abertura** continuava dizendo "oito
conceitos medidos duas vezes". São **cinco** — das oito colunas `ieps_cobertura_vacinal_*`, só
`bcg`, `poliomielite`, `triplice_viral_dose1`, `hepatite_a` e `pentavalente` têm par `pni_`. O
campo `licenca` da mesma tabela dizia "as três colunas do IEPS" e são **44**. Os dois números
foram medidos no Parquet.

**E é esta a lição mais transferível da rodada inteira:** um critério novo tem de ser testado
**com o defeito plantado**. Os dois portões acima passaram em todas as execuções desde que foram
escritos, e passavam porque não olhavam nada. Escrever a checagem e vê-la verde não prova que ela
funciona — prova que ela não falhou, que é outra coisa. A demonstração de que o critério 17 morde
foi feita corrompendo um arquivo do bundle de propósito; a de que o 12 morde, plantando um número
contraditório. Sem esse passo, portão é decoração — a mesma frase que a auditoria escreveu sobre a
validação que ninguém invocava, agora aplicada ao verificador dela.

### E a consequência que veio depois: o achado 65

Consertar o critério 17 obrigou a olhar o `SHA256SUMS.txt` de perto, e olhando de perto o achado
**65** — que o ledger tinha descartado como "não confirmado" — se revelou verdadeiro. Está narrado
na errata da § 1 e no `FECHAMENTO.md`. O commit é `047b10a`, e é ele que leva o placar a
**80 / 19 / 6**. Vale a generalização: **portão consertado acha defeito que portão quebrado
escondia**, e o defeito que ele achou não estava no dado — estava no ledger que dizia não haver
defeito.

### Os critérios que as três rodadas acrescentaram

`tools/verificar_fechamento.R` foi de 13 para **18 critérios**. Os cinco novos nasceram cada um de
um defeito real desta rodada, e a numeração mudou no meio do caminho: o critério auto-referente
era o 13, virou o 17 na primeira rodada e é o **18** desde a segunda, quando o critério do `dist/`
entrou como 17.

| critério | o que passou a olhar | nasceu em |
|---|---|---|
| 13 | regera a documentação num espelho e compara — pega `.md` fora de sincronia com o dicionário | 1ª |
| 14 | paridade sem diferença não explicada, com sha256, e relatório mais novo que as reivindicações | 1ª |
| 15 | todo renomeio de `deprecacao.csv` resolve numa coluna publicada, seguindo a cadeia | 1ª |
| 16 | quatro afirmações já falsificadas não podem voltar aos documentos gerados | 1ª |
| 17 | o release montado em `dist/` não está atrás da árvore, e o `SHA256SUMS` fecha | 2ª (consertado na 3ª) |
| 18 | o próprio script existe, cobre os dezessete acima e sai com código não zero | — |

*Errata de 26/07/2026: esta tabela dizia "os critérios **13 a 17**" e mapeava o 17 como o
auto-referente. Conferido em `tools/verificar_fechamento.R` com
`grep -nE '^tentar\([0-9]+,|^registrar\([0-9]+,'`: são 18, o 17 é o do `dist/` e o 18 é o
auto-referente.*

**Estado ao fim das três rodadas, medido:** suíte com **564 expectativas** em 14 arquivos,
`FAIL 0`; validação com **0 erros e 132 avisos**, todos justificados. Contra o baseline de 154
expectativas e 25 avisos.

*Errata de 26/07/2026: este parágrafo dizia "413 → 564 expectativas" e "121 avisos". O
"413 → 564" estava certo no contexto em que foi escrito — 413 era o placar da suíte ao fim da
rodada de correção e 564 é o placar depois da primeira reverificação —, mas o parágrafo agora
fecha uma seção que cobre as três rodadas, então o par que faz sentido é 154 → 564. Já os
**121 avisos estavam errados**: são 132 desde a segunda rodada, quando nasceu a checagem 20
(`faixa_declarada`), que sozinha responde por 11 deles.*
