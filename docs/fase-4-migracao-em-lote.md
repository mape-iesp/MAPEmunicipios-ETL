# Fases 4 a 6 — Migração das dimensões restantes


> **Retrato do momento das fases 4 a 6, encerradas em 26/07/2026.** O "estado" logo abaixo é o daquele ponto da migração: treze dimensões migradas e três pendentes, quando hoje as dezesseis estão publicadas. "Zero erros de qualidade" e "zero diferenças não explicadas" também são medidas daquele momento, com a bateria de checagens e o teste de paridade como estavam então — a auditoria de 26/07/2026 reexaminou os dois. Os números não foram atualizados de propósito: um registro de fase vale como registro, e datá-lo é mais honesto do que reescrevê-lo. Para o estado atual, veja `auditoria/RELATORIO-FINAL.md` e `CLAUDE.md`.


Estado: **treze dimensões migradas e validadas**, com zero erros de qualidade e
zero diferenças não explicadas no teste de paridade. Três dimensões continuam
pendentes, pelos motivos descritos ao final.

---

## A decisão que tornou isso viável

As dezessete dimensões passam pela mesma transformação. Escrever dezessete
scripts quase idênticos repetiria exatamente o erro que produziu o legado, onde
o mesmo bloco de expansão de painel aparece copiado cinco vezes com faixas de
ano divergentes.

Em vez disso, `mape_migrar_do_legado()` faz o que é comum, e o que muda entre as
dimensões cabe em argumentos num único arquivo de configuração. A sequência é
sempre a mesma: normalizar a caixa dos cabeçalhos, descartar o bloco
territorial, renomear pelo dicionário, normalizar as chaves, converter
sentinelas, validar e publicar.

Antes de escrever isso, medi o tamanho do problema. Comparando os nomes de
coluna de cada artefato de dimensão com o dicionário, seis dimensões casavam
sem nenhuma órfã, seis tinham uma ou duas (todas sobras do bloco territorial), e
apenas duas davam trabalho de verdade. Foi essa medição que justificou o
migrador genérico.

---

## O que foi publicado

| Dimensão | Linhas | Colunas | Avisos |
|---|---|---|---|
| `01_assistencia_social_dh` | 67.406 | 16 | 0 |
| `02_populacao` | 179.930 | 9 | 0 |
| `04_economia` | 127.786 | 19 | 0 |
| `05_sociedade` | 111.300 | 10 | 0 |
| `07_recursos_humanos` | 66.824 | 17 | 0 |
| `08_energia_internet` | 111.288 | 12 | 1 |
| `09_educacao` | 111.388 | 37 | 2 |
| `10_saude` | 149.144 | 65 | 4 |
| `11_transportes` | 183.814 | 7 | 1 |
| `12_habitacao` | 94.832 | 8 | 1 |
| `13_seguranca` | 132.907 | 65 | 2 |
| `14_corrupcao` | 1.516 | 8 | 1 |
| `16_eleicoes` | 133.496 | 36 | 1 |

Mais `00_diretorios/municipios`, `01_assistencia_social_dh/cadunico` e
`01_assistencia_social_dh/disque100` na camada de fonte.

---

## Defeitos corrigidos durante a migração

**As linhas de chave nula foram eliminadas na origem**, na ordem que o plano
determina: primeiro remover na fonte, depois validar que não há mais nenhuma, e
só então confiar na unicidade. São 42 linhas na População, 81 nos Recursos
Humanos (das quais 80 são as linhas fantasma da planilha MUNIC de 2019, que
contêm apenas o caractere `-`) e 137 em Energia e Internet.

Inverter essa ordem seria o erro mais caro possível: remover a deduplicação
antes de limpar a origem multiplicaria por nove as linhas sem município no
artefato publicado.

**Vinte e cinco colunas da Segurança tiveram o tipo recuperado.** Elas estão
como texto na base publicada porque `seguranca.R` converte para numérico apenas
as colunas 3 a 38 de um objeto que tem 68 — tudo o que está depois da posição 38
fica como texto. Como o dicionário foi semeado a partir da base publicada, ele
herdou a declaração errada, e por isso a validação passou a acusar divergência.
A sincronização de tipos resolve isso e **registra a troca**, para que a
correção fique visível em vez de parecer que o dicionário sempre esteve certo.

