# Por que o ETL e o pacote ficam em repositórios separados

Esta decisão foi tomada em 26 de julho de 2026, no momento em que o ETL passou a
ter dado publicado e o passo seguinte era entregar uma forma de consumi-lo.

## A decisão

**O ETL fica em `MAPEmunicipios-ETL` e o pacote R fica em `MAPEmunicipios`.**
São dois repositórios, com dois públicos e dois ciclos de vida diferentes.

| | `MAPEmunicipios-ETL` | `MAPEmunicipios` |
|---|---|---|
| Público | pesquisadores do MAPE que atualizam dado | qualquer pessoa que use os dados |
| Contém | scripts de extração, dicionário, QA, tabelas publicadas | funções de leitura, indicadores, site |
| Precisa de credencial do Google Cloud | sim, para reextrair | **nunca** |
| Precisa dos 18 GB do legado | sim, para conferir paridade | não |
| Muda quando | uma fonte publica dado novo | a interface de consumo muda |
| Licença | MIT no código, CC BY 4.0 nos dados | MIT |

O acoplamento entre os dois é um só: o ETL publica um **release do GitHub** com
uma tabela por arquivo, e o pacote baixa daquele release. Nenhum código é
compartilhado, nenhum caminho de arquivo atravessa a fronteira.

## Por que não deixar tudo junto

A tentação de um repositório único é real, e o argumento a favor dela também: um
lugar só, um histórico só, nada para sincronizar. Considerei e descartei, por
três motivos que se somam.

**O ETL não pode ser instalado.** `devtools::install_github("mape-iesp/MAPEmunicipios")`
precisa encontrar um `DESCRIPTION` na raiz e uma pasta `R/` que contenha apenas
funções exportáveis. A `R/` do ETL tem treze arquivos de infraestrutura de
pipeline — validação contra dicionário, normalização de chave, migração do
legado — que ninguém deveria carregar para ler uma tabela. Colocar o pacote num
subdiretório resolveria a mecânica e criaria um repositório em que a pasta que
importa não é a raiz, o que é justamente o tipo de armadilha que a
reestruturação existe para eliminar.

**Os dois têm ritmos incompatíveis.** O ETL muda quando o IBGE publica o PIB de
2023 — algumas vezes por ano, com um `renv.lock` de 137 pacotes fixados e um
teste de paridade que roda contra 18 GB de legado. O pacote muda quando alguém
quer uma função nova, e precisa passar em `R CMD check` em três sistemas
operacionais. Amarrar os dois num histórico só significa que cada atualização de
dado dispara a checagem do pacote, e cada correção de documentação do pacote
aparece no log de quem só queria saber quando o SNIS foi atualizado.

**O que é interno deve parecer interno.** O ETL carrega o `qa/`, o `pendencias/`,
o `plano/` e os relatórios de paridade — material que documenta honestamente os
defeitos herdados, incluindo a cobertura vacinal de 51.175% e as 222 chaves
duplicadas das emendas. Isso é exatamente o que um pesquisador do MAPE precisa
ver antes de usar uma variável, e exatamente o que não deveria ser a primeira
tela para um jornalista que quer o gasto em saúde do município dele. Separar não
esconde nada: os dois repositórios são públicos e o pacote aponta para o ETL. O
que muda é qual pergunta cada porta de entrada responde primeiro.

## O que isso exige do ETL

Duas coisas, e as duas ficaram prontas nesta etapa.

A primeira é que o release seja **completo e autodescritivo**: além das tabelas,
ele leva o dicionário inteiro e um `SHA256SUMS.txt`. O pacote não precisa
adivinhar tipo, unidade nem domínio de nenhuma coluna, porque tudo isso viaja
junto. É o que permite `mape_variaveis()` funcionar sem nenhuma chamada de rede
além do download da tabela.

A segunda é que o **contrato de nomes seja estável**. O pacote assume que
`03_meio_ambiente` continua se chamando assim e que `id_municipio` continua sendo
texto de sete dígitos. Ambos estão fixados: a numeração é só de acréscimo (seção
8.3 do plano) e o tipo das chaves está no `config/parametros.yml`.

## O que fica registrado como risco

O pacote pode ficar para trás do ETL sem que ninguém perceba, porque nada quebra
quando uma coluna nova aparece — ela simplesmente não é documentada do lado do
pacote. A mitigação é que `mape_variaveis()` lê o dicionário do release, e não
uma cópia embutida no pacote. Uma variável nova aparece na busca no dia seguinte
à publicação do release, sem precisar de nova versão do pacote.

O que **não** é automático é a função de indicador. Se uma fonte muda o nome de
uma coluna que um indicador usa, o indicador quebra. Por isso cada indicador
declara as colunas de que depende, e o pacote falha com uma mensagem que nomeia a
coluna ausente em vez de devolver `NA` em silêncio.
