import XCTest
import WordPressKit

@testable import WordPress

final class BlazeCampaignsStreamTests: CoreDataTestCase {
    private var sut: BlazeCampaignsStream!
    private var blog: Blog!
    // swiftlint:disable:next weak_delegate
    private var delegate = MockCampaignsStreamDelegate()
    private let service = MockBlazePaginatedService()

    override func setUp() {
        super.setUp()

        blog = ModelTestHelper.insertDotComBlog(context: mainContext)
        blog.dotComID = 1

        sut = BlazeCampaignsStream(blog: blog, service: service)
        sut.delegate = delegate
    }

    func testThatPagesAreLoaded() throws {
        XCTAssertTrue(sut.campaigns.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)

        // When loading the first page
        try loadNextPage()

        // Then the first page is loaded
        XCTAssertEqual(service.numberOfRequests, 1)
        XCTAssertEqual(delegate.appendedIndexPaths, [[IndexPath(row: 0, section: 0)]])
        guard delegate.states.count == 2 else {
            return XCTFail("Unexpected state updates recorded: \(delegate.states)")
        }
        do {
            let state = delegate.states[0]
            XCTAssertEqual(state.campaignIDs, [])
            XCTAssertTrue(state.isLoading)
            XCTAssertNil(state.error)
        }
        do {
            let state = delegate.states[1]
            XCTAssertEqual(state.campaignIDs, [1])
            XCTAssertFalse(state.isLoading)
            XCTAssertNil(state.error)
        }

        // When loading the second page
        delegate.reset()
        try loadNextPage()

        // Then the second page is loaded
        XCTAssertEqual(service.numberOfRequests, 2)
        XCTAssertEqual(delegate.appendedIndexPaths, [[IndexPath(row: 1, section: 0)]])
        guard delegate.states.count == 2 else {
            return XCTFail("Unexpected state updates recorded: \(delegate.states)")
        }
        do {
            let state = delegate.states[0]
            XCTAssertEqual(state.campaignIDs, [1])
            XCTAssertTrue(state.isLoading)
            XCTAssertNil(state.error)
        }
        do {
            let state = delegate.states[1]
            // Then the duplicated campaign with ID "1" is skipped
            XCTAssertEqual(state.campaignIDs, [1, 2])
            XCTAssertFalse(state.isLoading)
            XCTAssertNil(state.error)
        }

        // When loading with not more pages available
        delegate.reset()
        sut.load()

        // Then no requests are made
        XCTAssertTrue(delegate.appendedIndexPaths.isEmpty)
        XCTAssertTrue(delegate.states.isEmpty)
        XCTAssertEqual(service.numberOfRequests, 2)
    }

    func testFirstPageFailedToLoad() throws {
        // Given
        service.isFailing = true

        // When loading the first page
        do {
            try loadNextPage()
            XCTFail("Expected the request to fail")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }

        // Then
        XCTAssertEqual(service.numberOfRequests, 1)
        XCTAssertEqual(delegate.appendedIndexPaths, [])
        guard delegate.states.count == 2 else {
            return XCTFail("Unexpected state updates recorded: \(delegate.states)")
        }
        do {
            let state = delegate.states[0]
            XCTAssertEqual(state.campaignIDs, [])
            XCTAssertTrue(state.isLoading)
            XCTAssertNil(state.error)
        }
        do {
            let state = delegate.states[1]
            XCTAssertEqual(state.campaignIDs, [])
            XCTAssertFalse(state.isLoading)
            let error = try XCTUnwrap(state.error)
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }

        // When connection restored
        service.isFailing = false

        // When
        delegate.reset()
        try loadNextPage()

        // Then the first page is loaded
        XCTAssertEqual(service.numberOfRequests, 2)
        XCTAssertEqual(delegate.appendedIndexPaths, [[IndexPath(row: 0, section: 0)]])
        guard delegate.states.count == 2 else {
            return XCTFail("Unexpected state updates recorded: \(delegate.states)")
        }
        do {
            let state = delegate.states[0]
            XCTAssertEqual(state.campaignIDs, [])
            XCTAssertTrue(state.isLoading)
            XCTAssertNil(state.error)
        }
        do {
            let state = delegate.states[1]
            XCTAssertEqual(state.campaignIDs, [1])
            XCTAssertFalse(state.isLoading)
            XCTAssertNil(state.error)
        }
    }

