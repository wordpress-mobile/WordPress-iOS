import Foundation
import os
import JetpackSocial
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
import WordPressData

public final class JetpackSocialFactory: Sendable {
    public static let shared = JetpackSocialFactory()

    private let instances = OSAllocatedUnfairLock<[WordPressSite: SiteSocialConnectionsService]>(initialState: [:])

    private init() {}

    public func connectionsService(for site: WordPressSite) -> SiteSocialConnectionsService? {
        if let cached = instances.withLock({ $0[site] }) {
            return cached
        }
        guard let siteId = wpComSiteId(for: site) else {
            return nil
        }
        let client = makeClient(for: site)
        let service = SiteSocialConnectionsService(client: client, siteId: siteId)
        return instances.withLock { dict in
            if let existing = dict[site] {
                return existing
            }
            dict[site] = service
            return service
        }
    }

    public func reset() {
        instances.withLock { dict in
            dict.removeAll()
        }
    }

    private func makeClient(for site: WordPressSite) -> WPComApiClient {
        let session = URLSession(configuration: .ephemeral)
        let authentication = readWPComAuthentication(for: site)
        return WPComApiClient(
            urlSession: session,
            authentication: authentication
        )
    }

    private func readWPComAuthentication(for site: WordPressSite) -> WpAuthentication {
        switch site {
        case .dotCom(_, _, let authToken):
            return .bearer(token: authToken)
        case .selfHosted:
            // Self-hosted blogs reach WP.com via the Jetpack tunnel using the
            // default WP.com account token. Mirrors
            // AutoUpdatingWPComAuthenticationProvider in WordPressDotComClient.swift.
            guard
                let token = ContextManager.shared.performQuery({ context in
                    try? WPAccount.lookupDefaultWordPressComAccountToken(in: context)
                })
            else {
                return .none
            }
            return .bearer(token: token)
        }
    }

    private func wpComSiteId(for site: WordPressSite) -> Int64? {
        switch site {
        case let .dotCom(_, siteId, _):
            return Int64(siteId)
        case let .selfHosted(blogId, _, _, _, _):
            // Self-hosted with a WP.com account: resolve the dotComID from
            // the Blog to route requests through public-api.wordpress.com.
            // Sharing v2 requires a WP.com-linked blog, so blogs without a
            // dotComID return nil (no service is created).
            let dotComID = ContextManager.shared.performQuery { context -> Int64? in
                guard let blog = try? context.existingObject(with: blogId) else {
                    return nil
                }
                return blog.dotComID?.int64Value
            }
            guard let dotComID, dotComID > 0 else {
                return nil
            }
            return dotComID
        }
    }
}
