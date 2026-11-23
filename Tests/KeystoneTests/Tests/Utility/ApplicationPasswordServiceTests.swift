import Foundation
import os
import Testing
import OHHTTPStubs
import OHHTTPStubsSwift
import WordPressAPI
import WordPressCore
import WordPressData
@testable import WordPress

@MainActor
struct ApplicationPasswordServiceTests {
    @Test func deletesOtherPasswordWithCorrectUserAndUUID() async throws {
        let fixture = try ServiceFixture()
        defer { fixture.close() }
        try await fixture.service.deleteApplicationToken(uuid: fixture.other)
        let requests = fixture.requests
        #expect(!fixture.state.withLock { $0.targetExists })
        #expect(
            requests.filter { $0.method == "DELETE" }.map(\.path) == [
                "/wp-json/wp/v2/users/42/application-passwords/\(fixture.other.uuidString.lowercased())"
            ]
        )
        #expect(
            requests.filter { $0.method == "DELETE" || $0.path.hasSuffix("/introspect") }
                .allSatisfy { $0.authorization == fixture.authorization }
        )
    }

    @Test func rejectsCurrentUUIDRegardlessOfCase() async throws {
        let fixture = try ServiceFixture()
        defer { fixture.close() }
        fixture.state.withLock { $0.currentUUID = fixture.current.uuidString.lowercased() }
        await #expect(throws: ApplicationPasswordDeletionError.self) {
            try await fixture.service.deleteApplicationToken(uuid: fixture.current)
        }
        #expect(fixture.deletes.isEmpty)
    }

    @Test(arguments: ["invalid-uuid", ""])
    func rejectsUnknownIdentity(identity: String) async throws {
        let fixture = try ServiceFixture()
        defer { fixture.close() }
        fixture.state.withLock { $0.currentUUID = identity }
        await #expect(throws: ApplicationPasswordDeletionError.self) {
            try await fixture.service.deleteApplicationToken(uuid: fixture.other)
        }
        #expect(fixture.deletes.isEmpty)
    }

    @Test(arguments: [401, 403, 404, 500])
    func introspectionFailureNeverDeletes(status: Int) async throws {
        let fixture = try ServiceFixture()
        defer { fixture.close() }
        fixture.state.withLock { $0.introspectionStatus = status }
        await #expect(throws: (any Error).self) {
            try await fixture.service.deleteApplicationToken(uuid: fixture.other)
        }
        #expect(fixture.deletes.isEmpty)
    }

    @Test func targetNotFoundIsAlreadyDeleted() async throws {
        let fixture = try ServiceFixture()
        defer { fixture.close() }
        fixture.state.withLock { $0.deleteStatus = 404 }
        try await fixture.service.deleteApplicationToken(uuid: fixture.other)
        #expect(fixture.deletes.count == 1)
    }

    @Test(arguments: [401, 403, 500])
    func deletionFailureIsNotSuccessOrReplayed(status: Int) async throws {
        let fixture = try ServiceFixture()
        defer { fixture.close() }
        fixture.state.withLock { $0.deleteStatus = status }
        await #expect(throws: (any Error).self) {
            try await fixture.service.deleteApplicationToken(uuid: fixture.other)
        }
        #expect(fixture.deletes.count == 1)
        #expect(fixture.requests.allSatisfy { $0.method != "POST" })
        #expect(fixture.deletes.first?.authorization == fixture.authorization)
    }

    @Test func unrelated404IsAnError() async throws {
        let fixture = try ServiceFixture()
        defer { fixture.close() }
        fixture.state.withLock {
            $0.deleteStatus = 404; $0.deleteCode = "rest_no_route"
        }
        await #expect(throws: (any Error).self) {
            try await fixture.service.deleteApplicationToken(uuid: fixture.other)
        }
    }

    @Test func timeoutIsAnErrorAndRetryCanResolveToAlreadyGone() async throws {
        let fixture = try ServiceFixture()
        defer { fixture.close() }
        fixture.state.withLock { $0.deleteTimesOut = true }
        await #expect(throws: (any Error).self) {
            try await fixture.service.deleteApplicationToken(uuid: fixture.other)
        }
        fixture.state.withLock {
            $0.deleteTimesOut = false; $0.deleteStatus = 404
        }
        try await fixture.service.deleteApplicationToken(uuid: fixture.other)
        #expect(fixture.deletes.count == 2)
    }

    @Test func unconfirmedDeletionIsAnError() async throws {
        let fixture = try ServiceFixture()
        defer { fixture.close() }
        fixture.state.withLock { $0.deleted = false }
        await #expect(throws: ApplicationPasswordDeletionError.self) {
            try await fixture.service.deleteApplicationToken(uuid: fixture.other)
        }
    }

    @Test func identityIsRecheckedAfterDisplay() async throws {
        let fixture = try ServiceFixture()
        defer { fixture.close() }
        let tokens = try await fixture.service.loadApplicationTokens()
        #expect(tokens.first { $0.uuid == fixture.other }?.canDelete == true)
        fixture.password = "rotated-test-password"
        fixture.state.withLock { $0.currentUUID = fixture.other.uuidString }
        await #expect(throws: ApplicationPasswordDeletionError.self) {
            try await fixture.service.deleteApplicationToken(uuid: fixture.other)
        }
        #expect(fixture.deletes.isEmpty)
        #expect(fixture.requests.last { $0.path.hasSuffix("/introspect") }?.authorization != fixture.authorization)
    }

    @Test func failedIntrospectionClearsPriorCurrentMarkerAndDisablesDeletion() async throws {
        let fixture = try ServiceFixture()
        defer { fixture.close() }
        #expect(try await fixture.service.loadApplicationTokens().contains { $0.isCurrent })
        fixture.state.withLock { $0.introspectionStatus = 403 }
        let tokens = try await fixture.service.loadApplicationTokens()
        #expect(tokens.count == 2)
        #expect(tokens.allSatisfy { !$0.isCurrent && !$0.canDelete })
    }
}

