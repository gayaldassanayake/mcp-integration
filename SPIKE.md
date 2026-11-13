# Context engine spike: Postgres MCP

The `pgmcp` and `slackmcp` modules are copies of the `mcp` modules from
`gayaldassanayake/module-ballerinax-postgresql@feat/declarative-postgres-mcp` and
`gayaldassanayake/module-ballerinax-slack@feat/slack-mcp`, so the package builds from Ballerina Central only
(`ballerina/mcp`, `ballerinax/postgresql`, `ballerinax/slack`). Distribution 2201.14.0.

The Postgres MCP runs read-only (`execute_query`, `execute_query_row`; write tools return an error).
The Slack MCP starts only when `slackToken` is set; it is unset here.

## Seed data

`db/init.sql` creates `customers` (15 rows) and `support_tickets` (30 rows, FK `customer_id`). Both tables have
`id SERIAL` primary keys and `created_at`/`updated_at timestamptz`, with a trigger that bumps `updated_at` on update.
`db/mutate.sql` adds one customer and two tickets and updates two tickets and one customer.

Select `updated_at::text` (or `extract(epoch from updated_at)`) through MCP: a plain `timestamptz` column is
rendered in the JVM's time zone without an offset. Both runs below set the JVM to UTC.

## Local

```bash
docker compose up -d --wait            # postgres:16 on localhost:15432, seeded from db/init.sql
cd mcp_integration
cat > Config.toml <<'TOML'
postgresPort = 15432
postgresPassword = "mcp_demo_password"
postgresMcpPort = 18080
TOML
bal build
java -Duser.timezone=UTC -jar target/bin/mcp_integration.jar   # use the JDK 25 that ships with bal 2201.14
```

MCP URL: `http://localhost:18080/postgres-mcp` (host port 8080 belongs to the k3d load balancer).

Mutate: `docker exec -i mcp-integration-postgres psql -U postgres < db/mutate.sql`

Reset: `docker compose down && docker compose up -d --wait`

## MCP over curl

`db/mcp-smoke.sh [url]` runs this sequence:

```bash
U=http://localhost:18080/postgres-mcp
H=(-H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream')

# 1. initialize; the session id comes back in the mcp-session-id response header
curl -si "$U" "${H[@]}" -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"curl","version":"0"}}}'
S=<mcp-session-id>
H+=(-H "Mcp-Session-Id: $S")

# 2. initialized notification (202)
curl -s "$U" "${H[@]}" -d '{"jsonrpc":"2.0","method":"notifications/initialized"}'

# 3. tools/list
curl -s "$U" "${H[@]}" -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'

# 4. tools/call execute_query
curl -s "$U" "${H[@]}" -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"execute_query","arguments":{"sql":"SELECT id, subject, status, updated_at::text FROM support_tickets WHERE updated_at > now() - interval '\''1 day'\'' ORDER BY updated_at"}}}'
```

Rows come back as a JSON array encoded in `result.content[0].text`.

## k3d (cluster `openchoreo`, namespace `mcp-spike`)

Deployed as a plain Deployment and Service from a locally built image, not as a Devant component.

```bash
cd mcp_integration && bal build
docker build -t localhost:10082/mcp-spike-integration:latest . && docker push localhost:10082/mcp-spike-integration:latest
cd ..
kubectl apply -f k8s/postgres.yaml
kubectl create configmap postgres-init -n mcp-spike --from-file=init.sql=db/init.sql --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f k8s/integration.yaml
kubectl rollout restart -n mcp-spike deploy/mcp-integration   # after pushing a new image
```

Postgres uses an `emptyDir`, so deleting its pod reseeds from `db/init.sql`.

- In-cluster MCP URL: `http://mcp-integration.mcp-spike.svc.cluster.local:8080/postgres-mcp`
- Host MCP URL: `kubectl port-forward -n mcp-spike svc/mcp-integration 18090:8080`, then `http://localhost:18090/postgres-mcp`
- Mutate: `kubectl exec -i -n mcp-spike deploy/postgres -- psql -U postgres < db/mutate.sql`
- Reset: `kubectl delete pod -n mcp-spike -l app=postgres`
- Remove everything: `kubectl delete ns mcp-spike`
