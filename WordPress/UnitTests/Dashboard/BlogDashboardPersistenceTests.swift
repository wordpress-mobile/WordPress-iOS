import XCTest

@testable import WordPress

class BlogDashboardPersistenceTests: XCTestCase {
    private var persistence: BlogDashboardPersistence!

    override func setUp() {
        super.setUp()

        persistence = BlogDashboardPersistence()
    }

    func testSaveData() {
        persistence.persist(cards: cardsResponse, for: 1234)

        let directory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let fileURL = directory.appendingPathComponent("cards_1234.json")
        let data: Data = try! Data(contentsOf: fileURL)
        let cardsDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary

        XCTAssertEqual(cardsDictionary, cardsResponse)
    }

    func testGetCards() {
        persistence.persist(cards: cardsResponse, for: 1235)

        let persistedCards = persistence.getCards(for: 1235)

        XCTAssertEqual(persistedCards, cardsResponse)
    }
}

private extension BlogDashboardPersistenceTests {
    var cardsResponse: NSDictionary {
        let fileURL: URL = Bundle(for: BlogDashboardPersistenceTests.self).url(forResource: "dashboard-200-with-drafts-and-scheduled.json", withExtension: nil)!
        let data: Data = try! Data(contentsOf: fileURL)
        return try! JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
    }
}
