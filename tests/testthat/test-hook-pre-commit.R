# O hook de pre-commit --------------------------------------------------------
#
# Grupo 84 da auditoria: o hook que protege o repositório de duas coisas caras
# — commitar a árvore legada de 18 GB e commitar arquivo acima do limiar — não
# tinha teste nenhum. Ele é shell, roda fora do R e fora do grafo, e por isso
# ficava num ponto cego: quebrá-lo não faz nenhum teste falhar, e a próxima
# pessoa a descobrir seria a que commitasse um Parquet de 300 MB.
#
# Os testes criam repositórios git descartáveis em tempdir(), instalam o hook
# pelo instalador de verdade (tools/hooks/instalar.sh, e não por uma cópia à
# mão, para que o que se testa seja o que se instala) e olham o CÓDIGO DE SAÍDA
# do `git commit`. Nada aqui toca no repositório de trabalho.

git_rodar <- function(repo, ...) {
  saida <- suppressWarnings(
    system2("git", c("-C", repo, ...), stdout = TRUE, stderr = TRUE))
  status <- attr(saida, "status")
  list(codigo = if (is.null(status)) 0L else as.integer(status),
       texto = paste(saida, collapse = "\n"))
}

# Repositório novo, com o hook instalado. `limiar_mb = NULL` cria o repositório
# SEM config/parametros.yml, que é o caso em que o hook tem de cair no literal.
repo_descartavel <- function(limiar_mb = NULL) {
  repo <- file.path(tempdir(), paste0("mape-hook-", as.integer(runif(1, 1, 1e9))))
  dir.create(repo, recursive = TRUE, showWarnings = FALSE)
  git_rodar(repo, "init", "-q")
  git_rodar(repo, "config", "user.email", "teste@mape.local")
  git_rodar(repo, "config", "user.name", "Teste MAPE")
  git_rodar(repo, "config", "commit.gpgsign", "false")
  # Um core.hooksPath herdado da configuração global faria o hook nunca rodar,
  # e o teste passaria por engano. Fixá-lo aqui deixa o teste determinístico.
  git_rodar(repo, "config", "core.hooksPath", ".git/hooks")

  if (!is.null(limiar_mb)) {
    dir.create(file.path(repo, "config"), showWarnings = FALSE)
    writeLines(c("qa:", paste0("  max_mb_versionavel: ", limiar_mb)),
               file.path(repo, "config", "parametros.yml"))
  }

  # O hook entra no repositório descartável como entra em qualquer clone: em
  # tools/hooks/, e daí para .git/hooks/ pelo instalador de verdade — que é
  # quem dá a permissão de execução, e por isso também está sob teste.
  dir.create(file.path(repo, "tools", "hooks"), recursive = TRUE, showWarnings = FALSE)
  file.copy(here::here("tools", "hooks", "pre-commit"),
            file.path(repo, "tools", "hooks", "pre-commit"), overwrite = TRUE)
  instalacao <- withr::with_dir(repo, suppressWarnings(system2(
    "bash", shQuote(here::here("tools", "hooks", "instalar.sh")),
    stdout = TRUE, stderr = TRUE)))
  stopifnot(is.null(attr(instalacao, "status")))
  repo
}

arquivo_de <- function(repo, caminho, mb) {
  destino <- file.path(repo, caminho)
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  writeBin(raw(round(mb * 1024 * 1024)), destino)
  destino
}

commitar <- function(repo, caminho, mensagem = "teste") {
  git_rodar(repo, "add", "--", shQuote(caminho))
  git_rodar(repo, "commit", "-m", shQuote(mensagem))
}


test_that("o instalador põe o hook executável em .git/hooks", {
  repo <- repo_descartavel(limiar_mb = 1)
  withr::defer(unlink(repo, recursive = TRUE, force = TRUE))

  hook <- file.path(repo, ".git", "hooks", "pre-commit")
  expect_true(file.exists(hook))
  expect_true(file.access(hook, mode = 1) == 0)
  # É o hook deste repositório, byte a byte — e não uma versão antiga.
  expect_identical(readLines(hook), readLines(here::here("tools", "hooks", "pre-commit")))
})

test_that("arquivo acima do limiar é barrado, e o limiar vem do YAML", {
  repo <- repo_descartavel(limiar_mb = 1)
  withr::defer(unlink(repo, recursive = TRUE, force = TRUE))

  # O hook lê o limiar com Rscript. Se o Rscript não estiver ao alcance do
  # processo do commit, ele cai no literal 20 e este teste não provaria nada —
  # então a leitura é conferida antes, e a falta de R é falha, não motivo de
  # pular.
  leitura <- withr::with_dir(repo, suppressWarnings(system2(
    "Rscript", c("-e", shQuote('cat(yaml::read_yaml("config/parametros.yml")$qa$max_mb_versionavel)')),
    stdout = TRUE, stderr = FALSE)))
  expect_identical(as.character(leitura), "1")

  arquivo_de(repo, "grande.bin", mb = 2)
  r <- commitar(repo, "grande.bin")

  expect_gt(r$codigo, 0)
  # A mensagem cita o limiar de 1 MB: é a prova de que ele veio do YAML, e não
  # do literal 20 do fallback — com 20, um arquivo de 2 MB teria passado.
  expect_match(r$texto, "acima do limiar de 1 MB", fixed = TRUE)
  expect_match(r$texto, "Commit bloqueado", fixed = TRUE)
  # E não ficou commit nenhum: barrar é impedir, não avisar.
  expect_gt(git_rodar(repo, "rev-parse", "--verify", "HEAD")$codigo, 0)
})

