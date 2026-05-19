import Foundation
import os
import JetpackSocial
import WordPressAPI
import WordPressAPIInternal
import WordPressData

public final class JetpackSocialFactory: Sendable {
    public static let shared = JetpackSocialFactory()

    private let instances = OSAllocatedUnfairLock<[ServiceConfiguration: SiteSocialConnectionsService]>(initialState: [:])

    init() {}

    @MainActor
    public func connectionsService(for blog: Blog) -> SiteSocialConnectionsService? {
        guard let configuration = serviceConfiguration(for: blog) else {
            return nil
        }
        return connectionsService(
            configuration: configuration,
            canMarkAsShared: blog.isUserCapableOf(.editOthersPosts)
        )
    }

    @MainActor
    private func connectionsService(
        configuration: ServiceConfiguration,
        canMarkAsShared: Bool
    ) -> SiteSocialConnectionsService? {
        if let cached = instances.withLock({ $0[configuration] }) {
            cached.updatePermissions(canMarkAsShared: canMarkAsShared)
            return cached
        }
        let service = SiteSocialConnectionsService(
            client: WPComApiClient(
                urlSession: URLSession(configuration: .ephemeral),
                authentication: configuration.authentication
            ),
            siteId: configuration.siteId,
            canMarkAsShared: canMarkAsShared
        )
        let stored = instances.withLock { dict in
            if let existing = dict[configuration] {
                return existing
            }
            dict[configuration] = service
            return service
        }
        stored.updatePermissions(canMarkAsShared: canMarkAsShared)
        return stored
    }

    public func reset() {
        instances.withLock { dict in
            dict.removeAll()
        }
    }

    private func serviceConfiguration(for blog: Blog) -> ServiceConfiguration? {
        guard let siteId = blog.dotComID?.int64Value, siteId > 0 else {
            return nil
        }
        // Jetpack Social v2 talks to WP.com Publicize APIs. This includes
        // Jetpack-connected self-hosted blogs, but only when the blog is linked
        // to WP.com through its own account. App-password-only self-hosted
        // blogs are intentionally unsupported here.
        // TODO: Revisit app-password-only support if Social v2 gets a non-WP.com account flow.
        guard let account = blog.account else {
            return nil
        }
        guard let authToken = account.authToken, !authToken.isEmpty else {
            return nil
        }
        return ServiceConfiguration(
            siteId: siteId,
            accountID: TaggedManagedObjectID(account),
            authToken: authToken
        )
    }
}

private struct ServiceConfiguration: Hashable {
    let siteId: Int64
    let accountID: TaggedManagedObjectID<WPAccount>
    let authToken: String

    var authentication: WpAuthentication {
        .bearer(token: authToken)
    }
}
