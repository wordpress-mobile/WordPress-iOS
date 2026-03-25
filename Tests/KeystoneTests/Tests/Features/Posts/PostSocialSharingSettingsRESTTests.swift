import Testing
import Foundation
import WordPressAPI
import WordPressAPIInternal
@testable import WordPress
@testable import WordPressData

@MainActor
@Suite("PostSocialSharingSettings REST Tests")
struct PostSocialSharingSettingsRESTTests {

    @Test("Parses connections from typed wordpress-rs fields")
    func parsesConnections() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = makePost(connections: [
            PublicizeConnection(connectionId: "123", displayName: "My Page", serviceName: "facebook", enabled: true, status: "ok"),
            PublicizeConnection(connectionId: "456", displayName: "@myhandle", serviceName: "twitter", enabled: false, status: "ok")
        ])

        let settings = PostSocialSharingSettings.make(from: post, blog: blog)

        let allConnections = settings?.services.flatMap(\.connections) ?? []
        #expect(allConnections.count == 2)

        let fb = allConnections.first { $0.id == "123" }
        #expect(fb?.account == "My Page")
        #expect(fb?.enabled == true)

        let tw = allConnections.first { $0.id == "456" }
        #expect(tw?.account == "@myhandle")
        #expect(tw?.enabled == false)
    }

    @Test("Returns nil when post has no connections")
    func nilForMissingField() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = makePost(connections: nil)

        let settings = PostSocialSharingSettings.make(from: post, blog: blog)

        #expect(settings == nil)
    }

    @Test("Returns nil for empty connections array")
    func nilForEmptyArray() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = makePost(connections: [])

        let settings = PostSocialSharingSettings.make(from: post, blog: blog)

        #expect(settings == nil)
    }

    @Test("Creates connection updates for serialization")
    func serializesChanges() throws {
        let services = [
            PostSocialSharingSettings.Service(
                name: .facebook,
                connections: [
                    .init(account: "Page", id: "123", enabled: false)
                ]
            )
        ]
        let settings = PostSocialSharingSettings(
            services: services,
            message: "Check this out!",
            sharingLimit: nil
        )

        let updates = settings.makeConnectionUpdates()
        #expect(updates.count == 1)
        #expect(updates.first?.connectionId == "123")
        #expect(updates.first?.enabled == false)
    }

    @Test("Filters out broken connections")
    func filtersBrokenConnections() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = makePost(connections: [
            PublicizeConnection(connectionId: "1", displayName: "Good", serviceName: "facebook", enabled: true, status: "ok"),
            PublicizeConnection(connectionId: "2", displayName: "Broken", serviceName: "twitter", enabled: true, status: "broken")
        ])

        let settings = PostSocialSharingSettings.make(from: post, blog: blog)

        let allConnections = settings?.services.flatMap(\.connections) ?? []
        #expect(allConnections.count == 1)
        #expect(allConnections.first?.account == "Good")
    }

    @Test("Reads publicize message from post meta")
    func readsMessageFromMeta() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = makePost(
            connections: [
                PublicizeConnection(connectionId: "1", displayName: "Page", serviceName: "facebook", enabled: true, status: "ok")
            ],
            message: "Custom share message"
        )

        let settings = PostSocialSharingSettings.make(from: post, blog: blog)

        #expect(settings?.message == "Custom share message")
    }

    @Test("Falls back to post title when no custom message")
    func usesPostTitleAsMessage() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = makePost(
            connections: [
                PublicizeConnection(connectionId: "1", displayName: "Page", serviceName: "facebook", enabled: true, status: "ok")
            ],
            title: "My Post Title"
        )

        let settings = PostSocialSharingSettings.make(from: post, blog: blog)

        #expect(settings?.message == "My Post Title")
    }

    @Test("Treats nil status as healthy")
    func nilStatusIsHealthy() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = makePost(connections: [
            PublicizeConnection(connectionId: "1", displayName: "Page", serviceName: "facebook", enabled: true, status: nil)
        ])

        let settings = PostSocialSharingSettings.make(from: post, blog: blog)

        #expect(settings?.services.flatMap(\.connections).count == 1)
    }
}

// MARK: - Test Helpers

private func makePost(
    connections: [PublicizeConnection]?,
    message: String? = nil,
    title: String? = nil
) -> AnyPostWithEditContext {
    // Build additionalFields containing jetpack_publicize_connections
    let additionalFields: AnyJson?
    if let connections {
        let connectionsArray = connections.map { conn -> [String: Any] in
            var dict: [String: Any] = [
                "connection_id": conn.connectionId,
                "display_name": conn.displayName,
                "service_name": conn.serviceName
            ]
            if let enabled = conn.enabled {
                dict["enabled"] = enabled
            }
            if let status = conn.status {
                dict["status"] = status
            }
            return dict
        }
        let json: [String: Any] = [
            "jetpack_publicize_connections": connectionsArray
        ]
        // Other additional fields can go here
        if let data = try? JSONSerialization.data(withJSONObject: json),
           let jsonString = String(data: data, encoding: .utf8) {
            additionalFields = AnyJson.fromRawJson(json: jsonString)
        } else {
            additionalFields = nil
        }
    } else {
        additionalFields = nil
    }

    // Build meta containing jetpack_publicize_message
    let meta: PostMeta?
    if let message {
        meta = jetpackSocialSetPublicizeMessage(existing: nil, message: message)
    } else {
        meta = nil
    }

    return AnyPostWithEditContext(
        id: PostId(1),
        date: "2025-01-01T00:00:00",
        dateGmt: Date(timeIntervalSince1970: 0),
        guid: PostGuidWithEditContext(raw: nil, rendered: ""),
        link: "https://example.com",
        modified: "2025-01-01T00:00:00",
        modifiedGmt: Date(timeIntervalSince1970: 0),
        slug: "test-post",
        status: .draft,
        postType: "post",
        password: nil,
        permalinkTemplate: nil,
        generatedSlug: nil,
        title: title.map { PostTitleWithEditContext(raw: $0, rendered: $0) },
        content: PostContentWithEditContext(raw: nil, rendered: "", protected: nil, blockVersion: nil),
        author: nil,
        excerpt: nil,
        featuredMedia: nil,
        commentStatus: .open,
        pingStatus: .open,
        format: nil,
        meta: meta,
        sticky: nil,
        template: "",
        categories: nil,
        tags: nil,
        parent: nil,
        menuOrder: nil,
        additionalFields: additionalFields
    )
}
