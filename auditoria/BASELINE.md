# BASELINE — o estado do repositório antes da rodada de correção

Medido em 26/07/2026, antes de qualquer alteração, na árvore do commit `0526316`.

Este documento é a rede de segurança da rodada de correção: é contra ele que o critério 7 da
§ 12 de `prompt-correcao.md` compara cada tabela publicada, para que nenhuma perda de linha,
coluna, chave ou município passe despercebida.

Tudo aqui foi **medido**, nada foi copiado de prosa. O script que mede está reproduzido no fim.

## 1. As 26 tabelas publicadas

`chaves distintas` é o número de pares `id_municipio` × `ano` únicos (ou de `id_municipio`
únicos, quando a tabela não tem coluna `ano`). Onde ele é menor que `linhas`, há chave
duplicada — as duas ocorrências (`06_financas`, `15_dados_historicos`) são intencionais e estão
registradas no CLAUDE.md.

| tabela | camada | linhas | colunas | chaves distintas | municipios | anos | sha256 parquet | sha256 csv.gz |
|---|---|---:|---:|---:|---:|---|---|---|
| `01_assistencia_social_dh` | dimensao | 67406 | 16 | 67.406 | 5.570 | 2011-2023 | `a3fcd77d57a3f2750a89a22af3562e3214b5b09fec2cedf264e334d3f5ee291a` | `039af5c1127b60f4a2adf4ea70ecd15f7f97ecd2c95b8d9b0c9282fc9f88def2` |
| `02_populacao` | dimensao | 179930 | 9 | 179.930 | 5.570 | 1991-2023 | `f8b5ee30957721417e105769b29f5d59bd369533ed6fc5e70232ec92c3236e44` | `687caa95ed966680d5563062b532f0c180e4075a453888220b90c85d59b3384e` |
| `03_meio_ambiente` | dimensao | 183810 | 77 | 183.810 | 5.570 | 1991-2023 | `fc4a28bca29f6cc78eebc6456eeb2b2b8a567484a0dba721ebd20ef1a55d1714` | `3d9963ef99c06b8b6316f7c9275fc7a09ddf19d58679167baae4ccbddad0152d` |
| `04_economia` | dimensao | 127786 | 19 | 127.786 | 5.570 | 1999-2021 | `207b8354f7aee9dd48e160c458828db70637f7276354debbc019e95f92a325f9` | `4c5a40bdfc7995cd2ee079b52c37ffc6ee17d99a72fac318d02e1076a11df3e9` |
| `05_sociedade` | dimensao | 111300 | 10 | 111.300 | 5.565 | 1996-2015 | `eca64bbd1551ae8214c7b6134473ff76d746e7b4ec12d9f4668341c9b79ba4cf` | `7e6366b5d73f3c1a19c93d7374eb86fa6488e2aff67c9bc45d0e5ce1acaf4a67` |
| `06_financas` | dimensao | 180023 | 39 | 179.788 | 5.570 | 1989-2024 | `b1e5aa7eec0d49faf321325ae95c7fbcca3eb497d5cad5e4bb52a8fd07149343` | `e8daf43a085e62e6786df20c1bff14295d4e51afb5c63e636eee8709151b1f46` |
| `07_recursos_humanos` | dimensao | 66824 | 17 | 66.824 | 5.570 | 2009-2023 | `9e945b9363708805abaf041e76bb0749b928d6ce4bae60dafdc2c4cbeb0ef2b4` | `1f82309eb3e8613a2c82e8775763d5a6298395d6d9525fb679c62a193a8743e8` |
| `08_energia_internet` | dimensao | 111288 | 12 | 111.288 | 5.570 | 2004-2024 | `423f3440eaf0f9c4bddb18bacc1fbce7e045a5d1389a8690cdc6ca04000196f0` | `44f775bbdda6361b5ece2df7ced49e15f25d2c66c73639f04fe617f5d3cf792d` |
| `09_educacao` | dimensao | 111388 | 37 | 111.388 | 5.570 | 2005-2024 | `8162b09c80d9828e933c4b43f0bfe78e0f48d97dc461844d69c7a5e27c479061` | `f7ced9b4ba2c0be5c2a259f3a75a911a986f7b976d1c4d620803235de4dbd3d5` |
| `10_saude` | dimensao | 149144 | 65 | 149.144 | 5.570 | 1994-2021 | `17019b21c70f49d31af05023c8266d9252e8324f00f89c3c16f6e69eb94fe464` | `0f89a9b769774e93f78beed30ee405af0c3e8698ae8631c69c587a123521d5dd` |
| `11_transportes` | dimensao | 183814 | 7 | 183.814 | 5.570 | 1991-2024 | `de9b5c771b6d826648638cd901afaf2815594d62a301a86ab4adad9041174c39` | `04c51174c61b0d21d844a4f644dc800742f7cec757dcdbff447d45b553bce6d4` |
| `12_habitacao` | dimensao | 94832 | 8 | 94.832 | 5.570 | 2007-2024 | `0b4315413575ffc9a19246f28417ec5371631797969c051bd99acfba127828e1` | `b216df7fbc0f637453268b812b0873d7c1516e22e8f043476e8943e707da79a5` |
| `13_seguranca` | dimensao | 132907 | 65 | 132.907 | 5.640 | 1996-2021 | `2538dd0379bbe41ec7960c9c536a62e33a1e5ee2b6ee5f1bf65f8dd8aee2e751` | `1d952e7b6ec00a78048fe77591fa0422a9396001809668cc0e89c7fea46211d6` |
| `14_corrupcao` | dimensao | 1516 | 8 | 1.516 | 1.352 | 2006-2018 | `522775460f90217c60e6401be16b7dbd7b74636c134d1adf7d8e0d4f06bb2143` | `e71315ff970dc2aa877e35eb329aaeb6bcc8b075eb56f27c19193ce7e32e7683` |
| `15_dados_historicos` | dimensao | 5646 | 9 | 5.592 | 5.592 | (sem ano) | `8fba71ea7dfbb68f66ce98e6b0b0222a36e5cc1e2e9d65bcde736e48623e0d8a` | `ef8cc7a05768d251e741cabceb36a80a8823eddd323dc1d8fc6512b48e01d948` |
| `16_eleicoes` | dimensao | 133496 | 36 | 133.496 | 5.568 | 2000-2023 | `48aa24ea544770fd7249b96598ed46549fba1262e40522bfa142bfaf09313a5d` | `b936266d027b992a2e973bb1275f599c010eea128924291c2deb67cf1e4ad90a` |
| `00_diretorios/municipios` | fonte | 5570 | 27 | 5.570 | 5.570 | (sem ano) | `10aaef0c65d866413ebc3bdc4d3d086d75809ddd4203b5d2c1724adb49117735` | `6c99c70747646ac6702e20570d83d4b687d63d4f83c713cc804ff5fb974c2bd6` |
| `01_assistencia_social_dh/cadunico` | fonte | 50130 | 10 | 50.130 | 5.570 | 2015-2023 | `53c81edaf73647cf15b086bf46009d194e5786a913f9e335914fed6671da5d02` | `e6acfba3502b5a535c5aa1e055acc4cef1fe4e2e59b6f994301173215d30342d` |
| `01_assistencia_social_dh/disque100` | fonte | 59990 | 8 | 59.990 | 5.567 | 2011-2023 | `421cee05a0fa7b0be22a61d33927b1ec553c1ff55f0df81241712f8079983803` | `fcc7f5f38099b58c21a89bfc605e28e51b34eb20972e3fd44830ea979edebab0` |
| `03_meio_ambiente/adaptabrasil` | fonte | 5570 | 19 | 5.570 | 5.570 | 2015-2015 | `3cfb2a56a133ec963f41650b4e1c5c4f55ef623bc30803fa92018c0dac35beab` | `7aaf2404b5c016daebd741c2b19ff9a8bee878f865f83ea1f19cd3900ff65207` |
| `05_sociedade/atlas_ivs` | fonte | 11130 | 9 | 11.130 | 5.565 | 2000-2010 | `c1b99356c99ba4fb4ddc2ebc225dec5f2b98f6e18637ff2949bcbc4b207afe1a` | `914a486647ec77abbffcd5f7d533a4868932f4392e70672e2be275cea57f879f` |
| `09_educacao/censup` | fonte | 10642 | 12 | 10.642 | 885 | 2009-2023 | `0fbac8446ffdce5c42381f39e99ad5c3daf39038f2659016597d9c797f032ea3` | `cb0a2cdf7709883fc40b9fad5d8d8f6b704ec945258c21870f0442d6d0441f75` |
| `09_educacao/ideb` | fonte | 55694 | 26 | 55.694 | 5.570 | 2005-2023 | `3d09dd69a7eb33397ed68916f2bbb1d1426b8cdd10ea1b497c406865920b0a0a` | `81d3c9e98dd17fcb1ea374f629318c14a1e56c299a6d96552ac41edb0e8a6cd0` |
| `11_transportes/tarifa_zero` | fonte | 578 | 4 | 578 | 106 | 1992-2024 | `3e02f5372a06d17464a33bf0cd1babc67425a261aed1db5cf62c532aa38d6a54` | `3ba5c35bf16fb099e6e40f3c3118c3b584a435b11fec984fe35a901c2aae0dd8` |
| `11_transportes/tarifas` | fonte | 351 | 5 | 351 | 27 | 2005-2017 | `acb9f114a17513aa2b15c149165ab4a4bff9bedb08cfb299afa4955c025a3dd0` | `718f888c74d49803f9515e1727c27b7811b91d0122b455ad7c36f29721fd024a` |
| `12_habitacao/mcmv_fgts` | fonte | 11153 | 8 | 11.153 | 4.610 | 2007-2024 | `6d496d91c20173acd91fd9956b8e814b526b2ba7e3f0df40730631655778dea7` | `6d7ea524f3b77957fce3c183328b6899551448a0ac33029d243a96b1a7b52b1a` |

