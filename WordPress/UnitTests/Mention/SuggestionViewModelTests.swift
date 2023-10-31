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

    func testAvatarURLPreprocessing() {
        // Given
        let url = URL(string: "https://0.gravatar.com/avatar/6e010add837aef0e1bc8fd0a762c053e6184883ab9fbc7e92b72fae53c475f6c?s=32&d=identicon&r=G")!

        // When
        let processedURL = SuggestionViewModel.preprocessAvatarURL(url)

        // Then it changes the size, but keeps all the other query items
        XCTAssertEqual(processedURL.absoluteString, "https://0.gravatar.com/avatar/6e010add837aef0e1bc8fd0a762c053e6184883ab9fbc7e92b72fae53c475f6c?s=96&d=identicon&r=G")
    }
}
