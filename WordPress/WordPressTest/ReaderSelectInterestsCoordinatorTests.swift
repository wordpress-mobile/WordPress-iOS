import XCTest
@testable import WordPress

class ReaderSelectInterestsCoordinatorTests: XCTestCase {
    func testShouldDisplayReturnsTrue() {
        let store = EphemeralKeyValueDatabase()
        let service = MockFollowedInterestsService(populateItems: false)
        let coordinator = ReaderSelectInterestsCoordinator(service: service, store: store, userId: 1)

        service.success = true
        service.fetchSuccessExpectation = expectation(description: "Fetching of interests succeeds")

        let displayExpectation = expectation(description: "Should display returns true")
        coordinator.shouldDisplay { (result) in
            displayExpectation.fulfill()

            XCTAssertTrue(result)
        }

        waitForExpectations(timeout: 4, handler: nil)
    }

    func testShouldDisplayReturnsFalseIfUserHasFollowedInterests() {
        let store = EphemeralKeyValueDatabase()
        let service = MockFollowedInterestsService(populateItems: true)
        let coordinator = ReaderSelectInterestsCoordinator(service: service, store: store, userId: 1)

        let successExpectation = expectation(description: "Fetching of interests succeeds")

        service.success = true
        service.fetchSuccessExpectation = successExpectation

        let displayExpectation = expectation(description: "Should display returns true")
        coordinator.shouldDisplay { (result) in
            displayExpectation.fulfill()

            XCTAssertFalse(result)
        }

        waitForExpectations(timeout: 4, handler: nil)
    }

    func testShouldDisplayReturnsFalseIfUserHasSeenBefore() {
        let store = EphemeralKeyValueDatabase()
        let service = MockFollowedInterestsService(populateItems: true)
        let coordinator = ReaderSelectInterestsCoordinator(service: service, store: store, userId: 1)
        coordinator.markAsSeen()

        let successExpectation = expectation(description: "Fetching of interests succeeds")

        service.success = true
        service.fetchSuccessExpectation = successExpectation

        let displayExpectation = expectation(description: "Should display returns true")
        coordinator.shouldDisplay { (result) in
            displayExpectation.fulfill()

            XCTAssertFalse(result)
        }

        waitForExpectations(timeout: 4, handler: nil)
    }

    func testMarkAsSeen() {
        let store = EphemeralKeyValueDatabase()
        let service = MockFollowedInterestsService(populateItems: false)
        let coordinator = ReaderSelectInterestsCoordinator(service: service, store: store, userId: 1)

        coordinator.markAsSeen()

        XCTAssertTrue(coordinator.hasSeenBefore())
    }

    func testHasSeenBeforeFalse() {
        let store = EphemeralKeyValueDatabase()
        let service = MockFollowedInterestsService(populateItems: false)
        let coordinator = ReaderSelectInterestsCoordinator(service: service, store: store, userId: 1)

        XCTAssertFalse(coordinator.hasSeenBefore())
    }
}


// MARK: - MockFollowedInterestsService
class MockFollowedInterestsService: ReaderFollowedInterestsService {
    var success = true
    var fetchSuccessExpectation: XCTestExpectation?
    var fetchFailureExpectation: XCTestExpectation?

    private let failureError = NSError(domain: "org.wordpress.reader-tests", code: 1, userInfo: nil)

    private var testContextManager: CoreDataStack?
    private var context: NSManagedObjectContext?

    init(populateItems: Bool) {

        testContextManager = TestContextManager.sharedInstance()
        context = testContextManager?.mainContext

        // Don't populate the objects
        guard populateItems else {
            return
        }

        populateTestItems()
    }

    // MARK: - Fetch Methods
    func fetchFollowedInterestsLocally(completion: @escaping ([ReaderTagTopic]?) -> Void) {
        guard self.success else {
            fetchFailureExpectation?.fulfill()

            completion(nil)
            return
        }

        let interests = followedInterests()

        completion(interests)
        fetchSuccessExpectation?.fulfill()
    }

    func fetchFollowedInterestsRemotely(completion: @escaping ([ReaderTagTopic]?) -> Void) {
        self.fetchFollowedInterestsLocally(completion: completion)
    }

    // MARK: - Private: Helpers
    private func populateTestItems() {
        guard let context = context else {
            XCTFail("Context is nil")
            return
        }

        let interest = NSEntityDescription.insertNewObject(forEntityName: "ReaderTagTopic", into: context) as! ReaderTagTopic
        interest.path = "/tags/interest"
        interest.title = "interest"
        interest.type = ReaderTagTopic.TopicType
        interest.following = true

        do {
            try context.save()
        } catch let error as NSError {
            XCTAssertNil(error, "Error seeding topics")
        }
    }

    private func followedInterestsFetchRequest() -> NSFetchRequest<ReaderTagTopic> {
        let entityName = "ReaderTagTopic"
        let predicate = NSPredicate(format: "following = YES")
        let fetchRequest = NSFetchRequest<ReaderTagTopic>(entityName: entityName)
        fetchRequest.predicate = predicate

        return fetchRequest
    }

    private func followedInterests() -> [ReaderTagTopic]? {
        let fetchRequest = followedInterestsFetchRequest()
        do {
            guard let interests = try context?.fetch(fetchRequest) else {
                return nil
            }

            return interests
        } catch {
            XCTAssertNil(error, "Error fetching interests")

            return nil
        }
    }
}
