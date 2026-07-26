# Fase 1 — Fundação

Registro do que foi construído, do que foi decidido durante a construção e do
que ficou pendente. Escrito para que você consiga validar depois sem precisar
reconstituir o raciocínio.

O plano previa que a Fase 1 entregasse "o mínimo de infraestrutura que a Fase 2
exercita de verdade". É o que está aqui: dez módulos de função, oitenta testes,
um dicionário semeado com 434 variáveis e a primeira tabela publicada de ponta a
ponta.

---

## O que existe agora

```
MAPEmunicipios.Rproj          âncora do here()
_targets.R                    grafo, gerado a partir do dicionário
config/parametros.yml         todas as constantes do pipeline
.Renviron.exemplo             molde da credencial

R/                            camada de funções comuns
├── parametros.R              mape_param, mape_caminho, mape_anos_painel
├── chaves.R                  normalização e validação de id_municipio e ano
├── sentinelas.R              conversão de "NaoDisponivel" e afins em NA
├── io.R                      leitura e escrita, Parquet canônico
├── dicionario.R              o dicionário como entrada do pipeline
├── joins.R                   junções com cardinalidade declarada
├── painel.R                  esqueleto e expansão, com marca de imputação
├── deflacao.R                deflação que não sobrescreve o nominal
├── bigquery.R                billing configurável e registro de proveniência
└── validacao.R               as doze checagens da seção 11.2 do plano

dicionario/
├── dimensoes.csv             17 dimensões, vocabulário controlado
├── tabelas.csv               1 tabela registrada
├── variaveis.csv             434 variáveis
└── deprecacao.csv            174 renomeações

fontes/00_diretorios/municipios/R/
├── extrair_municipios.R      escrito, NÃO executado (ver princípio abaixo)
└── tratar_municipios.R       produz a tabela publicada

dados/fonte/00_diretorios/
├── municipios.parquet        503 KB, canônico
└── municipios.csv.gz         289 KB, exportação

qa/00_diretorios__municipios.md   relatório de qualidade

tests/testthat/               80 testes, 0 falhas
tools/migracao/               scripts de semeadura, rodam uma vez
```

---

## O princípio que governou tudo

Esta etapa **reestrutura o código e não atualiza os dados**. A tabela do
diretório foi produzida a partir do artefato que já existia (`diretorios.xlsx`),
e não de uma extração fresca do BigQuery.

A razão não é só economia. É que o teste de paridade contra a base publicada só
funciona se **uma variável mudar por vez**. Com o dado congelado, qualquer
diferença encontrada é atribuível ao código. Se a fonte fosse reextraída junto,
uma diferença poderia ser correção de defeito ou número novo publicado pela
fonte, e não haveria como distinguir.

Consequência visível na árvore: `extrair_municipios.R` existe, está completo e
documentado, e **nunca foi executado**. A primeira execução dele será o primeiro
teste real do procedimento de atualização.

---

## A camada de funções

Cada módulo elimina uma classe inteira de defeito encontrada no legado. A tabela
abaixo liga a função ao problema que ela resolve, porque sem isso as escolhas
parecem arbitrárias.

| Função | O que existe no legado e ela substitui |
|---|---|
| `mape_billing_id()` | 4 projetos GCP escritos dentro do código, em ~28 chamadas |
| `mape_query()` | nenhum registro de data de extração em lugar nenhum do projeto |
| `mape_deflacionar()` | 8 chamadas com `"12/2023"` no código, sobrescrevendo o nominal |
| `mape_normalizar_chaves()` | 12 coerções `as.character(ano)` espalhadas pela junção |
| `mape_id7_de_id6()` | recuperação do código de 7 dígitos com não-casados virando NA em silêncio |
| `mape_validar_dominio_chave()` | 27 códigos de UF e 27 `muncode` extintos sumindo no `left_join` |
| `mape_join()` | 16 junções sem `relationship`, sem `stopifnot`, sem contagem |
| `mape_esqueleto_painel()` | o mesmo bloco copiado 5 vezes, com faixas de ano divergentes |
| `mape_expandir_painel()` | expansão sem nenhuma marca de imputação |
| `mape_tratar_sentinelas()` | `indice_risco_seca` numérica e a coluna irmã como texto |
| `mape_escrever_tabela()` | `write.csv` sem `row.names = FALSE`, que produz a coluna fantasma |
| `mape_aplicar_renomeacao()` | o vetor posicional de 451 nomes |
| `mape_validar_tabela()` | nenhuma validação de nenhum tipo |

### Duas decisões de implementação que merecem registro

**`mape_como_codigo` devolve `NA` em vez de código truncado.** Um código que,
depois de limpo, não tem o número de dígitos esperado vira `NA` e é contabilizado
num aviso. Devolver um código pela metade seria pior, porque ele casaria com o
município errado numa junção.

**`mape_join` recusa juntar quando os tipos da chave divergem.** No legado, tipo
incompatível produz junção vazia sem erro, e essa é a causa mais comum de defeito
silencioso — a coluna `ano` alterna entre texto, numérico, inteiro e `integer64`
conforme a dimensão.

---

## Bugs encontrados durante a construção

Os quatro foram pegos pelos próprios testes ou pela execução, não por revisão.

**`formatC(x, flag = "0")` sobre vetor de texto preenche com espaço, não com
zero.** O código de município saía como `" 110015"` e era rejeitado como
inválido logo em seguida. Qualquer código que tivesse perdido o zero à esquerda
seria silenciosamente descartado. Corrigido com preenchimento manual.

**`basedosdados::get_billing_id()` devolve `FALSE` quando não há projeto
configurado, em vez de dar erro.** Sem checagem de tipo, `mape_billing_id()`
sairia com o literal `"FALSE"` no lugar do identificador do projeto.

