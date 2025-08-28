import XCTest
@testable import WordPressKit

class EditorServiceRemoteTests: XCTestCase {

    let mockRemoteApi = MockWordPressComRestApi()
    var editorServiceRemote: EditorServiceRemote!
    let siteID = 99999

    override func setUp() {
        super.setUp()
        editorServiceRemote = EditorServiceRemote(wordPressComRestApi: mockRemoteApi)
    }

    // MARK: - POST tests

    func testPostDesignateMobileEditorPostMethodIsCalled() {
        editorServiceRemote.postDesignateMobileEditor(siteID, editor: .gutenberg, success: { _ in }, failure: { _ in })
        XCTAssertTrue(mockRemoteApi.postMethodCalled)
    }

    func testPostDesignateMobileEditorSuccessSettingGutenberg() {
        let expec = expectation(description: "success")
        let response = mockResponse(forMobile: .gutenberg, andWeb: .gutenberg)

        editorServiceRemote.postDesignateMobileEditor(siteID, editor: .gutenberg, success: { editor in
            XCTAssertEqual(editor.mobile, .gutenberg)
            XCTAssertEqual(editor.web, .gutenberg)
            expec.fulfill()
        }) { (error) in
            XCTFail("This call should succeed. Error: \(error)")
            expec.fulfill()
        }
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        wait(for: [expec], timeout: 0.3)
    }

    func testPostDesignateMobileEditorSuccessSettingAztec() {
        let expec = expectation(description: "success")
        let response = mockResponse(forMobile: .aztec, andWeb: .classic)

        editorServiceRemote.postDesignateMobileEditor(siteID, editor: .aztec, success: { editor in
            XCTAssertEqual(editor.mobile, .aztec)
            XCTAssertEqual(editor.web, .classic)
            expec.fulfill()
        }) { (error) in
            XCTFail("This call should succeed. Error: \(error)")
            expec.fulfill()
        }
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        wait(for: [expec], timeout: 0.3)
    }

    func testPostDesignateMobileEditorDoesNotCrashWithBadKeyResponse() {
        let expec = expectation(description: "success")
        let response: [String: String] = [
            "editor_mobile_bad": "gutenberg",
            "editor_web": "gutenberg"
        ]

        editorServiceRemote.postDesignateMobileEditor(siteID, editor: .gutenberg, success: { _ in
            XCTFail("This should fail")
            expec.fulfill()
        }) { (error) in
            let nsError = error as NSError
            XCTAssertEqual(nsError.code, NSCoderValueNotFoundError)
            expec.fulfill()
        }
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        wait(for: [expec], timeout: 0.3)
    }

    func testPostDesignateMobileEditorThrowsErrorWithBadValueResponse() {
        let expec = expectation(description: "success")
        let response: [String: String] = [
            "editor_mobile": "guten_BORG",
            "editor_web": "guten_WRONG"
        ]
        editorServiceRemote.postDesignateMobileEditor(siteID, editor: .gutenberg, success: { _ in
            XCTFail("This should throw an error")
            expec.fulfill()
        }) { (error) in
            XCTAssertEqual(error as NSError, EditorSettings.Error.decodingFailed as NSError)
            expec.fulfill()
        }
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        wait(for: [expec], timeout: 0.3)
    }

    func testPostDesignateMobileEditorError() {
        let expec = expectation(description: "success")
        let errorExpec = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
        editorServiceRemote.postDesignateMobileEditor(siteID, editor: .gutenberg, success: { _ in
            XCTFail("This call should error")
            expec.fulfill()
        }) { (error) in
            XCTAssertEqual(error as NSError, errorExpec)
            expec.fulfill()
        }
        mockRemoteApi.failureBlockPassedIn?(errorExpec, nil)
        XCTAssertTrue(mockRemoteApi.postMethodCalled)

        wait(for: [expec], timeout: 0.3)
    }

    // MARK: - GET tests

