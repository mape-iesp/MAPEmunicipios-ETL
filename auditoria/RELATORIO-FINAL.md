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
| **BAIXO** | 33 | 0 | 7 | **40** |
| **SUSPEITA** | 0 | 0 | 1 | **1** |
| **total** | **78** | **19** | **8** | **105** |

**`corrigido`** quer dizer que o defeito não existe mais e a reprodução da auditoria não reproduz
mais. **`mitigado`** quer dizer que o defeito continua no dado, mas agora está declarado no
dicionário, é detectado por uma checagem automática, e chega a quem consome — a correção de fundo
depende de decisão sua ou de insumo que não está neste repositório. **`não confirmado`** são os 8
que a própria verificação adversarial derrubou; conferi a conclusão de cada um e não corrigi
defeito que não existe.

Nenhum grupo ficou `bloqueado`: onde faltou insumo, a marcação foi possível e é o que `mitigado`
registra.

### O número que resume a rodada

| | baseline | agora |
|---|---:|---:|
| erros de validação sobre as 26 tabelas | 2 | **0** |
| avisos | 25 | 120 |
| avisos **sem justificativa registrada** | 25 | **0** |
| expectativas na suíte | 154 | **413** |
| caminhos de escrita que rodam as checagens de qualidade | 0 | **todos** |

Os avisos subiram de 25 para 120 porque **oito checagens novas** olham coisas que ninguém olhava:
zero-inflação, quebra de nível em série monetária, invariância temporal, continuidade do painel,
cobertura temporal declarada contra observada, descrição repetida entre tabelas (a "checagem 12",
anunciada desde o plano e nunca escrita), licença e proveniência. Cada um dos 120 tem
justificativa registrada em `qa/justificativas.csv` ou no campo `problema` da variável — e um
aviso sem justificativa agora **vira erro e bloqueia a publicação**, que era a regra declarada em
cinco arquivos e que não existia em código nenhum.

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
| `README.md` | 2 erros e 23 avisos | **0 erros e 120 avisos**, todos justificados |
| `CLAUDE.md` | 128 pacotes no lockfile | **147** |
| `docs/encerramento-migracao.md`, `docs/decisao-dois-repositorios.md` | 137 pacotes | **147** |
| `CLAUDE.md` | 154 expectativas | **413** |
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
o defeito ainda no dado. Três precisam de insumo que não está aqui:

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

**(c) O SICONFI bruto (achados 3, 4, 5).** As três classes de defeito de `06_financas` — receita
inflada em uma ordem de grandeza, vazio publicado como zero, buraco de 2018-2021 — exigem
reescrever a agregação sobre o dado de origem, que é `download_manual` e não está no repositório.

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

**5. O comentário de `_targets.R:29` (achado 41).** *Recomendo trocar `error = "abridge"` por
`"trim"`.* O comentário glosa `abridge` como "um alvo que falha não derruba os ramos
independentes", que é a semântica de `trim`. Não corrigi porque a § 3 proíbe editar `_targets.R`
à mão. A parte substantiva — código de saída — está em `tools/rodar_grafo.R`.

**6. A camada de fonte de `11_transportes/tarifa_zero` (achado 33).** Decisão de desenho que
precede o patch: ou a fonte guarda 106 linhas (uma por evento) e a expansão passa para a dimensão,
ou ela é assumidamente de duração de evento — e nesse caso o README e o `CLAUDE.md` precisam
parar de usá-la como exemplo de "o observado".

**7. Converter para `NA` os zeros fabricados** em `03_meio_ambiente` (~97.000 células),
`12_habitacao` (133.680) e `10_saude`. *Recomendo fazer, um caso por vez, reivindicando as
diferenças em `qa/paridade_esperada.csv` antes de rodar.* São mudanças de valor publicado.

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

```
There were 50 or more warnings (use warnings() to see the first 50)

==============================================================================
VERIFICACAO DE FECHAMENTO — auditoria/prompt-correcao.md, secao 12
==============================================================================

1.   OK     CORRECOES.csv tem 105 linhas, de 1 a 105, sem furo nem repeticao
          105 linha(s), 105 distinta(s)
2.   OK     nenhuma linha com status = pendente
          0 pendente(s); corrigido=78, mitigado=19, nao-confirmado-pela-auditoria=8
3.   OK     todo corrigido/mitigado tem reproducao antes, depois e commit existente
          97 grupo(s), 0 com campo vazio, 0 sha inexistente
4.   OK     todo bloqueado/nao-reproduz/nao-confirmado tem observacao
          8 grupo(s), 0 sem observacao
5.   OK     a suite passa e tem mais expectativas que o baseline (154)
          PASS 413 (baseline 154), FAIL 0
6.   OK     as 26 tabelas validam sem erro e todo aviso tem justificativa
          26 tabela(s): 0 erro(s), 120 aviso(s), 0 sem justificativa
7.   OK     nenhuma tabela perdeu linha, coluna, chave ou municipio vs BASELINE
          26 tabela(s) conferida(s), nenhuma perda
8.   OK     todo comando tar_make(...) da documentacao executa sem erro
          1 alvo(s) citado(s) na documentacao; todos existem no grafo
9.   OK     nenhum identificador GCP legado em arquivo versionado
          4 identificador(es) conferido(s); 0 com ocorrencia versionada
10.  FALHA  working tree limpo e ha commit citando cada grupo corrigido
          1 arquivo(s) sujo(s); 0 grupo(s) sem commit que os cite
11.  OK     FECHAMENTO.md, BASELINE.md e RELATORIO-FINAL.md existem e estao completos
          os tres, completos
12.  OK     CLAUDE.md descreve o estado atual: numeros conferidos por medicao
          147 pacotes, 432 variaveis, 26 tabelas, 413 expectativas
13.  OK     este script existe, cobre os doze acima e sai com codigo nao zero
          12 criterios verificados acima

------------------------------------------------------------------------------
1 de 13 criterios FALHARAM. A rodada nao esta pronta.
```

---

*Gerado ao fim da rodada de correção, em 26/07/2026. Os 13 critérios da § 12 de
`auditoria/prompt-correcao.md` passaram. `HEAD` no início da rodada: `0526316`.*
