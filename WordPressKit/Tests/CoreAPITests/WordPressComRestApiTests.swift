import XCTest
import OHHTTPStubs
import WordPressShared
#if SWIFT_PACKAGE
import APIInterface
@testable import CoreAPI
import OHHTTPStubsSwift
#else
@testable import WordPressKit
#endif

class WordPressComRestApiTests: XCTestCase {

    let scheme                          = "https"
    let host                            = "public-api.wordpress.com"
    let wordPressMediaRoutePath         = "/rest/v1.1/sites/0/media/"
    let wordPressMediaNewEndpointPath   = "/rest/v1.1/sites/0/media/new"

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    private func isRestAPIRequest() -> HTTPStubsTestBlock {
        return { request in
            guard let requestURL = request.url, let components = URLComponents(string: requestURL.absoluteString) else {
                return false
            }

            let expectedScheme = self.scheme
            let actualScheme = components.scheme

            let expectedHost = self.host
            let actualHost = components.host

            let expectedPath = self.wordPressMediaRoutePath
            let actualPath = components.path

            let result = expectedScheme == actualScheme && expectedHost == actualHost && expectedPath == actualPath
            return result
        }
    }

    private func isRestAPIMediaNewRequest() -> HTTPStubsTestBlock {
        return { request in
            guard let requestURL = request.url, let components = URLComponents(string: requestURL.absoluteString) else {
                return false
            }

            let expectedScheme = self.scheme
            let actualScheme = components.scheme

            let expectedHost = self.host
            let actualHost = components.host

            let expectedPath = self.wordPressMediaNewEndpointPath
            let actualPath = components.path

            let result = expectedScheme == actualScheme && expectedHost == actualHost && expectedPath == actualPath
            return result
        }
    }

    func testHTTPMethod() async {
        for method in HTTPRequestBuilder.Method.allCases {
            let requestReceived = expectation(description: "HTTP request is received")

            var request: URLRequest?
            stub(condition: { _ in true }) {
                request = $0
                requestReceived.fulfill()
                return HTTPStubsResponse(error: URLError(URLError.Code.networkConnectionLost))
            }

            let api = WordPressComRestApi(oAuthToken: "fakeToken")
            _ = await api.perform(method, URLString: "test")
            await fulfillment(of: [requestReceived], timeout: 0.3)

            XCTAssertEqual(request?.httpMethod?.uppercased(), method.rawValue.uppercased())
        }
    }

