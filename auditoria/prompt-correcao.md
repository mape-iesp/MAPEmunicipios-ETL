# Prompt de correção da auditoria do MAPEmunicipios-ETL

Este documento existe para ser **colado inteiro** numa instância nova do Claude Code, aberta na raiz
deste repositório. Ele é a missão completa: o responsável pelo projeto não estará disponível durante a
execução, e todas as decisões que dependiam dele já estão tomadas aqui.

Ele também é o seu ponto de retomada. Se o seu contexto for compactado, releia este arquivo e
`auditoria/CORRECOES.csv` — juntos eles são o estado inteiro do trabalho.

---

## 1. A missão

`auditoria/CONSOLIDADO.md` reúne **105 grupos de achado** — 7 críticos, 25 altos, 32 médios, 40 baixos
e 1 suspeita — produzidos por treze auditores independentes e reexecutados por um verificador
adversarial. Oito grupos estão marcados `NÃO REPRODUZIDO`. Nenhum dos 105 foi corrigido.

Sua missão é **corrigir todos**, provar cada correção com a reprodução que a própria auditoria escreveu,
e deixar o repositório num estado em que os defeitos dessa classe não possam voltar em silêncio.

**A missão termina quando os treze critérios da § 12 passarem, e não antes.** Leia a § 12 agora, antes
de começar: ela é mecânica, verificável por comando, e é contra ela que o trabalho vai ser julgado.
Nenhum limite de custo, falha de autenticação ou achado bloqueado encurta essa lista — a § 6 e a § 11
dizem como seguir em cada caso.

**A regra de ouro deste trabalho**, que é a lição central da auditoria: *afirmação sem checagem é
defeito*. A maior parte dos 105 achados existe porque o repositório promete em prosa o que o código não
sustenta. Portanto: nenhuma correção sua termina em texto. Termina em código que falha quando a
promessa for violada, e em número que você mediu.

Corolário prático: **não confie em número nenhum que esteja em prosa neste repositório**, nem nos da
auditoria. Os da auditoria foram medidos antes das correções; depois delas ficam errados por
construção. Meça você, do Parquet.

---

## 2. O que ler antes de tocar em qualquer coisa

Nesta ordem:

1. `CLAUDE.md` — já foi reescrito para refletir a auditoria. A § "⛔ `tar_make()` sem argumento destrói
   dado publicado" e a tabela de errata são obrigatórias.
2. `auditoria/CONSOLIDADO.md` — a nota de método, o quadro de vereditos e o índice dos 105 grupos.
   Cada grupo tem `Afirmação`, `Reprodução`, `Saída observada`, `Impacto`, o que a verificação
   adversarial encontrou e **`Correção sugerida`**.
3. `README.md` — é alvo de errata, não fonte de verdade.
4. `plano/01-modelo-e-convencoes.md` e `plano/03-versionamento-qa.md` — quando precisar saber qual era
   a intenção de desenho de uma convenção que você vai mexer.

**`auditoria/A1.md`–`A13.md`, `auditoria/CONSOLIDADO.md` e `auditoria/prompt-auditoria.md` são
evidência imutável. Nunca edite nem apague nada neles.** Se um achado estiver errado, isso se registra
no seu ledger, não apagando a evidência. Consulte os `A*.md` quando a seção do consolidado não bastar.

---

## 3. Autorizações e proibições

Estas decisões são do responsável pelo projeto e já foram tomadas. Não as reabra.

**Autorizado:**

- **Commitar direto na `main`**, um commit por grupo de achado.
- **Renomear colunas publicadas**, registrando cada renomeação em `dicionario/deprecacao.csv`. O
  release v1.0.0 ainda não foi publicado, então o custo de renomear agora é baixo.
- **Corrigir por medição os números** de `README.md`, `docs/*.md` e `CLAUDE.md`.
- **Consultar o BigQuery**, exclusivamente pelo freio da § 6, que é obrigatório.
- **Remontar `dist/`** no fim, rodando `Rscript tools/publicar_release.R v1.0.0`. Isso só reescreve a
  pasta local.
