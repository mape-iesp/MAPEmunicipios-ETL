# Fase 2 — A dimensão-piloto

Migração da Assistência Social e Direitos Humanos, escolhida como piloto porque
tem três fontes com métodos de obtenção diferentes, uma fonte que não roda, e a
fonte cuja origem precisou ser reconstruída. Ela exercita o desenho sem ser
grande demais para o custo de errar.

O resultado: **duas tabelas publicadas, uma pendência registrada, e o teste de
paridade passando com zero diferenças não explicadas.**

---

## O que foi publicado

| Tabela | Linhas | Colunas | Cobertura |
|---|---|---|---|
| `01_assistencia_social_dh/cadunico` | 50.130 | 10 | 2015-2023 |
| `01_assistencia_social_dh/disque100` | 59.990 | 8 | 2011-2023 |
| `01_assistencia_social_dh` (dimensão) | 67.406 | 16 | 2011-2023 |

### Por que a dimensão tem menos linhas que o legado

A tabela de dimensão do legado tem 72.410 linhas; a nova tem 67.406. A
diferença não é perda de dado, é a decisão 3.3 do plano: **a tabela canônica
guarda o observado**, e não um esqueleto de painel preenchido.

O legado constrói um esqueleto município × ano de 1991 a 2023, corta em 2011 e
junta as fontes contra ele, o que gera linhas para pares município-ano em que
nenhuma das duas fontes tem dado. A tabela nova tem uma linha quando pelo menos
uma fonte observou alguma coisa.

Quem precisar do painel cheio chama `mape_expandir_painel()`, e aí as linhas
imputadas vêm marcadas — o que hoje não acontece em lugar nenhum da base.

---

## O teste de paridade

```
[paridade] 01_assistencia_social_dh: 14 coluna(s) comparada(s),
                                     0 diferença(s) não explicada(s)
```

As catorze colunas da dimensão na base publicada foram comparadas valor a valor,
pelos pares de chave presentes nos dois lados, com tolerância relativa de 1e-9.
Todas as diferenças encontradas são da classe **(b) renomeação**: mesmo valor,
nome novo.

O relatório completo está em `qa/paridade_01_assistencia_social_dh.md`.

Vale explicar por que esse resultado é confiável. A migração parte dos artefatos
que já existiam, sem reextrair nada do BigQuery. Com o dado de entrada
congelado, **só o código mudou**, e por isso qualquer diferença encontrada é
atribuível a ele. Se a fonte tivesse sido atualizada ao mesmo tempo, uma
diferença poderia ser correção de defeito ou número novo publicado pela fonte, e
não haveria como distinguir.

---

## O que a validação pegou, e que ninguém sabia

Este é o achado mais importante da fase, e ele apareceu porque a validação
**bloqueou a publicação** em vez de deixar passar.

A coluna `cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_pct` chega a
**128,8%**. É uma razão entre cadastros atualizados e cadastros totais na faixa
de renda: por definição, ela não pode passar de 100%.

O que a investigação mostrou:

- são **59 municípios**, um valor cada, **todos no ano de 2016**;
- a outra taxa da mesma tabela tem máximo exatamente 100,00, o que indica que
  ela é truncada na origem e esta não é;
- a concentração num único ano descarta ruído aleatório e aponta para falha na
  extração daquela edição.

A explicação provável é que numerador e denominador foram apurados em momentos
diferentes, de modo que famílias que mudaram de faixa de renda entre as duas
contagens aparecem só no numerador.

**A decisão foi manter os valores como vieram, sem truncar.** Truncar em 100
esconderia o problema e produziria uma série que parece correta. A limitação
está registrada no campo `observacoes` da tabela, e a validação continua
emitindo o aviso a cada execução.

Este caso é a demonstração de que a regra "aviso exige justificativa registrada"
funciona: o aviso não desaparece, ele fica documentado.

---

## Uma imprecisão minha que o caso expôs

A primeira versão da checagem de sufixo tratava qualquer valor fora de [0,100]
numa coluna `_pct` como **erro**. Isso confunde dois problemas que não são o
mesmo:

