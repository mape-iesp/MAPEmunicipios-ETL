# Plano de atualização dos dados

> **Este plano não foi executado.** Ele é o que uma instância nova do Claude Code precisa para pôr
> as 26 tabelas no dado mais recente e deixar cada fonte com um caminho de atualização
> programático.
>
> Para executar: [`PROMPT-EXECUCAO.md`](PROMPT-EXECUCAO.md).

## O problema, em três fatos medidos

**Uma das 26 tabelas tem caminho de atualização completo.** `00_diretorios/municipios` tem extração,
tratamento, manifesto com sha256 e bruto em `raw/`. As outras 25 param antes disso.

**Quinze dimensões não têm produtor nenhum.** Elas foram publicadas por
`tools/migracao/migrar_dimensoes.R`, que lia a árvore legada — e a árvore legada foi removida do
repositório em 26/07/2026. Atualizar os dados é, na prática, escrever os produtores que nunca
existiram.

**Nove fontes dependem de alguém baixar um arquivo à mão**, e cinco delas não têm nem o arquivo: o
manifesto existe, `arquivo_local` e `sha256` estão em branco. Duas fontes — `09_educacao/ideb` e
`09_educacao/censup` — não têm manifesto nenhum.

## Os arquivos

| arquivo | conteúdo |
|---|---|
| [`00-inventario-de-fontes.md`](00-inventario-de-fontes.md) | de onde cada uma das 26 tabelas vem, o que impede reobtê-la, as lacunas temporais e o que **não** é reobtenível |
| [`01-arquitetura-da-atualizacao.md`](01-arquitetura-da-atualizacao.md) | as regras: a escada de acesso, escopo parametrizado, o freio de custo, proveniência, a guarda de escrita |
| [`02-bigquery.md`](02-bigquery.md) | as fontes de BigQuery: descoberta grátis, o molde de extração, a ordem por custo e dependência |
| [`03-download-programatico.md`](03-download-programatico.md) | as fontes manuais, uma a uma: degrau-alvo, o que se sabe da origem, o que descobrir |
| [`04-fases-e-aceitacao.md`](04-fases-e-aceitacao.md) | as sete fases, com comandos e critérios de aceitação |
| [`PROMPT-EXECUCAO.md`](PROMPT-EXECUCAO.md) | o prompt de entrega, com a orquestração por subagentes |
| [`FONTES.csv`](FONTES.csv) | o inventário legível por código — mantido atualizado durante a rodada |

## A escada, que é a ideia central

Toda fonte é classificada num de cinco degraus, e o objetivo é subir todo mundo o mais alto
possível. Descer um degrau exige justificativa escrita no manifesto.

```
1. BigQuery / Base dos Dados     ← o alvo para a maioria
2. API oficial
3. HTTP com URL estável
4. Pacote R
5. Manual, com procedimento escrito passo a passo   ← aceitável, se declarado
```

O degrau 5 não é derrota. O que não se aceita mais é o estado de hoje em cinco fontes: arquivo sem
origem, sem data, sem hash e sem procedimento.

## O que este plano não faz

Não decide o que fazer com o **fator de bloco do PIB** (achado 1), com a **licença do FBSP** (achado
45), nem com a ampliação de `anos_painel`. As três são decisão do responsável, estão registradas em
`auditoria/RELATORIO-FINAL.md` § 5, e duas delas bloqueiam o release.

E não promete que tudo vira código: `15_dados_historicos` não é reobtenível — não há pacote de
replicação público de Kustov & Pardelli (2024), e a planilha do IBGE veio em CD-ROM. Para essa, a
saída é declarar, não automatizar.
