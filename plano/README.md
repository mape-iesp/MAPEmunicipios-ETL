# Plano de Reestruturação do ETL do MAPEmunicipios

Este é um documento de plano. Nada foi implementado, e ele foi escrito para ser executado aos
poucos, ao longo de várias sessões, tanto por quem já conhece o projeto quanto por quem chegar
depois sem contexto nenhum.

## Por onde começar

Se você tem quinze minutos, leia o **sumário executivo** e as **oito decisões estruturais**. Eles
contêm tudo que muda; o resto do documento é a justificativa e o detalhamento.

Se você vai executar, comece pela **Fase 0**. Ela leva menos de uma hora, não depende de nenhuma
decisão pendente, e resolve dois problemas urgentes: a árvore legada de 18 GB está desprotegida
contra um `git add` distraído, e o diretório `.git` carrega 15 GB de lixo recuperável.

## Os arquivos

| Arquivo | Conteúdo |
|---|---|
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
