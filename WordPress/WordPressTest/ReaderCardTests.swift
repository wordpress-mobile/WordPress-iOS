import XCTest
import Nimble

@testable import WordPress

class ReaderCardTests: XCTestCase {
    private var testContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()

        testContext = TestContextManager().newDerivedContext()
    }

    /// Create a Card of the type post from a RemoteReaderCard
    ///
    func testCreateCardPostFromRemote() {
        let expectation = self.expectation(description: "Create a Reader Card of type post")

        remoteCard(ofType: .post) { remoteCard in
            let card = ReaderCard(context: self.testContext, from: remoteCard)

            expect(card?.post).toNot(beNil())
            expect(card?.post?.postTitle).to(equal("Crypto Startup School: The legal and fundraising implications of crypto tokens"))
            expect(card?.post?.blogName).to(equal("TechCrunch"))
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    /// Create a Card of the type interests from a RemoteReaderCard
    ///
    func testCreateInterestsCardFromRemote() {
        let expectation = self.expectation(description: "Create a Reader Card of type interests")

        remoteCard(ofType: .interests) { remoteCard in
            let card = ReaderCard(context: self.testContext, from: remoteCard)
            let topics = card?.topicsArray

            expect(topics?.count).to(equal(2))
            expect(topics?.filter { $0.title == "Activism" }).toNot(beNil())
            expect(topics?.filter { $0.slug == "activism" }).toNot(beNil())
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    /// Don't create a Card if RemoteReaderCard type is unknown
    ///
    func testDontCreateCardTypeUnknown() {
        let expectation = self.expectation(description: "Don't create a Reader Card")

        remoteCard(ofType: .unknown) { remoteCard in
            let card = ReaderCard(context: self.testContext, from: remoteCard)

            expect(card).to(beNil())
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    private func remoteCard(ofType type: RemoteReaderCard.CardType, completion: @escaping (RemoteReaderCard) -> Void) {
        let apiMock = WordPressComMockRestApi()
        apiMock.succeed = true
        let remoteService = ReaderPostServiceRemote(wordPressComRestApi: apiMock)
        remoteService.fetchCards(for: [], success: { cards in
            completion(cards.first { $0.type == type }!)
        }, failure: { _ in })
    }
}
