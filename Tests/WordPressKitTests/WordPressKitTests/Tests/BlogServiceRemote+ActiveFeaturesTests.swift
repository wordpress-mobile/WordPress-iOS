import XCTest
@testable import WordPressKit

class BlogServiceRemote_ActiveFeaturesTests: RemoteTestCase, RESTTestable {

    private let siteID = NSNumber(value: 1001)
    private let syncBlogWithFeaturesFilename = "sites-site-active-features.json"
    private let syncBlogWithEmptyFeaturesFilename = "sites-site-no-active-features.json"

    private var syncBlogEndpoint: String {
        "/sites/\(siteID)"
    }

    private lazy var remote: BlogServiceRemoteREST = {
        .init(wordPressComRestApi: getRestApi(), siteID: siteID)
    }()

    // MARK: Tests

    func testSyncBlogParsesActiveFeatures() async throws {
        stubRemoteResponse(syncBlogEndpoint, filename: syncBlogWithFeaturesFilename, contentType: .ApplicationJSON)

        let blog = try await withCheckedThrowingContinuation { continuation in
            remote.syncBlog { remoteBlog in
                continuation.resume(returning: remoteBlog)
            } failure: { error in
                continuation.resume(throwing: error!)
            }
        }

        let features = try XCTUnwrap(blog?.planActiveFeatures)
        XCTAssertEqual(features.count, 3)
    }

    func testActiveFeaturesDefaultValue() async throws {
        stubRemoteResponse(syncBlogEndpoint, filename: syncBlogWithEmptyFeaturesFilename, contentType: .ApplicationJSON)

        let blog = try await withCheckedThrowingContinuation { continuation in
            remote.syncBlog { remoteBlog in
                continuation.resume(returning: remoteBlog)
            } failure: { error in
                continuation.resume(throwing: error!)
            }
        }

        let features = try XCTUnwrap(blog?.planActiveFeatures)
        XCTAssertTrue(features.isEmpty)
    }
}
