//
//  SuggestionsTableViewTests.swift
//  WordPressTest
//
//  Created by Salim Braksa on 8/7/2022.
//  Copyright © 2022 WordPress. All rights reserved.
//

import XCTest

@testable import WordPress

class SuggestionsTableViewTests: CoreDataTestCase {

    private var suggestionsTableView: SuggestionsTableView!
    private var delegate: SuggestionsTableViewDelegate!
    private var suggestions: [UserSuggestion] = []

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        self.suggestions = try self.loadUserSuggestions()
        self.delegate = SuggestionsTableViewMockDelegate()
        self.suggestionsTableView = SuggestionsTableView(siteID: 1, suggestionType: .mention, delegate: delegate)
        self.suggestionsTableView.suggestions = suggestions
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - Test suggestions array

    /// Tests that suggestions array is loaded.
    func testSuggestionsCount() {
        XCTAssertEqual(suggestions.count, 100)
    }

    // MARK: - Test moveProminentSuggestionsToTop(searchResults:prominentSuggestionsIds:)

    /// Tests that  search result remain the same when no prominent suggestions are provided
    func testMoveSuggestionsWithZeroProminentSuggestions() {
        // Given
        let searchResults = suggestions
        let prominentSuggestionsIds: [NSNumber] = []
        let expectedResult = searchResults

        // When
        let result = self.suggestionsTableView.moveProminentSuggestionsToTop(searchResults: searchResults, prominentSuggestionsIds: prominentSuggestionsIds)

        // Then
        XCTAssertEqual(expectedResult, result)
    }

    /// Tests that  search result remain the same when non-existing prominent suggestions are provided
    func testMoveSuggestionsWithNonExistingProminentSuggestions() {
        // Given
        let searchResults = suggestions
        let prominentSuggestionsIds: [NSNumber] = [1000, 10002]
        let expectedResult = searchResults

        // When
        let result = self.suggestionsTableView.moveProminentSuggestionsToTop(searchResults: searchResults, prominentSuggestionsIds: prominentSuggestionsIds)

        // Then
        XCTAssertEqual(expectedResult, result)
    }

    /// Tests that the provided prominent suggestion is moved to the top of the search result
    func testMoveSuggestionsWithOneProminentSuggestion() {
        // Given
        let searchResults = suggestions
        let prominentSuggestionsIds: [NSNumber] = [50]
        var expectedResult = searchResults
        let element = expectedResult.remove(at: 49)
        expectedResult.insert(element, at: 0)

        // When
        let result = self.suggestionsTableView.moveProminentSuggestionsToTop(searchResults: searchResults, prominentSuggestionsIds: prominentSuggestionsIds)

        // Then
        XCTAssertEqual(expectedResult, result)
    }

    /// Tests that the provided prominent suggestions are moved to the top of the search result
    func testMoveSuggestionsWithTwoProminentSuggestions() {
        // Given
        let searchResults = suggestions
        let prominentSuggestionsIds: [NSNumber] = [10, 15]
        var expectedResult = searchResults
        var element = expectedResult.remove(at: 9)
        expectedResult.insert(element, at: 0)
        element = expectedResult.remove(at: 14)
        expectedResult.insert(element, at: 1)

        // When
        let result = self.suggestionsTableView.moveProminentSuggestionsToTop(searchResults: searchResults, prominentSuggestionsIds: prominentSuggestionsIds)

        // Then
        XCTAssertEqual(expectedResult, result)
    }

    // MARK: - Test searchResults(searchQuery:suggestions:suggestionType) -> [Any]

    /// Tests that the search result has an exact match
    func testSearchResultsWithExactMatch() throws {
        // Given
        let searchQuery = "lvlahos2k"
        let expectedSuggestion = suggestions[92]

        // When
        let result = self.suggestionsTableView.searchResults(searchQuery: searchQuery, suggestions: suggestions, suggestionType: .mention)

        // Then
        let userSuggestion = try XCTUnwrap(result[0] as? UserSuggestion)
        XCTAssertEqual(userSuggestion, expectedSuggestion)
    }

