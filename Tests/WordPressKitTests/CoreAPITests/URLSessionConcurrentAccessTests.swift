import Foundation
import Testing

@testable import WordPressKit

/// Each round uses a new API object, because the session properties can only race on their first read.
struct URLSessionConcurrentAccessTests {
    private let rounds = 100

    @Test func wordPressComRestApiCreatesEachSessionOnce() {
        for _ in 0..<rounds {
            let api = WordPressComRestApi()
            #expect(readConcurrently { api.urlSession }.count == 1)
            #expect(readConcurrently { api.uploadURLSession }.count == 1)
        }
    }

    @Test func wordPressOrgXMLRPCApiCreatesSessionOnce() throws {
        let endpoint = try #require(URL(string: "https://example.com/xmlrpc.php"))
        for _ in 0..<rounds {
            let api = WordPressOrgXMLRPCApi(endpoint: endpoint)
            #expect(readConcurrently { api.urlSession }.count == 1)
        }
    }

    /// The upload session is the default session here, so its first read also creates the default session.
    @Test func wordPressOrgXMLRPCApiUploadSessionIsDefaultSession() throws {
        let endpoint = try #require(URL(string: "https://example.com/xmlrpc.php"))
        for _ in 0..<rounds {
            let api = WordPressOrgXMLRPCApi(endpoint: endpoint)
            #expect(readConcurrently { api.uploadURLSession }.count == 1)
            #expect(api.uploadURLSession === api.urlSession)
        }
    }

    /// Returns the distinct sessions that several threads read at the same time. The set keeps the sessions alive,
    /// so a freed session's address cannot be reused and hide a duplicate.
    private func readConcurrently(_ read: () -> URLSession) -> Set<URLSession> {
        let lock = NSLock()
        var sessions = Set<URLSession>()
        DispatchQueue.concurrentPerform(iterations: 8) { _ in
            let session = read()
            lock.withLock { _ = sessions.insert(session) }
        }
        return sessions
    }
}