- **Reescrever o histórico do git e dar force-push**, exclusivamente na última fase (§ 10), com o
  backup espelho que ela exige.

**Proibido:**

- **Despublicar coluna ou tabela.** A decisão do responsável foi *marcar, não remover*. Nada sai de
  `dados/`, nada vai para quarentena, nenhuma coluna desaparece do dicionário publicado.
- **`tar_make()` sem argumento, e qualquer `tar_make(dim_*)`**, até a § 5 estar concluída e provada.
  Hoje esses comandos destroem dado publicado.
- **`git commit --no-verify`** e qualquer contorno do hook de pre-commit.
- **Publicar o release no GitHub** (`gh release create` e afins), mexer na tag v1.0.0, ou empurrar
  qualquer coisa para o repositório `mape-iesp/MAPEmunicipios`.
- **Editar `_targets.R` à mão.** Os alvos são gerados de `dicionario/tabelas.csv`.
- **Copiar o conteúdo de `auditoria/VAZAMENTO-GCP.local.md`** para arquivo versionado, mensagem de
  commit, ou qualquer lugar que vá para o git. Esse arquivo não é versionado e é por isso que ele
  existe.
- **Rodar script do legado**, ou consultar o BigQuery fora do freio da § 6.
- **Parar para perguntar.** Não há ninguém para responder. A § 11 diz o que fazer quando faltar
  decisão.

---

## 4. Fase 0 — quatro entregas antes da primeira correção

**(a) `auditoria/FECHAMENTO.md` — a análise de fechamento que a auditoria deixou pendente.**
A lista está no fim de `CONSOLIDADO.md`: cadeias causais (agrupar os grupos que compartilham raiz),
**ordem de correção com dependências** (o que corrigir antes de reprocessar, o que exige a origem, o
que é só documentação), contradições entre relatórios, lacunas de cobertura, errata do README, e o
veredito sobre as sete afirmações centrais do projeto (chave, sufixo, dicionário, campos calculados,
fonte canônica, paridade, documentação). Escreva-a antes de corrigir: **é ela que define a sua ordem de
trabalho.** Ao final da execução, atualize o veredito das sete afirmações para o estado pós-correção.

**(b) `auditoria/CORRECOES.csv` — o ledger, com uma linha por grupo, de 1 a 105.**
Colunas: `grupo,severidade,veredito_auditoria,titulo_curto,status,reproduziu_antes,reproduziu_depois,commit,teste_novo,observacao`.
Valores de `status`:

| status | significa |
|---|---|
| `pendente` | ainda não trabalhado (estado inicial de todos) |
| `corrigido` | defeito eliminado na raiz, com reprodução provando |
| `mitigado` | dado marcado e documentado; a raiz exige a origem, que não veio |
| `bloqueado` | não foi possível; a observação diz exatamente o que falta |
| `nao-reproduz-hoje` | a reprodução não reproduz mais o defeito na árvore atual |
| `nao-confirmado-pela-auditoria` | os 8 grupos `NÃO REPRODUZIDO`; só confirmar a conclusão do verificador |

Atualize o ledger **no mesmo commit** da correção. Ele é o que te permite retomar depois de uma
compactação de contexto.

**(c) `auditoria/BASELINE.md` — o estado de partida, medido.**
Para cada uma das 26 tabelas publicadas: linhas, colunas, chaves distintas, municípios distintos,
faixa de anos, sha256 do Parquet e do csv.gz. Mais: a saída completa de
`testthat::test_dir("tests/testthat")` e de `mape_validar_tabela()` sobre as 26. Isso é a sua rede: sem
esse retrato, uma mudança de dado não intencional passa invisível. Meça antes de mexer em nada.

**(d) O teste de fumaça do BigQuery** — § 6. Dura minutos e decide a rota dos achados 1–5 e 8.

Depois disso, execute na ordem que o `FECHAMENTO.md` estabeleceu. Onde a ordem for indiferente:
CRÍTICO → ALTO → MÉDIO → BAIXO. Duas exceções que vêm antes de tudo: o **achado 6** (§ 5) e o
**freio do BigQuery** (§ 6).

