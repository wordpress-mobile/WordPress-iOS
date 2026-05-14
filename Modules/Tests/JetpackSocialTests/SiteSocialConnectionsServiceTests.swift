import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import Testing
import WordPressAPI
@testable import JetpackSocial

@Suite("SiteSocialConnectionsService initial state", .serialized)
struct SiteSocialConnectionsServiceTests {
    @Test("connections starts in loading state")
    @MainActor
    func connectionsLoadingOnInit() {
        let client = WPComApiClient(authentication: .none)
        let service = SiteSocialConnectionsService(
            client: client,
            siteId: 1,
            canMarkAsShared: false
        )
        if case .loading = service.connections {
        } else {
            Issue.record("Expected .loading, got \(service.connections)")
        }
    }

    @Test("shared permission can be initialized and refreshed")
    @MainActor
    func sharedPermissionCanBeInitializedAndRefreshed() {
        let client = WPComApiClient(authentication: .none)
        let service = SiteSocialConnectionsService(
            client: client,
            siteId: 1,
            canMarkAsShared: false
        )
        #expect(!service.canMarkAsShared)

        service.updatePermissions(canMarkAsShared: true)

        #expect(service.canMarkAsShared)
    }

    @Test("loadConnections returns the loaded site connections")
    @MainActor
    func loadConnectionsReturnsLoadedConnections() async throws {
        defer { HTTPStubs.removeAllStubs() }
        let requestRecorder = RequestRecorder()
        stubPublicizeConnections(
            requestRecorder: requestRecorder,
            responseObject: [connectionResponse(shared: false)]
        )
        let service = makeService()

        let connections = try await service.loadConnections()

        #expect(requestRecorder.didReceiveRequest)
        #expect(connections.map(\.externalID) == ["ext-42"])
        #expect(connections.map(\.serviceName) == ["mastodon"])
    }

    @Test("loadConnections throws when the site connection list cannot load")
    @MainActor
    func loadConnectionsThrowsWhenConnectionsFailToLoad() async {
        defer { HTTPStubs.removeAllStubs() }
        let requestRecorder = RequestRecorder()
        stubPublicizeConnections(
            requestRecorder: requestRecorder,
            statusCode: 500,
            responseObject: [
                "code": "rest_forbidden",
                "message": "Forbidden",
                "data": ["status": 500]
            ]
        )
        let service = makeService()

        do throws(SocialSharingError) {
            _ = try await service.loadConnections()
            Issue.record("Expected loading connections to throw")
        } catch {
            #expect(requestRecorder.didReceiveRequest)
            if case .network = error {
                return
            }
            Issue.record("Expected .network, got \(error)")
        }
    }

    @Test("updateConnection keeps the server-confirmed shared state on success")
    @MainActor
    func updateConnectionKeepsServerConfirmedSharedStateOnSuccess() async throws {
        defer { HTTPStubs.removeAllStubs() }
        let updateRecorder = RequestRecorder()
        stubPublicizeConnections(
            requestRecorder: RequestRecorder(),
            responseObject: [connectionResponse(shared: false)]
        )
        stubUpdatePublicizeConnection(
            requestRecorder: updateRecorder,
            responseObject: connectionResponse(shared: true)
        )
        let service = makeService()
        _ = try await service.loadConnections()

        let updated = try await service.updateConnection(id: "123", shared: true)

        #expect(updateRecorder.didReceiveRequest)
        #expect(updated.isShared)
        #expect(service.connections.value?.first?.isShared == true)
    }

    @Test("updateConnection rolls back shared state and throws on failure")
    @MainActor
    func updateConnectionRollsBackSharedStateAndThrowsOnFailure() async throws {
        defer { HTTPStubs.removeAllStubs() }
        let updateRecorder = RequestRecorder()
        stubPublicizeConnections(
            requestRecorder: RequestRecorder(),
            responseObject: [connectionResponse(shared: false)]
        )
        stubUpdatePublicizeConnection(
            requestRecorder: updateRecorder,
            statusCode: 500,
            responseObject: [
                "code": "rest_forbidden",
                "message": "Forbidden",
                "data": ["status": 500]
            ]
        )
        let service = makeService()
        _ = try await service.loadConnections()

        do throws(SocialSharingError) {
            _ = try await service.updateConnection(id: "123", shared: true)
            Issue.record("Expected updating the connection to throw")
        } catch {
            #expect(updateRecorder.didReceiveRequest)
            #expect(service.connections.value?.first?.isShared == false)
            if case .network = error {
                return
            }
            Issue.record("Expected .network, got \(error)")
        }
    }
}

@MainActor
private func makeService() -> SiteSocialConnectionsService {
    let client = WPComApiClient(authentication: .none)
    return SiteSocialConnectionsService(
        client: client,
        siteId: 1,
        canMarkAsShared: false
    )
}

private func stubPublicizeConnections(
    requestRecorder: RequestRecorder,
    statusCode: Int = 200,
    responseObject: Any
) {
    stub(
        condition: isHost("public-api.wordpress.com")
            && isMethodGET()
            && isPath("/wpcom/v2/sites/1/publicize/connections")
    ) { request in
        requestRecorder.record(request)
        return HTTPStubsResponse(
            jsonObject: responseObject,
            statusCode: Int32(statusCode),
            headers: ["Content-Type": "application/json"]
        )
    }
}

private func stubUpdatePublicizeConnection(
    requestRecorder: RequestRecorder,
    statusCode: Int = 200,
    responseObject: Any
) {
    stub(
        condition: isHost("public-api.wordpress.com")
            && isMethodPOST()
            && isPath("/wpcom/v2/sites/1/publicize/connections/123")
    ) { request in
        requestRecorder.record(request)
        return HTTPStubsResponse(
            jsonObject: responseObject,
            statusCode: Int32(statusCode),
            headers: ["Content-Type": "application/json"]
        )
    }
}

private func connectionResponse(shared: Bool) -> [String: Any] {
    [
        "connection_id": "123",
        "display_name": "Tony Li",
        "external_handle": "@tony",
        "external_id": "ext-42",
        "profile_link": "https://example.com/tony",
        "profile_picture": "https://example.com/tony.jpg",
        "service_label": "Mastodon",
        "service_name": "mastodon",
        "shared": shared,
        "status": "ok",
        "wpcom_user_id": 67890,
        "id": "123",
        "username": "tony",
        "profile_display_name": "Tony Li",
        "global": false
    ]
}

private final class RequestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var request: URLRequest?

    var didReceiveRequest: Bool {
        lock.lock()
        defer { lock.unlock() }
        return request != nil
    }

    func record(_ request: URLRequest) {
        lock.lock()
        self.request = request
        lock.unlock()
    }
}
