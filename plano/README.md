# Plano de Reestruturação do ETL do MAPEmunicipios

> **Este plano foi executado.** Ele está preservado como escrito, porque é o registro do
> raciocínio que produziu a estrutura atual — cada decisão, com o argumento e a evidência que a
> sustentaram.
>
> Para o que foi de fato entregue, leia [`docs/fechamento-etl.md`](../docs/fechamento-etl.md). Para
> operar o ETL no dia a dia, leia o [`README.md`](../README.md) da raiz.
>
> Onde o plano e o repositório divergirem, **o repositório manda**. Algumas coisas mudaram durante
> a execução, e as mudanças estão registradas em `docs/`.

## Por onde começar

Se você quer entender por que o ETL é como é, leia o **sumário executivo** e as **oito decisões
estruturais**. Eles contêm tudo que mudou; o resto é a justificativa e o detalhamento.

## Os arquivos

| Arquivo | Conteúdo |
|---|---|
| [prompt-original.md](prompt-original.md) | A especificação que originou este plano, preservada como foi escrita. Serve para conferir o que foi pedido contra o que foi entregue |
| [00-diagnostico-inventario.md](00-diagnostico-inventario.md) | Sumário executivo, diagnóstico do que verifiquei e onde o inventário anterior estava errado, e o levantamento das 17 dimensões |
| [01-modelo-e-convencoes.md](01-modelo-e-convencoes.md) | As oito decisões estruturais sobre o modelo de dados, a árvore de diretórios, a camada de funções comuns e a nomenclatura de colunas |
| [02-documentacao-e-atualizacao.md](02-documentacao-e-atualizacao.md) | O contrato de documentação, os procedimentos de atualização e a orquestração com `targets` |
| [03-versionamento-qa.md](03-versionamento-qa.md) | O que vai para o git e o que não vai, e o sistema de validação, incluindo o teste de paridade contra a base atual |
| [04-migracao-riscos.md](04-migracao-riscos.md) | As oito fases da migração, os riscos, as alterações necessárias no `CLAUDE.md` e as perguntas que ainda dependem de você |

## De onde veio o diagnóstico

O levantamento saiu da leitura do código legado em `mape_municipios/` (cerca de 18 GB, fora do
controle de versão), da inspeção dos arquivos `.RData` que cada dimensão produz, e do dicionário de
metadados em `6 Metadados/`.

Nenhum script legado foi executado. Vários deles consultam o BigQuery e geram cobrança real — o do
SICONFI sozinho baixa 18,5 milhões de linhas. Sempre que confirmar alguma coisa exigiria rodar uma
consulta paga, registrei o item como não verificado em vez de executar, e a lista completa desses
casos está na seção de diagnóstico.