---

## 5. Primeiro de todos: achado 6, tornar a escrita destrutiva impossível

`tar_make(dim_09_educacao)` troca 111.388 linhas publicadas por 60.672 e perde a coluna `ano_ref_ideb`.
`tar_make(dim_11_transportes)` troca 183.814 linhas e 5.570 municípios por 929 linhas e 133 municípios.
A gravação sai com `validar = FALSE`, e `mape_consolidar_dimensao()` tem `publicar = TRUE` por padrão.
Enquanto isso estiver de pé, qualquer passo seu que rode um alvo pode destruir dado. Portanto:

1. **Guarda em `mape_escrever_tabela()`**: ao sobrescrever uma tabela publicada que já existe, compare
   antes de gravar — linhas, colunas, chaves distintas e municípios distintos. Se o novo perder
   qualquer um dos quatro, **pare com erro** e mostre o diff. Só prossiga se receber
   `permitir_perda = TRUE` com um motivo, e registre o motivo. Perda silenciosa deixa de ser possível.
2. **Teste que prova a guarda**: em `tests/testthat/`, uma sobrescrita com perda que precisa falhar, e
   uma sem perda que precisa passar. Sem esse teste a correção não conta.
3. **Os três alvos `dim_*`**: faça `mape_consolidar_dimensao(d, publicar = FALSE)` reproduzir a tabela
   publicada. `01_assistencia_social_dh` já reproduz — use como controle. Para `09_educacao` e
   `11_transportes`, se a reprodução fiel exigir entrada que não está nesta árvore, o alvo deve
   **falhar alto**, nomeando a entrada que falta, em vez de publicar tabela truncada.
4. Só depois disso volte a rodar alvo do `targets` — e mesmo então, alvo por alvo, nunca `tar_make()`
   pelado.

Aproveite que está aqui: o alvo `documentacao` grava a própria dependência e o grafo nunca converge
(achado 69), e `tar_make()` sai com código 0 mesmo falhando (achado 41). Os dois são desta família.

---

## 6. O freio do BigQuery, obrigatório antes de qualquer consulta

`R/bigquery.R` hoje não tem freio nenhum: `mape_query()` chama `basedosdados::read_sql()` direto, sem
dry-run e sem teto. Antes de qualquer consulta real, reescreva `mape_query()` para:

1. Rodar **sempre** `bigrquery::bq_perform_query_dry_run()` primeiro e registrar os bytes. O dry-run
   mede exato e não custa nada.
2. **Recusar** a consulta se os bytes passarem de `bq_teto_bytes_consulta` (ponha em
   `config/parametros.yml`, valor inicial **64 GiB**).
3. Executar com **`maximum_bytes_billed`** igual ao teto — é isso que faz o servidor matar a consulta
   em vez de cobrá-la.
4. Acumular os bytes em `qa/custo_bigquery.csv` (uma linha por consulta: fonte, sql resumido, bytes do
   dry-run, bytes cobrados, data) e recusar quando o acumulado passar de `bq_teto_bytes_sessao`
   (valor inicial **512 GiB**, metade da cota grátis mensal).
5. **Cachear em `fontes/<dim>/<fonte>/raw/`** com sha256 no `MANIFESTO.yml`, para que nenhuma consulta
   precise rodar duas vezes.

**Por que estes números.** On-demand: 1 TiB por mês grátis por conta de faturamento, depois
US$ 6,25/TiB escaneado. As consultas pretendidas são pequenas — `br_ibge_pib.municipio` é da ordem de
centenas de MB, o SICONFI é a maior, poucos GB com as colunas selecionadas, então na prática você deve
usar uma fração mínima do teto. O teto de sessão de 512 GiB é **metade da cota grátis**, decidido pelo
responsável; no pior caso de a cota do mês já estar consumida, custaria US$ 3,13. Com dry-run e
`maximum_bytes_billed`, o custo catastrófico deixa de ser possível.