**O bloco territorial saiu de todas as dimensões.** No legado ele é replicado
dentro de quatro dimensões e removido depois por índice numérico na etapa de
junção, com três intervalos diferentes. Agora ele existe só em `00_diretorios`.

---

## O que a validação encontrou e que ninguém sabia

**A cobertura vacinal do SI-PNI chega a 51.175%.** Eu conhecia o caso de 13.050%
na BCG; a coluna agregada é pior. A causa é o denominador da população-alvo,
subestimado, combinado com a ausência de truncamento na fonte. Os valores foram
mantidos e o domínio `[0,100]` declarado no dicionário, de modo que a validação
emite aviso a cada execução em vez de o problema ficar invisível.

**Três colunas `_prop` não são proporções.** `anatel_bl_densidade_sobre_capital_uf`,
`anatel_tm_densidade_sobre_capital_uf` e
`fbsp_mortes_intervencao_policial_sobre_mvi` são razões em relação a um
referencial, e podem legitimamente passar de 1 — um município pode ter 2,5 vezes
a densidade de acessos da capital. Chamá-las de proporção mente sobre o domínio.
Foi criado o sufixo `_razao` para esse caso.

**`margem_pct` das eleições tem valores que não passam de 1.** É uma proporção
com o sufixo trocado, o inverso do caso anterior. Passou a `margem_prop`.

Nenhum desses três seria detectável por inspeção visual. Os três apareceram
porque a checagem de coerência entre sufixo e escala é executável.

---

## Uma imprecisão minha, corrigida duas vezes

A checagem de sufixo passou por dois refinamentos, os dois motivados por casos
reais que ela classificou mal.

O primeiro separou **escala errada** (erro) de **valor fora da faixa** (aviso).
Uma coluna `_pct` cujos valores não passam de 1 é uma proporção mal rotulada; uma
taxa que chega a 128% continua sendo um percentual.

O segundo fez a checagem **deferir ao domínio declarado**. Quando o dicionário
declara `[0,100]` e o dado chega a 51.175, isso é um defeito conhecido da fonte,
já reportado pela checagem de domínio. Emitir um segundo erro pela mesma causa
não acrescenta informação e bloqueia uma publicação que deveria acontecer com
ressalva. O dicionário é a especificação, e uma declaração explícita é uma
afirmação deliberada de quem a escreveu.

---

## O teste de paridade, e por que ele é confiável

Treze dimensões, **zero diferenças não explicadas**.

O mecanismo que torna isso significativo está em `qa/paridade_esperada.csv`: as
correções são **reivindicadas antes de rodar o teste**. Um teste em que se pode
justificar qualquer diferença depois de ver o resultado não testa nada.

As reivindicações registradas cobrem três tipos de mudança: a recuperação de
tipo na Segurança, as colunas removidas de propósito por serem redundantes com o
diretório, e as linhas de chave nula eliminadas na origem.

---

## As três dimensões que faltam

**`03_meio_ambiente`** — dezoito colunas do AdaptaBrasil têm nome no artefato de
dimensão (`AB1.1` até `AB9.2`) diferente do nome na base publicada, porque foram
renomeadas posicionalmente na etapa 3 do legado. Reconstruir esse mapeamento
exige extrair o vetor de renomeação e casar por posição dentro do bloco da
dimensão — trabalho que precisa ser feito com cuidado, porque é justamente o
mecanismo posicional que a reestruturação existe para eliminar.

**`06_financas`** — vinte e cinco colunas de emendas parlamentares vêm de um
`pivot_wider` que gera nomes em Title Case com acento (`Comércio.e.serviços`,
`Ciência.e.Tecnologia`), também renomeados posicionalmente depois. O mesmo
problema, em maior escala.

**`15_dados_historicos`** — a tabela é estática, sem coluna de ano, com chave
`muncode` e 54 registros duplicados. Ela precisa de tratamento próprio, porque a
consolidação automática se recusa a juntar uma tabela sem ano ao painel: fazer
isso replicaria os valores em todos os anos, que é exatamente o defeito que
multiplica a série no legado.

Nenhuma das três é bloqueada por decisão pendente. As três precisam de trabalho
manual cuidadoso, e é melhor fazê-lo com atenção do que apressado.
