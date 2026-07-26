# Eleições: microdados do TSE de 2022 e 2024 não migram

**Fonte:** `16_eleicoes/tse_2022_2024`  
**Registrado em:** 2026-07-26

## O que impede

São 1,28 GB de CSVs em disco que nenhum script do repositório referencia. A lista de anos eleitorais está fixada como seq(2000, 2020, by = 4), então a série para em 2020 mesmo com o dado de 2024 já baixado.

## Evidência

17 Eleições - Códigos e Dados/{2024/, 2022/}

## O que se perde

As eleições municipais de 2024 ficam de fora do painel. Decisão registrada: a atualização dos dados é uma segunda etapa do trabalho.

## O que seria preciso para recuperar

A faixa de anos já está parametrizada em config/parametros.yml (anos_eleicao). Estender passa a ser editar uma linha, mais conferir se o layout dos microdados de 2024 bate com o dos anteriores.

*(Errata de 26/07/2026, achado 104 da auditoria: `anos_eleicao` está em `config/parametros.yml` mas **não tem consumidor** — nenhuma função o lê, porque não existe `tratar_*.R` para 16_eleicoes e a tabela publicada veio dos scripts de migração. Editar a linha não muda nada hoje. O parâmetro fica reservado para quando o script do TSE existir.)*