**O teto não é motivo para abortar a missão.** Se um teto for atingido, a consulta é que para — não o
trabalho. Registre o achado afetado como `mitigado`, com o número de bytes que faltou, siga pela trilha
de mitigação da § 8 e continue para o próximo grupo. O mesmo vale se a autenticação falhar. **A missão
só termina quando o ledger não tiver mais nenhum `pendente`**, e nenhum limite de custo muda isso.

**Teste de fumaça, antes de tudo.** Existe token do `gargle` em cache
(`~/.cache/gargle/`, de 13/05) e `MAPE_GCP_BILLING` está no `.Renviron`. Faça um dry-run numa tabela
minúscula e veja se autentica. **`bigrquery` não abre navegador sozinho: se a autenticação exigir
interação, não tente resolvê-la e não espere.** Registre `bigquery-indisponivel` no ledger, siga pela
trilha de mitigação nos achados 1–5 e 8, e diga isso no relatório final.

**O que é elegível para extração.** Só onde um achado confirmado exige o dado da origem **e** a origem é
identificável a partir deste repositório:

- `04_economia` ← `br_ibge_pib` (achados 1 e 2)
- `06_financas` ← SICONFI, receitas orçamentárias (achados 3, 4 e 5)
- `09_educacao` ← `basedosdados.br_inep_ideb` e `basedosdados.br_inep_censo_educacao_superior`, se um
  achado precisar

**Não tente reextrair as 26 tabelas.** Só 3 declaram `metodo_acesso = bigquery`; 16 são `arquivo_local`
e 7 `download_manual`; os arquivos não estão no repositório (só `cadunico` e `disque100` têm `raw/`) e a
árvore legada não está nesta máquina. Isso não é limite de orçamento, é limite de informação.

**Como consultar.** Agregue no servidor com `GROUP BY` até a granularidade município × ano, para que o
download seja pequeno. **Nunca** faça consulta em laço por município ou por ano. Uma consulta por
fonte, cacheada.

**Se a reextração mudar dado publicado** — e ela vai —, a regra do projeto é reivindicar antes de rodar:
acrescente as diferenças esperadas a `qa/paridade_esperada.csv` **antes** de rodar `mape_paridade()`,
nunca depois de ver o resultado. A base de referência está no disco
(`qa/referencia/base_municipios_brasileiros.RDa`, 58 MB), então a paridade é executável.

Uma fonte nova ganha estrutura com `mape_nova_fonte()`, e o alvo aparece sozinho no grafo quando a
linha entrar em `dicionario/tabelas.csv` e o `tratar_*.R` existir. Não edite `_targets.R`.

---

## 7. O ciclo obrigatório, por achado

Para cada grupo, nesta ordem:

1. **Leia o grupo inteiro** no `CONSOLIDADO.md`, inclusive o que a verificação adversarial encontrou —
   é lá que estão as ressalvas e as correções de escala.
