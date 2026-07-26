# 10. O que vai para o git e o que não vai


> **Errata de 26/07/2026 (auditoria, achados 23 e 31).** Este documento fala em
> "doze checagens". O código nunca executou doze: a bateria tinha dez rótulos
> distintos, a checagem 11 (releitura da exportação) era vazia e a 12 (descrições
> repetidas) nunca foi escrita. As duas foram implementadas na rodada de correção,
> junto com outras seis, e o número deixou de ser digitado — `mape_validar_tabela()`
> conta quantas de fato rodaram e o relatório imprime essa contagem.


## 10.1 O precedente que já existe

O commit `20a3b11` já colocou sob controle de versão os dez arquivos `.txt` do CadÚnico (31 MB,
cerca de 663 mil linhas) e o `processed/cadunico.csv`, e o `CLAUDE.md` registra isso como política
vigente. Não é uma questão em aberto: é um precedente com custo, e a recomendação precisa dizer
explicitamente se o mantém, restringe ou reverte.

## 10.2 A recomendação: restringir

| Camada | Vai para o git? | Onde vive |
|---|---|---|
| Dado bruto (`raw/`) | não | local, com `sha256` no manifesto versionado |
| Intermediário | não | em `_targets/`, que já é o cache do orquestrador |
| Tabela de fonte (Parquet) | sim, se abaixo de 20 MB | repositório e release |
| Tabela de dimensão (Parquet) | sim, se abaixo de 20 MB | repositório e release |
| Base larga | não | apenas release |
| Dicionário e manifestos | sempre | são o contrato |

O limiar de 20 MB é deliberadamente generoso, e na prática **quase tudo cabe**. A soma de todas as
saídas de dimensão é de cerca de 66 MB em `.RData`, e em Parquet comprimido fica menor ainda. As
únicas exceções previstas são Meio Ambiente e Saúde.

A razão para **não versionar o bruto** é que ele é reobtível, seja por script ou por procedimento
documentado, é o que mais pesa, e versioná-lo não acrescenta reprodutibilidade nenhuma — o `sha256`
no manifesto oferece a mesma garantia por 64 bytes. Os doze arquivos da MUNIC, sozinhos, são 194 MB.

A razão para **versionar o processado** é o objetivo de acesso modular: quem quer só meio ambiente
clona o repositório, ou baixa um arquivo, e tem o que precisa. Um `git clone` continua barato.

## 10.3 O que fazer com o CadÚnico que já está commitado

**Recomendo deixar como está e não reescrever o histórico.**

Há três caminhos. Deixar custa 31 MB permanentes no histórico e não tem risco nenhum. Rodar
`git rm --cached` e adicionar ao `.gitignore` remove os arquivos do estado atual mas **não do
histórico**, o que é puramente cosmético — quem clonar continua baixando os 31 MB. Reescrever o
histórico com `git filter-repo` ou BFG recuperaria os 31 MB, mas muda todos os hashes de commit,
invalida clones existentes e quebra qualquer referência a um commit específico.

Trinta e um megabytes não justificam esse estrago. A política nova vale daqui em diante, e o
CadÚnico fica como exceção documentada.

Uma coisa que precisa ser feita na Fase 2, porém, é escrever o `MANIFESTO.yml` dessa fonte. Ela é
justamente aquela cuja origem **ninguém conhece** — procurei por `cadun`, `anomes_s` e `http` em
toda a árvore legada e não há nenhuma referência. Registrar isso formalmente como pendência é o que
impede que vire folclore ("esses arquivos sempre estiveram aí").

## 10.4 Proteger o legado

Este é o primeiro item executável do plano inteiro. A pasta `mape_municipios/` tem cerca de 18 GB e
está fora do git **por omissão**, não por decisão — não há nenhuma linha no `.gitignore` que a
cubra. Um `git add .` distraído versiona tudo.

```gitignore
# Árvore legada: referência canônica, ~18 GB, nunca versionar
mape_municipios/

# Dados brutos e derivados pesados
**/raw/
dados/derivado/
_targets/

# Ignora .Rproj em subpastas, versiona o da raiz (âncora do here())
*.Rproj
!/MAPEmunicipios.Rproj
```

Como reforço, um hook de `pre-commit` que rejeita qualquer arquivo acima de 20 MB e qualquer caminho
que comece por `mape_municipios/`.

## 10.5 Os 18 GB do `.git`

Medi: o diretório `.git` tem 18 GB, sendo 3,2 GB em `objects` (2,68 GiB de objetos soltos mais 504
MiB já empacotados) e **15 GB em `.git/lost-found`**.

O `lost-found` é resíduo de um `git fsck` que alguém rodou em algum momento. Ele não é referenciado
por nenhuma ref e o git não o usa para nada.

