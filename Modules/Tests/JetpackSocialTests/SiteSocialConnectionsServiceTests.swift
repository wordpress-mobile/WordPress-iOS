import Foundation
import Testing
import WordPressAPI
@testable import JetpackSocial

@Suite("SiteSocialConnectionsService idle state")
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

    @Test("connections starts in idle state")
    @MainActor
    func connectionsIdleOnInit() {
        let client = WPComApiClient(authentication: .none)
        let service = SiteSocialConnectionsService(
            client: client,
            siteId: 1
        )
        if case .idle = service.connections {
        } else {
            Issue.record("Expected .idle, got \(service.connections)")
        }
    }

}
