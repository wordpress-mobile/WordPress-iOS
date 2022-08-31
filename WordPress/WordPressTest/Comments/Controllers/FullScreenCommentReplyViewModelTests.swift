
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

    func testSuggestionsTableViewIsNotNil() {
        let tableView = sut.suggestionsTableView(with: number, useTransparentHeader: false, prominentSuggestionsIds: [number], delegate: SuggestionsTableViewDelegateMock())

        XCTAssertNotNil(tableView)
    }

    func testShouldShowSuggestionsIsFalse() {
        let expectedResult = false

        let result = sut.shouldShowSuggestions(with: number)

        XCTAssertEqual(result, expectedResult, "shouldShowSuggestions should return false")
    }
}
