# Extração: diretório de municípios (Base dos Dados) -------------------------
#
# Fonte primária de todas as chaves e de todo o bloco territorial do
# MAPEmunicipios. Nenhuma outra tabela replica estas colunas — no legado, as 26
# colunas cadastrais estão materializadas dentro de quatro dimensões e são
# removidas depois por índice numérico na etapa de junção.
#
# ATENÇÃO: este script NÃO roda durante a migração. O princípio da seção 12.2 do
# plano é que esta etapa reestrutura o código e não atualiza os dados. A tabela
# publicada é produzida por tratar_municipios.R a partir do artefato que já
# existe, para que o teste de paridade compare só o efeito do código.
#
# A primeira execução real deste script é o primeiro teste do procedimento de
# atualização descrito na seção 8.1 do plano.

suppressPackageStartupMessages({
  library(basedosdados)
})

extrair_municipios <- function(destino = NULL) {
  if (is.null(destino)) {
    destino <- mape_caminho("fontes", "00_diretorios", "municipios", "raw",
                            "municipios.parquet")
  }

  # As colunas são listadas explicitamente, e não com SELECT *, para que uma
  # coluna nova na tabela remota não entre em silêncio na base publicada.
  consulta <- "
    SELECT
      dados.id_municipio,
      dados.id_municipio_6,
      dados.id_municipio_tse,
      dados.id_municipio_rf,
      dados.id_municipio_bcb,
      dados.nome,
      dados.capital_uf,
      dados.id_comarca,
      dados.id_regiao_saude,
      dados.nome_regiao_saude,
      dados.id_regiao_imediata,
      dados.nome_regiao_imediata,
      dados.id_regiao_intermediaria,
      dados.nome_regiao_intermediaria,
      dados.id_microrregiao,
      dados.nome_microrregiao,
      dados.id_mesorregiao,
      dados.nome_mesorregiao,
      dados.id_regiao_metropolitana,
      dados.nome_regiao_metropolitana,
      dados.ddd,
      dados.id_uf,
      dados.sigla_uf,
      dados.nome_uf,
      dados.nome_regiao,
      dados.amazonia_legal,
      dados.centroide
    FROM `basedosdados.br_bd_diretorios_brasil.municipio` AS dados
  "

  bruto <- mape_query(consulta, fonte = "00_diretorios/municipios")

  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  arrow::write_parquet(bruto, destino)
  message("bruto gravado: ", destino, " (", nrow(bruto), " linhas)")
  invisible(destino)
}
