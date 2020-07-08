import UIKit
import XCTest
import Nimble

@testable import WordPress

class ReaderCardServiceTests: XCTestCase {

    private var coreDataStack: CoreDataStack!
    private var remoteService: ReaderPostServiceRemote!
    private var apiMock: WordPressComMockRestApi!

    override func setUp() {
        super.setUp()
        coreDataStack = TestContextManager()
        apiMock = WordPressComMockRestApi()
        remoteService = ReaderPostServiceRemote(wordPressComRestApi: apiMock)
    }

    override func tearDown() {
        super.tearDown()
        ContextManager.overrideSharedInstance(nil)
    }


    /// Save 9 cards in the database
    /// The API returns 10, but one of them is unknown and shouldn't be saved
    ///
    func testSaveCards() {
        let expectation = self.expectation(description: "Image should fail to return a video asset.")

        let service = ReaderCardService(service: remoteService, coreDataStack: coreDataStack)
        apiMock.succeed = true

        service.fetch(success: { _, _ in
            let cards = try? self.coreDataStack.mainContext.fetch(NSFetchRequest(entityName: ReaderCard.classNameWithoutNamespaces()))
            expect(cards?.count).to(equal(9))
            expectation.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: 5, handler: nil)
    }

    /// From the 9 cards saved, 8 should have posts
    ///
    func testSaveCardsWithPosts() {
        let expectation = self.expectation(description: "Image should fail to return a video asset.")

        let service = ReaderCardService(service: remoteService, coreDataStack: coreDataStack)
        apiMock.succeed = true

        service.fetch(success: { _, _ in
            let cards = try? self.coreDataStack.mainContext.fetch(NSFetchRequest(entityName: ReaderCard.classNameWithoutNamespaces())) as? [ReaderCard]
            expect(cards?.filter { $0.post != nil }.count).to(equal(8))
            expectation.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: 5, handler: nil)
    }

    /// Calls the failure block when the request fails
    ///
    func testFailure() {
        let expectation = self.expectation(description: "Image should fail to return a video asset.")

        let service = ReaderCardService(service: remoteService, coreDataStack: coreDataStack)
        apiMock.succeed = false

        service.fetch(success: { _, _ in }, failure: { error in
            expect(error).toNot(beNil())
            expectation.fulfill()
        })

        waitForExpectations(timeout: 5, handler: nil)
    }
}

class WordPressComMockRestApi: WordPressComRestApi {
    var succeed = false

    override func GET(_ URLString: String, parameters: [String: AnyObject]?, success: @escaping WordPressComRestApi.SuccessResponseBlock, failure: @escaping WordPressComRestApi.FailureReponseBlock) -> Progress? {
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
