
import XCTest
@testable import WordPress

class FullScreenCommentReplyViewModelTests: CoreDataTestCase {
    private var suggestionsServiceMock: SuggestionServiceMock!
    private var sut: FullScreenCommentReplyViewModel!
    private let number = NSNumber(value: 1)

    override func setUp() {
        super.setUp()
        suggestionsServiceMock = SuggestionServiceMock(context: mainContext)
        sut = FullScreenCommentReplyViewModel(suggestionsService: suggestionsServiceMock, context: mainContext)
    }

    /// Test if SuggestionsTableView is setup properly.
    func testSuggestionsTableViewSetup() {
        let expectedProminentSuggestionsIds = [number]
        let tableView = sut.suggestionsTableView(with: number, useTransparentHeader: false, prominentSuggestionsIds: expectedProminentSuggestionsIds, delegate: SuggestionsTableViewDelegateMock())


        let viewModel = tableView.viewModel as? SuggestionsListViewModel
        XCTAssertTrue(viewModel?.userSuggestionService is SuggestionServiceMock)
        XCTAssertTrue(viewModel?.suggestionType == .mention)
        XCTAssertFalse(tableView.translatesAutoresizingMaskIntoConstraints)
        XCTAssertFalse(tableView.useTransparentHeader)
        XCTAssertEqual(tableView.prominentSuggestionsIds, expectedProminentSuggestionsIds)
    }

    func testShouldShowSuggestionsIsFalse() {
        let expectedResult = false

        let result = sut.shouldShowSuggestions(with: number)

        XCTAssertEqual(result, expectedResult, "shouldShowSuggestions should return false")
    }
}