    /// Tests that the search result has a few matches
    func testSearchResultsWithPartialQuery() throws {
        // Given
        let searchQuery = "lv"
        let expectedSuggestions = [11, 93].compactMap { id -> UserSuggestion? in
            return suggestions.first(where: { $0.userID == id })
        }

        // When
        let result = self.suggestionsTableView.searchResults(searchQuery: searchQuery, suggestions: suggestions, suggestionType: .mention)

        // Then
        let userSuggestions = try XCTUnwrap(result as? [UserSuggestion])
        XCTAssertEqual(userSuggestions, expectedSuggestions)
    }

    /// Tests that the search result is the same as suggestions when the search query is empty
    func testSearchResultsWithEmptyQuery() throws {
        // Given
        let searchQuery = ""

        // When
        let result = self.suggestionsTableView.searchResults(searchQuery: searchQuery, suggestions: suggestions, suggestionType: .mention)

        // Then
        let userSuggestions = try XCTUnwrap(result as? [UserSuggestion])
        XCTAssertEqual(userSuggestions, suggestions)
    }

    // MARK: - Test showSuggestions(forWord:) -> Bool

    /// Tests that the seach result is empty when an empty word is provided
    func testShowSuggestionsWithEmptyWord() {
        // Given
        let word = ""

        // When
        let result = self.suggestionsTableView.showSuggestions(forWord: word)

        // Then
        XCTAssertTrue(suggestionsTableView.searchResults.isEmpty)
        XCTAssertFalse(result)
    }

    /// Tests that the seach result has an exact match
    func testShowSuggestionsWithExactMatch() throws {
        // Given
        let word = "@glegrandx"
        let expectedSuggestion = suggestions[33]

        // When
        let result = self.suggestionsTableView.showSuggestions(forWord: word)

        // Then
        XCTAssertTrue(suggestionsTableView.searchResults.count == 1)
        let userSuggestion = try XCTUnwrap(suggestionsTableView.searchResults[0] as? UserSuggestion)
        XCTAssertEqual(userSuggestion, expectedSuggestion)
        XCTAssertTrue(result)
    }

    /// Tests that the seach result has a few matches
    func testShowSuggestionsWithPartialMatch() throws {
        // Given
        let word = "@ca"
        let expectedSuggestions = [17, 22, 38, 44, 71, 80, 81, 88, 91].compactMap { id -> UserSuggestion? in
            return suggestions.first(where: { $0.userID == id })
        }

        // When
        let result = self.suggestionsTableView.showSuggestions(forWord: word)

        // Then
        XCTAssertTrue(suggestionsTableView.searchResults.count == 9)
        let searchResults = try XCTUnwrap(suggestionsTableView.searchResults as? [UserSuggestion])
        XCTAssertEqual(searchResults, expectedSuggestions)
        XCTAssertTrue(result)
    }

    /// Tests that the seach result has a few matches with prominent suggestions at the top
    func testShowSuggestionsWithPartialMatchAndOneProminentSuggestion() throws {
        // Given
        let word = "@ca"
        let expectedSuggestions = [88, 17, 22, 38, 44, 71, 80, 81, 91].compactMap { id -> UserSuggestion? in
            return suggestions.first(where: { $0.userID == id })
        }
        self.suggestionsTableView.prominentSuggestionsIds = [88]

        // When
        let result = self.suggestionsTableView.showSuggestions(forWord: word)

        // Then
        XCTAssertTrue(suggestionsTableView.searchResults.count == 9)
        let searchResults = try XCTUnwrap(suggestionsTableView.searchResults as? [UserSuggestion])
        XCTAssertEqual(searchResults, expectedSuggestions)
        XCTAssertTrue(result)
    }

    // MARK: - Helpers

    private func loadUserSuggestions() throws -> [UserSuggestion] {
        let bundle = Bundle(for: SuggestionsTableViewTests.self)
        let url = try XCTUnwrap(bundle.url(forResource: "user-suggestions", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let result = try JSONSerialization.jsonObject(with: data, options: [])
        let array = try XCTUnwrap(result as? [[String: Any]])
        return array.map { UserSuggestion(dictionary: $0, context: contextManager.mainContext)! }
    }

}