```bash
# Confirme que nada aponta para lá:
git fsck --no-progress

# Recupera 15 GB:
rm -rf .git/lost-found

# Compacta os 2,68 GiB de objetos soltos; espera-se cair para cerca de 600 MB:
git gc --aggressive --prune=now
```

Isso recupera cerca de 17 GB **sem reescrever nenhum histórico** e sem risco. É a melhor relação
entre esforço e resultado do plano inteiro, e leva minutos.

## 10.6 Versionar as publicações

As releases seguem versionamento semântico, com a tag no formato `dados-v2.0.0`. Uma mudança de
versão maior indica quebra de compatibilidade de schema, como renomeação ou remoção de coluna; a
menor indica tabela ou variável nova; e a de correção indica mudança de valor sem mudança de
estrutura.

Cada release leva um `SHA256SUMS.txt` como anexo, e o campo `versao_dados` de `tabelas.csv` é gerado
a partir da tag.

O `CHANGELOG-DADOS.md` é alimentado por `dicionario/deprecacao.csv`. É onde uma frase como
"corrigimos `total_receitas_fundeb`, que na verdade media a dedução do FUNDEB e não uma receita"
fica registrada de forma citável — o que importa, porque essa correção muda a interpretação de
qualquer análise que tenha usado a coluna.

Antes de qualquer outra coisa, a base publicada atual é congelada como **`dados-v1.0.0-legado`**.

---

# 11. Validação e controle de qualidade

## 11.1 As ferramentas

Recomendo **`pointblank` para validar dado** e **`testthat` para testar as funções**.

O `pointblank` gera um relatório em HTML legível por tabela, distingue entre aviso e erro por limiar,
e permite declarar a agenda de validação de forma declarativa. Isso importa porque o relatório vai
ser lido por pesquisadores, não por engenheiros. O `assertr` faz o mesmo trabalho de verificação, mas
o relatório é pobre. E `stopifnot` sozinho falha sem diagnóstico — ele fica reservado para dentro das
funções da camada comum.

## 11.2 As checagens obrigatórias por tabela

Toda tabela passa por estas doze checagens antes de ser publicada. Cada uma nasceu de um defeito
real encontrado no levantamento, e por isso listo ao lado o que ela previne.

| # | Checagem | Regra | O que previne |
|---|---|---|---|
| 1 | Unicidade da chave primária | erro | 222 chaves duplicadas em Finanças, 54 nos dados históricos |
| 2 | Ausência de chave nula | erro | as 122 linhas pré-deduplicação, 13 das quais sobrevivem |
| 3 | Domínio da chave contra o diretório | **aviso, com relatório de órfãos** | os 27 códigos de UF na Segurança e os 27 fora do diretório na História |
| 4 | Tipos conforme o dicionário | erro | `prefeito_eleito` e `partido` declarados numéricos; 27 colunas de Segurança como texto |
| 5 | Faixa de anos declarada contra observada | aviso | cinco bases anunciando 2024 num painel que acaba em 2023 |
| 6 | Cobertura de municípios | aviso | o FBSP cobrindo 27 municípios sem nenhum aviso |
| 7 | Linter de nomes e reservados | erro | pontos, acentos, Title Case, prefixos `total_` e `quantidade_` |
| 8 | Sentinelas não convertidos | erro | `"NaoDisponivel"`, `"Ignorado"`, `-999`, string vazia |
| 9 | Domínio de valor | aviso | cobertura vacinal de 13.050%; `-Inf` em `log_pib` |
| 10 | Coerência entre sufixo e escala | erro | colunas `_pct` fora de 0-100 e `_prop` fora de 0-1 |
| 11 | Equivalência entre os formatos exportados | erro | a coluna fantasma do CSV e a conversão silenciosa de texto para inteiro |
| 12 | Descrições idênticas entre tabelas | aviso | as oito descrições copiadas do PIB para o SICONFI |

A regra de bloqueio funciona assim: um **erro impede a publicação**, sem exceção. Um **aviso** entra
no relatório e exige uma justificativa registrada no campo `observacoes` da tabela. E aqui está o
detalhe que faz o sistema funcionar: um aviso sem justificativa **vira erro** na hora de publicar.
Sem isso, avisos viram paisagem em poucas semanas e o sistema inteiro perde utilidade.

Os resultados aparecem em três lugares: um HTML por tabela em `dados/qa/`, um resumo agregado em
`qa/RESUMO.md`, e a falha do alvo `valida_<slug>` no `targets`. Em integração contínua, o resumo vira
comentário no pull request.

