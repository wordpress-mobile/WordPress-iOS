import XCTest
@testable import WordPress

final class DefaultNewsManagerTests: XCTestCase {
    private struct Constants {
        static let title = "This is an awesome new feature!"
        static let contextId = "context"
        static let previousCardBuildNumber = "10.5"
        static let cardTitle = "Hello"
        static let cardContent = "How is your day going so far?"
        static let cardURL = URL(string: "http://wordpress.com")!
    }

    private final class MockNewsService: NewsService {
        func load(then completion: @escaping (Result<NewsItem>) -> Void) {
            let newsItem = NewsItem(title: Constants.title,
                                    content: Constants.contextId,
                                    extendedInfoURL: Constants.cardURL,
                                    version: currentBuildVersion()!)

            let result: Result<NewsItem> = .success(newsItem)
            completion(result)
        }
    }

    private final class MockInMemoryDefaults: NullMockUserDefaults {
        var previousVersion: Decimal?
        var previousContext: String?
        override func object(forKey defaultName: String) -> Any? {
            if defaultName == DefaultNewsManager.DatabaseKeys.lastDismissedCardVersion {
                return previousVersion
            } else if defaultName == DefaultNewsManager.DatabaseKeys.cardContainerIdentifier {
                return previousContext
            } else {
                return nil
            }
        }

        override func set(_ value: Any?, forKey defaultName: String) {
            //
        }
    }

    private final class MockDelegate: NewsManagerDelegate {
        var dismissed = false
        var extendedInfoRequested = false
        func didDismissNews() {
            dismissed = true
        }

        func didSelectReadMore() {
            extendedInfoRequested = true
        }
    }

    private final class MockStats: NewsStats {
        var presentTracked = false
        var dismissTracked = false
        var requestExtraInfoTracked = false

        func trackPresented(news: Result<NewsItem>?) {
            presentTracked = true
        }

        func trackDismissed(news: Result<NewsItem>?) {
            dismissTracked = true
        }

        func trackRequestedExtendedInfo(news: Result<NewsItem>?) {
            requestExtraInfoTracked = true
        }
    }

    private var manager: NewsManager?
    private var service: NewsService?
    private var database: MockInMemoryDefaults?
    private var delegate: MockDelegate?
    private var stats: MockStats?

    override func setUp() {
        super.setUp()
        service = MockNewsService()
        database = MockInMemoryDefaults()
        delegate = MockDelegate()
        stats = MockStats()
        manager = DefaultNewsManager(service: service!, database: database!, stats: stats!, delegate: delegate!)
    }

    override func tearDown() {
        manager = nil
        service = nil
        database = nil
        delegate = nil
        stats = nil
        super.tearDown()
    }

    func testManagerReturnsExpectedContent() {
        manager?.load(then: { result in
            switch result {
            case .error:
                XCTFail()
            case .success(let newsItem):
                XCTAssertEqual(newsItem.title, Constants.title)
            }
        })
    }

    func testManagerShouldPresentCardIfContextIsEmptyAndThereIsNoPreviousCard() {
        XCTAssertTrue(manager!.shouldPresentCard(contextId: Identifier.empty()))
    }

    func testManagerShouldPresentCardIfCardVersionIsGreaterThanPreviousCardVersion() {
        database?.previousVersion = Decimal(string: Constants.previousCardBuildNumber)
        let contextIdentifier = Identifier.empty()

        XCTAssertTrue(manager!.shouldPresentCard(contextId: contextIdentifier))
    }

    func testManagerShouldPresentUIIfCardVersionIsEqualToPreviousCardVersionAndIsHasNotBeenDismissed() {
        let contextIdentifier = Identifier.empty()

        XCTAssertTrue(manager!.shouldPresentCard(contextId: contextIdentifier))
    }

    func testManagerShouldNotPresentUIWhenIsItNotPresentedInTheRightContext() {
        database?.previousContext = Constants.contextId

        let newContext = Identifier.empty()

        XCTAssertFalse(manager!.shouldPresentCard(contextId: newContext))
    }

    func testManagerShouldPresentUIWhenIsItPresentedInTheRightContextAndTheCardVersionIsGreaterThanLastSavedVersion() {
        database?.previousContext = Constants.contextId
        database?.previousVersion = Decimal(string: Constants.previousCardBuildNumber)

        let newContext = Identifier(value: Constants.contextId)

        XCTAssertTrue(manager!.shouldPresentCard(contextId: newContext))
    }

    func testManagerCallsDelegateMethodWhenDismissing() {
        manager?.dismiss()

        XCTAssertTrue(delegate!.dismissed)
    }

    func restManagerCallsDelegateMethodWhenReadMore() {
        manager?.readMore()

        XCTAssertTrue(delegate!.extendedInfoRequested)
    }

    func testDismissCallsStats() {
        manager?.dismiss()

        XCTAssertTrue(stats!.dismissTracked)
    }

    func testPresentCallsStats() {
        let _ = manager?.didPresentCard()

        XCTAssertTrue(stats!.presentTracked)
    }

    func testRequestExtraInfoCallsStats() {
        manager?.readMore()

        XCTAssertTrue(stats!.requestExtraInfoTracked)
    }

    private static func currentBuildVersion() -> Decimal? {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil
        }

        return Decimal(string: version)
    }
}