    func testGetEditorSettingsGutenberg() {
        let expec = expectation(description: "success")
        let response = mockResponse(forMobile: .gutenberg, andWeb: .gutenberg)

        editorServiceRemote.getEditorSettings(siteID, success: { (editor) in
            XCTAssertEqual(editor.mobile, .gutenberg)
            XCTAssertEqual(editor.web, .gutenberg)
            expec.fulfill()
        }) { (error) in
            XCTFail("This call should succeed. Error: \(error)")
            expec.fulfill()
        }
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertTrue(mockRemoteApi.getMethodCalled)

        wait(for: [expec], timeout: 0.3)
    }

    func testGetEditorSettingsNotSetForMobile() {
        let expec = expectation(description: "success")
        let response = mockResponse(forMobile: .notSet, andWeb: .gutenberg)

        editorServiceRemote.getEditorSettings(siteID, success: { (editor) in
            XCTAssertEqual(editor.mobile, .notSet)
            XCTAssertEqual(editor.web, .gutenberg)
            expec.fulfill()
        }) { (error) in
            XCTFail("This call should succeed. Error: \(error)")
            expec.fulfill()
        }
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertTrue(mockRemoteApi.getMethodCalled)

        wait(for: [expec], timeout: 0.3)
    }

    func testGetEditorSettingsClassic() {
        let expec = expectation(description: "success")
        let response = mockResponse(forMobile: .aztec, andWeb: .classic)

        editorServiceRemote.getEditorSettings(siteID, success: { (editor) in
            XCTAssertEqual(editor.mobile, .aztec)
            XCTAssertEqual(editor.web, .classic)
            expec.fulfill()
        }) { (error) in
            XCTFail("This call should succeed. Error: \(error)")
            expec.fulfill()
        }
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertTrue(mockRemoteApi.getMethodCalled)

        wait(for: [expec], timeout: 0.3)
    }

    func testGetEditorSettingsFailure() {
        let expec = expectation(description: "success")
        let errorExpec = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)

        editorServiceRemote.getEditorSettings(siteID, success: { (_) in
            XCTFail("This call should error")
            expec.fulfill()
        }) { (error) in
             XCTAssertEqual(error as NSError, errorExpec)
            expec.fulfill()
        }
        mockRemoteApi.failureBlockPassedIn?(errorExpec, nil)
        XCTAssertTrue(mockRemoteApi.getMethodCalled)

        wait(for: [expec], timeout: 0.3)
    }

    func testPostDesignateGutenbergMobileEditorForAllSites() {
        let expec = expectation(description: "success")
        let editor = EditorSettings.Mobile.gutenberg

        let response: [String: String] = [
            "1": editor.rawValue,
            "2": editor.rawValue
        ]

        let expected: [Int: EditorSettings.Mobile] = [
            1: editor,
            2: editor
        ]

        editorServiceRemote.postDesignateMobileEditorForAllSites(editor, success: {
            XCTAssertEqual($0, expected)
            expec.fulfill()
        }) { (_) in
            XCTFail("This call should NOT error")
            expec.fulfill()
        }

        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertTrue(mockRemoteApi.postMethodCalled)

        wait(for: [expec], timeout: 0.3)
    }

    func testPostDesignateAztecMobileEditorForAllSites() {
        let expec = expectation(description: "success")
        let editor = EditorSettings.Mobile.aztec

        let response: [String: String] = [
            "1": editor.rawValue,
            "2": editor.rawValue
        ]

        let expected: [Int: EditorSettings.Mobile] = [
            1: editor,
            2: editor
        ]

        editorServiceRemote.postDesignateMobileEditorForAllSites(editor, success: {
            XCTAssertEqual($0, expected)
            expec.fulfill()
        }) { (_) in
            XCTFail("This call should NOT error")
            expec.fulfill()
        }

        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertTrue(mockRemoteApi.postMethodCalled)

        wait(for: [expec], timeout: 0.3)
    }
}

extension EditorServiceRemoteTests {
    func mockResponse(forMobile mobile: EditorSettings.Mobile, andWeb web: EditorSettings.Web) -> [String: String] {
        return [
            "editor_mobile": mobile.rawValue,
            "editor_web": web.rawValue
        ]
    }
}
