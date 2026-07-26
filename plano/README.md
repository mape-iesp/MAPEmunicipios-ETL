# plano/

Os planos do MAPEmunicipios, em duas pastas. A primeira é história executada; a segunda é trabalho
a fazer.

| pasta | o que é | estado |
|---|---|---|
| [`migracao-etl/`](migracao-etl/) | a reestruturação do ETL legado nesta árvore: diagnóstico, modelo de dados, convenções, versionamento e as oito fases da migração | **executado** — preservado como registro do raciocínio |
| [`atualizacao-dados/`](atualizacao-dados/) | pôr as 26 tabelas no dado mais recente, e dar a cada fonte um caminho de atualização programático | **a executar** |

Para operar o ETL no dia a dia, o ponto de partida é o [`README.md`](../README.md) da raiz e o
[`CLAUDE.md`](../CLAUDE.md). Para o estado do dado publicado, `auditoria/RELATORIO-FINAL.md`.

## Os arquivos mudaram de lugar em 26/07/2026

Os cinco documentos do plano de migração viviam na raiz de `plano/`. Como muita coisa aponta para
eles — inclusive os treze relatórios de auditoria, que são imutáveis e **não** foram reescritos —,
fica aqui o mapa:

| caminho antigo | caminho atual |
|---|---|
| `plano/README.md` | `plano/migracao-etl/README.md` |
| `plano/prompt-original.md` | `plano/migracao-etl/prompt-original.md` |
| `plano/00-diagnostico-inventario.md` | `plano/migracao-etl/00-diagnostico-inventario.md` |
| `plano/01-modelo-e-convencoes.md` | `plano/migracao-etl/01-modelo-e-convencoes.md` |
| `plano/02-documentacao-e-atualizacao.md` | `plano/migracao-etl/02-documentacao-e-atualizacao.md` |
| `plano/03-versionamento-qa.md` | `plano/migracao-etl/03-versionamento-qa.md` |
| `plano/04-migracao-riscos.md` | `plano/migracao-etl/04-migracao-riscos.md` |

Referências no texto a `plano/01`, `plano/02` e `plano/03` — comuns em `auditoria/`, no dicionário e
nos documentos gerados — apontam para os arquivos de `migracao-etl/` com o mesmo número.

## Como os dois planos se relacionam

A § 8 de [`migracao-etl/02-documentacao-e-atualizacao.md`](migracao-etl/02-documentacao-e-atualizacao.md)
já descrevia uma estratégia de atualização: acrescentar um ano, acrescentar uma fonte, acrescentar
uma dimensão, e o tratamento das fontes de download manual com `MANIFESTO.yml`.

Ela continua valendo, e `atualizacao-dados/` **não a substitui — a executa**. A diferença é que
aquele texto descrevia o procedimento supondo que os produtores existissem. Eles não existem: 15 das
26 tabelas não têm caminho de reconstrução nesta árvore, e a primeira extração de verdade só
aconteceu em 26/07/2026. `atualizacao-dados/` parte desse fato medido.