**Escala errada é erro.** Uma coluna `_pct` cujos valores não passam de 1 é, na
verdade, uma proporção com o sufixo trocado. O nome mente sobre o conteúdo, e é
exatamente isso que o vocabulário de sufixos existe para impedir.

**Valor fora da faixa é aviso.** Uma taxa que chega a 128% continua sendo um
percentual. O dado é publicável, desde que a limitação esteja documentada.

A checagem foi refeita para distinguir os dois, e os testes foram reescritos
para cobrir os três casos: proporção rotulada como percentual (erro), ordem de
grandeza incompatível (erro), e valor pontualmente fora da faixa (aviso).

---

## O que não migrou, e por quê

O **suplemento de Direitos Humanos da MUNIC 2023** não migra. Está registrado
em `pendencias/01_assistencia_social_dh__munic_dh.md` com diagnóstico completo.

O script do legado quebra em `library(labelled)`, um pacote que não está
instalado nem declarado em lugar nenhum do projeto. Confirmei que a fonte não
contribui com nenhuma coluna para a base publicada: as catorze colunas da
dimensão vêm todas do Disque 100 (seis) e do CadÚnico (oito).

Migrar uma fonte que não produz coluna nenhuma acrescentaria dado novo à base ao
mesmo tempo que o código muda, e contaminaria o teste de paridade. Ela volta
depois da migração, como fonte nova.

Há também um `Base_MUNIC_2019.xlsx` órfão na mesma pasta, que nenhum script abre.

---

## Renomeações desta dimensão

Todas registradas em `dicionario/deprecacao.csv`.

| Antes | Depois | Por quê |
|---|---|---|
| `total_violacoes` | `disque100_violacoes_i` | o prefixo `total_` é usado em sete dimensões para coisas sem relação; o novo nome diz fonte, conceito e tipo |
| `total_violacoes_crianca_adolescente` | `disque100_violacoes_crianca_adolescente_i` | idem |
| `total_violacoes_lgbtq` | `disque100_violacoes_lgbtq_i` | idem |
| `total_violacoes_pcd` | `disque100_violacoes_pcd_i` | idem |
| `total_violacoes_pessoa_idosa` | `disque100_violacoes_pessoa_idosa_i` | idem |
| `total_violacoes_religiao` | `disque100_violacoes_religiao_i` | idem |
| `cadun_taxa_atualizacao_cadastral_d` | `cadun_taxa_atualizacao_cadastral_pct` | o sufixo `_d` não distingue proporção de percentual; a TAC é percentual |
| `cadun_taxa_atualizacao_cadastral_rfpc_ate_meio_sm_d` | `..._pct` | idem |

As seis contagens do CadÚnico mantêm o sufixo `_i`, que já estava correto.

---

## Duas limitações que passam a estar documentadas

**O snapshot anual do CadÚnico é dezembro**, por causa de um filtro herdado do
legado. Isso descarta 2024, cujo arquivo bruto vai até novembro: a fonte cobre
2015 a 2024 e a tabela entrega 2015 a 2023. Vale rever se o snapshot deve passar
a ser o último mês disponível, mas isso muda a série e fica para depois da
migração.

**O Disque 100 conta denúncias, não violações confirmadas.** A série é sensível à
propensão a denunciar, que varia entre municípios e ao longo do tempo. Isso não
estava dito em lugar nenhum e agora está na descrição da tabela.

---

## O que a fase produziu de reutilizável

A migração das dezesseis dimensões restantes usa três funções escritas aqui:

`mape_registrar_tabela()` e `mape_atribuir_variaveis()` fazem o registro no
dicionário, para que o script de cada fonte contenha só o que é específico
daquela fonte. Sem isso, cada dimensão teria o seu próprio script de registro e
a convenção se dissolveria por volta da terceira cópia — que é como o legado
acabou com o mesmo bloco de expansão de painel copiado cinco vezes.

`mape_registrar_pendencia()` documenta fonte que não migra, com diagnóstico, em
vez de deixá-la sumir sem explicação.

`mape_consolidar_dimensao()`, `mape_montar_base_larga()` e `mape_paridade()`
completam o caminho da fonte até a comparação com o publicado.
