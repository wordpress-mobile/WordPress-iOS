import XCTest
@testable import WordPressKit

class ReaderTopicServiceRemoteTests: RemoteTestCase, RESTTestable {

    let mockApi = MockWordPressComRestApi()
    lazy var subject: ReaderTopicServiceRemote = {
        ReaderTopicServiceRemote(wordPressComRestApi: mockApi)
    }()

    func testFollowedSitesDefaultParameters() {
        let expectedParameter = "meta=site,feed"

        subject.fetchFollowedSites(forPage: 0, number: 0, success: { _, _ in }, failure: { _ in })

        XCTAssertTrue(mockApi.URLStringPassedIn?.contains(expectedParameter) ?? false)
    }

    func testFollowedSitesPageParameter() {
        let expectedParameter = "page=5"

        subject.fetchFollowedSites(forPage: 5, number: 0, success: { _, _ in }, failure: { _ in })

        XCTAssertTrue(mockApi.URLStringPassedIn?.contains(expectedParameter) ?? false)
    }

    func testFollowedSitesNumberParameter() {
        let expectedParameter = "number=7"

        subject.fetchFollowedSites(forPage: 0, number: 7, success: { _, _ in }, failure: { _ in })

        XCTAssertTrue(mockApi.URLStringPassedIn?.contains(expectedParameter) ?? false)
    }

    func testFollowedSitesSuccess() async throws {
        let subject = ReaderTopicServiceRemote(wordPressComRestApi: getRestApi())
        stubRemoteResponse("read/following/mine", filename: "reader-following-mine.json", contentType: .ApplicationJSON)

        let (totalSites, sites) = try await fetchFollowedSites(service: subject, page: 1, number: 1)

        XCTAssertEqual(totalSites, 1)
        XCTAssertEqual(sites?.count, 1)
    }

    func testFollowedSitesFailure() async throws {
        let subject = ReaderTopicServiceRemote(wordPressComRestApi: getRestApi())
        stubRemoteResponse("read/following/mine", filename: "reader-following-mine.json", contentType: .ApplicationJSON, status: 500)

        do {
            try await fetchFollowedSites(service: subject, page: 1, number: 1)
            XCTFail("Expected the call to throw")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Helpers

    @discardableResult
    private func fetchFollowedSites(service: ReaderTopicServiceRemote, page: UInt, number: UInt) async throws -> (NSNumber?, [RemoteReaderSiteInfo]?) {
        return try await withUnsafeThrowingContinuation { continuation in
            service.fetchFollowedSites(
                forPage: 1,
                number: 1,
                success: { continuation.resume(returning: ($0, $1))},
                failure: { continuation.resume(throwing: $0!) }
            )
        }
    }

}
