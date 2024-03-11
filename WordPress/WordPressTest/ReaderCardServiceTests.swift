import UIKit
import XCTest
import Nimble

@testable import WordPress

class ReaderCardServiceTests: CoreDataTestCase {

    private var remoteService: ReaderPostServiceRemoteMock!
    private var followedInterestsService: ReaderFollowedInterestsServiceMock!

    override func setUp() {
        super.setUp()
        followedInterestsService = ReaderFollowedInterestsServiceMock(context: mainContext)
        remoteService = ReaderPostServiceRemoteMock()
    }

    /// Returns an error if the user don't follow any Interest
    ///
    func testReturnErrorWhenNotFollowingAnyInterest() {
        let expectation = self.expectation(description: "Error when now following interests")
        let service = ReaderCardService(service: remoteService, coreDataStack: contextManager, followedInterestsService: followedInterestsService)
        followedInterestsService.returnInterests = false

        service.fetch(isFirstPage: true, success: { _, _ in }, failure: { error in
            expect(error).toNot(beNil())
            expectation.fulfill()
        })

        waitForExpectations(timeout: 5, handler: nil)
    }

    /// Save 10 cards in the database
    /// The API returns 11, but one of them is unknown and shouldn't be saved
    ///
    func testSaveCards() {
        let expectation = self.expectation(description: "10 reader cards should be returned")

        let service = ReaderCardService(service: remoteService, coreDataStack: contextManager, followedInterestsService: followedInterestsService)

        service.fetch(isFirstPage: true, success: { _, _ in
            let cards = try? self.mainContext.fetch(NSFetchRequest(entityName: ReaderCard.classNameWithoutNamespaces()))
            expect(cards?.count).to(equal(10))
            expectation.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: 5, handler: nil)
    }

    /// From the 10 cards saved, 8 should have posts
    ///
    func testSaveCardsWithPosts() {
        let expectation = self.expectation(description: "8 cards with posts should be returned")

        let service = ReaderCardService(service: remoteService, coreDataStack: contextManager, followedInterestsService: followedInterestsService)

        service.fetch(isFirstPage: true, success: { _, _ in
            let cards = try? self.mainContext.fetch(NSFetchRequest(entityName: ReaderCard.classNameWithoutNamespaces())) as? [ReaderCard]
            expect(cards?.filter { $0.post != nil }.count).to(equal(8))
            expectation.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: 5, handler: nil)
    }

    /// Calls the failure block when the request fails
    ///
    func testFailure() {
        let expectation = self.expectation(description: "Failure callback should be called")
        let service = ReaderCardService(service: remoteService, coreDataStack: contextManager, followedInterestsService: followedInterestsService)
        remoteService.shouldCallFailure = true

        service.fetch(isFirstPage: true, success: { _, _ in }, failure: { error in
            expect(error).toNot(beNil())
            expectation.fulfill()
        })

        waitForExpectations(timeout: 5, handler: nil)
    }

    /// When fetching the first page, clean all the cards
    ///
    func testFirstPageClean() {
        let expectation = self.expectation(description: "Only 10 cards should be returned")
        let service = ReaderCardService(service: remoteService, coreDataStack: contextManager, followedInterestsService: followedInterestsService)

        service.fetch(isFirstPage: false, success: { _, _ in
            // Fetch again, this time the 1st page
            service.fetch(isFirstPage: true, success: { _, _ in
                let cards = try? self.mainContext.fetch(NSFetchRequest(entityName: ReaderCard.classNameWithoutNamespaces())) as? [ReaderCard]
                expect(cards?.count).to(equal(10))
                expectation.fulfill()
            }, failure: { _ in })
        }, failure: {_ in })

        waitForExpectations(timeout: 5, handler: nil)

        service.clean()
        let cards = try? self.mainContext.fetch(NSFetchRequest(entityName: ReaderCard.classNameWithoutNamespaces())) as? [ReaderCard]
        expect(cards?.count).to(equal(0))
    }
}

final class ReaderPostServiceRemoteMock: ReaderCardServiceRemote {

    var shouldCallFailure = false

    func fetchStreamCards(for topics: [String],
                          page: String?,
                          sortingOption: WordPressKit.ReaderSortingOption,
                          refreshCount: Int?,
                          count: Int?,
                          success: @escaping ([WordPressKit.RemoteReaderCard], String?) -> Void,
                          failure: @escaping (any Error) -> Void) {
        mockFetch(success: success, failure: failure)
    }

    func fetchCards(for topics: [String],
                    page: String?,
                    sortingOption: WordPressKit.ReaderSortingOption,
                    refreshCount: Int?,
                    success: @escaping ([WordPressKit.RemoteReaderCard], String?) -> Void,
                    failure: @escaping (any Error) -> Void) {
        mockFetch(success: success, failure: failure)
    }

    func mockFetch(success: @escaping ([WordPressKit.RemoteReaderCard], String?) -> Void,
                   failure: @escaping (any Error) -> Void) {
        guard !shouldCallFailure else {
            failure(NSError(code: -1, domain: "", description: ""))
            return
        }

        guard let fileUrl = Bundle.main.url(forResource: "reader-cards.json", withExtension: nil),
              let data = try? Data(contentsOf: fileUrl),
              let cards = try? JSONDecoder().decode([RemoteReaderCard].self, from: data) else {
            XCTFail("Error setting up mock data")
            return
        }
        success(cards, nil)
    }

}

private class ReaderFollowedInterestsServiceMock: ReaderFollowedInterestsService {
    var returnInterests = true

    private let context: NSManagedObjectContext

    lazy var topics: [ReaderTagTopic] = {
        let pugTopic = ReaderTagTopic(context: context)
        pugTopic.slug = "pug"
        pugTopic.isRecommended = false
        pugTopic.tagID = 1
        pugTopic.inUse = false
        pugTopic.following = true
        pugTopic.path = ""
        pugTopic.showInMenu = false
        pugTopic.title = "Pug"
        pugTopic.type = "pug"

        let catTopic = ReaderTagTopic(context: context)
        catTopic.slug = "cat"
        catTopic.isRecommended = false
        catTopic.tagID = 2
        catTopic.inUse = false
        catTopic.following = true
        catTopic.path = ""
        catTopic.showInMenu = false
        catTopic.title = "Cat"
        catTopic.type = "cat"

        return [pugTopic, catTopic]
    }()

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchFollowedInterestsLocally(completion: @escaping ([ReaderTagTopic]?) -> Void) {
        completion(returnInterests ? topics : [])
    }

    func fetchFollowedInterestsRemotely(completion: @escaping ([ReaderTagTopic]?) -> Void) {
        completion(returnInterests ? topics : [])
    }

    func followInterests(_ interests: [RemoteReaderInterest], success: @escaping ([ReaderTagTopic]?) -> Void, failure: @escaping (Error) -> Void, isLoggedIn: Bool) {

    }

    func path(slug: String) -> String {
        return ""
    }
}
