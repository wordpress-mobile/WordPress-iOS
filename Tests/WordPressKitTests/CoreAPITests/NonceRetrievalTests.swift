import Foundation
import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift

@testable import WordPressKit

class NonceRetrievalTests: XCTestCase {

    static let nonce = "leg1tn0nce"
    static let siteURL = URL(string: "https://test.com")!
    static let siteLoginURL = URL(string: "https://test.com/wp-login.php")!
    static let siteAdminURL = URL(string: "https://test.com/wp-admin/")!
    static let newPostURL = URL(string: "https://test.com/wp-admin/post-new.php")!
    static let ajaxURL = URL(string: "https://test.com/wp-admin/admin-ajax.php?action=rest-nonce")!

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    func testUsingNewPostPage() async {
        stubLoginRedirect(dest: Self.newPostURL)
        stubNewPostPage(statusCode: 200)

        let nonce = await NonceRetrievalMethod.newPostScrap.retrieveNonce(
            username: "test",
            password: .init("pass"),
            loginURL: Self.siteLoginURL,
            adminURL: Self.siteAdminURL,
            using: URLSession(configuration: .ephemeral)
        )
        XCTAssertEqual(nonce, Self.nonce)
    }

    func testUsingRESTNonceAjax() async {
        stubLoginRedirect(dest: Self.ajaxURL)
        stubAjax(statusCode: 200)

        let nonce = await NonceRetrievalMethod.ajaxNonceRequest.retrieveNonce(
            username: "test",
            password: .init("pass"),
            loginURL: Self.siteLoginURL,
            adminURL: Self.siteAdminURL,
            using: URLSession(configuration: .ephemeral)
        )
        XCTAssertEqual(nonce, Self.nonce)
    }

    private func stubLoginRedirect(dest: URL) {
        stub(condition: isAbsoluteURLString(Self.siteLoginURL.absoluteString)) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 302, headers: ["Location": dest.absoluteString])
        }
    }

    private func stubNewPostPage(nonceScript: String? = nil, statusCode: Int32) {
        let script = nonceScript ?? """
            wp.apiFetch.nonceMiddleware = wp.apiFetch.createNonceMiddleware( "\(Self.nonce)" );
            wp.apiFetch.use( wp.apiFetch.nonceMiddleware );
            wp.apiFetch.use( wp.apiFetch.mediaUploadMiddleware );
            """
        let html = "<!DOCTYPE html><html>\n\(script)\n</html>"
        stub(condition: isAbsoluteURLString(Self.newPostURL.absoluteString)) { _ in
            HTTPStubsResponse(data: html.data(using: .utf8)!, statusCode: statusCode, headers: nil)
        }
    }

    private func stubAjax(statusCode: Int32) {
        stub(condition: isAbsoluteURLString(Self.ajaxURL.absoluteString)) { _ in
            HTTPStubsResponse(data: (statusCode == 200 ? Self.nonce : "<html>...</html>").data(using: .utf8)!, statusCode: statusCode, headers: nil)
        }
    }

}
