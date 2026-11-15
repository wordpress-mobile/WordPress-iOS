import Foundation
import Testing

@testable import WordPress
@testable import WordPressKit

@Suite("Reader user profile service")
struct ReaderUserProfileServiceTests {
    @Test("Maps the fields of the user response")
    func mapsProfile() async {
        let api = WordPressComRestApiStub()
        api.body = [
            "user_login": "example-user",
            "display_name": " Example User ",
            "avatar_URL": "https://example.com/avatar.png",
            "primary_blog": ["URL": "https://example.wordpress.com"],
            "description": "Writes about bread."
        ]

        let profile = await WordPressComReaderUserProfileService(wordPressComRestApi: api)
            .fetchProfile(handle: "Example-User")

        #expect(api.requestedURLString == "rest/v1.1/users/Example-User")
        #expect(
            profile
                == ReaderUserProfile(
                    username: "example-user",
                    displayName: "Example User",
                    avatarURL: URL(string: "https://example.com/avatar.png"),
                    siteURL: URL(string: "https://example.wordpress.com"),
                    bio: "Writes about bread."
                )
        )
    }

    @Test("Keeps a handle from changing the path of the request")
    func encodesHandle() async {
        let api = WordPressComRestApiStub()

        _ = await WordPressComReaderUserProfileService(wordPressComRestApi: api)
            .fetchProfile(handle: "a/b?c")

        #expect(api.requestedURLString == "rest/v1.1/users/a%2Fb%3Fc")
    }

    @Test("Has no profile when the response is for another user")
    func anotherUser() async {
        let api = WordPressComRestApiStub()
        api.body = ["user_login": "someone-else", "display_name": "Someone Else"]

        let profile = await WordPressComReaderUserProfileService(wordPressComRestApi: api)
            .fetchProfile(handle: "example-user")

        #expect(profile == nil)
    }

    @Test("Has no profile when the request fails or there is no account")
    func failure() async {
        let api = WordPressComRestApiStub()
        api.fails = true

        #expect(
            await WordPressComReaderUserProfileService(wordPressComRestApi: api)
                .fetchProfile(handle: "example-user") == nil
        )
        #expect(
            await WordPressComReaderUserProfileService(wordPressComRestApi: nil)
                .fetchProfile(handle: "example-user") == nil
        )
    }

    @Test("Uses the username when the display name is blank")
    func blankDisplayName() async {
        let profile = await fetchProfile(displayName: "  ", description: nil)

        #expect(profile?.displayName == "example-user")
    }

    @Test("Decodes the entities WordPress.com returns in a display name")
    func decodesDisplayNameEntities() async {
        let profile = await fetchProfile(displayName: "Jaye &amp; Anita", description: nil)

        #expect(profile?.displayName == "Jaye & Anita")
    }

    @Test("Decodes the entities WordPress.com returns in a bio")
    func decodesBioEntities() async {
        let profile = await fetchProfile(description: "Books &amp; coffee, 1 &lt; 2")

        #expect(profile?.bio == "Books & coffee, 1 < 2")
    }

    @Test("Keeps the line breaks inside a bio and trims the ones around it")
    func trimsBio() async {
        let profile = await fetchProfile(description: "\n  First line\n\nSecond line \n")

        #expect(profile?.bio == "First line\n\nSecond line")
    }

    @Test("Has no bio when the description is blank or missing", arguments: ["", " \n ", nil] as [String?])
    func blankBio(description: String?) async {
        let profile = await fetchProfile(description: description)

        #expect(profile != nil)
        #expect(profile?.bio == nil)
    }

    private func fetchProfile(displayName: String = "Example User", description: String?) async -> ReaderUserProfile? {
        let api = WordPressComRestApiStub()
        api.body = ["user_login": "example-user", "display_name": displayName]
        api.body["description"] = description
        return await WordPressComReaderUserProfileService(wordPressComRestApi: api)
            .fetchProfile(handle: "example-user")
    }
}

private final class WordPressComRestApiStub: WordPressComRestApi {
    var body: [String: Any] = [:]
    var fails = false
    private(set) var requestedURLString: String?

    override func perform(
        _ method: HTTPRequestBuilder.Method,
        URLString: String,
        parameters: [String: Any]? = nil,
        fulfilling progress: Progress? = nil
    ) async -> APIResult<AnyObject> {
        requestedURLString = URLString
        if fails {
            return .failure(.connection(.init(.notConnectedToInternet)))
        }
        return .success(HTTPAPIResponse(response: HTTPURLResponse(), body: body as AnyObject))
    }
}
