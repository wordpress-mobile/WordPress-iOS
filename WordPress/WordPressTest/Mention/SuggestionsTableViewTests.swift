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

    // MARK: - Tests

    /// Test to make sure that `suggestions` are loaded.
    func testSuggestionsCount() {
        XCTAssertEqual(suggestions.count, 100)
    }

    func test_moveProminentSuggestionsToTop() {
        let input = suggestions

        // Case #1
        let expectedResult1 = input
        let result1 = self.suggestionsTableView.moveProminentSuggestionsToTop(searchResults: input, prominentSuggestionsIds: [])

        // Case #2
        var expectedResult2 = input
        var element = expectedResult2.remove(at: 49)
        expectedResult2.insert(element, at: 0)
        let result2 = self.suggestionsTableView.moveProminentSuggestionsToTop(searchResults: input, prominentSuggestionsIds: [50])

        // Case #3
        var expectedResult3 = input
        element = expectedResult3.remove(at: 9)
        expectedResult3.insert(element, at: 0)
        element = expectedResult3.remove(at: 14)
        expectedResult3.insert(element, at: 1)
        let result3 = self.suggestionsTableView.moveProminentSuggestionsToTop(searchResults: input, prominentSuggestionsIds: [10, 15])

        // Assertions
        XCTAssertTrue(result1.elementsEqual(expectedResult1))
        XCTAssertTrue(result2.elementsEqual(expectedResult2))
        XCTAssertTrue(result3.elementsEqual(expectedResult3))
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
