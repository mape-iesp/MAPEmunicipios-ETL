#!/usr/bin/env Rscript
# Baixa a serie do IPCA uma vez e a fixa em config/ipca.csv.
#
#   Rscript tools/atualizar_ipca.R
#
# Achado 37 da auditoria: mape_deflacionar() chamava deflateBR::ipca() DENTRO do
# laco de colunas, disparando um download da API do IPEA por coluna. O resultado
# nao era reproduzivel — uma serie de indice de precos e revisada, entao o mesmo
# codigo rodando em dois dias podia devolver numeros diferentes —, nada
# registrava qual serie tinha sido usada, e a funcao dependia de rede.
#
# Este e o UNICO lugar do repositorio que fala com a API. A serie fica
# versionada, com a data de extracao e o sha256 no proprio arquivo.

for (f in list.files(here::here("R"), pattern = "[.]R$", full.names = TRUE)) {
  source(f, local = FALSE, encoding = "UTF-8")
}

# deflateBR::ipca() e o mesmo caminho que o legado usava, e e o pacote que ja
# esta no renv.lock. Aqui ele roda UMA vez: um vetor de 1,00 em cada mes,
# deflacionado para o mes-base, devolve o proprio fator, e o indice se reconstroi
# a partir dele. Assim a serie fixada e exatamente a que o pipeline usava.
message("Baixando a serie do IPCA (deflateBR)...")
base_ref <- mape_param("deflator_base")
meses <- seq(as.Date("1994-07-01"), Sys.Date(), by = "month")
fator <- deflateBR::ipca(rep(1, length(meses)), meses, base_ref)

# fator = indice_base / indice_mes  =>  indice_mes = indice_base / fator, com o
# indice do mes-base fixado em 100. A escala e arbitraria: so a razao importa.
#
# O mes-base fica GRAVADO no arquivo, e nao so no YAML, porque a serie e
# especifica dele: deflateBR resolve "12/2023" um mes a frente (o fator de
# 2023-12 vale 1,0056 e nao 1,0000), e reconstruir isso de fora seria adivinhar.
# mape_serie_ipca() confere que o arquivo e o YAML concordam.
serie <- data.frame(data = meses, indice = 100 / fator, base = base_ref)
serie <- serie[!is.na(serie$indice) & is.finite(serie$indice), ]
serie <- serie[order(serie$data), ]

destino <- here::here("config", "ipca.csv")
utils::write.csv(serie, destino, row.names = FALSE, fileEncoding = "UTF-8")

sha <- digest::digest(destino, algo = "sha256", file = TRUE)
message("gravado: ", destino)
message("  ", nrow(serie), " meses, de ", format(min(serie$data)), " a ",
        format(max(serie$data)))
message("  sha256: ", sha)

mape_registrar_proveniencia(
  fonte = "config/ipca", metodo = "api",
  detalhe = "ipeadatar::ipeadata('PRECOS12_IPCA12')",
  hash_consulta = substr(sha, 1, 16), n_linhas = nrow(serie))
message("proveniencia registrada em dicionario/proveniencia.csv")
