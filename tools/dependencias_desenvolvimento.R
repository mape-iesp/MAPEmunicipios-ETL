# Dependências de desenvolvimento --------------------------------------------
#
# Este arquivo não é executado por nada. Ele existe para que `renv::snapshot()`
# enxergue os pacotes que o projeto usa mas nenhum script do pipeline carrega.
#
# O snapshot implícito do renv descobre dependências varrendo os `library()` e
# `::` do código. Isso funciona bem para o pipeline e falha para três casos:
#
#   testthat    é carregado pelo test_dir(), não por um script
#   visNetwork  é usado por targets::tar_visnetwork(), que o chama internamente
#   pointblank  está previsto para a validação declarativa e ainda não foi ligado
#
# Sem esta declaração, o snapshot os remove do lockfile a cada execução, e quem
# clonar o repositório e rodar `renv::restore()` não consegue rodar os testes.
#
# Se você acrescentar uma dependência que só é usada em desenvolvimento,
# declare-a aqui.

library(testthat)     # a suíte de testes
library(visNetwork)   # targets::tar_visnetwork()
library(pointblank)   # validação declarativa (previsto, ainda não ligado)
