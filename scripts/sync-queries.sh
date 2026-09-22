#!/usr/bin/env bash
# Copies the query files out of the grammar repository. nvim looks for queries
# on the runtimepath under queries/<lang>/, which a parser repo cloned by
# nvim-treesitter is not on - so this plugin carries a copy. Re-run this after
# changing the grammar's queries.
set -euo pipefail
grammar=${1:-../diesel-treesitter}
for query in highlights locals folds injections; do
  cp -v "$grammar/queries/$query.scm" "$(dirname "$0")/../queries/diesel/$query.scm"
done
