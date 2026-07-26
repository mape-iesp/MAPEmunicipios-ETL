# Tratamento: diretório de municípios ----------------------------------------
#
# Produz a tabela 00_diretorios/municipios, que é a espinha do painel: ela é a
# única dona das chaves e do bloco territorial.
#
# Durante a migração a entrada é o artefato que já existe (o .xlsx da árvore
# nova), e não uma extração fresca. Quando a segunda etapa do trabalho começar e
# o dado for atualizado de fato, basta trocar `origem` pelo Parquet que
# extrair_municipios.R grava — o resto do tratamento não muda.

tratar_municipios <- function(origem = NULL) {
  if (is.null(origem)) {
    # Achado 9: aqui havia um literal apontando para
    # "01_dimensoes_individuais/00_diretorios/processed/diretorios.xlsx", dentro
    # da árvore legada — que foi REMOVIDA do repositório em 26/07/2026 sem que o
    # produtor fosse reescrito. O alvo fonte_00_diretorios_municipios falhava
    # desde então com "arquivo não encontrado", e era o único alvo de fonte do
    # diretório.
    #
    # O arquivo foi recuperado do histórico para raw/ e o caminho passa por
    # mape_verificar_raw(), que confere o sha256 do MANIFESTO.yml — exatamente o
    # que cadunico e disque100 já fazem.
    origem <- mape_verificar_raw("00_diretorios/municipios", "diretorios.xlsx")
  }

  bruto <- if (grepl("[.]parquet$", origem)) {
    as.data.frame(arrow::read_parquet(origem))
  } else {
    as.data.frame(openxlsx::read.xlsx(origem))
  }
  message("bruto: ", nrow(bruto), " linhas x ", ncol(bruto), " colunas")

  x <- bruto

  # 1. Caixa dos cabeçalhos. Resolve, na entrada, a colisão que no legado
  #    aparece como ANO/Ano/ano e NM_UF/nm_uf convivendo entre fontes.
  x <- janitor::clean_names(x)

  # 2. Renomeações do bloco territorial.
  #
  #    `nome` é genérico demais para uma coluna publicada e colide com a coluna
  #    `nome` que vaza do IEPS na dimensão Saúde; vira nome_municipio.
  #
  #    capital_uf e amazonia_legal são booleanos gravados como texto; recebem o
  #    prefixo flag_ e passam a ser 0/1, o que os torna somáveis.
  #
  #    centroide é uma geometria em texto; o nome passa a dizer isso.
  nomes <- c(nome = "nome_municipio",
             capital_uf = "flag_capital_uf",
             amazonia_legal = "flag_amazonia_legal",
             centroide = "centroide_wkt")
  for (de in names(nomes)) {
    if (de %in% names(x)) names(x)[names(x) == de] <- nomes[[de]]
  }

  # 3. Sentinelas antes de tipar, para que "" e "NA" não virem categorias.
  x <- mape_tratar_sentinelas(x, converter_numerico = FALSE)

  # 4. Booleanos. A fonte grava "0"/"1" como texto; o contrato é 0/1 inteiro.
  for (col in c("flag_capital_uf", "flag_amazonia_legal")) {
    if (col %in% names(x)) {
      v <- tolower(trimws(as.character(x[[col]])))
      x[[col]] <- as.integer(v %in% c("1", "true", "sim", "t", "verdadeiro"))
    }
  }

  # 5. Códigos. id_municipio com 7 dígitos, id_municipio_6 com 6. Os demais
  #    códigos (TSE, RF, BCB, comarca, regiões) ficam como texto sem
  #    normalização de largura, porque cada um tem a sua e inventar zeros à
  #    esquerda neles corromperia a chave.
  x$id_municipio   <- mape_como_codigo(x$id_municipio, 7L)
  x$id_municipio_6 <- mape_como_codigo(x$id_municipio_6, 6L)

  # 6. Ordem canônica: chaves, identificação, hierarquia territorial, extras.
  ordem <- c("id_municipio", "id_municipio_6", "id_municipio_tse",
             "id_municipio_rf", "id_municipio_bcb",
             "nome_municipio", "sigla_uf", "nome_uf", "id_uf", "nome_regiao",
             "flag_capital_uf", "flag_amazonia_legal", "ddd",
             "id_comarca", "id_regiao_saude", "nome_regiao_saude",
             "id_regiao_imediata", "nome_regiao_imediata",
             "id_regiao_intermediaria", "nome_regiao_intermediaria",
             "id_microrregiao", "nome_microrregiao",
             "id_mesorregiao", "nome_mesorregiao",
             "id_regiao_metropolitana", "nome_regiao_metropolitana",
             "centroide_wkt")
  x <- x[, c(intersect(ordem, names(x)), setdiff(names(x), ordem)), drop = FALSE]

  # 7. Validação. A tabela é transversal, então a chave é só id_municipio.
  mape_validar_chave(x, chaves = "id_municipio")
  stopifnot(nrow(x) == 5570)

  x
}
