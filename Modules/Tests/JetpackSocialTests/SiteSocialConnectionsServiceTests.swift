import Foundation
import Testing
import WordPressAPI
@testable import JetpackSocial

@Suite("SiteSocialConnectionsService initial state")
struct SiteSocialConnectionsServiceTests {
    @Test("currentConnectionIDs is empty before loading")
    @MainActor
    func emptyBeforeLoad() {
        let client = WPComApiClient(authentication: .none)
        let service = SiteSocialConnectionsService(
            client: client,
            siteId: 1
        )
        #expect(service.currentConnectionIDs().isEmpty)
    }

    @Test("connections starts in loading state")
    @MainActor
    func connectionsLoadingOnInit() {
        let client = WPComApiClient(authentication: .none)
        let service = SiteSocialConnectionsService(
            client: client,
            siteId: 1
        )
        if case .loading = service.connections {
        } else {
            Issue.record("Expected .loading, got \(service.connections)")
        }
    }

}