@MainActor
private final class ServiceFixture {
    struct Request {
        let method: String
        let path: String
        let authorization: String?
    }
    struct State {
        var currentUUID: String
        var introspectionStatus = 200
        var deleteStatus = 200
        var deleteCode = "rest_application_password_not_found"
        var deleteTimesOut = false
        var deleted = true
        var targetExists = true
        var requests: [Request] = []
    }

    let current = UUID()
    let other = UUID()
    let state: OSAllocatedUnfairLock<State>
    let coreDataStack = ContextManager.forTesting()
    let host = "\(UUID().uuidString.lowercased()).example.test"
    let authorization = "Basic " + Data("demo:original-test-password".utf8).base64EncodedString()
    var password = "original-test-password"
    private var descriptor: HTTPStubsDescriptor?
    private(set) var service: ApplicationPasswordService!

    var requests: [Request] { state.withLock { $0.requests } }
    var deletes: [Request] { requests.filter { $0.method == "DELETE" } }

    init() throws {
        state = OSAllocatedUnfairLock(initialState: State(currentUUID: current.uuidString))
        let state = self.state
        let current = self.current
        let other = self.other
        descriptor = stub(condition: isHost(host)) { request in
            state.withLock { state in
                let path = request.url!.path
                let method = request.httpMethod ?? "GET"
                state.requests.append(
                    Request(
                        method: method,
                        path: path,
                        authorization: request.value(forHTTPHeaderField: "Authorization")
                    )
                )
                func response(_ json: Any, status: Int = 200) -> HTTPStubsResponse {
                    HTTPStubsResponse(
                        jsonObject: json,
                        statusCode: Int32(status),
                        headers: ["Content-Type": "application/json"]
                    )
                }
                func token(_ uuid: String) -> [String: Any] {
                    [
                        "uuid": uuid.lowercased(), "app_id": "same-app", "name": "Same name",
                        "created": "2026-11-24T00:00:00",
                        "last_used": NSNull(), "last_ip": NSNull()
                    ]
                }
                func error(_ status: Int, code: String = "rest_application_password_not_found") -> HTTPStubsResponse {
                    response(["code": code, "message": "Test failure", "data": ["status": status]], status: status)
                }
                if path.hasSuffix("/introspect") {
                    return state.introspectionStatus == 200
                        ? response(token(state.currentUUID)) : error(state.introspectionStatus)
                }
                if method == "DELETE" {
                    // Core compares the path UUID to its stored lowercase string exactly.
                    guard path.hasSuffix(other.uuidString.lowercased()) else { return error(404) }
                    if state.deleteTimesOut { return HTTPStubsResponse(error: URLError(.timedOut)) }
                    if state.deleteStatus != 200 { return error(state.deleteStatus, code: state.deleteCode) }
                    if state.deleted { state.targetExists = false }
                    return response(["deleted": state.deleted, "previous": token(other.uuidString)])
                }
                if path.hasSuffix("/application-passwords") {
                    return response([token(current.uuidString)] + (state.targetExists ? [token(other.uuidString)] : []))
                }
                if path.hasSuffix("/users/me") {
                    return response(["id": 42, "name": "Demo", "url": "", "description": "", "link": "", "slug": "demo"]
                    )
                }
                return error(404, code: "rest_no_route")
            }
        }
        let api = try makeAPI()
        let client = WordPressClient(api: api, siteURL: URL(string: "https://\(host)")!)
        service = ApplicationPasswordService(
            api: client,
            currentUserId: 42,
            makeDeletionAPI: { [unowned self] in try self.makeAPI() }
        )
    }

    private func makeAPI() throws -> WordPressAPI {
        let blog = BlogBuilder(coreDataStack.mainContext).build()
        let site = try WordPressSite(
            blogId: TaggedManagedObjectID(blog),
            siteURL: URL(string: "https://\(host)")!,
            flavor: .selfHosted(
                .init(apiRootURL: .parse(input: "https://\(host)/wp-json"), username: "demo", token: password)
            )
        )
        return try WordPressClient.applicationPasswordAPI(for: site)
    }

    func close() {
        if let descriptor { HTTPStubs.removeStub(descriptor) }
    }
}
