@testable import WordPressKit
import Testing

struct ActivityTests {

    @Test func activityDecoding() throws {
        let data = try #require(activityLogComment.data(using: .utf8))
        let activity = try JSONDecoder().decode(Activity.self, from: data)
        #expect(activity.activityID == "AWRNRTAUjEqjFGbx8DZj")
        #expect(activity.isRewindable == false)
        #expect(activity.rewindID == "1530304735.2771")
    }

    @Test func actorWithMCPAgentFields() throws {
        let data = try #require(activityLogMCPAgent.data(using: .utf8))
        let activity = try JSONDecoder().decode(Activity.self, from: data)
        let actor = try #require(activity.actor)
        #expect(actor.isMCPAgent == true)
        #expect(actor.mcpClient == "Claude")
        #expect(actor.displayName == "bot-user")
        #expect(actor.role == "administrator")
    }

    @Test func actorWithoutMCPAgentFields() throws {
        let data = try #require(activityLogComment.data(using: .utf8))
        let activity = try JSONDecoder().decode(Activity.self, from: data)
        let actor = try #require(activity.actor)
        #expect(actor.isMCPAgent == false)
        #expect(actor.mcpClient == nil)
    }

    @Test func actorWithExplicitlyFalseMCPAgent() throws {
        let data = try #require(activityLogExplicitlyNotMCPAgent.data(using: .utf8))
        let activity = try JSONDecoder().decode(Activity.self, from: data)
        let actor = try #require(activity.actor)
        #expect(actor.isMCPAgent == false)
        #expect(actor.mcpClient == nil)
    }

    @Test func actorWithMCPAgentButNoClient() throws {
        let data = try #require(activityLogMCPAgentNoClient.data(using: .utf8))
        let activity = try JSONDecoder().decode(Activity.self, from: data)
        let actor = try #require(activity.actor)
        #expect(actor.isMCPAgent == true)
        #expect(actor.mcpClient == nil)
    }
}

private let activityLogMCPAgent: String = """
{
    "summary": "Post published",
    "content": {
        "text": "Post published by MCP agent"
    },
    "name": "post__published",
    "actor": {
        "type": "Person",
        "name": "bot-user",
        "external_user_id": 0,
        "wpcom_user_id": 100000001,
        "icon": {
            "type": "Image",
            "url": "https://secure.gravatar.com/avatar/example?s=96&d=identicon&r=g",
            "width": 96,
            "height": 96
        },
        "role": "administrator",
        "is_mcp_agent": true,
        "mcp_client": "Claude"
    },
    "type": "Create",
    "published": "2026-03-17T10:00:00.000+00:00",
    "generator": {
        "jetpack_version": 0,
        "blog_id": 137726971
    },
    "is_rewindable": false,
    "rewind_id": "1710000000.0001",
    "gridicon": "posts",
    "status": "success",
    "activity_id": "test-mcp-agent-activity",
    "object": {
        "type": "Post",
        "object_id": 100
    },
    "is_discarded": false
}
"""

private let activityLogExplicitlyNotMCPAgent: String = """
{
    "summary": "Post updated",
    "content": {
        "text": "Post updated by a human"
    },
    "name": "post__updated",
    "actor": {
        "type": "Person",
        "name": "human-user",
        "external_user_id": 0,
        "wpcom_user_id": 100000002,
        "icon": {
            "type": "Image",
            "url": "https://secure.gravatar.com/avatar/example2?s=96&d=identicon&r=g",
            "width": 96,
            "height": 96
        },
        "role": "editor",
        "is_mcp_agent": false,
        "mcp_client": null
    },
    "type": "Update",
    "published": "2026-03-17T11:00:00.000+00:00",
    "generator": {
        "jetpack_version": 0,
        "blog_id": 137726971
    },
    "is_rewindable": false,
    "rewind_id": "1710000001.0001",
    "gridicon": "posts",
    "status": "success",
    "activity_id": "test-not-mcp-agent",
    "object": {
        "type": "Post",
        "object_id": 101
    },
    "is_discarded": false
}
"""

private let activityLogMCPAgentNoClient: String = """
{
    "summary": "Post drafted",
    "content": {
        "text": "Post drafted by MCP agent without client"
    },
    "name": "post__drafted",
    "actor": {
        "type": "Person",
        "name": "agent-user",
        "external_user_id": 0,
        "wpcom_user_id": 100000003,
        "icon": {
            "type": "Image",
            "url": "https://secure.gravatar.com/avatar/example3?s=96&d=identicon&r=g",
            "width": 96,
            "height": 96
        },
        "role": "administrator",
        "is_mcp_agent": true
    },
    "type": "Create",
    "published": "2026-03-17T12:00:00.000+00:00",
    "generator": {
        "jetpack_version": 0,
        "blog_id": 137726971
    },
    "is_rewindable": false,
    "rewind_id": "1710000002.0001",
    "gridicon": "posts",
    "status": "success",
    "activity_id": "test-mcp-agent-no-client",
    "object": {
        "type": "Post",
        "object_id": 102
    },
    "is_discarded": false
}
"""

// See https://github.com/wordpress-mobile/WordPress-iOS/blob/16adc688f718136ea57c45d5d26c5c13de9d2b9f/WordPress/WordPressTest/Test%20Data/activity-log-comment.json
private let activityLogComment: String = """
{
    "summary": "Comment approved",
    "content": {
        "text": "Comment by aaaaaaaaaa on Hola Lima! 🇵🇪: Great post! True talent!",
        "ranges": [
                   {
                   "url": "https://wordpress.com/comment/137726971/7",
                   "indices": [
                               0,
                               7
                               ],
                   "site_id": 137726971,
                   "root_id": 441,
                   "section": "comment",
                   "intent": "edit",
                   "id": 7
                   },
                   {
                   "url": "https://wordpress.com/edit/post/137726971/441",
                   "indices": [
                               25,
                               40
                               ],
                   "site_id": 137726971,
                   "section": "post",
                   "intent": "edit",
                   "context": "single",
                   "id": 441
                   }
                   ]
    },
    "name": "comment__approved",
    "actor": {
        "type": "Person",
        "name": "etoledom",
        "external_user_id": 0,
        "wpcom_user_id": 129935412,
        "icon": {
            "type": "Image",
            "url": "https://secure.gravatar.com/avatar/8e06b8f61330e7bc0e5eb4e67aa68e0f?s=96&d=identicon&r=g",
            "width": 96,
            "height": 96
        },
        "role": "administrator"
    },
    "type": "Accept",
    "published": "2018-06-29T20:38:55.277+00:00",
    "generator": {
        "jetpack_version": 0,
        "blog_id": 137726971
    },
    "is_rewindable": false,
    "rewind_id": "1530304735.2771",
    "gridicon": "comment",
    "status": null,
    "activity_id": "AWRNRTAUjEqjFGbx8DZj",
    "object": {
        "type": "Comment",
        "object_id": 7
    },
    "target": {
        "type": "Article",
        "name": "Hola Lima! 🇵🇪",
        "post_id": 229,
        "post_type": "post",
        "post_status": "publish"
    },
    "is_discarded": false
}
"""