Totais: **16 dimensões** e **10 tabelas de fonte**, 26 ao todo.

## 2. A suíte de testes

```
Rscript -e 'testthat::test_dir("tests/testthat")'
```

| | |
|---|---:|
| arquivos | 6 |
| expectativas que passam | **154** |
| falhas | 0 |
| avisos | 0 |
| pulados | 0 |

Distribuição por arquivo: `test-chaves.R` 24, `test-consumo.R` 29,
`test-documentacao-ingestao.R` 24, `test-io-dicionario-validacao.R` 32,
`test-painel-compactacao.R` 18, `test-sentinelas-joins-painel.R` 27.

O critério 5 da § 12 exige que a contagem final seja **maior** que 154.

**Efeito colateral conhecido** (achados 59 e 87): rodar a suíte reescreve o carimbo de data de
`qa/00_diretorios__municipios.md`, que é versionado. Confirmado nesta medição: `git status`
acusa o arquivo depois de `test_dir()`.

## 3. `mape_validar_tabela()` sobre as 26 tabelas

Medido com `mape_gravar_relatorio_qa()` neutralizada na sessão, justamente para **não** sujar
`qa/` — o que a função faz incondicionalmente (achado 59).

**Total: 2 erros e 25 avisos.** README, CLAUDE.md e `docs/` anunciam 23 avisos (achado 81).

