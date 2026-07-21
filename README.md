# PostgreSQL and Slack MCP Integration

This WSO2 Integrator project demonstrates two reusable Ballerina MCP servers running in one integration:

- PostgreSQL MCP exposes safe SQL tools backed by `ballerinax/postgresql`.
- Slack MCP exposes workspace, conversation, user, message, and guarded send-message tools backed by `ballerinax/slack`.

Both servers are declared as listeners. They start with the Ballerina package lifecycle and do not require or reserve a `main()` function.

## Endpoints

| MCP server | Streamable HTTP endpoint |
|---|---|
| PostgreSQL | `http://localhost:8080/postgres-mcp` |
| Slack | `http://localhost:8081/slack-mcp` |

## Prerequisites

- Ballerina 2201.13.0
- Java 21
- Docker
- A Slack app with a bot token for a dedicated test workspace

The MCP-enabled connector versions used by this demo are feature-branch builds and are not yet available from Ballerina Central. The released `ballerina/mcp:1.1.0` package is resolved directly from Ballerina Central.

## Publish the dependencies locally

### 1. PostgreSQL connector with MCP

```bash
git clone --branch feat/declarative-postgres-mcp \
  https://github.com/gayaldassanayake/module-ballerinax-postgresql.git
cd module-ballerinax-postgresql
./gradlew :postgresql-native:build :postgresql-compiler-plugin:build
cd ballerina
bal pack --offline
bal push --repository local
cd ../..
```

The connector's complete historical test suite currently includes an unrelated CDC dependency incompatibility. The MCP module tests can be run separately with:

```bash
cd module-ballerinax-postgresql/ballerina
bal test --offline --tests 'postgresql.mcp:*'
cd ../..
```

### 2. Slack connector with MCP

```bash
git clone --branch feat/slack-mcp \
  https://github.com/gayaldassanayake/module-ballerinax-slack.git
cd module-ballerinax-slack/ballerina
bal test --offline
bal pack --offline
bal push --repository local
cd ../..
```

## Configure the demo

Start the seeded PostgreSQL database:

```bash
docker compose up -d
docker compose ps
```

Create the runtime configuration:

```bash
cp mcp_integration/Config.toml.sample mcp_integration/Config.toml
```

Replace `slackToken` with a bot token from your test Slack app. Keep `slackReadOnly = true` until you intentionally want an agent to send messages.

Useful Slack bot scopes for the complete tool set are:

- `chat:write`
- `channels:history`, `channels:read`
- `groups:history`, `groups:read`
- `im:history`, `im:read`
- `mpim:history`, `mpim:read`
- `users:read`, `users:read.email`
- `search:read`

After changing scopes, reinstall the Slack app and invite the bot to any channel whose history it should read.

## Run

```bash
cd mcp_integration
bal run
```

## Test with curl

List PostgreSQL tools:

```bash
curl -s http://127.0.0.1:8080/postgres-mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

Query the seeded customers:

```bash
curl -s http://127.0.0.1:8080/postgres-mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"execute_query","arguments":{"sql":"SELECT id, name, tier FROM customers ORDER BY id"}}}'
```

Check the Slack workspace identity:

```bash
curl -s http://127.0.0.1:8081/slack-mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_workspace_info","arguments":{}}}'
```

## Agent demo scenario

Connect an MCP-capable agent to both endpoints and give it this task:

> Find every gold or platinum customer in PostgreSQL, summarize the result by membership tier, and post the summary to Slack channel `<CHANNEL_ID>`. Show me the database rows and the Slack message permalink.

For the final Slack write, set `slackReadOnly = false`, restart the integration, and use a dedicated demo channel. The bot must be a member of that channel.

## Cleanup

Stop the Ballerina process with `Ctrl+C`, then remove the demo database:

```bash
docker compose down -v
```

Real credentials belong only in the ignored `mcp_integration/Config.toml` file. Never commit Slack tokens or production database passwords.