    func testSecondPageFailedToLoad() throws {
        // Given first page already loaded
        try loadNextPage()

        // When connection fails
        service.isFailing = true

        // When
        delegate.reset()
        do {
            try loadNextPage()
            XCTFail("Expected the request to fail")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }

        // Then the second page fails to load
        XCTAssertEqual(service.numberOfRequests, 2)
        XCTAssertEqual(delegate.appendedIndexPaths, [])
        guard delegate.states.count == 2 else {
            return XCTFail("Unexpected state updates recorded: \(delegate.states)")
        }
        do {
            let state = delegate.states[0]
            XCTAssertEqual(state.campaignIDs, [1])
            XCTAssertTrue(state.isLoading)
            XCTAssertNil(state.error)
        }
        do {
            let state = delegate.states[1]
            XCTAssertEqual(state.campaignIDs, [1])
            XCTAssertFalse(state.isLoading)
            let error = try XCTUnwrap(state.error)
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }

        // When connection is restored
        service.isFailing = false

        // When loading the second page
        delegate.reset()
        try loadNextPage()

        // Then the second page is loaded
        XCTAssertEqual(service.numberOfRequests, 3)
        XCTAssertEqual(delegate.appendedIndexPaths, [[IndexPath(row: 1, section: 0)]])
        guard delegate.states.count == 2 else {
            return XCTFail("Unexpected state updates recorded: \(delegate.states)")
        }
        do {
            let state = delegate.states[0]
            XCTAssertEqual(state.campaignIDs, [1])
            XCTAssertTrue(state.isLoading)
            XCTAssertNil(state.error)
        }
        do {
            let state = delegate.states[1]
            // Then the duplicated campaign with ID "1" is skipped
            XCTAssertEqual(state.campaignIDs, [1, 2])
            XCTAssertFalse(state.isLoading)
            XCTAssertNil(state.error)
        }
    }

    @discardableResult
    private func loadNextPage() throws -> BlazeCampaignsSearchResponse {
        let expectation = self.expectation(description: "didLoadNextPage")
        var result: Result<BlazeCampaignsSearchResponse, Error>?
        sut.load {
            result = $0
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
        return try XCTUnwrap(result).get()
    }
}

private final class MockCampaignsStreamDelegate: BlazeCampaignsStreamDelegate {
    var appendedIndexPaths: [[IndexPath]] = []
    var states: [RecordedBlazeCampaignsStreamState] = []

    func reset() {
        appendedIndexPaths = []
        states = []
    }

    func stream(_ stream: BlazeCampaignsStream, didAppendItemsAt indexPaths: [IndexPath]) {
        appendedIndexPaths.append(indexPaths)
    }

    func streamDidRefreshState(_ stream: BlazeCampaignsStream) {
        states.append(RecordedBlazeCampaignsStreamState(campaigns: stream.campaigns, isLoading: stream.isLoading, error: stream.error))
    }
}

private struct RecordedBlazeCampaignsStreamState {
    let campaigns: [BlazeCampaign]
    var campaignIDs: [Int] { campaigns.map(\.campaignID) }
    let isLoading: Bool
    let error: Error?
}

private final class MockBlazePaginatedService: BlazeServiceProtocol {
    var numberOfRequests = 0
    var isFailing = false

    func getRecentCampaigns(for blog: Blog, page: Int, completion: @escaping (Result<BlazeCampaignsSearchResponse, Error>) -> Void) {
        XCTAssertEqual(blog.dotComID, 1)
        XCTAssertTrue([1, 2].contains(page))

        numberOfRequests += 1

        guard !isFailing else {
            return completion(.failure(URLError(.notConnectedToInternet)))
        }

        do {
            let data = try Bundle.test.json(named: "blaze-search-page-\(page)")
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            let response = try decoder.decode(BlazeCampaignsSearchResponse.self, from: data)
            completion(.success(response))
        } catch {
            completion(.failure(error))
        }
    }
}
