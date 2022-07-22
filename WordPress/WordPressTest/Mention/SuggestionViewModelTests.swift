import Foundation
import XCTest

@testable import WordPress

final class SuggestionViewModelTests: CoreDataTestCase {

    /// Tests that the user suggestion view model properties are properly formatted.
    func testUserSuggestionViewModel() throws {
        // Given
        let dictionary: [String: Any] = [
            "ID": 1 as UInt,
            "user_login": "ghaskayne0",
            "display_name": "Geoffrey Haskayne",
            "image_URL": "https://fakeimg.pl/250x100"
        ]
        let model = try XCTUnwrap(UserSuggestion(dictionary: dictionary, context: mainContext))

        // When
        let viewModel = SuggestionViewModel(suggestion: model)

        // Then
        XCTAssertEqual(viewModel.title, "@ghaskayne0")
        XCTAssertEqual(viewModel.subtitle, "Geoffrey Haskayne")
        XCTAssertEqual(viewModel.imageURL, URL(string: "https://fakeimg.pl/250x100"))
    }

    /// Tests that the site suggestion view model properties are properly formatted.
    func testSiteSuggestionViewModel() throws {
        // Given
        let decoder = JSONDecoder()
        decoder.userInfo[CodingUserInfoKey.managedObjectContext] = mainContext
        let dictionary: [String: Any] = [
            "title": "Pied Piper",
            "siteurl": "https://businessweek.com",
            "subdomain": "piedpiper",
            "blavatar": "https://fakeimg.pl/250x100"
        ]
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        let model = try decoder.decode(SiteSuggestion.self, from: data)

        // When
        let viewModel = SuggestionViewModel(suggestion: model)

        // Then
        XCTAssertEqual(viewModel.title, "+piedpiper")
        XCTAssertEqual(viewModel.subtitle, "Pied Piper")
        XCTAssertEqual(viewModel.imageURL, URL(string: "https://fakeimg.pl/250x100"))
    }
}
