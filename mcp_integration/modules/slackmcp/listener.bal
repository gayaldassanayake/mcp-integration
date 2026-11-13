// Copyright (c) 2026 WSO2 LLC (http://www.wso2.com).
// Licensed under the Apache License, Version 2.0.

import ballerina/mcp;

# A declarative Slack MCP listener.
public isolated class SlackMcpListener {
    private final mcp:Listener mcpListener;
    private final SlackMcpService mcpService;

    # Initializes and attaches the Slack MCP service.
    public function init(ConnectionConfig connectionConfig, ServiceConfig serviceConfig = {},
            ServerConfig serverConfig = {}) returns error? {
        self.mcpService = check new (connectionConfig, serviceConfig);
        mcp:Listener|error mcpTransportListener = new (serverConfig.port, {...serverConfig.listenerConfig.clone()});
        if mcpTransportListener is error {
            return mcpTransportListener;
        }
        self.mcpListener = mcpTransportListener;
        check self.mcpListener.attach(self.mcpService, serverConfig.path);
    }

    public isolated function attach(mcp:Service|mcp:AdvancedService mcpService,
            string[]|string? name = ()) returns mcp:Error? {
        return self.mcpListener.attach(mcpService, name);
    }

    public isolated function detach(mcp:Service|mcp:AdvancedService mcpService) returns mcp:Error? {
        return self.mcpListener.detach(mcpService);
    }

    public isolated function 'start() returns mcp:Error? {
        return self.mcpListener.'start();
    }

    public isolated function gracefulStop() returns mcp:Error? {
        return self.mcpListener.gracefulStop();
    }

    public isolated function immediateStop() returns mcp:Error? {
        return self.mcpListener.immediateStop();
    }
}