2. **Rode a reprodução ANTES de corrigir.** Extraia o bloco ```r para o scratchpad e execute.
   - Reproduziu → siga.
   - Não reproduziu → `status = nao-reproduz-hoje`, cole a saída na observação e **não corrija defeito
     que não existe**. Isso é resultado legítimo, não fracasso.
   - Grupo marcado `NÃO REPRODUZIDO` pela auditoria → não corrija; confirme a conclusão do verificador
     e registre.
3. **Decida a correção.** A `Correção sugerida` é proposta, não ordem: foi escrita por quem não teve de
   fazê-la funcionar. Se divergir, diga por quê no commit. Prefira sempre a correção **estrutural** — a
   checagem que torna a classe inteira de defeito impossível — à correção local. A maioria dos grupos
   pede as duas: consertar a instância e acrescentar a checagem que a teria pegado.
4. **Aplique.**
5. **Rode a mesma reprodução depois.** O defeito tem de ter desaparecido. Guarde as duas saídas.
6. **Rode a validação** da tabela afetada e a suíte inteira (`testthat::test_dir("tests/testthat")`).
7. **Escreva o teste que faltava.** Todo invariante novo precisa de um teste em `tests/testthat/` que
   falhe sem a sua correção. Garantia em prosa é exatamente o que produziu esta auditoria. Anote em
   `teste_novo` no ledger.
8. **Commite**, um grupo por commit: `Achado NN: <o que mudou>`. No corpo, o antes e o depois medidos, e
   a divergência da correção sugerida, se houver. Inclua o trailer `Co-Authored-By` que as suas
   instruções mandarem. Atualize `auditoria/CORRECOES.csv` no mesmo commit.

Vários grupos compartilham raiz. Quando corrigir a raiz e isso fechar outros grupos, feche-os no mesmo
commit e diga no ledger qual grupo os resolveu — mas **rode a reprodução de cada um** para provar.

Você pode delegar a subagentes a **verificação independente** de uma correção (rodar reprodução, medir
tabela, revisar diff), e isso é bom uso de paralelismo. Não delegue a aplicação: as edições precisam
ser sequenciais, sobre os mesmos arquivos de dicionário e dado, e worktree separado não serve para
Parquet publicado.

---

## 8. O que é permitido mudar no dado publicado

A decisão do responsável: **marcar, não despublicar.**

**Permitido:** pôr `NA` em célula comprovadamente falsa; criar coluna `flag_*`; criar campo novo de
dicionário (por exemplo `pct_zero` e `janela_efetiva`, pedidos pelos achados 4 e 21) e preenchê-lo em
`mape_recalcular_campos()`; preencher `problema` e `observacoes`; pôr `confianca_inferencia = baixa` e
`revisao_pendente = TRUE`; ajustar `acao`; renomear coluna cujo nome mente sobre a unidade; recalcular
onde o achado prova que a fórmula ou a unidade está errada; estreitar `dominio_valido` para que a
validação passe a disparar.

**Proibido:** remover coluna ou tabela; reduzir linhas; mudar valor em silêncio.

**Toda mudança de dado publicado tem de reportar, na mensagem do commit**, o antes e o depois: linhas,
colunas, chaves distintas, municípios distintos, e mínimo/máximo das colunas tocadas. Depois de mexer
numa tabela, reescreva **os dois formatos** (Parquet e csv.gz) coerentemente e regere os documentos
gerados dela.

**As duas chaves duplicadas são de propósito** — `06_financas` (222) e `15_dados_historicos` (54). Não
as "conserte". O defeito do achado 11 é que a guarda de `mape_montar_base_larga()` não *vê* as 54, e
que a dimensão inteira é descartada por um `next` silencioso em `R/dimensao.R:103` e `:122`. Corrija a
cegueira, não a duplicata.

**Sobre o csv.gz**: `write.csv(..., fileEncoding = "UTF-8")` sobre conexão é ignorado pelo R (achado
99), e `id_municipio` volta como `integer` em `read.csv()` padrão (achado 103). São dois achados desta
família — quando corrigir a escrita, confira que a releitura do arquivo **exportado** é comparada, o
que hoje não acontece (achado 39).

---

## 9. Documentação e números

Deixe a errata para o fim de cada frente, porque os números mudam com as correções.

- **Todo número em prosa tem de ser remedido** ao final, não copiado da auditoria. Alvos:
  `README.md`, `docs/*.md`, `CLAUDE.md`, mais os gerados (`dicionario/README.md`,
  `dados/dimensao/*.md`, `qa/*.md`, `fontes/*/*/README.md`).
- Os gerados se regeram com `tar_make(documentacao)` — **só depois** da § 5 estar concluída.
- A **tabela de errata do `CLAUDE.md`** existe para encolher: cada linha corrigida sai dela. Se
  terminar vazia, tire a tabela e diga que a auditoria foi fechada.
- Os **seis comandos `tar_make()` que a documentação ensina e que não funcionam** (achado 70,
  incluindo a receita do README em § "Um ano novo numa fonte que já existe") têm de passar a funcionar
  ou sair da documentação. Não deixe receita que falha.
- `docs/encerramento-migracao.md` tem 5 de 8 números errados no quadro "O estado final" e um rótulo
  errado (achado 96).
- Onde a auditoria descreve um defeito que você corrigiu, o campo `problema` da variável não pode
  continuar descrevendo o problema antigo como se fosse o vivo (achados 7, 63).

---

## 10. Última fase: o histórico do git

Só comece isto quando: o ledger não tiver nenhum `pendente`, a suíte estiver verde, e o working tree
estiver limpo.

1. **Backup espelho, primeiro.** `git clone --mirror . <scratchpad>/backup-mirror.git` e verifique que
   ele abre (`git -C <...> log --oneline | head`). Registre o sha do `HEAD` atual no relatório final.
   Sem esse backup verificado, não prossiga.
2. **A árvore antes do histórico.** `R/bigquery.R:3-7` traz quatro identificadores de projeto GCP
   legados escritos no comentário, em repositório público. Reescreva o comentário para dizer o fato —
   que o legado usava quatro contas de faturamento diferentes — sem os nomes. Os outros arquivos
   versionados afetados estão listados na nota do vazamento.
3. **`git-filter-repo` não está instalado.** Instale com `brew install git-filter-repo`. **Se falhar,
   pare esta fase**, registre `bloqueado` e siga para o relatório. Não improvise com `git filter-branch`
   nem com script próprio de reescrita: o risco não vale.
4. **Purgue duas coisas**: os blobs de `raw/` do CadÚnico (10,6 MiB, `fontes/**/raw/*.txt`), e a string
   do identificador GCP via `--replace-text`. A string exata está em
   `auditoria/VAZAMENTO-GCP.local.md`, que não é versionado — leia dali, e **nunca** escreva o valor
   em arquivo versionado, mensagem de commit ou comando que fique registrado.
5. **Um único `git push --force-with-lease origin main`** no fim.
6. **No relatório final, diga o que a reescrita não resolve**: quem tiver clone antigo continua com os
   objetos, e é preciso pedir ao GitHub a expiração dos objetos órfãos.

---

## 11. Quando faltar decisão, ou algo der errado

- **Não pergunte.** Não há ninguém. Quando duas leituras forem defensáveis, escolha a **mais
  conservadora** — a que não muda valor publicado, não remove nada e não amplia escopo —, registre a
  premissa no ledger e no relatório final.
- **Achado que exige dado que não está aqui**: `status = bloqueado`, e a observação diz exatamente o
  que falta e o que rodar quando chegar. Nunca finja correção. Nunca deixe correção pela metade: volte
  ao estado limpo e registre.
- **Nunca** `git reset --hard` sobre trabalho já commitado, e nunca `--no-verify`.
- **Se o contexto estiver acabando**: o ledger e os commits são o estado. Nada essencial pode estar só
  na sua cabeça. Deixe o ledger consistente antes de qualquer coisa.
- Ruído esperado que não é problema: todo `Rscript` imprime `The project is out-of-sync — use
  renv::status()`. Ignore. `renv.lock` fixa 147 pacotes.
- Lembre que `mape_validar_tabela()` grava em `qa/` incondicionalmente e um dos testes escreve dentro da
  árvore real (achados 59 e 87) — confira o `git status` depois de rodar a suíte, e conserte esses dois
  quando chegar a vez deles.

---

## 12. Definição de pronto

A tarefa **não** está pronta quando você tiver mexido em 105 lugares, nem quando os arquivos estiverem
escritos. Está pronta quando os treze critérios abaixo passarem, e **cada um deles é verificável por
comando**. Se algum não passar, você ainda está trabalhando.

Coerente com a regra de ouro desta missão, a própria definição de pronto tem de ser provada por código,
não afirmada em prosa. Portanto o critério 13 é: **escrever `tools/verificar_fechamento.R`**, que checa
mecanicamente os doze primeiros, imprime uma linha por critério com `OK` ou `FALHA`, e **sai com código
diferente de zero se qualquer um falhar**. Você só declara a missão concluída depois de colar a saída
limpa desse script no relatório final.

| # | critério | como se verifica |
|---:|---|---|
| 1 | `auditoria/CORRECOES.csv` tem exatamente 105 linhas, uma por grupo, de 1 a 105, sem repetição e sem furo | contar e comparar com `seq_len(105)` |
| 2 | Nenhuma linha com `status = pendente` | `sum(status == "pendente") == 0` |
| 3 | Todo `corrigido` e `mitigado` tem `reproduziu_antes`, `reproduziu_depois` e `commit` preenchidos, e o sha do commit existe | `git cat-file -e <sha>` para cada |
| 4 | Todo `bloqueado`, `nao-reproduz-hoje` e `nao-confirmado-pela-auditoria` tem `observacao` não vazia dizendo o motivo | campo não vazio |
| 5 | A suíte passa inteira, e tem **mais** expectativas que o baseline — porque todo invariante novo virou teste | `testthat::test_dir()` sem falha; contagem > a de `BASELINE.md` |
| 6 | `mape_validar_tabela()` roda nas 26 tabelas sem nenhum erro além das duas chaves duplicadas intencionais, e **todo aviso tem justificativa registrada** em `observacoes` ou `problema` | percorrer as 26 e conferir cada aviso |
| 7 | Nenhuma tabela publicada perdeu linha, coluna, chave ou município em relação ao `BASELINE.md`, salvo onde um achado exigia e o commit documenta | comparar com o baseline, tabela por tabela |
| 8 | Todo comando `tar_make(...)` que a documentação ensina executa sem erro | extrair os comandos de `README.md`, `CLAUDE.md` e `docs/` e rodar cada um |
| 9 | Nenhum dos quatro identificadores GCP legados aparece em arquivo versionado | `git grep` pelos nomes, esperando zero |
| 10 | Working tree limpo, tudo commitado na `main`, e há pelo menos um commit citando cada grupo corrigido | `git status --porcelain` vazio; `git log` contra o ledger |
| 11 | Os três documentos existem e estão completos: `auditoria/FECHAMENTO.md` (inclusive o veredito pós-correção sobre as sete afirmações centrais), `auditoria/BASELINE.md`, `auditoria/RELATORIO-FINAL.md` | existir, e conter as seções que a § 4 e a lista abaixo pedem |
| 12 | `CLAUDE.md` descreve o repositório como ele ficou: a tabela de errata só com o que ainda vale, os avisos vencidos removidos, os números remedidos | conferir cada número contra medição |
| 13 | `tools/verificar_fechamento.R` existe, cobre os doze acima e sai com 0 | rodar |

**`auditoria/RELATORIO-FINAL.md`** é o que o responsável vai ler primeiro. Tem de dizer, nesta ordem:

1. Um quadro: quantos grupos `corrigido`, `mitigado`, `bloqueado`, `nao-reproduz-hoje`, por severidade.
2. **Qual dado publicado mudou**, tabela por tabela, com antes e depois medidos. Se nenhum mudou, dizer.
3. Quais números da documentação mudaram, com o valor velho e o novo.
4. O que ficou **bloqueado**, com o que falta e o comando exato para retomar quando chegar.
5. O que **depende de decisão dele**, com a sua recomendação para cada caso.
6. Se a reextração rodou: o que foi consultado, quantos bytes, quanto custou — de `qa/custo_bigquery.csv`.
7. Se a reescrita de histórico rodou: o sha do `HEAD` de antes, o caminho do backup espelho, e o pedido
   de expiração de objetos órfãos que ainda falta fazer ao GitHub.
8. Os comandos exatos dos próximos passos, inclusive publicar o release.
9. A saída limpa de `tools/verificar_fechamento.R`.

**O que não conta como pronto:** ledger com `pendente`; correção sem reprodução rodada depois;
invariante novo sem teste; número em prosa que você não mediu; achado fechado porque "a correção
sugerida foi aplicada" sem a prova; suíte vermelha; working tree sujo.

E o teste final, que nenhum script mede: uma segunda auditoria, rodando `auditoria/prompt-auditoria.md`
de novo sobre o repositório corrigido, não deveria encontrar estes defeitos — nem encontrá-los
disfarçados de prosa nova.