| tabela | checagem | gravidade | descrição |
|---|---|---|---|
| `01_assistencia_social_dh` | schema | aviso | cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_pct: 59 valor(es) fora do domínio [0,100] (observado: 18.03 a 128.8) |
| `01_assistencia_social_dh/cadunico` | schema | aviso | cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_pct: 59 valor(es) fora do domínio [0,100] (observado: 18.03 a 128.8) |
| `06_financas` | chave_unica | erro | 222 chave(s) duplicada(s), 235 linha(s) excedente(s) |
| `06_financas` | schema | aviso | siconfi_receitas_proprias_sobre_receitas_brutas_prop: 4 valor(es) fora de [0,1]. |
| `09_educacao/censup` | cobertura_municipios | aviso | a tabela cobre apenas 15.9% dos municípios do diretório |
| `10_saude` | schema | aviso | pni_cobertura_vacinal_agregada_pct: 15378 valor(es) fora do domínio [0,100] (observado: 0.19 a 51175) |
| `10_saude` | schema | aviso | pni_cobertura_bcg_pct: 60527 valor(es) fora do domínio [0,100] (observado: 0 a 13050) |
| `10_saude` | schema | aviso | pni_cobertura_dtp_pct: 54466 valor(es) fora do domínio [0,100] (observado: 0 a 2900) |
| `10_saude` | schema | aviso | pni_cobertura_dtpa_gestante_pct: 2527 valor(es) fora do domínio [0,100] (observado: 0 a 10350) |
| `10_saude` | schema | aviso | pni_cobertura_febre_amarela_pct: 30809 valor(es) fora do domínio [0,100] (observado: 0 a 10100) |
| `10_saude` | schema | aviso | pni_cobertura_haemophilus_influenzae_b_pct: 5007 valor(es) fora do domínio [0,100] (observado: 0 a 1500) |
| `10_saude` | schema | aviso | pni_cobertura_hepatite_a_pct: 12023 valor(es) fora do domínio [0,100] (observado: 0 a 8150) |
| `10_saude` | schema | aviso | pni_cobertura_hepatite_b_pct: 59903 valor(es) fora do domínio [0,100] (observado: 0 a 12500) |
| `10_saude` | schema | aviso | pni_cobertura_penta_pct: 18830 valor(es) fora do domínio [0,100] (observado: 0 a 12500) |
| `10_saude` | schema | aviso | pni_cobertura_poliomielite_pct: 70103 valor(es) fora do domínio [0,100] (observado: 0 a 11250) |
| `10_saude` | schema | aviso | pni_cobertura_poliomielite_reforco_4a_pct: 3485 valor(es) fora do domínio [0,100] (observado: 0 a 341.67) |
| `10_saude` | schema | aviso | pni_cobertura_sarampo_pct: 17327 valor(es) fora do domínio [0,100] (observado: 0 a 2600) |
| `10_saude` | schema | aviso | pni_cobertura_tetra_viral_pct: 6384 valor(es) fora do domínio [0,100] (observado: 0 a 7250) |
| `10_saude` | schema | aviso | pni_cobertura_triplice_bacteriana_pct: 13556 valor(es) fora do domínio [0,100] (observado: 0 a 9000) |
| `10_saude` | schema | aviso | pni_cobertura_triplice_viral_dose1_pct: 62946 valor(es) fora do domínio [0,100] (observado: 0 a 9550) |
| `10_saude` | schema | aviso | pni_cobertura_triplice_viral_d2_pct: 12450 valor(es) fora do domínio [0,100] (observado: 0 a 7400) |
| `11_transportes/tarifa_zero` | cobertura_municipios | aviso | a tabela cobre apenas 1.9% dos municípios do diretório |
| `11_transportes/tarifas` | cobertura_municipios | aviso | a tabela cobre apenas 0.5% dos municípios do diretório |
| `13_seguranca` | dominio_chave | aviso | 70 código(s) fora do diretório em 352 linha(s) (0.265%). Exemplos: 1100000, 1200000, 1300000, 1400000, 1500000 |
| `14_corrupcao` | cobertura_municipios | aviso | a tabela cobre apenas 24.3% dos municípios do diretório |
| `15_dados_historicos` | chave_unica | erro | 54 chave(s) duplicada(s), 54 linha(s) excedente(s) |
| `15_dados_historicos` | dominio_chave | aviso | 27 código(s) fora do diretório em 27 linha(s) (0.478%). Exemplos: 1399902, 1599904, 2399903, 2399909, 2399910 |

