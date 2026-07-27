# Prompt de execução — atualização dos dados do MAPEmunicipios

> Este arquivo é para ser entregue a uma instância nova do Claude Code, na raiz deste repositório.
> Cole o bloco inteiro, ou diga: *"leia `plano/atualizacao-dados/PROMPT-EXECUCAO.md` e execute"*.

---

## Quem você é e o que vai fazer

Você vai executar a **rodada de atualização de dados** do MAPEmunicipios: pôr as 26 tabelas
publicadas no dado mais recente que as origens oferecem, e — mais importante que isso — deixar cada
fonte com um **caminho de atualização programático**, de modo que a próxima rodada seja um comando e
não uma arqueologia.

Duas frases resumem o alvo:

1. **Download manual vira código.** Onde não der, o procedimento manual fica escrito passo a passo.
2. **Fonte sem origem conhecida não se mantém em silêncio.** Ou se descobre de onde veio, ou se
   declara que não se sabe.

## Leia nesta ordem, antes de agir

1. `CLAUDE.md` — as regras da casa. Ele manda sobre tudo que estiver escrito aqui.
2. `plano/atualizacao-dados/00-inventario-de-fontes.md` — de onde cada tabela vem e o que a trava.
3. `plano/atualizacao-dados/01-arquitetura-da-atualizacao.md` — as regras da atualização.
4. `plano/atualizacao-dados/02-bigquery.md` e `03-download-programatico.md` — o plano por fonte.
5. `plano/atualizacao-dados/04-fases-e-aceitacao.md` — a ordem e os critérios.
6. `auditoria/RELATORIO-FINAL.md` §§ 4 e 5 — o que ficou aberto e o que depende de decisão. A § 4
   lista sete grupos travados por falta de insumo, e **seis deles são insumo que esta rodada
   entrega**: o cruzamento está em `00-inventario-de-fontes.md` § 0.7, e é o que deve reger a sua
   ordem de prioridade.

`plano/atualizacao-dados/FONTES.csv` é o inventário legível por código; é ele que você mantém
atualizado ao longo da rodada.

## Regras que não se negociam

Estas custaram dinheiro ou dado da última vez que foram quebradas.

- **Nunca rode script do legado.** Vários consultam o BigQuery sem filtro: o do SICONFI baixa 18,5
  milhões de linhas, o do SIM varre o país inteiro, e alguns executam a consulta e descartam o
  resultado.
- **Toda consulta passa por `mape_query()`**, que faz dry-run obrigatório, aplica teto e registra o
  custo. Nunca chame `bigrquery` direto. Nunca escreva `set_billing_id` literal.
- **Nunca `SELECT *`.** Colunas listadas uma a uma, sempre.
- **Nunca ano literal em script.** O escopo sai de `mape_param("anos_painel")`.
- **Nunca edite `_targets.R` à mão.** Os alvos são gerados de `dicionario/tabelas.csv`.
- **Nunca contorne a guarda de escrita por reflexo.** Se `mape_escrever_tabela()` barrar, o certo é
  descobrir por quê. `permitir_perda = TRUE` exige `motivo_perda`, e fica registrado.
- **Nunca versione dado bruto.** `raw/` está no `.gitignore`; o que se versiona é o sha256 no
  manifesto. O hook de pre-commit barra arquivo acima de 20 MB — instale-o com
  `bash tools/hooks/instalar.sh`.
- **Número em prosa é afirmação a verificar.** Meça no Parquet antes de repetir qualquer estatística,
  inclusive as deste plano.
- **Tudo em português**: comentário, nome de função, documento e mensagem de commit (frase
  descritiva, sem prefixo de convenção).

## Use subagentes — esta parte é obrigatória

O trabalho é largo e paralelizável. **Não faça em série o que dá para fanout.** Use a ferramenta
Agent, com vários subagentes numa mesma mensagem para que rodem concorrentemente.

### O que vai para subagente

| frente | subagente | quantos |
|---|---|---|
| **Descoberta de origem** (fase 1) | um por fonte: acha URL atual, API, tabela na Base dos Dados, licença, periodicidade, último período publicado | ~15, em levas de 4 a 6 |
| **Busca online** | pesquisa web e leitura de páginas de órgão, portal de dados abertos, catálogo da BD | dentro da frente acima |
| **Leitura de código** | mapear o que cada `tratar_*.R` e cada consolidador faz, sem você ler tudo | sob demanda |
| **Documentação** | escrever `README.md` de fonte, procedimento manual passo a passo, seção de relatório | um por documento |
| **Verificação adversarial** | receber uma afirmação pronta e tentar derrubá-la | nos pontos de decisão |

### O que **não** vai para subagente

- **Consulta paga ao BigQuery.** Só a instância principal executa `mape_query()` sem
  `so_estimar`, e **uma de cada vez**. Subagentes em paralelo estourariam o teto de sessão
  (`bq.teto_gib_sessao`) sem que ninguém visse a soma crescer.
- **Escrita em arquivo compartilhado.** `FONTES.csv`, `dicionario/*.csv`, `config/parametros.yml` e
  o ledger são escritos **só pela instância principal**. Dois subagentes editando o mesmo CSV se
  sobrescrevem em silêncio.
- **`git commit`.** Sempre você.

### O contrato de saída de um subagente de descoberta

Peça exatamente isto, e peça que ele grave o resultado em
`plano/atualizacao-dados/descoberta/<slug>.md` — **um arquivo por fonte, nunca um arquivo
compartilhado** — e devolva o mesmo conteúdo como resposta:

