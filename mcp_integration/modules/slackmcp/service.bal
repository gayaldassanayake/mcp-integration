// Copyright (c) 2026 WSO2 LLC (http://www.wso2.com).
// Licensed under the Apache License, Version 2.0.

import ballerina/mcp;
import ballerinax/slack;

public isolated service class SlackMcpService {
    *mcp:AdvancedService;

    private final slack:Client slackClient;
    private final boolean readOnly;
    private final readonly & string[] allowedChannelIds;
    private final int defaultPageSize;
    private final int maxPageSize;

    public isolated function init(ConnectionConfig connectionConfig, ServiceConfig serviceConfig = {}) returns error? {
        self.slackClient = check new ({auth: {token: connectionConfig.token}});
        self.readOnly = serviceConfig.readOnly;
        self.allowedChannelIds = serviceConfig.allowedChannelIds.cloneReadOnly();
        self.defaultPageSize = serviceConfig.defaultPageSize > 0 ? serviceConfig.defaultPageSize : 20;
        self.maxPageSize = serviceConfig.maxPageSize > 0 ? serviceConfig.maxPageSize : 100;
    }

    remote isolated function onListTools() returns mcp:ListToolsResult|mcp:ServerError {
        return {tools: [
            tool("get_workspace_info", "Get the authenticated Slack workspace and identity.", schema(), true),
            tool("list_conversations", "List Slack conversations accessible to the authenticated identity.",
                schema({'limit: integerSchema(), cursor: stringSchema(), types: stringSchema()}), true),
            tool("get_conversation", "Get metadata for a Slack channel or direct-message conversation.",
                schema({channel_id: stringSchema()}, ["channel_id"]), true),
            tool("search_messages", "Search Slack messages using Slack search syntax.",
                schema({query: stringSchema(), count: integerSchema(), page: integerSchema()}, ["query"]), true),
            tool("get_conversation_history", "Read a bounded page of messages from a Slack conversation.",
                schema({channel_id: stringSchema(), 'limit: integerSchema(), cursor: stringSchema(), oldest: numberSchema(), latest: numberSchema()}, ["channel_id"]), true),
            tool("get_thread", "Read replies in a Slack message thread.",
                schema({channel_id: stringSchema(), thread_ts: numberSchema(), 'limit: integerSchema(), cursor: stringSchema()}, ["channel_id", "thread_ts"]), true),
            tool("find_users", "Find Slack users by name or email.",
                schema({query: stringSchema(), email: stringSchema(), 'limit: integerSchema(), cursor: stringSchema()}), true),
            tool("get_message_permalink", "Get a shareable permalink for a Slack message.",
                schema({channel_id: stringSchema(), message_ts: stringSchema()}, ["channel_id", "message_ts"]), true),
            tool("send_message", "Send a Slack message. Refused in READ_ONLY mode.",
                schema({channel_id: stringSchema(), text: stringSchema(), thread_ts: stringSchema()}, ["channel_id", "text"]), false)
        ]};
    }

    remote isolated function onCallTool(mcp:CallToolParams params, mcp:Session? session = ())
            returns mcp:CallToolResult|mcp:ServerError {
        record {} arguments = params.arguments ?: {};
        match params.name {
            "get_workspace_info" => { return self.getWorkspaceInfo(); }
            "list_conversations" => { return self.listConversations(arguments); }
            "get_conversation" => { return self.getConversation(arguments); }
            "search_messages" => { return self.searchMessages(arguments); }
            "get_conversation_history" => { return self.getConversationHistory(arguments); }
            "get_thread" => { return self.getThread(arguments); }
            "find_users" => { return self.findUsers(arguments); }
            "get_message_permalink" => { return self.getMessagePermalink(arguments); }
            "send_message" => { return self.sendMessage(arguments); }
            _ => { return error mcp:ServerError(string `Unknown tool: ${params.name}`); }
        }
    }

    private isolated function getWorkspaceInfo() returns mcp:CallToolResult|mcp:ServerError {
        anydata|error identity = self.slackClient->/auth\.test();
        if identity is error { return slackError(identity); }
        return result(identity);
    }

    private isolated function listConversations(record {} arguments) returns mcp:CallToolResult|mcp:ServerError {
        slack:ConversationsListQueries query = {'limit: pageSize(arguments, self.defaultPageSize, self.maxPageSize)};
        string? cursor = optionalString(arguments, "cursor");
        if cursor is string { query.cursor = cursor; }
        string? types = optionalString(arguments, "types");
        if types is string { query.types = types; }
        anydata|error response = self.slackClient->/conversations\.list({}, query);
        if response is error { return slackError(response); }
        return result(response);
    }

    private isolated function getConversation(record {} arguments) returns mcp:CallToolResult|mcp:ServerError {
        string channelId = check requiredString(arguments, "channel_id");
        anydata|error response = self.slackClient->/conversations\.info({}, channel = channelId);
        if response is error { return slackError(response); }
        return result(response);
    }

    private isolated function searchMessages(record {} arguments) returns mcp:CallToolResult|mcp:ServerError {
        string query = check requiredString(arguments, "query");
        slack:SearchMessagesQueries queryParams = {
            query,
            count: pageSize(arguments, self.defaultPageSize, self.maxPageSize)
        };
        int? page = optionalInt(arguments, "page");
        if page is int { queryParams.page = page; }
        anydata|error response = self.slackClient->/search\.messages({}, queryParams);
        if response is error { return slackError(response); }
        return result(response);
    }

    private isolated function getConversationHistory(record {} arguments) returns mcp:CallToolResult|mcp:ServerError {
        string channelId = check requiredString(arguments, "channel_id");
        slack:ConversationsHistoryQueries query = {
            channel: channelId,
            'limit: pageSize(arguments, self.defaultPageSize, self.maxPageSize),
            cursor: optionalString(arguments, "cursor"),
            oldest: optionalDecimal(arguments, "oldest"),
            latest: optionalDecimal(arguments, "latest")
        };
        anydata|error response = self.slackClient->/conversations\.history({}, query);
        if response is error { return slackError(response); }
        return result(response);
    }

    private isolated function getThread(record {} arguments) returns mcp:CallToolResult|mcp:ServerError {
        string channelId = check requiredString(arguments, "channel_id");
        decimal threadTs = check requiredDecimal(arguments, "thread_ts");
        slack:ConversationsRepliesQueries query = {
            channel: channelId,
            ts: threadTs,
            'limit: pageSize(arguments, self.defaultPageSize, self.maxPageSize),
            cursor: optionalString(arguments, "cursor")
        };
        anydata|error response = self.slackClient->/conversations\.replies({}, query);
        if response is error { return slackError(response); }
        return result(response);
    }

    private isolated function findUsers(record {} arguments) returns mcp:CallToolResult|mcp:ServerError {
        string? email = optionalString(arguments, "email");
        if email is string {
            anydata|error response = self.slackClient->/users\.lookupByEmail({}, email = email);
            if response is error { return slackError(response); }
            return result(response);
        }
        slack:UsersListQueries query = {
            'limit: pageSize(arguments, self.defaultPageSize, self.maxPageSize),
            cursor: optionalString(arguments, "cursor")
        };
        anydata|error response = self.slackClient->/users\.list({}, query);
        if response is error { return slackError(response); }
        return result(response);
    }

    private isolated function getMessagePermalink(record {} arguments) returns mcp:CallToolResult|mcp:ServerError {
        string channelId = check requiredString(arguments, "channel_id");
        string messageTs = check requiredString(arguments, "message_ts");
        anydata|error response = self.slackClient->/chat\.getPermalink({}, channel = channelId,
            messageTs = messageTs);
        if response is error { return slackError(response); }
        return result(response);
    }

    private isolated function sendMessage(record {} arguments) returns mcp:CallToolResult|mcp:ServerError {
        if self.readOnly {
            return error mcp:ServerError("disabled: server is running in READ_ONLY mode; set `readOnly` to false to enable write tools");
        }
        string channelId = check requiredString(arguments, "channel_id");
        if self.allowedChannelIds.length() > 0 && !isChannelAllowed(self.allowedChannelIds, channelId) {
            return error mcp:ServerError(string `channel '${channelId}' is not in allowedChannelIds`);
        }
        string text = check requiredString(arguments, "text");
        slack:ChatPostMessageBody payload = {channel: channelId, text};
        string? threadTs = optionalString(arguments, "thread_ts");
        if threadTs is string { payload.threadTs = threadTs; }
        anydata|error response = self.slackClient->/chat\.postMessage.post(payload);
        if response is error { return slackError(response); }
        return result(response);
    }

}

isolated function tool(string name, string description, mcp:JsonSchema inputSchema, boolean readOnly) returns mcp:ToolDefinition {
    return {name, description, inputSchema, annotations: {readOnlyHint: readOnly, destructiveHint: false}};
}

isolated function schema(map<anydata> properties = {}, string[] required = []) returns mcp:JsonSchema {
    return {'type: "object", properties, required};
}

isolated function stringSchema() returns map<anydata> => {'type: "string"};
isolated function integerSchema() returns map<anydata> => {'type: "integer"};
isolated function numberSchema() returns map<anydata> => {'type: "number"};

isolated function result(anydata value) returns mcp:CallToolResult {
    string text = value.toJsonString();
    return {content: [{'type: "text", text}], structuredContent: {result: value}};
}

isolated function slackError(error err) returns mcp:ServerError => error mcp:ServerError(err.message());

isolated function requiredString(record {} arguments, string key) returns string|mcp:ServerError {
    string|error value = arguments[key].cloneWithType();
    return value is error ? error mcp:ServerError(string `Missing or invalid '${key}' parameter`) : value;
}

isolated function optionalString(record {} arguments, string key) returns string? {
    if !arguments.hasKey(key) { return (); }
    string|error value = arguments[key].cloneWithType();
    return value is error ? () : value;
}

isolated function requiredDecimal(record {} arguments, string key) returns decimal|mcp:ServerError {
    decimal|error value = arguments[key].cloneWithType();
    return value is error ? error mcp:ServerError(string `Missing or invalid '${key}' parameter`) : value;
}

isolated function optionalDecimal(record {} arguments, string key) returns decimal? {
    if !arguments.hasKey(key) { return (); }
    decimal|error value = arguments[key].cloneWithType();
    return value is error ? () : value;
}

isolated function optionalInt(record {} arguments, string key) returns int? {
    if !arguments.hasKey(key) { return (); }
    int|error value = arguments[key].cloneWithType();
    return value is error ? () : value;
}

isolated function pageSize(record {} arguments, int defaultPageSize, int maxPageSize) returns int {
    int requested = optionalInt(arguments, "limit") ?: defaultPageSize;
    if requested < 1 { return 1; }
    return requested > maxPageSize ? maxPageSize : requested;
}

isolated function isChannelAllowed(readonly & string[] allowedChannelIds, string channelId) returns boolean {
    foreach string allowedChannelId in allowedChannelIds {
        if allowedChannelId == channelId { return true; }
    }
    return false;
}
