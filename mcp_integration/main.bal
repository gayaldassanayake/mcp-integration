import ballerina/lang.runtime;
import ballerinax/postgresql.driver as _;
import gayaltest/mcp_integration.pgmcp;
import gayaltest/mcp_integration.slackmcp;

listener pgmcp:PostgresMcpListener postgresqlMcpListener = new (
    {
        host: postgresHost,
        port: postgresPort,
        username: postgresUsername,
        password: postgresPassword,
        database: postgresDatabase
    },
    {readOnly: true},
    {port: postgresMcpPort, path: postgresMcpPath}
);

function init() returns error? {
    if slackToken == "" {
        return;
    }
    slackmcp:SlackMcpListener slackMcpListener = check new (
        {token: slackToken},
        {readOnly: slackReadOnly, allowedChannelIds: []},
        {port: slackMcpPort, path: slackMcpPath}
    );
    runtime:registerListener(slackMcpListener);
}
