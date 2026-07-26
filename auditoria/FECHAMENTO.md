# Fechamento da auditoria — cadeias causais, ordem de correção e veredito

Escrito em 26/07/2026, **antes** da primeira correção, a partir dos 105 grupos de
`CONSOLIDADO.md` e da medição de `BASELINE.md`. É este documento que define a ordem de trabalho
da rodada de correção.

A seção 7 (veredito sobre as sete afirmações centrais) é atualizada ao final da rodada, com o
estado pós-correção ao lado do estado inicial.

---

## 1. A leitura de conjunto

Os 105 grupos não são 105 defeitos independentes. São, em boa medida, **um mesmo defeito
estrutural manifestado em 105 lugares**, e a frase que o resume está no próprio prompt da rodada:
*afirmação sem checagem é defeito*.

O repositório foi construído sobre uma disciplina declarada — chave tipada, sufixo de vocabulário
fechado, dicionário como especificação, validação como portão, paridade como prova. Cada uma
dessas promessas foi escrita em prosa, em vários lugares, com convicção. Nenhuma delas foi
escrita em código que falhe quando a promessa for violada.

O resultado é assimétrico de um jeito característico: **a documentação descreve um sistema mais
rigoroso do que o que existe, e o dado publicado é pior do que a documentação admite.** Os dois
erros se somam em vez de se cancelarem, porque quem lê a documentação não tem motivo para
desconfiar do dado, e quem mede o dado não encontra na documentação o registro do que mediu.

Três números medidos hoje resumem o tamanho do buraco:

| medida | valor |
|---|---|
| tabelas publicadas que um alvo do grafo reproduz como publicadas | **3 de 26** |
| caminhos de escrita que rodam as checagens de qualidade | **0** |
| tabelas gravadas com validação desligada | **23 de 26** |

---

## 2. As nove cadeias causais

Agrupei os 105 por **raiz compartilhada**, não por severidade nem por arquivo. Corrigir a raiz de
uma cadeia fecha vários grupos de uma vez; corrigir grupo a grupo sem ver a cadeia produz
remendo que volta.

### Cadeia A — Não existe portão de escrita (13 grupos)

**Grupos:** 6, 22, 9, 31, 38, 39, 44, 59, 60, 83, 85, 87, 42

**Raiz:** `mape_escrever_tabela()` chama `mape_validar_schema()`, que é uma checagem de tipos, e
nunca `mape_validar_tabela()`, que é a bateria de qualidade. As doze checagens do plano existem
como função que ninguém invoca no caminho de publicação. Somado a isso,
`mape_consolidar_dimensao()` grava com `publicar = TRUE` por padrão e `validar = FALSE`, sem
comparar com o que já está publicado.

