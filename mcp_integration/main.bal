import ballerinax/postgresql.driver as _;
import ballerinax/postgresql.mcp as pgmcp;
import ballerinax/slack.mcp as slackmcp;

listener pgmcp:PostgresMcpListener postgresqlMcpListener = new (
    {
        host: postgresHost,
        port: postgresPort,
        username: postgresUsername,
        password: string `${postgresPassword}`,
        database: postgresDatabase
    },
    {readOnly: true},
    {port: postgresMcpPort, path: postgresMcpPath}
);
listener slackmcp:SlackMcpListener slackMcpListener = new (
    {token: string `${slackToken}`},
    {readOnly: slackReadOnly, allowedChannelIds: []},
    {port: slackMcpPort, path: slackMcpPath}
);
