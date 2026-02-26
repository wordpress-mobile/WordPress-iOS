import XCTest

@testable import WordPress
@testable import WordPressData

class ReaderCardTests: CoreDataTestCase {
    /// Create a Card of the type post from a RemoteReaderCard
    ///
    func testCreateCardPostFromRemote() {
        let expectation = self.expectation(description: "Create a Reader Card of type post")

        remoteCard(ofType: .post) { remoteCard in
            let card = ReaderCard.createOrReuse(context: self.mainContext, from: remoteCard)

            XCTAssertNotNil(card?.post)
            XCTAssertEqual(card?.post?.postTitle, "Pats, Please")
            XCTAssertEqual(card?.post?.blogName, "Grace & Gratitude")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    /// Create a Card of the type interests from a RemoteReaderCard
    ///
    func testCreateInterestsCardFromRemote() {
        let expectation = self.expectation(description: "Create a Reader Card of type interests")

        remoteCard(ofType: .interests) { remoteCard in
            let card = ReaderCard.createOrReuse(context: self.mainContext, from: remoteCard)
            let topics = card?.topicsArray

            // THEN return 0 as these were disabled in 26.5
            XCTAssertNil(topics)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    /// Create a Card of the type sites from a RemoteReaderCard
    ///
    func testCreateSitesCardFromRemote() {
        let expectation = self.expectation(description: "Create a Reader Card of type sites")

        remoteCard(ofType: .sites) { remoteCard in
            let card = ReaderCard.createOrReuse(context: self.mainContext, from: remoteCard)
            let topics = card?.sitesArray

            XCTAssertEqual(topics?.count, 1)
            XCTAssertNotNil(topics?.filter { $0.siteDescription == "Lorem Ipsum Sit Dolor Amet" })
            XCTAssertNotNil(topics?.filter { $0.siteURL == "http://loremipsum.wordpress.com" })
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    /// Don't create a Card if RemoteReaderCard type is unknown
    ///
    func testDontCreateCardTypeUnknown() {
        let expectation = self.expectation(description: "Don't create a Reader Card")

        remoteCard(ofType: .unknown) { remoteCard in
            let card = ReaderCard.createOrReuse(context: self.mainContext, from: remoteCard)

            XCTAssertNil(card)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    private func remoteCard(ofType type: RemoteReaderCard.CardType, completion: @escaping (RemoteReaderCard) -> Void) {
        let apiMock = ReaderPostServiceRemoteMock()
        apiMock.mockFetch { cards, _ in
            completion(cards.first { $0.type == type }!)
        } failure: { _ in }
    }
}
