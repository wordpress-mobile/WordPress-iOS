import XCTest
import Nimble

@testable import WordPress

final class BlogDashboardPersonalizationViewModelTests: CoreDataTestCase {
    private let repository = InMemoryUserDefaults()
    private lazy var service = BlogDashboardPersonalizationService(repository: repository, siteID: 1)
    private var blog: Blog!

    var viewModel: BlogDashboardPersonalizationViewModel!

    override func setUp() {
        super.setUp()

        blog = BlogBuilder(contextManager.mainContext).build()
        viewModel = BlogDashboardPersonalizationViewModel(blog: blog, service: service)
    }

    func testThatCardStateIsToggled() throws {
        // Given
        let cardViewModel = try XCTUnwrap(viewModel.cards.first)
        let card = cardViewModel.id
        XCTAssertEqual(card, .todaysStats)
        XCTAssertTrue(cardViewModel.isOn, "By default, the cards are enabled")
        XCTAssertTrue(service.isEnabled(card))

        // When
        cardViewModel.isOn.toggle()

        // Then
        XCTAssertFalse(cardViewModel.isOn)
        XCTAssertFalse(service.isEnabled(card), "Service wasn't updated")
    }

    func testThatAllCardsHaveTitles() {
        for card in viewModel.cards {
            XCTAssertTrue(!card.title.isEmpty)
        }
    }

    func testThatQuickStartCardsIsNotDisplayedWhenNoTourIsActive() {
        XCTAssertFalse(viewModel.cards.contains(where: { $0.id == .quickStart }))
    }
}
