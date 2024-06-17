import XCTest
import OHHTTPStubs
import wpxmlrpc
#if SWIFT_PACKAGE
@testable import CoreAPI
import OHHTTPStubsSwift
#else
@testable import WordPressKit
#endif

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
        api.callMethod("wp.getPost", parameters: nil, success: { (responseObject: AnyObject, _: HTTPURLResponse?) in
            expect.fulfill()
            XCTAssert(responseObject is [String: AnyObject], "The response should be a dictionary")
            }, failure: { (_, _) in
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
            success: { (responseObject: AnyObject, _: HTTPURLResponse?) in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { (error, _) in
                expect.fulfill()
                // When building for SPM, the compiler doesn't generate the domain constant.
#if SWIFT_PACKAGE
                XCTAssertEqual(error.domain, "CoreAPI.WordPressOrgXMLRPCApiError")
#else
                XCTAssertEqual(error.domain, WordPressOrgXMLRPCApiErrorDomain)
#endif
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
            success: { (responseObject: AnyObject, _: HTTPURLResponse?) in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { (error, _) in
                expect.fulfill()

                XCTAssertFalse(error is WordPressOrgXMLRPCApiError)
                // When building for SPM, the compiler doesn't generate the domain constant.
#if SWIFT_PACKAGE
                XCTAssertEqual(error.domain, "CoreAPI.WordPressOrgXMLRPCApiError")
#else
                XCTAssertEqual(error.domain, WordPressOrgXMLRPCApiErrorDomain)
#endif
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
            success: { (responseObject: AnyObject, _: HTTPURLResponse?) in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { (error, _) in
                expect.fulfill()

                XCTAssertTrue(error is WordPressOrgXMLRPCApiError)
                // When building for SPM, the compiler doesn't generate the domain constant.
#if SWIFT_PACKAGE
                XCTAssertEqual(error.domain, "CoreAPI.WordPressOrgXMLRPCApiError")
#else
                XCTAssertEqual(error.domain, WordPressOrgXMLRPCApiErrorDomain)
#endif
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
            success: { (responseObject: AnyObject, _: HTTPURLResponse?) in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { (error, _) in
                expect.fulfill()

                XCTAssertTrue(error is URLError)
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
            success: { (responseObject: AnyObject, _: HTTPURLResponse?) in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { (error, _) in
                expect.fulfill()

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
            success: { (responseObject: AnyObject, _: HTTPURLResponse?) in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { (error, _) in
                expect.fulfill()

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
            success: { (responseObject: AnyObject, _: HTTPURLResponse?) in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { (error, _) in
                expect.fulfill()

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
            success: { (responseObject: AnyObject, _: HTTPURLResponse?) in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { (error, _) in
                expect.fulfill()

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
            success: { (_, _) in success.fulfill() },
            failure: { (_, _) in }
        )

        let observerCalled = expectation(description: "Progress observer is called")
        observerCalled.assertForOverFulfill = false
        let observer = progress?.observe(\.fractionCompleted, options: .new, changeHandler: { _, _ in
            XCTAssertTrue(Thread.isMainThread)
            observerCalled.fulfill()
        })

        wait(for: [success, observerCalled], timeout: 0.3)
        observer?.invalidate()

        XCTAssertEqual(progress?.fractionCompleted, 1)
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
            success: { (_, _) in },
            failure: { (_, _) in failure.fulfill() }
        )

        let observerCalled = expectation(description: "Progress observer is called")
        observerCalled.assertForOverFulfill = false
        let observer = progress?.observe(\.fractionCompleted, options: .new, changeHandler: { _, _ in
            XCTAssertTrue(Thread.isMainThread)
            observerCalled.fulfill()
        })

        wait(for: [failure, observerCalled], timeout: 0.3)
        observer?.invalidate()

        XCTAssertEqual(progress?.fractionCompleted, 1)
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
            success: { (_, _) in success.fulfill() },
            failure: { (_, _) in }
        )

        let observerCalled = expectation(description: "Progress observer is called")
        observerCalled.assertForOverFulfill = false
        let observer = progress?.observe(\.fractionCompleted, options: .new, changeHandler: { _, _ in
            XCTAssertTrue(Thread.isMainThread)
            observerCalled.fulfill()
        })

        wait(for: [success, observerCalled], timeout: 0.3)
        observer?.invalidate()

        XCTAssertEqual(progress?.fractionCompleted, 1)
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
            success: { (_, _) in },
            failure: { (_, _) in failure.fulfill() }
        )

        let observerCalled = expectation(description: "Progress observer is called")
        observerCalled.assertForOverFulfill = false
        let observer = progress?.observe(\.fractionCompleted, options: .new, changeHandler: { _, _ in
            XCTAssertTrue(Thread.isMainThread)
            observerCalled.fulfill()
        })

        wait(for: [failure, observerCalled], timeout: 0.3)
        observer?.invalidate()

        XCTAssertEqual(progress?.fractionCompleted, 1)
    }

}
