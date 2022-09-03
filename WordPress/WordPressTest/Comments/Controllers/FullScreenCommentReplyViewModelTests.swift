
import XCTest
@testable import WordPress

class FullScreenCommentReplyViewModelTests: CoreDataTestCase {
    private var suggestionsServiceMock: SuggestionServiceMock!
    private var sut: FullScreenCommentReplyViewModel!

    override func setUp() {
        super.setUp()
        suggestionsServiceMock = SuggestionServiceMock(context: mainContext)
        sut = FullScreenCommentReplyViewModel(suggestionsService: suggestionsServiceMock, context: mainContext)
    }

    /// Test SuggestionsTableView setup.
    func testSuggestionsTableViewSetup() throws {
        let blog = BlogBuilder(mainContext).build()
        try mainContext.save()

        let tableView = sut.suggestionsTableView(with: blog.dotComID!, useTransparentHeader: false, prominentSuggestionsIds: nil, delegate: SuggestionsTableViewDelegateMock())

        let viewModel = tableView.viewModel as? SuggestionsListViewModel
        XCTAssertTrue(viewModel?.userSuggestionService is SuggestionServiceMock)
        XCTAssertTrue(viewModel?.suggestionType == .mention)
        XCTAssertFalse(tableView.translatesAutoresizingMaskIntoConstraints)
        XCTAssertFalse(tableView.useTransparentHeader)
        XCTAssertEqual(tableView.prominentSuggestionsIds, nil)
    }

    /// Test if shouldShowSuggestions returns true.
    /// It should return true if there is a blog with the same siteID in the database.
    func testShouldShowSuggestionsIsTrue() throws {
        let blog = BlogBuilder(mainContext).build()
        try mainContext.save()
        let expectedResult = true

        let result = sut.shouldShowSuggestions(with: blog.dotComID!)

        XCTAssertEqual(result, expectedResult)
    }

    /// Test if shouldShowSuggestions returns false.
    /// It should return false when siteID is nil.
    func testShouldShowSuggestionsIsFalseWhenSiteIDIsNil() throws {
        let expectedResult = false

        let result = sut.shouldShowSuggestions(with: nil)

        XCTAssertEqual(result, expectedResult)
    }

    /// Test if shouldShowSuggestions returns false.
    /// It should return false if there is no blog with the same siteID in the database.
    func testShouldShowSuggestionsIsFalseWhenNoBlogWithSameSiteID() throws {
        let expectedResult = false

        let result = sut.shouldShowSuggestions(with: NSNumber(value: 1))

        XCTAssertEqual(result, expectedResult)
    }
}