Os dois erros são as duas chaves duplicadas intencionais. O critério 6 da § 12 aceita
exatamente esses dois e exige justificativa registrada para cada um dos avisos.

Distribuição dos 25 avisos: 16 em `10_saude` (coberturas do SI-PNI acima de 100), 4 de
`cobertura_municipios` (`09_educacao/censup`, `11_transportes/tarifa_zero`,
`11_transportes/tarifas`, `14_corrupcao`), 2 do domínio de `cadun_taxa_atualizacao_cadastral_*`
(a mesma coluna, contada na fonte e na dimensão), 2 de `dominio_chave` (`13_seguranca`,
`15_dados_historicos`) e 1 de domínio em `06_financas`.

## 4. Ambiente

| | |
|---|---|
| R | 4.5.2 |
| pacotes no `renv.lock` | **147** |
| `HEAD` no início da rodada | `0526316` |
| alvos no grafo | 14 |
| alvos já construídos | 9 (nenhum `dim_*`, nenhum `documentacao`, nenhum `base_larga`) |

## 5. O script que mediu

```r
suppressMessages({library(arrow); library(bit64); library(digest)})
dims   <- sort(list.files("dados/dimensao", pattern = "[.]parquet$", full.names = TRUE))
fontes <- sort(list.files("dados/fonte", pattern = "[.]parquet$", full.names = TRUE, recursive = TRUE))
for (p in c(dims, fontes)) {
  d <- as.data.frame(arrow::read_parquet(p))
  chaves <- if (all(c("id_municipio","ano") %in% names(d))) nrow(unique(d[, c("id_municipio","ano")]))
            else if ("id_municipio" %in% names(d)) length(unique(d$id_municipio)) else NA_integer_
  cat(basename(p), nrow(d), ncol(d), chaves, length(unique(d$id_municipio)),
      digest::digest(file = p, algo = "sha256"), "\n")
}
```

Para a validação, o mesmo laço sobre `mape_tabelas_publicadas()`, chamando
`mape_validar_tabela(x, slug, erro = FALSE)` com `mape_gravar_relatorio_qa` substituída por
`function(...) invisible(NULL)`.
