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

    /// Tests that suggestions search result remain the same when no prominent suggestions are provided
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

    /// Tests that suggestions search result remain the same when non-existing prominent suggestions are provided
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
