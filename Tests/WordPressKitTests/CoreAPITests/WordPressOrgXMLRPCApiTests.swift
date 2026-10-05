import XCTest
import OHHTTPStubs
import wpxmlrpc
import OHHTTPStubsSwift

@testable import WordPressKit

class WordPressOrgXMLRPCApiTests: XCTestCase {

    let xmlrpcEndpoint = "http://wordpress.org/xmlrpc.php"
    let xmlContentTypeHeaders: [String: Any] = ["Content-Type": "application/xml"]

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    private func isXmlRpcAPIRequest() -> HTTPStubsTestBlock {
        return { request in
            return request.url?.absoluteString == self.xmlrpcEndpoint
        }
    }

    func testSuccessfullCall() throws {
        let stubPath = try XCTUnwrap(OHPathForFileInBundle("xmlrpc-response-getpost.xml", Bundle.coreAPITestsBundle))
        stub(condition: isXmlRpcAPIRequest()) { _ in
            return fixture(filePath: stubPath, headers: self.xmlContentTypeHeaders)
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressOrgXMLRPCApi(endpoint: URL(string: xmlrpcEndpoint)! as URL)
        api.callMethod("wp.getPost", parameters: nil, success: { responseObject, _ in
            expect.fulfill()
            XCTAssert(responseObject is [String: AnyObject], "The response should be a dictionary")
            }, failure: { _, _ in
                expect.fulfill()
                XCTFail("This call should be successfull")
            }
        )
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func test404() {
        stub(condition: isXmlRpcAPIRequest()) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 404, headers: self.xmlContentTypeHeaders)
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressOrgXMLRPCApi(endpoint: URL(string: xmlrpcEndpoint)! as URL)
        api.callMethod(
            "wp.getPost",
            parameters: nil,
            success: { _, _ in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { error, _ in
                expect.fulfill()

                XCTAssertTrue(error is WordPressOrgXMLRPCApiError)

                let error = error as NSError
                XCTAssertEqual(error.code, WordPressOrgXMLRPCApiError.httpErrorStatusCode.rawValue)
                XCTAssertEqual(error.localizedFailureReason, "An HTTP error code 404 was returned.")
                XCTAssertNotNil(error.userInfo[WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyData as String])
                XCTAssertNotNil(error.userInfo[WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyStatusCode as String])
            }
        )
        wait(for: [expect], timeout: 0.3)
    }

    func test403() {
        stub(condition: isXmlRpcAPIRequest()) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 403, headers: self.xmlContentTypeHeaders)
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressOrgXMLRPCApi(endpoint: URL(string: xmlrpcEndpoint)! as URL)
        api.callMethod(
            "wp.getPost",
            parameters: nil,
            success: { _, _ in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { error, _ in
                expect.fulfill()

                XCTAssertFalse(error is WordPressOrgXMLRPCApiError)

                let error = error as NSError
                XCTAssertEqual(error.code, 403)
                XCTAssertEqual(error.localizedFailureReason, "An HTTP error code 403 was returned.")
                XCTAssertNotNil(error.userInfo[WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyData as String])
                XCTAssertNotNil(error.userInfo[WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyStatusCode as String])
            }
        )
        wait(for: [expect], timeout: 0.3)
    }

    func test403WithoutContentTypeHeader() {
        stub(condition: isXmlRpcAPIRequest()) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 403, headers: nil)
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressOrgXMLRPCApi(endpoint: URL(string: xmlrpcEndpoint)! as URL)
        api.callMethod(
            "wp.getPost",
            parameters: nil,
            success: { _, _ in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { error, _ in
                expect.fulfill()

                XCTAssertTrue(error is WordPressOrgXMLRPCApiError)

                let error = error as NSError
                XCTAssertEqual(error.code, WordPressOrgXMLRPCApiError.unknown.rawValue)
                XCTAssertEqual(error.localizedFailureReason, WordPressOrgXMLRPCApiError.unknown.failureReason)
                XCTAssertNotNil(error.userInfo[WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyData as String])
                XCTAssertNil(error.userInfo[WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyStatusCode as String])
            }
        )
        wait(for: [expect], timeout: 0.3)
    }

    func testConnectionError() {
        stub(condition: isXmlRpcAPIRequest()) { _ in
            HTTPStubsResponse(error: URLError(.timedOut))
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressOrgXMLRPCApi(endpoint: URL(string: xmlrpcEndpoint)! as URL)
        api.callMethod(
            "wp.getPost",
            parameters: nil,
            success: { _, _ in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { error, _ in
                expect.fulfill()

                XCTAssertTrue(error is URLError)

                let error = error as NSError
                XCTAssertEqual(error.domain, URLError.errorDomain)
                XCTAssertEqual(error.code, URLError.Code.timedOut.rawValue)
            }
        )
        wait(for: [expect], timeout: 0.3)
    }

    func testFault() throws {
        let responseFile = try XCTUnwrap(OHPathForFileInBundle("xmlrpc-bad-username-password-error.xml", Bundle.coreAPITestsBundle))
        stub(condition: isXmlRpcAPIRequest()) { _ in
            fixture(filePath: responseFile, headers: self.xmlContentTypeHeaders)
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressOrgXMLRPCApi(endpoint: URL(string: xmlrpcEndpoint)! as URL)
        api.callMethod(
            "wp.getPost",
            parameters: nil,
            success: { _, _ in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { error, _ in
                expect.fulfill()

                let error = error as NSError
                XCTAssertEqual(error.domain, WPXMLRPCFaultErrorDomain)
                // 403 is the 'faultCode' in the HTTP response xml.
                XCTAssertEqual(error.code, 403)
                XCTAssertNotNil(error.userInfo[WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyData as String])
                XCTAssertNil(error.userInfo[WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyStatusCode as String])
            }
        )
        wait(for: [expect], timeout: 0.3)
    }

    func testFault401() throws {
        let responseFile = try XCTUnwrap(OHPathForFileInBundle("xmlrpc-bad-username-password-error.xml", Bundle.coreAPITestsBundle))
        stub(condition: isXmlRpcAPIRequest()) { _ in
            fixture(filePath: responseFile, status: 401, headers: self.xmlContentTypeHeaders)
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressOrgXMLRPCApi(endpoint: URL(string: xmlrpcEndpoint)! as URL)
        api.callMethod(
            "wp.getPost",
            parameters: nil,
            success: { _, _ in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { error, _ in
                expect.fulfill()

                let error = error as NSError

                XCTAssertEqual(error.domain, WPXMLRPCFaultErrorDomain)
                // 403 is the 'faultCode' in the HTTP response xml.
                XCTAssertEqual(error.code, 403)
                XCTAssertNil(error.userInfo[WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyStatusCode as String])
                XCTAssertNotNil(error.userInfo[WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyData as String])
            }
        )
        wait(for: [expect], timeout: 0.3)
    }

    func testMalformedXML() throws {
        stub(condition: isXmlRpcAPIRequest()) { _ in
            HTTPStubsResponse(
                data: #"<?xml version="1.0" encoding="UTF-8"?><methodRespons"#.data(using: .utf8)!,
                statusCode: 200,
                headers: self.xmlContentTypeHeaders
            )
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressOrgXMLRPCApi(endpoint: URL(string: xmlrpcEndpoint)! as URL)
        api.callMethod(
            "wp.getPost",
            parameters: nil,
            success: { _, _ in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { error, _ in
                expect.fulfill()

                let error = error as NSError

                XCTAssertEqual(error.domain, XMLParser.errorDomain)
                XCTAssertNotNil(error.userInfo[WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyData as String])
                XCTAssertNil(error.userInfo[WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyStatusCode as String])
            }
        )
        wait(for: [expect], timeout: 0.3)
    }

    func testInvalidXML() throws {
        let responseFile = try XCTUnwrap(OHPathForFileInBundle("xmlrpc-response-invalid.html", Bundle.coreAPITestsBundle))
        stub(condition: isXmlRpcAPIRequest()) { _ in
            fixture(filePath: responseFile, headers: self.xmlContentTypeHeaders)
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressOrgXMLRPCApi(endpoint: URL(string: xmlrpcEndpoint)! as URL)
        api.callMethod(
            "wp.getPost",
            parameters: nil,
            success: { _, _ in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { error, _ in
                expect.fulfill()

                let error = error as NSError

                XCTAssertEqual(error.domain, WPXMLRPCErrorDomain)
                XCTAssertEqual(error.code, WPXMLRPCError.invalidInputError.rawValue)
                XCTAssertNotNil(error.userInfo[WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyData as String])
                XCTAssertNil(error.userInfo[WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyStatusCode as String])
            }
        )
        wait(for: [expect], timeout: 0.3)
    }

    func testProgressUpdate() throws {
        let stubPath = try XCTUnwrap(OHPathForFileInBundle("xmlrpc-response-getpost.xml", Bundle.coreAPITestsBundle))
        stub(condition: isXmlRpcAPIRequest()) { _ in
            return fixture(filePath: stubPath, headers: self.xmlContentTypeHeaders)
        }

        let success = self.expectation(description: "The success callback should be invoked")
        let api = WordPressOrgXMLRPCApi(endpoint: URL(string: xmlrpcEndpoint)! as URL)
        let progress = api.callMethod(
            "wp.getPost",
            parameters: nil,
            success: { _, _ in success.fulfill() },
            failure: { _, _ in }
        )

        let observerCalled = expectation(description: "Progress observer is called")
        observerCalled.assertForOverFulfill = false
        let observer = progress.observe(\.fractionCompleted, options: .new, changeHandler: { _, _ in
            XCTAssertTrue(Thread.isMainThread)
            observerCalled.fulfill()
        })

        wait(for: [success, observerCalled], timeout: 0.3)
        observer.invalidate()

        XCTAssertEqual(progress.fractionCompleted, 1)
    }

    func testProgressUpdateFailure() throws {
        let stubPath = try XCTUnwrap(OHPathForFileInBundle("xmlrpc-bad-username-password-error.xml", Bundle.coreAPITestsBundle))
        stub(condition: isXmlRpcAPIRequest()) { _ in
            return fixture(filePath: stubPath, headers: self.xmlContentTypeHeaders)
        }

        let failure = self.expectation(description: "The failure callback should be invoked")
        let api = WordPressOrgXMLRPCApi(endpoint: URL(string: xmlrpcEndpoint)! as URL)
        let progress = api.callMethod(
            "wp.getPost",
            parameters: nil,
            success: { _, _ in },
            failure: { _, _ in failure.fulfill() }
        )

        let observerCalled = expectation(description: "Progress observer is called")
        observerCalled.assertForOverFulfill = false
        let observer = progress.observe(\.fractionCompleted, options: .new, changeHandler: { _, _ in
            XCTAssertTrue(Thread.isMainThread)
            observerCalled.fulfill()
        })

        wait(for: [failure, observerCalled], timeout: 0.3)
        observer.invalidate()

        XCTAssertEqual(progress.fractionCompleted, 1)
    }

    func testProgressUpdateStreamAPI() throws {
        let stubPath = try XCTUnwrap(OHPathForFileInBundle("xmlrpc-response-getpost.xml", Bundle.coreAPITestsBundle))
        stub(condition: isXmlRpcAPIRequest()) { _ in
            return fixture(filePath: stubPath, headers: self.xmlContentTypeHeaders)
        }

        let success = self.expectation(description: "The success callback should be invoked")
        let api = WordPressOrgXMLRPCApi(endpoint: URL(string: xmlrpcEndpoint)! as URL)
        let progress = api.streamCallMethod(
            "wp.getPost",
            parameters: nil,
            success: { _, _ in success.fulfill() },
            failure: { _, _ in }
        )

        let observerCalled = expectation(description: "Progress observer is called")
        observerCalled.assertForOverFulfill = false
        let observer = progress.observe(\.fractionCompleted, options: .new, changeHandler: { _, _ in
            XCTAssertTrue(Thread.isMainThread)
            observerCalled.fulfill()
        })

        wait(for: [success, observerCalled], timeout: 0.3)
        observer.invalidate()

        XCTAssertEqual(progress.fractionCompleted, 1)
    }

    func testProgressUpdateStreamAPIFailure() throws {
        let stubPath = try XCTUnwrap(OHPathForFileInBundle("xmlrpc-bad-username-password-error.xml", Bundle.coreAPITestsBundle))
        stub(condition: isXmlRpcAPIRequest()) { _ in
            return fixture(filePath: stubPath, headers: self.xmlContentTypeHeaders)
        }

        let failure = self.expectation(description: "The failure callback should be invoked")
        let api = WordPressOrgXMLRPCApi(endpoint: URL(string: xmlrpcEndpoint)! as URL)
        let progress = api.streamCallMethod(
            "wp.getPost",
            parameters: nil,
            success: { _, _ in },
            failure: { _, _ in failure.fulfill() }
        )

        let observerCalled = expectation(description: "Progress observer is called")
        observerCalled.assertForOverFulfill = false
        let observer = progress.observe(\.fractionCompleted, options: .new, changeHandler: { _, _ in
            XCTAssertTrue(Thread.isMainThread)
            observerCalled.fulfill()
        })

        wait(for: [failure, observerCalled], timeout: 0.3)
        observer.invalidate()

        XCTAssertEqual(progress.fractionCompleted, 1)
    }

    /// Requests that start together on a new instance have to share one session.
    ///
    /// If the session is created lazily, each of them can create one. All but one of those sessions
    /// are then destroyed while their requests are still running.
    func testRequestsStartedTogetherOnANewInstanceShareOneSession() async throws {
        let stubPath = try XCTUnwrap(OHPathForFileInBundle("xmlrpc-response-getpost.xml", Bundle.coreAPITestsBundle))
        stub(condition: isXmlRpcAPIRequest()) { _ in
            fixture(filePath: stubPath, headers: self.xmlContentTypeHeaders)
        }

        // `URLSession` tells this delegate which session each request ran on.
        let recorder = SessionRecorder()
        let previousDelegate = wpkURLSessionNotifyingDelegate
        wpkURLSessionNotifyingDelegate = recorder
        defer { wpkURLSessionNotifyingDelegate = previousDelegate }

        let endpoint = try XCTUnwrap(URL(string: xmlrpcEndpoint))
        let instanceCount = 50
        let requestCount = 8
        for _ in 0..<instanceCount {
            let api = WordPressOrgXMLRPCApi(endpoint: endpoint)
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<requestCount {
                    group.addTask { _ = await api.call(method: "wp.getPost", parameters: nil) }
                }
            }
        }

        // The delegate can hear about a request a moment after the request has returned.
        let deadline = Date().addingTimeInterval(10)
        while recorder.requestCount < instanceCount * requestCount, Date() < deadline {
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTAssertEqual(recorder.requestCount, instanceCount * requestCount)
        XCTAssertEqual(recorder.sessionCount, instanceCount, "Some instances used more than one session")
    }
}

/// Records the sessions that requests ran on.
///
/// It keeps hold of them, so that a new session can't be mistaken for an earlier one that has been
/// deallocated and whose address has been reused.
private final class SessionRecorder: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var sessions: [URLSession] = []
    private var requests = 0

    var sessionCount: Int { lock.withLock { sessions.count } }
    var requestCount: Int { lock.withLock { requests } }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        lock.withLock {
            requests += 1
            if !sessions.contains(where: { $0 === session }) {
                sessions.append(session)
            }
        }
    }
}
