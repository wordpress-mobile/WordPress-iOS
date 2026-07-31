import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import Testing
import WordPressData
import WordPressKit
import XCTest

@testable import WordPress

@Suite(.serialized)
struct BlogServiceSyncTests {
    @Test @MainActor
    func coreRESTBlogSyncsOptionsUsingApplicationPassword() async throws {
        let host = "\(UUID().uuidString.lowercased()).example.com"
        let coreDataStack = ContextManager.forTesting()
        let blog = makeSelfHostedBlog(in: coreDataStack, host: host, usesCoreREST: true)
        try blog.setApplicationToken("application-password")
        defer { try? blog.deleteApplicationToken() }
        coreDataStack.saveContextAndWait(coreDataStack.mainContext)

        let stubDescriptor = stub(condition: isHost(host) && isPath("/xmlrpc.php")) { request in
            let body = request.httpBodyStream?.read().flatMap { String(data: $0, encoding: .utf8) }
            #expect(body?.contains("<string>application-password</string>") == true)
            return HTTPStubsResponse(
                data: Self.optionsResponse,
                statusCode: 200,
                headers: ["Content-Type": "text/xml; charset=UTF-8"]
            )
        }
        defer { HTTPStubs.removeStub(stubDescriptor) }

        let service = BlogService(coreDataStack: coreDataStack)
        let callbacks = await waitForCallbacks(from: service, blog: blog)

        #expect(callbacks.count == 1)
        guard case .success = callbacks.first else {
            Issue.record("Expected syncBlog to invoke its success callback, got \(callbacks)")
            return
        }
        #expect(blog.getOptionString(name: "jetpack_version") == "15.0")
    }

    @Test @MainActor
    func coreRESTBlogFailureUpdatesXMLRPCAvailabilityAndCompletesOnce() async throws {
        let host = "\(UUID().uuidString.lowercased()).example.com"
        let coreDataStack = ContextManager.forTesting()
        let blog = makeSelfHostedBlog(in: coreDataStack, host: host, usesCoreREST: true)
        try blog.setApplicationToken("application-password")
        defer { try? blog.deleteApplicationToken() }
        coreDataStack.saveContextAndWait(coreDataStack.mainContext)

        let stubDescriptor = stub(condition: isHost(host) && isPath("/xmlrpc.php")) { _ in
            HTTPStubsResponse(
                data: Data("Not found".utf8),
                statusCode: 404,
                headers: ["Content-Type": "text/html"]
            )
        }
        defer { HTTPStubs.removeStub(stubDescriptor) }

        let service = BlogService(coreDataStack: coreDataStack)
        let callbacks = await waitForCallbacks(from: service, blog: blog)

        #expect(callbacks.count == 1)
        guard case .failure = callbacks.first else {
            Issue.record("Expected syncBlog to invoke its failure callback, got \(callbacks)")
            return
        }
        #expect(blog.isXMLRPCDisabled)
    }

    @Test @MainActor
    func coreRESTBlogReportsMalformedOptionsResponse() async throws {
        let host = "\(UUID().uuidString.lowercased()).example.com"
        let coreDataStack = ContextManager.forTesting()
        let blog = makeSelfHostedBlog(in: coreDataStack, host: host, usesCoreREST: true)
        try blog.setApplicationToken("application-password")
        defer { try? blog.deleteApplicationToken() }
        coreDataStack.saveContextAndWait(coreDataStack.mainContext)

        let stubDescriptor = stub(condition: isHost(host) && isPath("/xmlrpc.php")) { _ in
            HTTPStubsResponse(
                data: Self.malformedOptionsResponse,
                statusCode: 200,
                headers: ["Content-Type": "text/xml; charset=UTF-8"]
            )
        }
        defer { HTTPStubs.removeStub(stubDescriptor) }

        let service = BlogService(coreDataStack: coreDataStack)
        let callbacks = await waitForCallbacks(from: service, blog: blog)

        #expect(callbacks.count == 1)
        guard case .failure(let error) = callbacks.first else {
            Issue.record("Expected syncBlog to reject malformed options, got \(callbacks)")
            return
        }
        #expect(error as? WordPressOrgXMLRPCApiError == .responseSerializationFailed)
        #expect(!blog.isXMLRPCDisabled)
    }

    @Test @MainActor
    func coreRESTBlogReportsMissingPassword() async {
        let host = "\(UUID().uuidString.lowercased()).example.com"
        let coreDataStack = ContextManager.forTesting()
        let blog = makeSelfHostedBlog(in: coreDataStack, host: host, usesCoreREST: true)
        coreDataStack.saveContextAndWait(coreDataStack.mainContext)

        let service = BlogService(coreDataStack: coreDataStack)
        let callbacks = await waitForCallbacks(from: service, blog: blog)

        #expect(callbacks.count == 1)
        guard case .failure(let error) = callbacks.first,
            let credentialsError = error as? Blog.BlogCredentialsError
        else {
            Issue.record("Expected syncBlog to report a credential error, got \(callbacks)")
            return
        }
        guard case .blogPasswordMissing = credentialsError else {
            Issue.record("Expected a missing password error, got \(credentialsError)")
            return
        }
        #expect(!blog.isXMLRPCDisabled)
    }