A checagem 11 merece uma nota, porque ela é incomum e resolve um problema específico deste projeto.
Como mostrei na decisão sobre formatos, os quatro arquivos publicados hoje não são equivalentes
entre si: o CSV ganha uma coluna sem nome e converte quatro colunas de texto para inteiro, enquanto
o `.RDa` preserva o texto. A checagem relê cada arquivo exportado e compara o schema com o canônico,
o que teria pego esse problema no dia em que ele apareceu.

## 11.3 O teste de paridade contra a base atual

Este é o critério de aceitação global. **Nenhuma dimensão é promovida sem passar por ele.**

O teste é conclusivo porque a migração parte dos artefatos existentes, sem reextrair — o princípio
da seção 12.2. Com o dado de entrada congelado, **só o código muda**, e portanto toda diferença
encontrada é atribuível a ele. Se a fonte fosse reextraída junto, uma diferença poderia ser tanto
uma correção quanto um número novo publicado pela fonte, e não haveria como distinguir.

A referência é a base congelada na tag `dados-v1.0.0-legado`, cuja mensagem registra os checksums
SHA-256 dos quatro artefatos. Vale conferir o checksum antes de rodar o teste: como esses arquivos
vivem fora do controle de versão, nada impede que sejam sobrescritos por engano.

```r
mape_paridade(dimensao,
              referencia = "mape_municipios/4 Base completa/base_municipios_brasileiros.RDa")
```

O procedimento tem cinco passos. Primeiro, carregar a base de referência e recortar as colunas da
dimensão — as fronteiras são conhecidas, porque medi as posições das flags `dimensao_*`. Segundo,
reconstruir o mesmo recorte a partir das tabelas modulares, via `mape_montar_base_larga()`. Terceiro,
aplicar `dicionario/deprecacao.csv` para casar os nomes antigos com os novos. Quarto, comparar coluna
a coluna, com tolerância numérica declarada. Quinto, classificar cada diferença encontrada e gerar
um relatório em `qa/paridade_<dimensao>.md`.

A classificação tem três categorias, e a distinção entre elas é o que torna o teste utilizável.

**Diferenças esperadas e desejadas** são correções de bug. A regra crucial é que elas precisam ser
**reivindicadas antes de rodar o teste**, em `qa/paridade_esperada.csv`, e nunca explicadas depois.
Um teste em que se pode justificar qualquer diferença a posteriori não testa nada. A lista, com base
no que já sei:

| Correção | Efeito esperado |
|---|---|
| Linhas com identificador nulo removidas | 13 linhas a menos no publicado |
| `sigla_uf` reconstituída a partir do diretório | de 146.867 vazios para nenhum |
| Dois indicadores do AdaptaBrasil recuperados | duas colunas a mais |
| Duplicatas dos dados históricos resolvidas | 54 municípios com ano de fundação diferente, e correto |
| Duplicatas de Finanças resolvidas | 235 linhas a menos |
| Parsing monetário do MCMV corrigido | `val_contratado` até cem vezes menor |
| Rio de Janeiro reagregado em 1996-1998 | mortalidade do município cerca de trinta vezes maior nesses anos |
| IEPS completo | 47 colunas com aproximadamente o dobro de valores preenchidos |
| Brancos e nulos destrocados | duas colunas trocam de conteúdo entre si |
| Dupla contagem da Corrupção corrigida | `montante_fiscalizado` cerca de 4,87 vezes menor na mediana |
| Zeros fabricados da Educação removidos | 27.850 células passam de `0` para vazio |

**Diferenças esperadas e neutras** são renomeações puras. A verificação é objetiva: o vetor de
valores precisa ser `identical()` sob o mapa de deprecação.

**Diferenças não explicadas** bloqueiam a promoção da dimensão. Sem exceção.

## 11.4 A ordem de correção do defeito de chave nula

Esta é a única ordem segura, e vale destacar porque a ordem intuitiva é a errada.

O pipeline hoje tem dois problemas encadeados: existem linhas com `id_municipio` nulo chegando das
fontes, e existe um `distinct(id_municipio, ano)` no fim que colapsa quase todas elas. O resultado
líquido é que 122 linhas fantasma entram e 13 sobrevivem.

Quem olhar para o `distinct()` cego, corretamente identificá-lo como um problema e removê-lo
primeiro vai **piorar o artefato publicado**, saltando de 13 para 122 linhas sem município. E o
efeito só apareceria depois, na base larga, longe da origem.

A sequência correta:

1. **Eliminar as chaves nulas na origem.** No RH, filtrar as 80 linhas fantasma da planilha de 2019 e
   resolver a linha de 2011 sem identificador. Na População, as 42 linhas com identificador nulo.
2. **Validar** que a checagem número 2 acusa zero chaves nulas em todas as fontes.
3. **Só então remover o `distinct()`.**
4. **Reintroduzir a unicidade como asserção**, e não como correção silenciosa. É a diferença entre
   um pipeline que apaga o problema e um que o denuncia.
