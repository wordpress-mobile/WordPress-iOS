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

    fileprivate func isRestAPIRequest() -> OHHTTPStubsTestBlock {
        return { request in
            let pathWithLocale = WordPressComRestApi.pathByAppendingPreferredLanguageLocale(self.wordPressMediaRoute)
            return request.url?.absoluteString == self.wordPressComRestApi + pathWithLocale
        }
    }

    fileprivate func isRestAPIMediaNewRequest() -> OHHTTPStubsTestBlock {
        return { request in
            let pathWithLocale = WordPressComRestApi.pathByAppendingPreferredLanguageLocale(self.wordPressMediaNewEndpoint)
            return request.url?.absoluteString == self.wordPressComRestApi + pathWithLocale
        }
    }

    func testSuccessfullCall() {
        stub(condition: isRestAPIRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiMedia.json", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        api.GET(wordPressMediaRoute, parameters: nil, success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
            expect.fulfill()
            XCTAssert(responseObject is [String: AnyObject], "The response should be a dictionary")
            }, failure: { (error, httpResponse) in
                expect.fulfill()
                XCTFail("This call should be successfull")
            }
        )
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testInvalidTokenFailedCall() {
        stub(condition: isRestAPIRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiFailRequestInvalidToken.json", type(of: self))
            return fixture(filePath: stubPath!, status: 400, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        api.GET(wordPressMediaRoute, parameters: nil, success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
            expect.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, httpResponse) in
                expect.fulfill()
                XCTAssert(error.domain == String(reflecting: WordPressComRestApiError.self), "The error should a WordPressComRestApiError")
                XCTAssert(error.code == Int(WordPressComRestApiError.invalidToken.rawValue), "The error code should be invalid token")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testInvalidJSONReceivedFailedCall() {
        stub(condition: isRestAPIRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiFailInvalidJSON.json", type(of: self))
            return fixture(filePath: stubPath!, status: 200, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        api.GET(wordPressMediaRoute, parameters: nil, success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
            expect.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, httpResponse) in
                expect.fulfill()
                XCTAssert(error.domain == "NSCocoaErrorDomain", "The error domain should be NSCocoaErrorDomain")
                XCTAssert(error.code == Int(3840), "The code should be invalid token")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testInvalidJSONSentFailedCall() {
        stub(condition: isRestAPIMediaNewRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiFailInvalidInput.json", type(of: self))
            return fixture(filePath: stubPath!, status: 400, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        api.POST(wordPressMediaNewEndpoint, parameters: nil, success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
            expect.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, httpResponse) in
                expect.fulfill()
                XCTAssert(error.domain == String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
                XCTAssert(error.code == Int(WordPressComRestApiError.invalidInput.rawValue), "The error code should be invalid input")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testUnauthorizedFailedCall() {
        stub(condition: isRestAPIMediaNewRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiFailUnauthorized.json", type(of: self))
            return fixture(filePath: stubPath!, status: 403, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        api.POST(wordPressMediaNewEndpoint, parameters: nil, success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
            expect.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, httpResponse) in
                expect.fulfill()
                XCTAssert(error.domain == String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
                XCTAssert(error.code == Int(WordPressComRestApiError.authorizationRequired.rawValue), "The error code should be AuthorizationRequired")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testMultipleErrorsFailedCall() {
        stub(condition: isRestAPIMediaNewRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiMultipleErrors.json", type(of: self))
            return fixture(filePath: stubPath!, status: 403, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        api.POST(wordPressMediaNewEndpoint, parameters: nil, success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
            expect.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, httpResponse) in
                expect.fulfill()
                XCTAssert(error.domain == String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
                XCTAssert(error.code == Int(WordPressComRestApiError.uploadFailed.rawValue), "The error code should be AuthorizationRequired")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
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
        stub(condition: isRestAPIMediaNewRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiMedia.json", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        let filePart = FilePart(parameterName: "file", url: URL(fileURLWithPath: "/a.txt") as URL, filename: "a.txt", mimeType: "image/jpeg")
        api.multipartPOST(wordPressMediaNewEndpoint, parameters: nil, fileParts: [filePart], success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
            expect.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, httpResponse) in
                expect.fulfill()
            }
        )
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testStreamMethodParallelCalls() {
        stub(condition: isRestAPIMediaNewRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiMedia.json", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
        guard
            let mediaPath = OHPathForFile("test-image.jpg", type(of: self))
        else {
            return
        }
        let mediaURL = URL(fileURLWithPath: mediaPath)
        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken: "fakeToken")
        let filePart = FilePart(parameterName: "media[]", url: mediaURL as URL, filename: "test-image.jpg", mimeType: "image/jpeg")
        let progress1 = api.multipartPOST(wordPressMediaNewEndpoint, parameters: nil, fileParts: [filePart], success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
                XCTFail("This call should fail")
            }, failure: { (error, httpResponse) in
                print(error)
                XCTAssert(error.domain == NSURLErrorDomain, "The error domain should be NSURLErrorDomain")
                XCTAssert(error.code == NSURLErrorCancelled, "The error code should be NSURLErrorCancelled")
            }
        )
        progress1?.cancel()
        api.multipartPOST(wordPressMediaNewEndpoint, parameters: nil, fileParts: [filePart], success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
            expect.fulfill()

            }, failure: { (error, httpResponse) in
                expect.fulfill()
                XCTFail("This call should succesful")
            }
        )
        self.waitForExpectations(timeout: 5, handler: nil)
    }
}