**Como se propaga:** o achado 6 (crítico) é o sintoma agudo — `tar_make(dim_11_transportes)`
troca 183.814 linhas por 929 e ninguém é avisado. O 22 é a promessa falsa que o encobre ("erro
impede a publicação, sem exceção"). O 31 e o 83 são o selo de qualidade emitido sobre tabelas
defeituosas. O 38 é a cláusula de justificativa que nunca foi escrita. O 59, 60 e 87 são a suíte
sujando a árvore e passando vacuamente, ou seja, a rede de segurança da rede de segurança
também não segura.

**Correção da raiz:** um portão real em `mape_escrever_tabela()` — validação de qualidade *mais*
comparação contra a tabela publicada, com erro em caso de perda. Feito isso, 6, 22, 39 e boa
parte de 9, 31, 44 e 85 caem juntos.

**Esta é a cadeia que vem primeiro, e o achado 6 vem primeiro dentro dela**, porque enquanto ela
estiver de pé qualquer outro passo da rodada pode destruir dado.

### Cadeia B — O dicionário descreve outra coisa que não o dado (16 grupos)

**Grupos:** 7, 18, 23, 30, 35, 36, 43, 48, 50, 55, 56, 63, 76, 92, 101, 102

**Raiz:** o dicionário é editado à mão e nunca confrontado com o Parquet que ele diz especificar.
Não há checagem de descrição, de coerência entre sufixo e `unidade`, nem de cobertura
(coluna publicada sem linha, linha sem coluna).

**Como se propaga:** sete descrições de `06_financas` são as descrições do PIB de `04_economia`
deslizadas em bloco (18) porque um bloco foi colado com deslocamento de linha e nada comparou.
A checagem que teria pego isso é a "checagem 12", anunciada e nunca implementada (23). Brancos e
nulos de prefeito estão trocados (30). `variacao_absoluta_area_desmatada_km2` é percentual
publicado como km² (7, crítico) porque nenhum sufixo físico é verificado. 27 variáveis não têm
descrição nenhuma (56). Os campos calculados `minimo`/`maximo` do PIB são padrão de bits (35) e
os de `id_municipio`/`ano` descrevem a tabela errada (36).

**Correção da raiz:** implementar a checagem 12 por similaridade, a checagem sufixo × `unidade`,
a checagem de descrição vazia e a de discriminante do nome; corrigir `mape_recalcular_campos()`
para `integer64` e para o casamento (`nome_canonico`, `tabela`). Depois disso, as edições de
conteúdo (18, 30, 50, 56, 63, 92) são trabalho mecânico com rede.

### Cadeia C — Vazio publicado como zero (9 grupos)

**Grupos:** 4, 5, 15, 16, 21, 27, 29, 49, 75

**Raiz:** duas fontes distintas de zero falso, que se somam. Primeira, `sum()` sobre subconjunto
vazio devolve `0` e não `NA` — é a origem das seis colunas do SICONFI (4, 5, ambos críticos).
Segunda, a expansão do painel preenche com zero o retângulo município × ano inteiro, inclusive
onde a fonte não cobre e inclusive onde o município ainda não existia (15, 27, 29).

**Como se propaga:** `pct_na` grava 0,26% para uma coluna que é 97% vazia, então a especificação
afirma que a coluna está completa. `mape_cobertura()` conta zero como dado e chega a reportar
100% onde a cobertura real é de 27 municípios (21). Nenhuma checagem olha proporção de zeros, e
por isso 12_habitacao recebe QA limpo com totais fisicamente impossíveis (16).

**Correção da raiz:** uma checagem de zero-inflação e janela efetiva por coluna, mais os campos
calculados `pct_zero` e `janela_efetiva` no dicionário. Ela sozinha detecta 4, 5, 15, 16, 27 e 29.

### Cadeia D — O painel é replicado sem marcador, e o caminho de volta não executa (8 grupos)

**Grupos:** 10, 14, 17, 33, 34, 58, 78, 79

**Raiz:** `mape_expandir_painel()` quebra em qualquer tabela que já tenha coluna `ano`
(`painel.R:82-86`), então o caminho declarado de expansão nunca roda; as dimensões publicadas
foram expandidas pelos scripts de migração, que não emitiram as flags que o plano promete. O
resultado é um painel em que medição e replicação são indistinguíveis.

**Como se propaga:** `03_meio_ambiente` repete o retrato de 2015 de 2010 a 2020 sem marcador
(17). `vulnerabilidade_socioeconomica_pct` é uma medição só publicada como dois censos (14).
A fonte "canônica" `tarifa_zero` já vem expandida com 81,7% de carry-forward e a evidência
apagada (33). E `metodo = "replicar"` faz produto cartesiano silencioso quando há mais de um ano
medido (58).

### Cadeia E — A paridade não prova o que promete (6 grupos)

**Grupos:** 24, 25, 40, 66, 67, 68

**Raiz:** três furos independentes na mesma função: ausência conta como igualdade, número de
linhas não é comparado, e o curinga `*` imuniza 52,5% das colunas. Somados, "zero diferenças não
explicadas" é uma frase que não tem conteúdo verificável.

### Cadeia F — Números em prosa que ninguém remede (13 grupos)

**Grupos:** 11, 53, 54, 64, 70, 72, 81, 89, 95, 96, 97, 98, 103

**Raiz:** o repositório digita números na documentação em vez de gerá-los. Todo número digitado
apodrece; o mecanismo de campo calculado que o dicionário já tem nunca foi estendido à prosa.

**Como se propaga:** 128 pacotes contra 147 reais (95); 23 avisos contra 25 (81, confirmado por
medição hoje); "440 colunas e 16 dimensões" contra 423 e 15 (11); 5 de 8 números errados no
quadro de encerramento (96); "células vazias" com dois valores diferentes no mesmo minuto (64);
seis comandos `tar_make()` que não executam (70).

### Cadeia G — O dado veio errado da origem e a origem não foi reconsultada (10 grupos)

**Grupos:** 1, 2, 3, 8, 12, 13, 28, 47, 52, 5

**Raiz:** defeitos herdados do pipeline legado que a migração transportou fielmente — e a
paridade, por medir fidelidade e não plausibilidade, atestou como corretos.

**Como se propaga:** o PIB tem três quebras de nível por empilhamento de séries na origem (1); o
VAB de serviços muda de definição em 2002 (2); a receita do SICONFI soma estágios e hierarquia
(3); os `_brl2023` do IEPS estão em reais de 2021 (8); 70 códigos não municipais inflam a soma
nacional de homicídios (12) e os 30 pseudo-códigos do Rio deixam 1996-1998 97% subestimado (13);
nove municípios têm população extrapolada linearmente (28); 17 células sob `_km` estão em metros
(52).

**Dependência externa:** 1, 2 e 8 exigem a origem. **O teste de fumaça do BigQuery passou** (ver
§ 5), então essa rota está aberta para `br_ibge_pib`. 12 e 13 **não** exigem a origem: o dado
está publicado na própria tabela e o conserto é uma reagregação.

### Cadeia H — Chave e código não são o que o contrato diz (5 grupos)

**Grupos:** 19, 20, 57, 100, 103

**Raiz:** o contrato de tipo de chave está declarado em `config/parametros.yml` e **nenhuma
função o lê**. Sem leitor, o contrato é decoração.

**Como se propaga:** `mape_tratar_sentinelas()` converte `id_municipio` para double e o scaffold
oficial faz isso em toda fonte nova (20); `mape_como_codigo()` fabrica código bem-formado a
partir de qualquer entrada curta (57); `mape_id7_de_id6()` resolve ambiguidade pelo primeiro
casamento (100); sete colunas de dinheiro declaradas `integer` estouram o int32 e 23.761 células
viram `NA` no csv.gz (19); `id_municipio` volta como `integer` em qualquer `read.csv()` (103).

### Cadeia I — Infraestrutura que promete e não entrega (9 grupos)

**Grupos:** 41, 45, 46, 61, 69, 77, 80, 84, 86, 90, 105

**Raiz:** dispersa; são promessas locais em roxygen, scaffold e hook que não têm implementação
correspondente. Não compartilham raiz técnica, mas compartilham a patologia da rodada.

### Os 8 não confirmados

**Grupos:** 65, 74, 75, 82, 88, 91, 93, 94. Nenhuma correção de defeito é devida. Confirmo a
conclusão do verificador em cada um e registro no ledger. Vale destacar o **88**, porque ele
contradiz uma instrução da rodada: o verificador mediu que o identificador GCP está em **3**
commits (não 6 — o 6 era artefato de um ref remoto obsoleto) e **recomenda explicitamente não
reescrever o histórico**. Isso é tratado na § 6.

---

## 3. Contradições entre relatórios

Três, e o consolidado já resolveu duas:

1. **Achado 8 contra a proposta do próprio auditor.** O auditor A11 propôs trocar
   `deflator_sufixo` para `brl2021` globalmente; o verificador mostrou que isso renomearia 73
   colunas das quais 70 não estão em 2021. A correção certa é pontual (3 colunas do IEPS).
   **Prevalece o verificador.**
2. **Achado 47 sobre o Rio.** O auditor incluiu o Rio de Janeiro no descolamento contra o FBSP;
   o verificador mostrou que a evidência estadual não sustenta. **Escopo restrito a São Paulo,
   2018-2019.**
3. **Achado 88 contra a § 10 do prompt de correção.** O verificador conclui "não reescrever o
   histórico"; o prompt autoriza e instrui a reescrita. Não é contradição entre auditores, é
   entre a auditoria e a decisão do responsável. Ver § 6.

E uma contradição **dentro** do consolidado, que registro: o grupo 72 recomenda "não reescrever o
histórico" para os blobs do CadÚnico, com análise de custo-benefício; a § 10 do prompt manda
purgá-los. Mesma situação do 88.

---

## 4. Lacunas de cobertura da auditoria

O que os treze auditores **não** olharam, e que esta rodada deve evitar quebrar às cegas:

- **`dist/v1.0.0/`** foi olhado só de raspão (achados 65, 97). O release carrega cópias dos
  defeitos de dicionário; toda correção de dicionário exige remontar `dist/`.
- **`tools/migracao/`** foi lido como evidência histórica, não auditado como código. Como ele é a
  origem de 23 das 26 tabelas, os defeitos que produziu estão nos dados e não nos scripts.
- **Interação entre correções.** Nenhum auditor mediu o que acontece quando duas correções tocam
  a mesma tabela. É por isso que o `BASELINE.md` existe.
- **`16_eleicoes`, `07_recursos_humanos` e `14_corrupcao`** receberam menos escrutínio de dado que
  `04_economia`, `06_financas`, `10_saude` e `13_seguranca`.

---

## 5. A ordem de correção, com dependências

Quatro blocos. Dentro de cada bloco, CRÍTICO → ALTO → MÉDIO → BAIXO.

### Bloco 0 — Segurança (bloqueia tudo o mais)

| ordem | grupo | por quê vem antes |
|---:|---|---|
| 1 | **6** | enquanto não houver guarda de perda, qualquer passo pode destruir dado |
| 2 | freio do BigQuery (§ 6 do prompt) | nenhuma consulta antes do dry-run e do teto |

O achado 6 puxa junto a implementação da guarda de perda em `mape_escrever_tabela()`, que é a
mesma peça exigida por 9 e 22.

### Bloco 1 — Portões e checagens (a infraestrutura que os demais usam)

Grupos **22, 39, 38, 23, 31, 83, 59, 60, 87, 44, 85, 80, 86** e as checagens novas exigidas por
2, 4, 5, 14, 16, 27, 28, 29, 49, 52, 54, 56.

**Por que antes das correções de dado:** cada checagem nova é o teste que prova a correção de
dado correspondente. Escrever a correção primeiro e a checagem depois inverte a ordem da prova.

### Bloco 2 — Dado publicado

- **Sem dependência externa:** 7, 12, 13, 19, 29, 15, 16, 52, 2 (marcação), 4, 5 (marcação).
- **Com dependência do BigQuery:** 1, 8, e o que 2 e 3 permitirem.
- **Bloqueado por insumo ausente:** 16 (a planilha original do MCMV não está no repositório),
  14 (exige o Atlas do IVS), 27 (exige o calendário de vigência das vacinas), 28 (exige as
  estimativas do IBGE).

### Bloco 3 — Dicionário, documentação e números

Todo o resto: cadeias B (parte de conteúdo), E, F, I. **Por último, por construção**, porque os
números só podem ser remedidos depois que o dado e o código pararem de mudar.

### Bloco 4 — Fechamento

`tools/verificar_fechamento.R`, remontagem de `dist/`, histórico do git, relatório final.

---

## 6. As decisões que tomei sem poder perguntar

Registradas aqui porque a § 11 do prompt manda registrar, e porque afetam o resultado.

**(a) Histórico do git (grupos 72 e 88).** A auditoria recomenda não reescrever; o prompt manda
reescrever. Vou seguir o prompt, que é a decisão do responsável, **mas** com uma correção de
fato que o próprio verificador estabeleceu: o alvo é 3 commits e não 6. Registro a divergência
no relatório final para que a decisão possa ser revista com o número certo.

**(b) Escopo do achado 8.** Aplico a correção do verificador (3 colunas do IEPS), não a do
auditor (73 colunas). A do auditor renomearia colunas corretas.

**(c) Onde a auditoria oferece duas rotas, escolho a que não muda valor publicado.** Exemplo: no
grupo 2, entre "publicar as quatro participações de 1999-2001 como `NA`" e "criar
`flag_serie_antiga`", escolho a flag — ela marca sem destruir, que é a decisão declarada do
responsável ("marcar, não remover").

---

## 7. Veredito sobre as sete afirmações centrais do projeto

Coluna "antes" medida em 26/07/2026 sobre o commit `0526316`. Coluna "depois" preenchida ao final
da rodada.

| # | afirmação | antes | depois |
|---:|---|---|---|
| 1 | **Chave.** `id_municipio` é texto de 7 dígitos e `ano` é inteiro, em toda tabela publicada | ⚠️ **verdadeiro no dado, não garantido pelo código.** O contrato está em `config/parametros.yml` e nenhuma função o lê; três funções o violam ativamente (20, 57, 100) e o csv.gz o quebra na releitura (103) | *(a preencher)* |
| 2 | **Sufixo.** O vocabulário fechado permite à validação *provar* a unidade | ❌ **falso.** A prova existe para 4 dos 15 tokens (73). `_km2` não tem checagem, e é exatamente aí que está o achado crítico 7 | *(a preencher)* |
| 3 | **Dicionário como especificação.** É lido pelo código e é a fonte de verdade | ⚠️ **metade verdadeiro.** É de fato lido para renomear, tipar e gerar documentação; mas nada confronta o que ele afirma com o que o Parquet contém, e por isso ele carrega descrições de outra tabela (18), nomes que mentem sobre a unidade (7, 48) e 27 variáveis sem descrição (56) | *(a preencher)* |
| 4 | **Campos calculados.** São reescritos do dado a cada execução e por isso não apodrecem | ⚠️ **verdadeiro no mecanismo, falso no resultado.** O mecanismo roda, mas grava padrão de bits para `integer64` (35) e escreve na linha da tabela errada quando o nome é compartilhado (36) | *(a preencher)* |
| 5 | **Fonte canônica.** A camada de fonte guarda o dado como foi observado | ❌ **falso em pelo menos dois lugares.** `tarifa_zero` já vem expandida com 81,7% de carry-forward (33) e `raw/cadunico.csv` é a saída do pipeline legado, não o bruto (46) | *(a preencher)* |
| 6 | **Paridade.** Zero diferenças não explicadas contra o pipeline antigo | ❌ **falso, e mais fraco do que parece.** Ausência conta como igualdade (24), linhas não são comparadas (67), o curinga imuniza 52,5% das colunas (66) e `15_dados_historicos` nunca passou e não pode passar (25) | *(a preencher)* |
| 7 | **Documentação gerada.** Os arquivos gerados descrevem fielmente o dado | ❌ **falso.** 5 das 7 tabelas com defeito declarado recebem "as doze checagens passaram" (31); dois documentos gerados no mesmo minuto dão valores diferentes para a mesma métrica (64); 83 colunas publicadas não têm linha na documentação da sua tabela (43) | *(a preencher)* |

**Placar inicial: nenhuma das sete se sustenta como escrita.** Duas são verdadeiras no dado mas
não garantidas pelo código (1, 4), uma é meia verdade (3), e quatro são falsas (2, 5, 6, 7).
