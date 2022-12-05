import XCTest

@testable import WordPress

class SuggestionsListViewModelTests: CoreDataTestCase {

    private var viewModel: SuggestionsListViewModel!
    private var userSuggestions: [UserSuggestion] = []

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        let context = self.contextManager.mainContext
        let blog = Blog(context: context)
        let viewModel = SuggestionsListViewModel(blog: blog)
        viewModel.context = context
        viewModel.suggestionType = .mention
        viewModel.userSuggestionService = SuggestionServiceMock(context: context)
        viewModel.siteSuggestionService = SiteSuggestionServiceMock(context: context)
        viewModel.reloadData()
        self.userSuggestions = viewModel.suggestions.users
        self.viewModel = viewModel
    }

    // MARK: - Test suggestions array

    /// Tests that the site suggestions array is loaded.
    func testSiteSuggestionsCount() {
        self.viewModel.suggestionType = .xpost
        self.viewModel.reloadData()
        XCTAssertEqual(viewModel.suggestions.sites.count, 5)
    }

    /// Tests that the user suggestions array is loaded.
    func testUserSuggestionsCount() {
        XCTAssertEqual(userSuggestions.count, 103)
    }

    // MARK: - Test searchSuggestions(forWord:) -> Bool

    /// Tests that the search result for site suggestions returns all suggestions when +  sign is provided
    func testSearchSiteSuggestionsWithPlusSign() {
        // Given
        let word = "+"
        self.viewModel.suggestionType = .xpost
        self.viewModel.reloadData()
        let expectedResult = SuggestionsListSection()
        expectedResult.rows = viewModel.suggestions.sites.map { SuggestionViewModel(suggestion: $0) }

        // When
        let result = self.viewModel.searchSuggestions(withWord: word)

        // Then
        XCTAssertTrue(isEqual([expectedResult], viewModel.sections))
        XCTAssertTrue(result)
    }

    /// Tests that the search result for site suggestions returns an exact match
    func testSearchSiteSuggestionsWithExactMatch() {
        // Given
        let word = "+bitwolf"
        self.viewModel.suggestionType = .xpost
        self.viewModel.reloadData()
        let expectedResult = SuggestionsListSection()
        expectedResult.rows = [SuggestionViewModel(suggestion: viewModel.suggestions.sites[2])]

        // When
        let result = self.viewModel.searchSuggestions(withWord: word)

        // Then
        XCTAssertTrue(isEqual([expectedResult], viewModel.sections))
        XCTAssertTrue(result)
    }

    /// Tests that the search result is empty when an empty word is provided
    func testSearchSuggestionsWithEmptyWord() {
        // Given
        let word = ""

        // When
        let result = self.viewModel.searchSuggestions(withWord: word)

        // Then
        XCTAssertTrue(viewModel.sections.isEmpty)
        XCTAssertFalse(result)
    }

    /// Tests that the search result is not empty when @ sign is provided
    func testSearchSuggestionsWithAtSignWord() {
        // Given
        let word = "@"
        let expectedResult = SuggestionsListSection()
        expectedResult.rows = userSuggestions.map { SuggestionViewModel(suggestion: $0) }

        // When
        let result = self.viewModel.searchSuggestions(withWord: word)

        // Then
        XCTAssertTrue(isEqual(viewModel.sections, [expectedResult]))
        XCTAssertTrue(result)
    }

    /// Tests that the search result has an exact match
    func testSearchSuggestionsWithExactMatch() throws {
        // Given
        let word = "@glegrandx"
        let expectedResult = SuggestionsListSection()
        expectedResult.rows = [SuggestionViewModel(suggestion: userSuggestions[33])]

        // When
        let result = self.viewModel.searchSuggestions(withWord: word)

        // Then
        XCTAssertTrue(isEqual([expectedResult], viewModel.sections))
        XCTAssertTrue(result)
    }

    /// Tests that the search result has one match with case-insensitive and diacritic-insensitive
    func testSearchSuggestionsWithOneMatch() throws {
        // Given
        let word = "@Caa"
        let expectedResult = suggestionsList(fromProminentIds: [], regularIds: [101])

        // When
        let result = self.viewModel.searchSuggestions(withWord: word)

        // Then
        XCTAssertTrue(isEqual(expectedResult, viewModel.sections))
        XCTAssertTrue(result)
    }

    /// Tests that the search result has a few matches
    func testSearchSuggestionsWithPartialUpperCaseMatch() throws {
        // Given
        let word = "@Ca"
        let expectedResult = suggestionsList(fromProminentIds: [], regularIds: [101, 81, 71, 102, 38, 17, 103, 88, 80, 91, 44, 22])

        // When
        let result = self.viewModel.searchSuggestions(withWord: word)

        // Then
        XCTAssertTrue(isEqual(expectedResult, viewModel.sections))
        XCTAssertTrue(result)
    }

    /// Tests that the search result has a few matches
    func testSearchSuggestionsWithPartialLowerCaseMatch() throws {
        // Given
        let word = "@ca"
        let expectedResult = suggestionsList(fromProminentIds: [], regularIds: [101, 81, 71, 102, 38, 17, 103, 88, 80, 91, 44, 22])

        // When
        let result = self.viewModel.searchSuggestions(withWord: word)

        // Then
        XCTAssertTrue(isEqual(expectedResult, viewModel.sections))
        XCTAssertTrue(result)
    }

    /// Tests that the search result has a few matches with one prominent suggestion at the top
    func testSearchSuggestionsWithPartialMatchAndOneProminentSuggestion() throws {
        // Given
        let word = "@ca"
        let expectedResult = suggestionsList(fromProminentIds: [88], regularIds: [101, 81, 71, 102, 38, 17, 103, 80, 91, 44, 22])
        self.viewModel.prominentSuggestionsIds = [88]

        // When
        let result = self.viewModel.searchSuggestions(withWord: word)

        // Then
        XCTAssertTrue(isEqual(expectedResult, viewModel.sections))
        XCTAssertTrue(result)
    }

    /// Tests that the search result has a few matches with two prominent suggestions at the top
    func testSearchSuggestionsWithPartialMatchAndTwoProminentSuggestion() throws {
        // Given
        let word = "@ca"
        let expectedResult = suggestionsList(fromProminentIds: [91, 88], regularIds: [101, 81, 71, 102, 38, 17, 103, 80, 44, 22])
        self.viewModel.prominentSuggestionsIds = [91, 88]

        // When
        let result = self.viewModel.searchSuggestions(withWord: word)

        // Then
        XCTAssertTrue(isEqual(expectedResult, viewModel.sections))
        XCTAssertTrue(result)
    }

    // MARK: - Test prominentSuggestions(fromPostAuthorId:commentAuthorId:defaultAccountId:)

    /// Tests that a prominent suggestions array is created with a post author id and comment author id
    func testProminentSuggestionsWithPostAuthorAndCommentAuthor() {
        // Given
        let postAuthorId = NSNumber(value: 1)
        let commentAuthorId = NSNumber(value: 2)

        // When
        let result = SuggestionsTableView.prominentSuggestions(fromPostAuthorId: postAuthorId, commentAuthorId: commentAuthorId, defaultAccountId: nil)

        // Then
        XCTAssertEqual(result, [1, 2])
    }

    /// Tests that a default account is excluded from the prominent suggestions array
    func testDefaultAccountExcludedFromProminentSuggestions() {
        // Given
        let postAuthorId = NSNumber(value: 1)
        let commentAuthorId = NSNumber(value: 2)
        let accountId = NSNumber(value: 1)

        // When
        let result = SuggestionsTableView.prominentSuggestions(fromPostAuthorId: postAuthorId, commentAuthorId: commentAuthorId, defaultAccountId: accountId)

        // Then
        XCTAssertEqual(result, [2])
    }

    // MARK: - Helpers

    private func suggestionsList(fromProminentIds prominentIds: [Int], regularIds: [Int]) -> [SuggestionsListSection] {
        let prominentSection = suggestionsSection(fromIds: prominentIds)
        let regularSection = suggestionsSection(fromIds: regularIds)
        return [prominentSection, regularSection].compactMap { $0 }
    }

    private func suggestionsSection(fromIds ids: [Int]) -> SuggestionsListSection? {
        guard !ids.isEmpty else { return nil }
        let rows = ids.compactMap { id -> SuggestionViewModel? in
            let suggestion = userSuggestions.first(where: { $0.userID == NSNumber(value: id) })
            return suggestion == nil ? nil : SuggestionViewModel(suggestion: suggestion!)
        }
        let section = SuggestionsListSection()
        section.rows = rows
        return section
    }

    private func isEqual(_ left: SuggestionViewModel, _ right: SuggestionViewModel) -> Bool {
        return [left.title, left.subtitle, left.imageURL?.absoluteString] == [right.title, right.subtitle, right.imageURL?.absoluteString]
    }

    private func isEqual(_ left: SuggestionsListSection, _ right: SuggestionsListSection) -> Bool {
        return isEqual(left.rows, right.rows)
    }

    private func isEqual(_ left: [SuggestionsListSection], _ right: [SuggestionsListSection]) -> Bool {
        guard left.count == right.count else { return false }
        for (index, element) in left.enumerated() {
            guard !isEqual(element, right[index]) else { continue }
            return false
        }
        return true
    }

    private func isEqual(_ left: [SuggestionViewModel], _ right: [SuggestionViewModel]) -> Bool {
        guard left.count == right.count else { return false }
        for (index, element) in left.enumerated() {
            guard !isEqual(element, right[index]) else { continue }
            return false
        }
        return true
    }
}
