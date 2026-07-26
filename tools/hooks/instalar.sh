#!/usr/bin/env bash
#
# Instala os hooks do repositório em .git/hooks/.
#
# Hooks não são versionados pelo git, então quem clonar o repositório precisa
# rodar isto uma vez:
#
#   bash tools/hooks/instalar.sh

set -euo pipefail

raiz=$(git rev-parse --show-toplevel)
origem="$raiz/tools/hooks"
destino="$raiz/.git/hooks"

for hook in pre-commit; do
  cp "$origem/$hook" "$destino/$hook"
  chmod +x "$destino/$hook"
  echo "instalado: .git/hooks/$hook"
done

echo "pronto."