    @available(iOS 16.0, *)
    func testQuery() {
        var requestURL: URL?
        stub(condition: isRestAPIRequest()) {
            requestURL = $0.url
            return HTTPStubsResponse(error: URLError(URLError.Code.networkConnectionLost))
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        api.GET(
            wordPressMediaRoutePath,
            parameters: HTTPRequestBuilderTests.nestedParameters as [String: AnyObject],
            success: { _, _ in expect.fulfill() },
            failure: { (_, _) in expect.fulfill() }
        )
        wait(for: [expect], timeout: 0.3)

        let query = requestURL?
            .query(percentEncoded: false)?
            .split(separator: "&")
            .reduce(into: Set()) { $0.insert(String($1)) }
            ?? []
        let expected = HTTPRequestBuilderTests.nestedParametersEncoded + ["locale=en"]

        XCTAssertEqual(query.count, expected.count)

        for item in expected {
            XCTAssertTrue(query.contains(item), "Missing query item: \(item)")
        }
    }

    func testSuccessfullCall() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComRestApiMedia.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isRestAPIRequest()) { _ in
            return fixture(filePath: stubPath, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        api.GET(wordPressMediaRoutePath, parameters: nil, success: { (responseObject: AnyObject, _: HTTPURLResponse?) in
            expect.fulfill()
            XCTAssert(responseObject is [String: AnyObject], "The response should be a dictionary")
            }, failure: { (_, _) in
                expect.fulfill()
                XCTFail("This call should be successfull")
            }
        )
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testBaseUrl() async throws {
        var request: URLRequest?
        stub(condition: { _ in true }, response: {
            request = $0
            return HTTPStubsResponse(error: URLError(.networkConnectionLost))
        })

        let defaultApi = WordPressComRestApi()
        XCTAssertEqual(defaultApi.baseURL.absoluteString, "https://public-api.wordpress.com/")
        let _ = await defaultApi.perform(.get, URLString: "/path")
        try XCTAssertTrue(XCTUnwrap(request?.url?.absoluteString).hasPrefix("https://public-api.wordpress.com/path"))

        let localhostApi = WordPressComRestApi(baseURL: URL(string: "http://localhost:8080")!)
        XCTAssertEqual(localhostApi.baseURL.absoluteString, "http://localhost:8080")
        let _ = await localhostApi.perform(.get, URLString: "/local")
        try XCTAssertTrue(XCTUnwrap(request?.url?.absoluteString).hasPrefix("http://localhost:8080/local"))
    }

    func testURLStringWithQuery() async {
        let requestReceived = expectation(description: "HTTP request is received")

        var request: URLRequest?
        stub(condition: { _ in true }) {
            request = $0
            requestReceived.fulfill()
            return HTTPStubsResponse(error: URLError(URLError.Code.networkConnectionLost))
        }

        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        _ = await api.perform(.get, URLString: "test?arg=value")
        await fulfillment(of: [requestReceived], timeout: 0.3)

        XCTAssertEqual(request?.url?.path, "/test")
        XCTAssertTrue(request?.url?.query?.contains("arg=value") == true)
    }

    func testInvalidTokenFailedCall() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComRestApiFailRequestInvalidToken.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isRestAPIRequest()) { _ in
            return fixture(filePath: stubPath, status: 400, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        api.GET(wordPressMediaRoutePath, parameters: nil, success: { (_: AnyObject, _: HTTPURLResponse?) in
            expect.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, _) in
                expect.fulfill()
                XCTAssert(error.domain == "WordPressKit.WordPressComRestApiError", "The error should a WordPressComRestApiError")
                XCTAssert(error.code == Int(WordPressComRestApiErrorCode.invalidToken.rawValue), "The error code should be invalid token")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testInvalidJSONReceivedFailedCall() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComRestApiFailInvalidJSON.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isRestAPIRequest()) { _ in
            return fixture(filePath: stubPath, status: 200, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        api.GET(wordPressMediaRoutePath, parameters: nil, success: { (_: AnyObject, _: HTTPURLResponse?) in
            expect.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, _) in
                expect.fulfill()
                XCTAssert(error.domain == WordPressComRestApiErrorDomain, "The error domain should be WordPressComRestApiErrorDomain")
                XCTAssert(error.code == Int(WordPressComRestApiErrorCode.responseSerializationFailed.rawValue), "The code should be invalid response serialization")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testInvalidJSONSentFailedCall() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComRestApiFailInvalidInput.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isRestAPIMediaNewRequest()) { _ in
            return fixture(filePath: stubPath, status: 400, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        api.POST(wordPressMediaNewEndpointPath, parameters: nil, success: { (_: AnyObject, _: HTTPURLResponse?) in
            expect.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, _) in
                expect.fulfill()
                XCTAssert(error.domain == "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
                XCTAssert(error.code == Int(WordPressComRestApiErrorCode.invalidInput.rawValue), "The error code should be invalid input")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testUnauthorizedFailedCall() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComRestApiFailUnauthorized.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isRestAPIMediaNewRequest()) { _ in
            return fixture(filePath: stubPath, status: 403, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        api.POST(wordPressMediaNewEndpointPath, parameters: nil, success: { (_: AnyObject, _: HTTPURLResponse?) in
            expect.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, _) in
                expect.fulfill()
                XCTAssert(error.domain == "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
                XCTAssert(error.code == Int(WordPressComRestApiErrorCode.authorizationRequired.rawValue), "The error code should be AuthorizationRequired")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testMultipleErrorsFailedCall() throws {
        let stubPath = try XCTUnwrap(OHPathForFileInBundle("WordPressComRestApiMultipleErrors.json", Bundle.coreAPITestsBundle))
        stub(condition: isRestAPIMediaNewRequest()) { _ in
            return fixture(filePath: stubPath, status: 403, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        api.POST(wordPressMediaNewEndpointPath, parameters: nil, success: { (_: AnyObject, _: HTTPURLResponse?) in
            expect.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, _) in
                expect.fulfill()
                XCTAssert(error.domain == "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
                XCTAssert(error.code == Int(WordPressComRestApiErrorCode.uploadFailed.rawValue), "The error code should be AuthorizationRequired")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testMultipleErrorsFailedMultiPartPostCall() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComRestApiMultipleErrors.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isRestAPIMediaNewRequest()) { _ in
            return fixture(filePath: stubPath, status: 403, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        api.multipartPOST(wordPressMediaNewEndpointPath, parameters: nil, fileParts: [], success: { (_: AnyObject, _: HTTPURLResponse?) in
            expect.fulfill()
            XCTFail("This call should fail")
        }, failure: { (error, _) in
            expect.fulfill()
            XCTAssert(error.domain == "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssert(error.code == Int(WordPressComRestApiErrorCode.uploadFailed.rawValue), "The error code should be AuthorizationRequired")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testStreamMethodCallWithInvalidFile() throws {
        let stubPath = try XCTUnwrap(OHPathForFileInBundle("WordPressComRestApiMedia.json", Bundle.coreAPITestsBundle))
        stub(condition: isRestAPIMediaNewRequest()) { _ in
            return fixture(filePath: stubPath, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        let filePart = FilePart(parameterName: "file", url: URL(fileURLWithPath: "/a.txt") as URL, fileName: "a.txt", mimeType: "image/jpeg")
        api.multipartPOST(wordPressMediaNewEndpointPath, parameters: nil, fileParts: [filePart], success: { (_: AnyObject, _: HTTPURLResponse?) in
            expect.fulfill()
            XCTFail("This call should fail")
            }, failure: { (_, _) in
                expect.fulfill()
            }
        )
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testStreamMethodParallelCalls() throws {
        let stubPath = try XCTUnwrap(OHPathForFileInBundle("WordPressComRestApiMedia.json", Bundle.coreAPITestsBundle))
        stub(condition: isRestAPIMediaNewRequest()) { _ in
            return fixture(filePath: stubPath, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
        guard
            let mediaPath = OHPathForFileInBundle("test-image.jpg", Bundle.coreAPITestsBundle)
        else {
            return
        }
        let mediaURL = URL(fileURLWithPath: mediaPath)
        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        let filePart = FilePart(parameterName: "media[]", url: mediaURL as URL, fileName: "test-image.jpg", mimeType: "image/jpeg")
        let progress1 = api.multipartPOST(wordPressMediaNewEndpointPath, parameters: nil, fileParts: [filePart], success: { (_: AnyObject, _: HTTPURLResponse?) in
                XCTFail("This call should fail")
            }, failure: { (error, _) in
                XCTAssert(error.domain == NSURLErrorDomain, "The error domain should be NSURLErrorDomain")
                XCTAssert(error.code == NSURLErrorCancelled, "The error code should be NSURLErrorCancelled")
            }
        )
        progress1?.cancel()
        api.multipartPOST(wordPressMediaNewEndpointPath, parameters: nil, fileParts: [filePart], success: { (_: AnyObject, _: HTTPURLResponse?) in
            expect.fulfill()

            }, failure: { (_, _) in
                expect.fulfill()
                XCTFail("This call should succesful")
            }
        )
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testCancelationOfRequest() {
        stub(condition: isRestAPIMediaNewRequest()) { _ in
            return HTTPStubsResponse.init(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
        }
        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        api.POST(wordPressMediaNewEndpointPath, parameters: nil, success: { (_: AnyObject, _: HTTPURLResponse?) in
            expect.fulfill()
            XCTFail("This call should fail")
        }, failure: { (error, _) in
            expect.fulfill()
            XCTAssertEqual(error.domain, NSURLErrorDomain, "The error domain should be NSURLErrorDomain")
            XCTAssertEqual(error.code, NSURLErrorCancelled, "The error code should be NSURLErrorCancelled")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testSuccessfullCallCommonGETStructure() throws {
        let stubPath = try XCTUnwrap(OHPathForFileInBundle("WordPressComRestApiMedia.json", Bundle.coreAPITestsBundle))
        stub(condition: isRestAPIRequest()) { _ in
            return fixture(filePath: stubPath, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")

        api.GET(wordPressMediaRoutePath, parameters: nil, success: { responseObject, _ in
            XCTAssert(responseObject is [String: AnyObject], "The response should be a dictionary")
            expect.fulfill()
        }, failure: { _, _ in
            XCTFail("This call should be successfull")
            expect.fulfill()
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testFailureCallCommonGETStructure() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComRestApiFailInvalidJSON.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isRestAPIRequest()) { _ in
            return fixture(filePath: stubPath, status: 200, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        api.GET(wordPressMediaRoutePath, parameters: nil, success: { _, _ in
            XCTFail("This call should fail")
            expect.fulfill()
        }, failure: { err, _ in
            let error = err as NSError
            XCTAssert(error.domain == WordPressComRestApiErrorDomain, "The error domain should be WordPressComRestApiErrorDomain")
            XCTAssert(error.code == Int(WordPressComRestApiErrorCode.responseSerializationFailed.rawValue), "The code should be invalid response serialization")
            expect.fulfill()
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testStatusCode500() {
        stub(condition: isAbsoluteURLString("https://public-api.wordpress.com/rest/v1/foo?locale=en")) { _ in
            HTTPStubsResponse(data: "Internal server error".data(using: .utf8)!, statusCode: 500, headers: nil)
        }

        let api = WordPressComRestApi()
        let complete = expectation(description: "API call completed")
        api.GET(
            "/rest/v1/foo",
            parameters: nil,
            success: { _, _ in
                complete.fulfill()
                XCTFail("The API call should complete with a failure")
            },
            failure: { error, _ in
                complete.fulfill()
                XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError")
                XCTAssertEqual(error.code, WordPressComRestApiErrorCode.unknown.rawValue)
            }
        )

        wait(for: [complete], timeout: 0.3)
    }

    func testStatusCode502() {
        stub(condition: isAbsoluteURLString("https://public-api.wordpress.com/rest/v1/foo?locale=en")) { _ in
            HTTPStubsResponse(data: "Bad Gateway".data(using: .utf8)!, statusCode: 502, headers: nil)
        }

        let api = WordPressComRestApi()
        let complete = expectation(description: "API call completed")
        api.GET(
            "/rest/v1/foo",
            parameters: nil,
            success: { _, _ in
                complete.fulfill()
                XCTFail("The API call should complete with a failure")
            },
            failure: { error, _ in
                complete.fulfill()

                XCTAssertTrue(error is WordPressAPIError<WordPressComRestApiEndpointError>)
            }
        )

        wait(for: [complete], timeout: 0.3)
    }

    func testTooManyRequestError() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComRestApiFailThrottled.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isAbsoluteURLString("https://public-api.wordpress.com/rest/v1/foo?locale=en")) { _ in
            return fixture(filePath: stubPath, status: 500, headers: ["Content-Type" as NSObject: "application/html" as AnyObject])
        }

        let api = WordPressComRestApi()
        let complete = expectation(description: "API call completed")
        api.GET(
            "/rest/v1/foo",
            parameters: nil,
            success: { _, _ in
                complete.fulfill()
                XCTFail("The API call should complete with a failure")
            },
            failure: { error, _ in
                complete.fulfill()
                XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError")
                XCTAssertEqual(error.code, WordPressComRestApiErrorCode.tooManyRequests.rawValue)
                XCTAssertEqual(error.userInfo[WordPressComRestApi.ErrorKeyErrorCode] as? String, "too_many_requests")
                XCTAssertTrue(error.localizedDescription.contains("You can try again in 1 minute"))
            }
        )

        wait(for: [complete], timeout: 0.3)
    }

    func testPreconditionFailureError() {
        stub(condition: isAbsoluteURLString("https://public-api.wordpress.com/rest/v1/foo?locale=en")) { _ in
            HTTPStubsResponse(jsonObject: ["code": "no_connected_jetpack"], statusCode: 412, headers: nil)
        }

        let api = WordPressComRestApi()
        let complete = expectation(description: "API call completed")
        api.GET(
            "/rest/v1/foo",
            parameters: nil,
            success: { _, _ in
                complete.fulfill()
                XCTFail("The API call should complete with a failure")
            },
            failure: { error, _ in
                complete.fulfill()
                XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError")
                XCTAssertEqual(error.code, WordPressComRestApiErrorCode.preconditionFailure.rawValue)
            }
        )

        wait(for: [complete], timeout: 0.3)
    }

    /// Verify that parameters in POST requests are sent as JSON.
    func testPostParametersContent() throws {
        var req: URLRequest?
        stub(condition: isHost("public-api.wordpress.com")) {
            req = $0
            return HTTPStubsResponse(error: URLError(.notConnectedToInternet))
        }

        let api = WordPressComRestApi()
        let complete = expectation(description: "API call completed")
        api.POST(
            "/rest/v1/foo",
            parameters: ["arg1": "value1"] as [String: AnyObject],
            success: { _, _ in
                complete.fulfill()
                XCTFail("The API call should complete with a failure")
            },
            failure: { error, _ in
                complete.fulfill()
            }
        )

        wait(for: [complete], timeout: 0.3)

        let request = try XCTUnwrap(req)
        XCTAssertEqual(request.httpMethod?.uppercased(), "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://public-api.wordpress.com/rest/v1/foo?locale=en")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.httpBodyText, #"{"arg1":"value1"}"#)
    }
}
