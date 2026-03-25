import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressData
import WordPressShared

extension PostSocialSharingSettings {

    /// Creates `PostSocialSharingSettings` from typed wordpress-rs fields
    /// on an `AnyPostWithEditContext`.
    ///
    /// Returns `nil` if the post has no connections or all connections are broken.
    static func make(
        from post: AnyPostWithEditContext,
        blog: Blog
    ) -> PostSocialSharingSettings? {
        guard let connections = post.jetpackSocialPublicizeConnections,
              !connections.isEmpty else {
            return nil
        }

        var serviceMap = [String: [Connection]]()
        for conn in connections where !isBroken(status: conn.status) {
            var list = serviceMap[conn.serviceName] ?? []
            list.append(Connection(
                account: conn.displayName,
                id: conn.connectionId,
                enabled: conn.enabled ?? true
            ))
            serviceMap[conn.serviceName] = list
        }

        let services = serviceMap.map {
            let name = PublicizeService.ServiceName(rawValue: $0.key) ?? .unknown
            return Service(name: name, connections: $0.value)
        }

        guard !services.isEmpty else {
            return nil
        }

        let message = post.jetpackSocialPublicizeMessage
            ?? post.title?.raw
            ?? ""

        return PostSocialSharingSettings(
            services: services,
            message: message,
            sharingLimit: blog.sharingLimit
        )
    }

    /// Creates default sharing settings for a new post with all blog connections enabled.
    /// Returns `nil` if the blog has no usable connections.
    static func makeDefault(for blog: Blog, postTitle: String = "") -> PostSocialSharingSettings? {
        let connections = blog.sortedConnections.filter { !$0.requiresUserAction() }
        guard !connections.isEmpty else {
            return nil
        }

        var serviceMap = [String: [Connection]]()
        for conn in connections {
            var list = serviceMap[conn.service] ?? []
            list.append(Connection(
                account: conn.externalDisplay,
                id: String(conn.connectionID.intValue),
                enabled: true
            ))
            serviceMap[conn.service] = list
        }

        let services = serviceMap.map {
            let name = PublicizeService.ServiceName(rawValue: $0.key) ?? .unknown
            return Service(name: name, connections: $0.value)
        }
        guard !services.isEmpty else {
            return nil
        }

        return PostSocialSharingSettings(
            services: services,
            message: postTitle,
            sharingLimit: blog.sharingLimit
        )
    }

    // MARK: - Serialization

    /// Creates `PublicizeConnectionUpdate` values for the wordpress-rs write API.
    func makeConnectionUpdates() -> [JetpackPublicizeConnectionUpdate] {
        services.flatMap(\.connections).map {
            JetpackPublicizeConnectionUpdate(connectionId: $0.id, enabled: $0.enabled)
        }
    }

    // MARK: - Private

    private static func isBroken(status: String?) -> Bool {
        status == "broken" || status == "must_reauth"
    }
}