    @Test @MainActor
    func legacyBlogStillSyncsOptionsUsingPassword() async {
        let host = "\(UUID().uuidString.lowercased()).example.com"
        let coreDataStack = ContextManager.forTesting()
        let blog = makeSelfHostedBlog(in: coreDataStack, host: host, usesCoreREST: false)
        blog.password = "legacy-password"
        coreDataStack.saveContextAndWait(coreDataStack.mainContext)

        let stubDescriptor = stub(condition: isHost(host) && isPath("/xmlrpc.php")) { request in
            let body = request.httpBodyStream?.read().flatMap { String(data: $0, encoding: .utf8) }
            #expect(body?.contains("<string>legacy-password</string>") == true)
            return HTTPStubsResponse(
                data: Self.optionsResponse,
                statusCode: 200,
                headers: ["Content-Type": "text/xml; charset=UTF-8"]
            )
        }
        defer { HTTPStubs.removeStub(stubDescriptor) }

        let service = BlogService(coreDataStack: coreDataStack)
        let callbacks = await waitForCallbacks(from: service, blog: blog)

        #expect(callbacks.count == 1)
        guard case .success = callbacks.first else {
            Issue.record("Expected legacy syncBlog to invoke success, got \(callbacks)")
            return
        }
        #expect(blog.getOptionString(name: "jetpack_version") == "15.0")
    }

    @Test @MainActor
    func wordPressComBlogStillUsesWordPressComREST() async {
        let coreDataStack = ContextManager.forTesting()
        let blog = BlogBuilder(coreDataStack.mainContext, dotComID: 123)
            .withAnAccount(authToken: "wpcom-token")
            .isHostedAtWPcom()
            .build()
        coreDataStack.saveContextAndWait(coreDataStack.mainContext)
        let requestRecorder = RequestRecorder()

        let stubDescriptor = stub(
            condition: isHost("public-api.wordpress.com") && isPath("/rest/v1.1/sites/123")
        ) { request in
            requestRecorder.record(request.url)
            return HTTPStubsResponse(error: URLError(.timedOut))
        }
        defer { HTTPStubs.removeStub(stubDescriptor) }

        let service = BlogService(coreDataStack: coreDataStack)
        let callbacks = await waitForCallbacks(from: service, blog: blog)

        #expect(callbacks.count == 1)
        guard case .failure = callbacks.first else {
            Issue.record("Expected the stubbed WordPress.com request to fail, got \(callbacks)")
            return
        }
        #expect(requestRecorder.url?.host == "public-api.wordpress.com")
        #expect(requestRecorder.url?.path == "/rest/v1.1/sites/123")
    }

    @MainActor
    private func makeSelfHostedBlog(
        in coreDataStack: ContextManager,
        host: String,
        usesCoreREST: Bool
    ) -> Blog {
        let builder = BlogBuilder(coreDataStack.mainContext, dotComID: nil)
            .with(url: "https://\(host)")
            .with(username: "test-user")
            .with(siteName: "Test Site")
        if usesCoreREST {
            _ = builder.with(restApiRootURL: "https://\(host)/wp-json")
        }
        let blog = builder.build()
        blog.xmlrpc = "https://\(host)/xmlrpc.php"
        return blog
    }

    @MainActor
    private func waitForCallbacks(from service: BlogService, blog: Blog) async -> [Callback] {
        var callbacks: [Callback] = []
        service.syncBlog(
            blog,
            success: {
                callbacks.append(.success)
            },
            failure: { error in
                callbacks.append(.failure(error))
            }
        )

        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(5))
        while callbacks.isEmpty, clock.now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
        if !callbacks.isEmpty {
            try? await Task.sleep(for: .milliseconds(100))
        }
        return callbacks
    }

    private enum Callback: CustomStringConvertible {
        case success
        case failure(Error)

        var description: String {
            switch self {
            case .success:
                return "success"
            case .failure(let error):
                return "failure(\(error))"
            }
        }
    }

    private static let optionsResponse = Data(
        """
        <?xml version="1.0"?>
        <methodResponse>
          <params>
            <param>
              <value>
                <struct>
                  <member>
                    <name>jetpack_version</name>
                    <value>
                      <struct>
                        <member>
                          <name>value</name>
                          <value><string>15.0</string></value>
                        </member>
                      </struct>
                    </value>
                  </member>
                </struct>
              </value>
            </param>
          </params>
        </methodResponse>
        """
        .utf8
    )

    private static let malformedOptionsResponse = Data(
        """
        <?xml version="1.0"?>
        <methodResponse>
          <params>
            <param><value><string>unexpected</string></value></param>
          </params>
        </methodResponse>
        """
        .utf8
    )
}

private final class RequestRecorder {
    private let lock = NSLock()
    private var recordedURL: URL?

    var url: URL? {
        lock.withLock { recordedURL }
    }

    func record(_ url: URL?) {
        lock.withLock { recordedURL = url }
    }
}
