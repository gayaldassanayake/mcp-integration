#!/usr/bin/env bash
set -euo pipefail
U=${1:-http://localhost:18080/postgres-mcp}
H=(-H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream')
S=$(curl -s -D - -o /dev/null "$U" "${H[@]}" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"curl","version":"0"}}}' \
  | awk 'tolower($1)=="mcp-session-id:"{print $2}' | tr -d '\r')
echo "session: $S"
H+=(-H "Mcp-Session-Id: $S")
curl -s "$U" "${H[@]}" -d '{"jsonrpc":"2.0","method":"notifications/initialized"}'
curl -s "$U" "${H[@]}" -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'; echo
curl -s "$U" "${H[@]}" -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"execute_query","arguments":{"sql":"SELECT id, subject, status, updated_at::text FROM support_tickets ORDER BY updated_at DESC LIMIT 3"}}}'; echo