test_that("arquivo abaixo do limiar passa", {
  repo <- repo_descartavel(limiar_mb = 1)
  withr::defer(unlink(repo, recursive = TRUE, force = TRUE))

  writeLines("id_municipio,valor\n3550308,1", file.path(repo, "pequeno.csv"))
  r <- commitar(repo, "pequeno.csv")

  expect_identical(r$codigo, 0L)
  expect_identical(git_rodar(repo, "rev-parse", "--verify", "HEAD")$codigo, 0L)
  expect_match(git_rodar(repo, "show", "--name-only", "--format=")$texto,
               "pequeno.csv", fixed = TRUE)
})

test_that("caminho da árvore legada é barrado mesmo sendo minúsculo", {
  repo <- repo_descartavel(limiar_mb = 1)
  withr::defer(unlink(repo, recursive = TRUE, force = TRUE))

  dir.create(file.path(repo, "mape_municipios", "4 Base completa"), recursive = TRUE)
  writeLines("x", file.path(repo, "mape_municipios", "4 Base completa", "leia.txt"))
  r <- commitar(repo, "mape_municipios")

  expect_gt(r$codigo, 0)
  expect_match(r$texto, "pertence à árvore legada", fixed = TRUE)
  expect_gt(git_rodar(repo, "rev-parse", "--verify", "HEAD")$codigo, 0)
})

test_that("sem config/parametros.yml, o fallback de 20 MB funciona de verdade", {
  # Este é o defeito que o teste existe para travar. Com `set -euo pipefail` na
  # linha 13, a atribuição `LIMIAR_MB=$(Rscript ...)` herdava o código de saída
  # do Rscript, e um Rscript que falha — sem R, sem o pacote yaml, ou rodando de
  # um worktree sem config/parametros.yml — derrubava o hook ali mesmo, antes de
  # olhar arquivo nenhum. O `case` das linhas seguintes, que existe justamente
  # para pôr 20 no lugar, era inalcançável.
  #
  # O sintoma era duplo e nenhum dos dois avisava: TODO commit era bloqueado com
  # saída vazia, e o limiar declarado no fallback nunca valia.
  repo <- repo_descartavel(limiar_mb = NULL)
  withr::defer(unlink(repo, recursive = TRUE, force = TRUE))

  expect_false(file.exists(file.path(repo, "config", "parametros.yml")))

  # (a) o commit pequeno passa — antes, morria em silêncio com código 1.
  writeLines("oi", file.path(repo, "pequeno.txt"))
  r <- commitar(repo, "pequeno.txt")
  expect_identical(r$codigo, 0L)
  expect_identical(git_rodar(repo, "rev-parse", "--verify", "HEAD")$codigo, 0L)

  # (b) e o limiar do fallback é o de verdade: 21 MB continuam barrados, com o
  # 20 na mensagem. Falhar aberto seria pior que o defeito.
  arquivo_de(repo, "enorme.bin", mb = 21)
  r <- commitar(repo, "enorme.bin")
  expect_gt(r$codigo, 0)
  expect_match(r$texto, "acima do limiar de 20 MB", fixed = TRUE)
})

test_that("acento no caminho e arquivo apagado depois do add continuam barrados", {
  # Achado 61, nos dois sentidos. Sem `-z`, o git devolveria
  # "fontes/mun\303\255cipio.bin" entre aspas e escapado, e o hook não acharia o
  # arquivo; medindo a árvore de trabalho em vez do índice, um arquivo apagado
  # depois do `git add` passaria com o objeto grande já dentro do commit.
  #
  # Os arquivos têm 21 MB para que o teste valha mesmo se o hook cair no
  # fallback: o que está sob teste aqui é o parsing do caminho, não o limiar.
  repo <- repo_descartavel(limiar_mb = NULL)
  withr::defer(unlink(repo, recursive = TRUE, force = TRUE))

  acentuado <- "fontes/munícipio.bin"
  arquivo_de(repo, acentuado, mb = 21)
  r <- commitar(repo, "fontes")
  expect_gt(r$codigo, 0)
  expect_match(r$texto, "acima do limiar", fixed = TRUE)

  # Agora o arquivo some da árvore depois do `git add`: o objeto continua no
  # índice, e é ele que vai para o commit.
  arquivo_de(repo, "sumido.bin", mb = 21)
  git_rodar(repo, "add", "--", "sumido.bin")
  unlink(file.path(repo, "sumido.bin"))
  r <- git_rodar(repo, "commit", "-m", shQuote("removido depois do add"))
  expect_gt(r$codigo, 0)
  expect_match(r$texto, "sumido.bin", fixed = TRUE)
})
