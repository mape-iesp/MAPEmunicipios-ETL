# Carrega a camada de funções comuns antes dos testes.
for (f in list.files(here::here("R"), pattern = "[.]R$", full.names = TRUE)) {
  source(f, local = FALSE, encoding = "UTF-8")
}

# Diretório mínimo, usado pelos testes que precisam validar domínio de chave
# sem depender da tabela publicada existir.
diretorio_teste <- data.frame(
  id_municipio   = c("1100015", "3304557", "3550308", "1700400"),
  id_municipio_6 = c("110001",  "330455",  "355030",  "170040"),
  nome_municipio = c("Alta Floresta D'Oeste", "Rio de Janeiro",
                     "São Paulo", "Abreulândia"),
  stringsAsFactors = FALSE
)

# Os caches de sessão. Trocar a âncora mape.raiz sem limpá-los faria a raiz
# falsa herdar o parâmetro ou o dicionário da raiz real — e, pior, deixaria o
# dicionário fabricado por um teste valendo para os testes seguintes.
limpar_caches_mape <- function() {
  rm(list = ls(.mape_cache_param), envir = .mape_cache_param)
  rm(list = ls(.mape_cache_dic), envir = .mape_cache_dic)
  invisible(NULL)
}

# Uma árvore descartável com o config real copiado, para exercitar os caminhos
# que LEEM e ESCREVEM em dados/ sem tocar em nada publicado. Copiar o config de
# verdade mantém o teste falando dos mesmos parâmetros que a produção.
#
# Uso:
#   raiz <- raiz_de_teste()
#   withr::local_options(mape.raiz = raiz)
#   withr::defer(limpar_caches_mape())
raiz_de_teste <- function() {
  r <- file.path(tempdir(), paste0("mape-teste-", as.integer(runif(1, 1, 1e9))))
  dir.create(file.path(r, "config"), recursive = TRUE, showWarnings = FALSE)
  file.copy(here::here("config", "parametros.yml"), file.path(r, "config"))
  limpar_caches_mape()
  r
}

# Grava um Parquet dentro da raiz de teste, criando a pasta da camada.
gravar_fixture <- function(raiz, x, tabela, camada = "dimensao") {
  destino <- file.path(raiz, "dados", camada, paste0(tabela, ".parquet"))
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  arrow::write_parquet(x, destino)
  destino
}
