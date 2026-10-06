import Foundation
import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift
@testable import WordPressKit

// XCTest, like the neighboring remote tests, to reuse RemoteTestCase's HTTP stubs.
final class NotificationActivityServiceRemoteTests: RemoteTestCase, RESTTestable {

    private let seenEndpoint = "notifications/seen"
    private let meEndpoint = "me?"
    private var remote: NotificationActivityServiceRemote!

    override func setUp() {
        super.setUp()
        remote = NotificationActivityServiceRemote(wordPressComRestApi: getRestApi())
    }

    override func tearDown() {
        remote = nil
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    private func stub(_ endpoint: String, _ json: String, status: Int32 = 200) {
        HTTPStubs.removeAllStubs()
        stubRemoteResponse(endpoint, data: Data(json.utf8), contentType: .ApplicationJSON, status: status)
    }

    private func markSeenError(timestamp: Date = Date(timeIntervalSince1970: 1_789_725_600)) async -> Error? {
        do {
            try await remote.markSeen(timestamp: timestamp)
            return nil
        } catch {
            return error
        }
    }

    func testMarkSeenAcceptsExplicitSuccess() async {
        stub(seenEndpoint, #"{"success":true,"last_seen_time":"1790000000"}"#)
        let error = await markSeenError()
        XCTAssertNil(error)
    }

    func testMarkSeenSendsUnixSeconds() async {
        // Only the expected body succeeds; the more recent stub is matched first.
        stub(seenEndpoint, #"{"success":false}"#)
        OHHTTPStubsSwift.stub(condition: hasJsonBody(["time": 1_789_725_600])) { _ in
            HTTPStubsResponse(
                data: Data(#"{"success":true}"#.utf8),
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }
        let error = await markSeenError()
        XCTAssertNil(error)
    }

    func testMarkSeenRejectsFalseMissingOrNullSuccess() async {
        for body in [#"{"success":false}"#, "{}", #"{"success":null}"#] {
            stub(seenEndpoint, body)
            let error = await markSeenError()
            XCTAssertTrue(error is NotificationActivityServiceRemote.SeenRejectedError, "body: \(body)")
        }
    }

    func testMarkSeenTreatsClientErrorsAsRejection() async {
        let cases: [(status: Int32, body: String)] = [
            (400, #"{"error":"invalid_input","message":"Invalid time"}"#),
            (400, #"{"error":"invalid_param","message":"Invalid time"}"#),
            (404, "Not Found")
        ]
        for (status, body) in cases {
            stub(seenEndpoint, body, status: status)
            let error = await markSeenError()
            XCTAssertTrue(error is NotificationActivityServiceRemote.SeenRejectedError, "status: \(status)")
        }
    }

    func testMarkSeenPassesThroughRetryableErrors() async {
        let cases: [(status: Int32, body: String)] = [
            (403, #"{"error":"authorization_required","message":"An active access token must be used."}"#),
            (403, #"{"error":"invalid_token","message":"Invalid token"}"#),
            (429, #"{"error":"rate_limited","message":"Slow down"}"#),
            (500, #"{"error":"server_error","message":"Oops"}"#),
            (503, "Service Unavailable")
        ]
        for (status, body) in cases {
            stub(seenEndpoint, body, status: status)
            let error = await markSeenError()
            XCTAssertNotNil(error, "status: \(status)")
            XCTAssertFalse(
                error is NotificationActivityServiceRemote.SeenRejectedError,
                "status: \(status) body: \(body)"
            )
        }
    }

    func testFetchHasUnseenNotesReadsTheFlag() async throws {
        stub(meEndpoint, #"{"has_unseen_notes":true}"#)
        let hasUnseen = try await remote.fetchHasUnseenNotes()
        XCTAssertTrue(hasUnseen)
    }

    func testFetchHasUnseenNotesTreatsMissingFlagAsError() async {
        stub(meEndpoint, "{}")
        do {
            _ = try await remote.fetchHasUnseenNotes()
            XCTFail("A missing flag must be an error, not false")
        } catch {}
    }
}