**A regex de inferência de escala não reconhecia o sufixo `_prop`.** A convenção
nova usa `_prop` como sufixo, e minha regex só reconhecia `prop_` como prefixo.
Trinta variáveis ficaram sem escala inferida até eu notar.

**O levantamento de nomes devolvia instruções misturadas com nomes.** Oito
propostas eram a palavra `remover`, que teria virado uma coluna publicada
chamada "remover". Viraram um campo `acao` separado.

---

## O dicionário

Semeado a partir do `mape_municipios DICIONÁRIO.xlsx`, que é a única peça de
documentação do projeto validada contra o dado real. Confirmei no início da
semeadura, com `stopifnot`, que o campo `Nome_banco` é `identical()` aos nomes
das colunas da base publicada, na mesma ordem.

São **434 variáveis** — as 451 da base menos as 17 flags `dimensao_*`, que deixam
de existir.

### O que é calculado e o que é digitado

Esta separação é a que resolve, sozinha, uma classe inteira de erro. Os campos
`tipo_real`, `pct_na`, `n_distintos`, `minimo`, `maximo` e `n_infinito` saem do
dado publicado, medidos. Os campos `descricao`, `licenca` e `periodicidade`
descrevem intenção e só uma pessoa pode preenchê-los.

É exatamente nos campos que hoje são digitados que os números não fecham: a soma
das variáveis declaradas dá 533 contra 451 reais, e o artigo declara 182.407
observações contra 180.285 — este último, aliás, é a contagem **antes** da
deduplicação, o que sugere que foi apurado na etapa errada do pipeline.

### O que foi inferido, e com que confiança

| Confiança | Variáveis | Significado |
|---|---|---|
| alta | 157 | o nome e a faixa observada concordam |
| média | 215 | a regra se aplicou bem; confirmar ao migrar a dimensão |
| baixa | 62 | sem pista suficiente, precisa de olho humano |

**124 variáveis (29%) estão marcadas com `revisao_pendente = TRUE`.** É a lista
curta do que precisa ser olhado antes de publicar, e os motivos são:

| Motivo | Quantas |
|---|---|
| inferência de escala ou unidade incerta | 40 |
| tipo declarado divergia do tipo real | 50 |
| sem descrição no legado | 34 |

As 50 divergências de tipo são um achado por si só. `flag_capital_uf`,
`flag_amazonia_legal`, `ano` e as colunas `snis_populacao_atendida_*` estão como
**texto** na base publicada, quando deveriam ser numéricas. Isso é consequência
do acoplamento posicional: `seguranca.R` converte para numérico as colunas 3 a 38
de um objeto que tem 68, e o que está depois da posição 38 fica como texto.

### Correção ao plano: os infinitos não existem

O plano listava `log_pib` com `-Inf` entre os defeitos a corrigir logo, por causa
de `log10()` aplicado sem tratar zeros. **Medi na base publicada e não há nenhum
valor infinito** nas três colunas `log_*`. A razão é que nenhum município-ano tem
PIB igual a zero: o filtro `>= 0` permite, mas o dado nunca exerce.

O defeito é **latente, não manifesto**. Continua valendo corrigir, porque
reapareceria numa reextração, mas ele sai da lista de correções urgentes. A
checagem de valores infinitos entrou na validação para que, se um dia aparecer,
apareça com aviso.

---

## A primeira tabela publicada

`00_diretorios/municipios` — 5.570 linhas, 27 colunas, 503 KB em Parquet.

Passou nas doze checagens sem nenhum erro nem aviso. Conferências de sanidade
que fiz além do QA: 27 capitais (26 estaduais mais o Distrito Federal), 772
municípios na Amazônia Legal, chave única, nenhum código nulo, e o CSV exportado
sem a coluna fantasma.

Quatro colunas mudaram de nome, cada uma por um motivo verificável:

| Antes | Depois | Por quê |
|---|---|---|
| `nome` | `nome_municipio` | genérico demais, e colide com a coluna `nome` que vaza do IEPS na Saúde |
| `capital_uf` | `flag_capital_uf` | é booleano; o prefixo o torna somável e verificável |
| `amazonia_legal` | `flag_amazonia_legal` | idem |
| `centroide` | `centroide_wkt` | o nome passa a dizer que é geometria em texto |

---

## O orquestrador

Os alvos **não são escritos à mão**: `_targets.R` os gera a partir de
`dicionario/tabelas.csv`. Acrescentar uma fonte é acrescentar uma linha no
dicionário e um script `tratar_<nome>.R` — nunca editar o `_targets.R`.

Isso importa porque o público são bolsistas rotativos, e um arquivo de
orquestração que cresce a cada fonte vira uma barreira de entrada.

```r
targets::tar_make()                                  # o que estiver desatualizado
targets::tar_make(fonte_00_diretorios_municipios)    # uma fonte só
targets::tar_visnetwork()                            # desenha o grafo
```

Confirmei a incrementalidade: na segunda execução, quatro dos cinco alvos foram
pulados.

---

## O que ficou pendente

**O `renv` ainda não foi inicializado.** Deixei para o fim de propósito:
`renv::init()` altera o `.Rprofile` e passa a resolver pacotes pela biblioteca do
projeto, o que interromperia o trabalho em andamento se rodasse no meio. É o
último passo da Fase 1.

**As 124 variáveis marcadas para revisão** continuam marcadas. A intenção é
resolvê-las conforme cada dimensão for migrada, quando a fonte já tiver sido lida
a fundo — é mais preciso do que decidir agora, no escuro.

**Só uma das dezessete dimensões tem tabela publicada.** As outras dezesseis
entram nas Fases 4 a 6.
