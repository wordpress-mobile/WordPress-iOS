import XCTest
@testable import WordPress

class ReaderSelectInterestsCoordinatorTests: XCTestCase {
    func testisFollowingInterestsReturnsFalse() {
        let store = EphemeralKeyValueDatabase()
        let service = MockFollowedInterestsService(populateItems: false)
        let coordinator = ReaderSelectInterestsCoordinator(service: service, store: store, userId: 1)

        service.success = true
        service.fetchSuccessExpectation = expectation(description: "Fetching of interests succeeds")

        let displayExpectation = expectation(description: "Should display returns true")
        coordinator.isFollowingInterests { (result) in
            displayExpectation.fulfill()

            XCTAssertFalse(result)
        }

        waitForExpectations(timeout: 4, handler: nil)
    }

    func testisFollowingInterestsReturnsTrue() {
        let store = EphemeralKeyValueDatabase()
        let service = MockFollowedInterestsService(populateItems: true)
        let coordinator = ReaderSelectInterestsCoordinator(service: service, store: store, userId: 1)

        let successExpectation = expectation(description: "Fetching of interests succeeds")

        service.success = true
        service.fetchSuccessExpectation = successExpectation

        let displayExpectation = expectation(description: "Should display returns true")
        coordinator.isFollowingInterests { (result) in
            displayExpectation.fulfill()

            XCTAssertTrue(result)
        }

        waitForExpectations(timeout: 4, handler: nil)
    }

    func testSaveInterestsTriggersSuccess() {
        let store = EphemeralKeyValueDatabase()
        let service = MockFollowedInterestsService(populateItems: false)
        let coordinator = ReaderSelectInterestsCoordinator(service: service, store: store, userId: nil)

        let successExpectation = expectation(description: "Saving of interests callback returns true")

        let interest = MockInterestsService.mock(title: "title", slug: "slug")
        coordinator.saveInterests(interests: [interest]) { success in
            successExpectation.fulfill()
            XCTAssertTrue(success)
        }

        waitForExpectations(timeout: 4, handler: nil)
    }

    func testSaveInterestsTriggersFailure() {
        let store = EphemeralKeyValueDatabase()
        let service = MockFollowedInterestsService(populateItems: false)
        let coordinator = ReaderSelectInterestsCoordinator(service: service, store: store, userId: nil)

        service.success = false

        let failureExpectation = expectation(description: "Saving of interests callback returns false")

        let interest = MockInterestsService.mock(title: "title", slug: "slug")
        coordinator.saveInterests(interests: [interest]) { success in
            failureExpectation.fulfill()
            XCTAssertFalse(success)
        }

        waitForExpectations(timeout: 4, handler: nil)
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

    func followInterests(_ interests: [RemoteReaderInterest],
                         success: @escaping ([ReaderTagTopic]?) -> Void,
                         failure: @escaping (Error) -> Void,
                         isLoggedIn: Bool) {
        guard self.success else {
            fetchFailureExpectation?.fulfill()

            failure(failureError)
            return
        }

        guard let context = context else {
            XCTFail("Context is nil")
            return
        }

        interests.forEach { remoteInterest in
            let topic = NSEntityDescription.insertNewObject(forEntityName: "ReaderTagTopic", into: context) as! ReaderTagTopic
            topic.tagID = isLoggedIn ? 1 : ReaderTagTopic.loggedOutTagID
            topic.type = ReaderTagTopic.TopicType
            topic.path = "/tag/interest"
            topic.following = true
            topic.showInMenu = true
            topic.title = remoteInterest.title
            topic.slug = remoteInterest.slug
        }

        do {
            try context.save()
        } catch let error as NSError {
            XCTAssertNil(error, "Error adding interest")
        }

        success(followedInterests())
        fetchSuccessExpectation?.fulfill()
    }

    func path(slug: String) -> String {
        return "/path/to/slug"
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
        interest.showInMenu = true

        do {
            try context.save()
        } catch let error as NSError {
            XCTAssertNil(error, "Error seeding topics")
        }
    }


    private func followedInterestsFetchRequest() -> NSFetchRequest<ReaderTagTopic> {
        let entityName = "ReaderTagTopic"
        let predicate = NSPredicate(format: "following = YES AND showInMenu = YES")
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