```
FONTE: <slug>
ORIGEM_ATUAL: <URL verificada, com a data em que você a acessou>
METODO: bigquery | api | http | pacote_r | manual
IDENTIFICADOR: <tabela da Base dos Dados, endpoint, ou caminho do arquivo>
ULTIMO_PERIODO_PUBLICADO: <o que a ORIGEM tem hoje>
PERIODICIDADE: <observada, não a declarada>
LICENCA: <nome + URL>
ESQUEMA_MUDOU: sim | nao | nao_sei  — e o que mudou
DEGRAU: 1 a 5, conforme a escada da § 1.1
EVIDENCIA: <o que você viu, onde, quando>
INCERTEZA: <o que você NÃO conseguiu confirmar>
```

**Exija o campo `INCERTEZA` preenchido.** Subagente que devolve tudo confirmado, sem nenhuma
incerteza, normalmente não verificou — mande de volta.

E diga a eles, com estas palavras: *"não invente identificador de tabela da Base dos Dados nem URL;
se não confirmou, escreva `nao_confirmado` e diga o que tentou."* Identificador inventado é o modo
de falha mais provável desta fase, porque parece plausível e só quebra na hora da consulta.

## A ordem de execução

Siga `04-fases-e-aceitacao.md`. O esqueleto:

```bash
# FASE 0 — linha de base. Se isto não sair com código 0, pare e resolva antes.
Rscript tools/verificar_fechamento.R
Rscript -e 'testthat::test_dir("tests/testthat")'
git status --porcelain                            # tem de estar vazio AQUI
Rscript tools/validar_tudo.R                      # reescreve os 26 qa/*.md; na linha de base a
                                                  # única diferença é o carimbo de hora — confira
                                                  # com `git diff qa/` e desfaça com
                                                  # `git checkout -- qa/`
```

Depois: **fase 1 (descoberta, com fanout de subagentes)** → fase 2 (infraestrutura que faltar) →
fase 3 (extração, uma por vez, com dry-run antes) → fase 4 (tratamento e publicação) → fase 5
(dimensões) → fase 6 (fechamento) → fase 7 (release, só depois das decisões).

**Comece pelo `00_diretorios/municipios`.** É a espinha dorsal, é a única fonte com caminho completo
hoje, e é a extração mais barata — serve de teste do procedimento inteiro antes de você gastar byte
com o resto.

## Onde você para e pergunta

Não decida sozinho nestes pontos. Os itens 2 e 3 são os itens 1 e 2 da § 5 de
`auditoria/RELATORIO-FINAL.md`, e o item 4 é a regra que ela aplica caso a caso (itens 3, 7 e 8). Os
outros quatro não estão no relatório: são decisão registrada neste plano —
`01-arquitetura-da-atualizacao.md` §§ 1.3, 1.7 e 1.8, e a fase 3 de `04-fases-e-aceitacao.md`:

1. **Ampliar `anos_painel`.** Muda as 26 tabelas de uma vez.
2. **A série de PIB de `04_economia`** (achado 1). Reextrair sem decidir o que fazer com o fator de
   bloco troca um defeito por outro.
3. **A licença de `13_seguranca`** (FBSP, CC BY-NC-ND contra CC BY 4.0). Bloqueia o release.
4. **Qualquer mudança de valor publicado** — inclusive revisão feita pela origem. Reivindique em
   `qa/paridade_esperada.csv` antes de rodar.
5. **Dependência nova no `renv.lock`.**
6. **Subir o teto de custo** do BigQuery. A resposta certa quase sempre é reduzir o escopo.
7. **O Censo 2022** em fonte censitária: edição nova é `ano_ref` novo, não ano de painel — mas a
   decisão de incorporá-lo é do responsável.

## O que você entrega no fim

1. As fontes atualizadas, cada uma com `extrair_*.R`, `tratar_*.R`, `MANIFESTO.yml` completo e
   proveniência registrada.
2. `FONTES.csv` atualizado e o **ledger da rodada**, uma linha por fonte, sem `pendente` sem
   observação.
3. `plano/atualizacao-dados/RELATORIO-ATUALIZACAO.md` com quatro seções: o que mudou no dado
   publicado, o que ficou aberto e por quê, o que depende de decisão, e quanto custou em bytes
   escaneados (de `qa/custo_bigquery.csv`).
4. Documentação regerada — não editada à mão.
5. `Rscript tools/verificar_fechamento.R` saindo com código 0, e a árvore limpa.

## Uma última coisa

Este repositório passou por uma auditoria de 105 grupos de defeito, e a causa-raiz da maioria não foi
código errado: foi **afirmação escrita como se fosse fato medido**. Cobertura declarada que não
batia com a observada, licença "a verificar" que virou release, extração que nunca rodou descrita no
presente do indicativo. Este próprio plano trazia essa última: dizia que
`extrair_municipios.R` "roda", quando ele nunca foi executado.

Depois disso os 105 foram **reverificados três vezes**, e cada rodada derrubou coisa que a anterior
dera por fechada — cinco grupos na primeira, seis na segunda, dois na terceira, e os dois últimos
eram portões recém-escritos que **nasceram quebrados e passavam sempre**. O diagnóstico comum:
*o código era corrigido, o `.md` publicado continuava com o texto velho, e o critério media o
código.* Foi daí que saíram os critérios 13 a 17 de `tools/verificar_fechamento.R`, que hoje tem 18.

As três lições, na ordem em que vão te atingir:

1. **Meça antes de repetir**, inclusive o que este plano afirma.
2. **Regere o artefato**, não só o código e o dicionário — o `.md` é o que o consumidor lê.
3. **Faça seu portão reprovar uma vez** antes de confiar nele.

Se você não conseguir atualizar uma fonte, **escreva que não conseguiu, com o que tentou**. Um item
honestamente bloqueado vale mais que um item declarado pronto que a próxima pessoa vai descobrir que
não está.
