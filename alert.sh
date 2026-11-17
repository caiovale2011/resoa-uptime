#!/usr/bin/env bash
# Um aviso por queda: abre uma issue quando o site cai (o GitHub manda e-mail)
# e comenta + fecha quando volta. Sem e-mail repetido a cada 10 minutos.
set -euo pipefail

STATUS="$1"
LABEL="fora-do-ar"
OWNER="${GITHUB_REPOSITORY%%/*}"
NOW="$(TZ=America/Sao_Paulo date '+%d/%m/%Y %H:%M')"
PREFIX=""
[ "${SIMULAR_QUEDA:-false}" = "true" ] && PREFIX="[TESTE] "

gh label create "$LABEL" --color B60205 --description "Resoa fora do ar" >/dev/null 2>&1 || true

open_issue="$(gh issue list --label "$LABEL" --state open --json number --jq '.[0].number // empty')"

if [ "$STATUS" = "down" ]; then
  if [ -z "$open_issue" ]; then
    gh issue create \
      --title "${PREFIX}Resoa fora do ar desde $NOW (horário de Brasília)" \
      --label "$LABEL" \
      --assignee "$OWNER" \
      --body-file report.md
    echo "Alerta aberto."
  else
    echo "Queda já avisada na issue #$open_issue; sem novo e-mail."
  fi
else
  if [ -n "$open_issue" ]; then
    opened="$(gh issue view "$open_issue" --json createdAt --jq .createdAt)"
    minutes=$(( ( $(date +%s) - $(date -d "$opened" +%s) ) / 60 ))
    gh issue comment "$open_issue" --body "Voltou ao ar em $NOW (horário de Brasília). Ficou fora por cerca de $minutes minutos, contando a partir do primeiro aviso."
    gh issue close "$open_issue"
    echo "Alerta encerrado."
  else
    echo "Tudo no ar."
  fi
fi
