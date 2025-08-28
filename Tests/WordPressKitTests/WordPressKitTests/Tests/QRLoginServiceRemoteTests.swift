import XCTest
@testable import WordPressKit

class QRLoginServiceRemoteTests: RemoteTestCase, RESTTestable {
    let mockRemoteApi = MockWordPressComRestApi()
    var qrLoginServiceRemote: QRLoginServiceRemote!

    override func setUp() {
        qrLoginServiceRemote = QRLoginServiceRemote(wordPressComRestApi: getRestApi())
    }

    // MARK: - Validate Tests

    // Calls the success block with valid data when the request succeeds
    //
    func testValidResponseObject() {
        let expect = expectation(description: "Validate the response object successfully")
        stubRemoteResponse("wpcom/v2/auth/qr-code/validate", filename: "qrlogin-validate-200.json", contentType: .ApplicationJSON)

        let browser = "Chrome"
        let location = "Mount Laurel, New Jersey"

        qrLoginServiceRemote.validate(token: "", data: "") { response in
            XCTAssertEqual(browser, response.browser)
            XCTAssertEqual(location, response.location)
            expect.fulfill()
        } failure: { _, _ in }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // Calls the failure block with invalidData when providing invalid token/data
    //
    func testValidateInvalidData() {
        let expect = expectation(description: "Validate the invalid data error is being handled")
        stubRemoteResponse("wpcom/v2/auth/qr-code/validate", filename: "qrlogin-validate-400.json", contentType: .ApplicationJSON, status: 400)

        qrLoginServiceRemote.validate(token: "invalid_token", data: "invalid_data") { _ in
            XCTFail("This request should not succeed")
        } failure: { _, qrLoginError in
            XCTAssertEqual(qrLoginError!, .invalidData)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // Calls the failure block with expired when providing expired token/data
    //
    func testValidateExpired() {
        let expect = expectation(description: "Validate the expired data error is being handled")
        stubRemoteResponse("wpcom/v2/auth/qr-code/validate", filename: "qrlogin-validate-expired-401.json", contentType: .ApplicationJSON, status: 401)

        qrLoginServiceRemote.validate(token: "expired_token", data: "expired_data") { _ in
            XCTFail("This request should not succeed")
        } failure: { _, qrLoginError in
            XCTAssertEqual(qrLoginError!, .expired)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // Calls the failure block with invalidData when parsing an invalid response
    //
    func testInvalidJSON() {
        let expect = expectation(description: "Validate the failure object is being returned")
        stubRemoteResponse("wpcom/v2/auth/qr-code/validate", data: "foo".data(using: .utf8)!, contentType: .ApplicationJSON)

        qrLoginServiceRemote.validate(token: "expired_token", data: "expired_data") { _ in
            XCTFail("This request should not succeed")
        } failure: { _, qrLoginError in
            XCTAssertEqual(qrLoginError!, .invalidData)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Authenticate Tests

    // Calls the success block when authenticating valid data
    //
    func testAuthenticateSuccess() {
        let expect = expectation(description: "Successful Authentication")
        stubRemoteResponse("wpcom/v2/auth/qr-code/authenticate", filename: "qrlogin-authenticate-200.json", contentType: .ApplicationJSON)

        qrLoginServiceRemote.authenticate(token: "valid_token", data: "valid_data") { authenticated in
            XCTAssertTrue(authenticated)
            expect.fulfill()
        } failure: { _ in }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // Calls the failure block when providing invalid data
    //
    func testAuthenticateFailure() {
        let expect = expectation(description: "Failed Authentication")
        stubRemoteResponse("wpcom/v2/auth/qr-code/authenticate", filename: "qrlogin-authenticate-failed-400.json", contentType: .ApplicationJSON, status: 400)

        qrLoginServiceRemote.authenticate(token: "valid_token", data: "valid_data") { authenticated in
            XCTFail("This request should not succeed")
        } failure: { error in
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // Calls the failure block when parsing invalid JSON
    func testAuthenticateInvalidJSON() {
        let expect = expectation(description: "Failed Authentication")
        stubRemoteResponse("wpcom/v2/auth/qr-code/authenticate", data: "foo".data(using: .utf8)!, contentType: .ApplicationJSON)

        qrLoginServiceRemote.authenticate(token: "valid_token", data: "valid_data") { authenticated in
            XCTFail("This request should not succeed")
        } failure: { error in
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
