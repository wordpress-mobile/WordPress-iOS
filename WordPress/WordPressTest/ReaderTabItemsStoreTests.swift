@testable import WordPress
import XCTest
import WordPressFlux


class MockTopicService: ReaderTopicService {

    var success = true
    var fetchReaderMenuExpectation: XCTestExpectation?
    var fetchMenuSuccessExpectation: XCTestExpectation?
    var fetchMenuFailureExpectation: XCTestExpectation?
    var failureError: Error?

    override func fetchReaderMenu(success: (() -> Void)!, failure: ((Error?) -> Void)!) {
        fetchReaderMenuExpectation?.fulfill()

        guard self.success else {
            fetchMenuFailureExpectation?.fulfill()
            failure(failureError)
            return
        }
        fetchMenuSuccessExpectation?.fulfill()
        success()
    }
}


class ReaderTabItemsStoreTests: XCTestCase {

    var contextManager: TestContextManager!
    var context: MockContext!
    private var subscription: Receipt?
    private var store: ReaderTabItemsStore!
    private var service: MockTopicService!

    private let mockError = NSError(domain: "mockContextDomain", code: -1, userInfo: nil)

    override func setUp() {
        contextManager = TestContextManager()
        context = contextManager.getMockContext()
        service = MockTopicService(managedObjectContext: context)
        store = ReaderTabItemsStore(context: context, service: service)
    }

    override func tearDown() {
        contextManager = nil
        context = nil
        service = nil
        subscription = nil
        store = nil
    }

    /// get items succeeds
    func testGetItemsSuccess() {
        // Given
        let mockTopic = ReaderAbstractTopic(context: context)
        mockTopic.title = "imamock"
        let mockTopics = [mockTopic]

        context.returnedObjects = mockTopics

        let stateChangeExpectation = expectation(description: "state change emitted")
        stateChangeExpectation.expectedFulfillmentCount = 2

        subscription = store.onChange {
            stateChangeExpectation.fulfill()
            // it will behave as isLoggedIn() == false
            XCTAssertEqual(["Following", "imamock", "Saved"], self.store.items.map { $0.title })
        }
        // When
        store.getItems()
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    /// remote service fetch fails - fetch local items
    func testGetLocalItemsOnRemoteServiceFailure() {
        // Given
        let mockTopic = ReaderAbstractTopic(context: context)
        mockTopic.title = "imamock"
        let mockTopics = [mockTopic]

        context.returnedObjects = mockTopics

        service.success = false
        service.fetchReaderMenuExpectation = expectation(description: "fetch menu items executed")
        service.fetchMenuFailureExpectation = expectation(description: "fetch from remote service failed")

        let stateChangeExpectation = expectation(description: "state change emitted")
        stateChangeExpectation.expectedFulfillmentCount = 2

        subscription = store.onChange {
            stateChangeExpectation.fulfill()
            // it will behave as isLoggedIn() == false
            XCTAssertEqual(["Following", "imamock", "Saved"], self.store.items.map { $0.title })
        }
        // When
        store.getItems()
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    /// fetch request fails
    func testGetItemsFetchRequestFailure() {
        // Given
        context.success = false
        context.fetchError = mockError

        service.fetchReaderMenuExpectation = expectation(description: "fetch menu items executed")
        service.fetchMenuSuccessExpectation = expectation(description: "fetch from remote service succeeded")

        let stateChangeExpectation = expectation(description: "state change emitted")
        stateChangeExpectation.expectedFulfillmentCount = 2

        subscription = store.onChange {
            stateChangeExpectation.fulfill()
            switch self.store.state {
            case .ready, .loading:
                XCTFail("failure not detected")
            case .error(let error):
                XCTAssertEqual(error as NSError, self.mockError)
            }
        }
        // When
        store.getItems()
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")

            }
        }
    }
}
