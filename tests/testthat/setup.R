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
