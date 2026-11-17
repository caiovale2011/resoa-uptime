#!/usr/bin/env bash
# Checa se o Resoa está no ar. Só declara "fora" depois de 3 tentativas
# seguidas com 1 minuto entre elas, para não alarmar por um soluço de rede.
set -u

SITE_URL="https://www.resoaclinic.com.br/"
API_URL="https://www.resoaclinic.com.br/.well-known/oauth-protected-resource"
ATTEMPTS=3
WAIT_SECONDS=60
REPORT="report.md"

probe() {
  # $1 = nome, $2 = url, $3 = texto que a resposta precisa conter
  local name="$1" url="$2" expect="$3" body headers code err
  body="$(mktemp)"; headers="$(mktemp)"
  code="$(curl -sS -L -m 20 -o "$body" -D "$headers" -w '%{http_code}' "$url" 2>"$body.err")"
  err="$(tr -d '\r' < "$body.err" | head -c 200)"
  if [ "$code" = "200" ] && grep -q "$expect" "$body"; then
    echo "ok"
    return 0
  fi
  local vercel_error
  vercel_error="$(grep -i '^x-vercel-error:' "$headers" | tail -1 | cut -d' ' -f2- | tr -d '\r')"
  {
    echo "- **$name** ($url): HTTP ${code:-sem resposta}"
    [ -n "$vercel_error" ] && echo "  - erro informado pela Vercel: \`$vercel_error\`"
    [ -n "$err" ] && echo "  - conexão: \`$err\`"
    [ "$code" = "200" ] && echo "  - respondeu, mas sem o conteúdo esperado"
  } >> "$REPORT.tmp"
  return 1
}

status="down"
for attempt in $(seq 1 "$ATTEMPTS"); do
  : > "$REPORT.tmp"
  site_ok=0; api_ok=0
  probe "Página do site" "$SITE_URL" "Resoa" >/dev/null && site_ok=1
  probe "Servidor (funções da API)" "$API_URL" "authorization_servers" >/dev/null && api_ok=1
  if [ "$site_ok" = 1 ] && [ "$api_ok" = 1 ]; then
    status="up"
    break
  fi
  [ "$attempt" -lt "$ATTEMPTS" ] && sleep "$WAIT_SECONDS"
done

if [ "$status" = "down" ]; then
  vercel_status="$(curl -sS -m 15 https://www.vercel-status.com/api/v2/status.json \
    | python3 -c 'import sys,json; d=json.load(sys.stdin)["status"]; print(d["indicator"]+"|"+d["description"])' 2>/dev/null || echo "desconhecido|não foi possível consultar")"
  indicator="${vercel_status%%|*}"; description="${vercel_status#*|}"
  {
    echo "Falhou em $ATTEMPTS tentativas seguidas, com 1 minuto entre elas."
    echo
    cat "$REPORT.tmp"
    echo
    if [ "$indicator" != "none" ] && [ "$indicator" != "desconhecido" ]; then
      echo "**A própria Vercel (hospedagem) informa problema agora:** $description — veja https://www.vercel-status.com"
      echo "Provavelmente não é defeito do Resoa; é esperar a Vercel resolver."
    else
      echo "Página de status da Vercel: $description. Vale olhar o painel da Vercel e o último deploy."
    fi
  } > "$REPORT"
fi

echo "status=$status" >> "$GITHUB_OUTPUT"
echo "Resultado: $status"
[ -f "$REPORT" ] && cat "$REPORT"
exit 0
