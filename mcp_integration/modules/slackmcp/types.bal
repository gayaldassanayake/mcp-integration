// Copyright (c) 2026 WSO2 LLC (http://www.wso2.com).
// Licensed under the Apache License, Version 2.0.

import ballerina/mcp;

# Configuration for the Slack client used by the MCP service.
public type ConnectionConfig record {|
    # Slack bot or user token used for the Slack Web API.
    string token;
|};

# Configuration that controls the Slack MCP tools.
public type ServiceConfig record {|
    # Refuses tools that change Slack when true.
    boolean readOnly = true;
    # When non-empty, write operations are restricted to these Slack conversation IDs.
    string[] allowedChannelIds = [];
    # Default number of items returned from paginated Slack APIs.
    int defaultPageSize = 20;
    # Upper bound applied to a requested page size.
    int maxPageSize = 100;
|};

# Configuration for the streamable HTTP MCP server.
public type ServerConfig record {|
    int port = 8080;
    string path = "/mcp";
    mcp:ListenerConfiguration listenerConfig = {};
|};
