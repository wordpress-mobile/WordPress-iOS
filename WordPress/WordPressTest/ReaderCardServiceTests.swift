import UIKit
import XCTest
import Nimble

@testable import WordPress

class ReaderCardServiceTests: XCTestCase {

    private var coreDataStack: CoreDataStack!
    private var remoteService: ReaderPostServiceRemote!
    private var followedInterestsService: ReaderFollowedInterestsServiceMock!
    private var apiMock: WordPressComMockRestApi!

    override func setUp() {
        super.setUp()
        coreDataStack = TestContextManager()
        apiMock = WordPressComMockRestApi()
        followedInterestsService = ReaderFollowedInterestsServiceMock(context: coreDataStack.mainContext)
        remoteService = ReaderPostServiceRemote(wordPressComRestApi: apiMock)
    }

    override func tearDown() {
        super.tearDown()
        ContextManager.overrideSharedInstance(nil)
    }

    /// Call the cards API with the saved slugs
    ///
    func testCallApiWithTheSavedSlugs() {
        let expectation = self.expectation(description: "Call the API with pug and cat slugs")

        apiMock.succeed = true
        let service = ReaderCardService(service: remoteService, coreDataStack: coreDataStack, followedInterestsService: followedInterestsService)
        service.fetch(isFirstPage: true, success: { _, _ in
            expect(self.apiMock.GETCalledWithURL).to(contain("tags%5B%5D=pug"))
            expect(self.apiMock.GETCalledWithURL).to(contain("tags%5B%5D=cat"))
            expectation.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: 5, handler: nil)
    }

    /// Call the cards API with the page handle when requesting the next page
    ///
    func testCallApiWithPageHandleWhenRequestingNextPage() {
        let expectation = self.expectation(description: "Call the API with pug and cat slugs")

        apiMock.succeed = true
        let service = ReaderCardService(service: remoteService, coreDataStack: coreDataStack, followedInterestsService: followedInterestsService)
        service.fetch(isFirstPage: true, success: { _, _ in
            service.fetch(isFirstPage: false, success: { _, _ in
                expect(self.apiMock.GETCalledWithURL).to(contain("&page_handle=ZnJvbT0xMCZiZWZvcmU9MjAyMC0wNy0yNlQxMyUzQTU1JTNBMDMlMkIwMSUzQTAw"))
                expectation.fulfill()
            }, failure: { _ in })
        }, failure: { _ in })

        waitForExpectations(timeout: 5, handler: nil)
    }

    /// Returns an error if the user don't follow any Interest
    ///
    func testReturnErrorWhenNotFollowingAnyInterest() {
        let expectation = self.expectation(description: "Error when now following interests")
        apiMock.succeed = true
        let service = ReaderCardService(service: remoteService, coreDataStack: coreDataStack, followedInterestsService: followedInterestsService)
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

        let service = ReaderCardService(service: remoteService, coreDataStack: coreDataStack, followedInterestsService: followedInterestsService)
        apiMock.succeed = true

        service.fetch(isFirstPage: true, success: { _, _ in
            let cards = try? self.coreDataStack.mainContext.fetch(NSFetchRequest(entityName: ReaderCard.classNameWithoutNamespaces()))
            expect(cards?.count).to(equal(10))
            expectation.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: 5, handler: nil)
    }

    /// From the 10 cards saved, 8 should have posts
    ///
    func testSaveCardsWithPosts() {
        let expectation = self.expectation(description: "8 cards with posts should be returned")

        let service = ReaderCardService(service: remoteService, coreDataStack: coreDataStack, followedInterestsService: followedInterestsService)
        apiMock.succeed = true

        service.fetch(isFirstPage: true, success: { _, _ in
            let cards = try? self.coreDataStack.mainContext.fetch(NSFetchRequest(entityName: ReaderCard.classNameWithoutNamespaces())) as? [ReaderCard]
            expect(cards?.filter { $0.post != nil }.count).to(equal(8))
            expectation.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: 5, handler: nil)
    }

    /// Calls the failure block when the request fails
    ///
    func testFailure() {
        let expectation = self.expectation(description: "Failure callback should be called")

        let service = ReaderCardService(service: remoteService, coreDataStack: coreDataStack, followedInterestsService: followedInterestsService)
        apiMock.succeed = false

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

        let service = ReaderCardService(service: remoteService, coreDataStack: coreDataStack, followedInterestsService: followedInterestsService)
        apiMock.succeed = true

        service.fetch(isFirstPage: false, success: { _, _ in
            // Fetch again, this time the 1st page
            service.fetch(isFirstPage: true, success: { _, _ in
                let cards = try? self.coreDataStack.mainContext.fetch(NSFetchRequest(entityName: ReaderCard.classNameWithoutNamespaces())) as? [ReaderCard]
                expect(cards?.count).to(equal(10))
                expectation.fulfill()
            }, failure: { _ in })
        }, failure: {_ in })

        waitForExpectations(timeout: 5, handler: nil)
    }
}

class WordPressComMockRestApi: WordPressComRestApi {
    var succeed = false
    var GETCalledWithURL: String?

    override func GET(_ URLString: String, parameters: [String: AnyObject]?, success: @escaping WordPressComRestApi.SuccessResponseBlock, failure: @escaping WordPressComRestApi.FailureReponseBlock) -> Progress? {
        GETCalledWithURL = URLString
        guard
            let fileURL: URL = Bundle.main.url(forResource: "reader-cards-success.json", withExtension: nil),
            let data: Data = try? Data(contentsOf: fileURL),
            let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as AnyObject
        else {
            return Progress()
        }

        if succeed {
            success(jsonObject, nil)
        } else {
            failure(NSError(domain: "", code: -1, userInfo: nil), nil)
        }

        return Progress()
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
