import XCTest
@testable import WordPress
import OHHTTPStubs

class WordPressComRestApiTests: XCTestCase {

    let wordPressComRestApi = "https://public-api.wordpress.com/rest/"
    let wordPressMediaRoute = "v1.1/sites/0/media/"
    let wordPressMediaNewEndpoint = "v1.1/sites/0/media/new"

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }

    private func isRestAPIRequest() -> OHHTTPStubsTestBlock {
        return { request in
            let pathWithLocale = WordPressComRestApi.pathByAppendingPreferredLanguageLocale(self.wordPressMediaRoute)
            return request.URL?.absoluteString == self.wordPressComRestApi + pathWithLocale
        }
    }

    private func isRestAPIMediaNewRequest() -> OHHTTPStubsTestBlock {
        return { request in
            let pathWithLocale = WordPressComRestApi.pathByAppendingPreferredLanguageLocale(self.wordPressMediaNewEndpoint)
            return request.URL?.absoluteString == self.wordPressComRestApi + pathWithLocale
        }
    }

    func testSuccessfullCall() {
        stub(isRestAPIRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiMedia.json", self.dynamicType)
            return fixture(stubPath!, headers: ["Content-Type":"application/json"])
        }

        let expectation = self.expectationWithDescription("One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken:"fakeToken")
        api.GET(wordPressMediaRoute, parameters:nil, success: { (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) in
            expectation.fulfill()
            XCTAssert(responseObject is [String:AnyObject], "The response should be a dictionary")
            }, failure: { (error, httpResponse) in
                expectation.fulfill()
                XCTFail("This call should be successfull")
            }
        )
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testInvalidTokenFailedCall() {
        stub(isRestAPIRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiFailRequestInvalidToken.json", self.dynamicType)
            return fixture(stubPath!, status:400, headers: ["Content-Type":"application/json"])
        }

        let expectation = self.expectationWithDescription("One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken:"fakeToken")
        api.GET(wordPressMediaRoute, parameters:nil, success: { (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) in
            expectation.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, httpResponse) in
                expectation.fulfill()
                XCTAssert(error.domain == String(reflecting:WordPressComRestApiError.self), "The error should a WordPressComRestApiError")
                XCTAssert(error.code == Int(WordPressComRestApiError.InvalidToken.rawValue), "The error code should be invalid token")
        })
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testInvalidJSONReceivedFailedCall() {
        stub(isRestAPIRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiFailInvalidJSON.json", self.dynamicType)
            return fixture(stubPath!, status:200, headers: ["Content-Type":"application/json"])
        }
        let expectation = self.expectationWithDescription("One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken:"fakeToken")
        api.GET(wordPressMediaRoute, parameters:nil, success: { (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) in
            expectation.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, httpResponse) in
                expectation.fulfill()
                XCTAssert(error.domain == "NSCocoaErrorDomain", "The error domain should be NSCocoaErrorDomain")
                XCTAssert(error.code == Int(3840), "The code should be invalid token")
        })
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testInvalidJSONSentFailedCall() {
        stub(isRestAPIMediaNewRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiFailInvalidInput.json", self.dynamicType)
            return fixture(stubPath!, status:400, headers: ["Content-Type":"application/json"])
        }
        let expectation = self.expectationWithDescription("One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken:"fakeToken")
        api.POST(wordPressMediaNewEndpoint, parameters:nil, success: { (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) in
            expectation.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, httpResponse) in
                expectation.fulfill()
                XCTAssert(error.domain == String(reflecting:WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
                XCTAssert(error.code == Int(WordPressComRestApiError.InvalidInput.rawValue), "The error code should be invalid input")
        })
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testUnauthorizedFailedCall() {
        stub(isRestAPIMediaNewRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiFailUnauthorized.json", self.dynamicType)
            return fixture(stubPath!, status:403, headers: ["Content-Type":"application/json"])
        }
        let expectation = self.expectationWithDescription("One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken:"fakeToken")
        api.POST(wordPressMediaNewEndpoint, parameters:nil, success: { (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) in
            expectation.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, httpResponse) in
                expectation.fulfill()
                XCTAssert(error.domain == String(reflecting:WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
                XCTAssert(error.code == Int(WordPressComRestApiError.AuthorizationRequired.rawValue), "The error code should be AuthorizationRequired")
        })
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testMultipleErrorsFailedCall() {
        stub(isRestAPIMediaNewRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiMultipleErrors.json", self.dynamicType)
            return fixture(stubPath!, status:403, headers: ["Content-Type":"application/json"])
        }
        let expectation = self.expectationWithDescription("One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken:"fakeToken")
        api.POST(wordPressMediaNewEndpoint, parameters:nil, success: { (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) in
            expectation.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, httpResponse) in
                expectation.fulfill()
                XCTAssert(error.domain == String(reflecting:WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
                XCTAssert(error.code == Int(WordPressComRestApiError.UploadFailed.rawValue), "The error code should be AuthorizationRequired")
        })
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testThatAppendingLocaleWorks() {

        let path = "path/path"
        let localeKey = "locale"
        let preferredLanguageIdentifier = WordPressComLanguageDatabase().deviceLanguage.slug
        let expectedPath = "\(path)?\(localeKey)=\(preferredLanguageIdentifier)"

        let localeAppendedPath = WordPressComRestApi.pathByAppendingPreferredLanguageLocale(path)
        XCTAssert(localeAppendedPath == expectedPath, "Expected the locale to be appended to the path as (\(expectedPath)) but instead encountered (\(localeAppendedPath)).")
    }

    func testThatAppendingLocaleWorksWithExistingParams() {

        let path = "path/path?someKey=value"
        let localeKey = "locale"
        let preferredLanguageIdentifier = WordPressComLanguageDatabase().deviceLanguage.slug
        let expectedPath = "\(path)&\(localeKey)=\(preferredLanguageIdentifier)"

        let localeAppendedPath = WordPressComRestApi.pathByAppendingPreferredLanguageLocale(path)
        XCTAssert(localeAppendedPath == expectedPath, "Expected the locale to be appended to the path as (\(expectedPath)) but instead encountered (\(localeAppendedPath)).")
    }

    func testThatAppendingLocaleIgnoresIfAlreadyIncluded() {

        let localeKey = "locale"
        let preferredLanguageIdentifier = WordPressComLanguageDatabase().deviceLanguage.slug
        let path = "path/path?\(localeKey)=\(preferredLanguageIdentifier)&someKey=value"

        let localeAppendedPath = WordPressComRestApi.pathByAppendingPreferredLanguageLocale(path)
        XCTAssert(localeAppendedPath == path, "Expected the locale to already be appended to the path as (\(path)) but instead encountered (\(localeAppendedPath)).")
    }

    func testStreamMethodCallWithInvalidFile() {
        stub(isRestAPIMediaNewRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiMedia.json", self.dynamicType)
            return fixture(stubPath!, headers: ["Content-Type":"application/json"])
        }

        let expectation = self.expectationWithDescription("One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken:"fakeToken")
        let filePart = FilePart(parameterName: "file", url: NSURL(fileURLWithPath:"/a.txt"), filename: "a.txt", mimeType: "image/jpeg")
        api.multipartPOST(wordPressMediaNewEndpoint, parameters:nil, fileParts:[filePart], success: { (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) in
            expectation.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, httpResponse) in
                expectation.fulfill()
            }
        )
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testStreamMethodParallelCalls() {
        stub(isRestAPIMediaNewRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiMedia.json", self.dynamicType)
            return fixture(stubPath!, headers: ["Content-Type":"application/json"])
        }
        guard
            let mediaPath = OHPathForFile("test-image.jpg", self.dynamicType)
        else {
            return
        }
        let mediaURL = NSURL(fileURLWithPath:mediaPath)
        let expectation = self.expectationWithDescription("One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken:"fakeToken")
        let filePart = FilePart(parameterName: "media[]", url: mediaURL, filename: "test-image.jpg", mimeType: "image/jpeg")
        let progress1 = api.multipartPOST(wordPressMediaNewEndpoint, parameters:nil, fileParts:[filePart], success: { (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) in
                XCTFail("This call should fail")
            }, failure: { (error, httpResponse) in
                print(error)
                XCTAssert(error.domain == NSURLErrorDomain, "The error domain should be NSURLErrorDomain")
                XCTAssert(error.code == NSURLErrorCancelled, "The error code should be NSURLErrorCancelled")
            }
        )
        progress1?.cancel()
        api.multipartPOST(wordPressMediaNewEndpoint, parameters:nil, fileParts:[filePart], success: { (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) in
            expectation.fulfill()

            }, failure: { (error, httpResponse) in
                expectation.fulfill()
                XCTFail("This call should succesful")
            }
        )
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }
}
