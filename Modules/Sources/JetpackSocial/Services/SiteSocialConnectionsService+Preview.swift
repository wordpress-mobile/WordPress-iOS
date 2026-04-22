#if DEBUG
import Foundation
import WordPressAPI

extension SiteSocialConnectionsService {
    /// Pre-populates the service with in-memory state for SwiftUI previews and
    /// view-layer unit tests. Network calls still go through the supplied
    /// client if invoked, but the initial `@Published` state is seeded.
    @MainActor
    public static func preview(
        connections: [SocialConnection] = []
    ) -> SiteSocialConnectionsService {
        let client = WPComApiClient(authentication: .none)
        let service = SiteSocialConnectionsService(client: client, siteId: 0)
        service._seedForPreview(connections: connections)
        return service
    }
}
#endif
