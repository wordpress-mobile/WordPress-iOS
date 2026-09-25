import Foundation
import WordPressData
import WordPressKit

struct ReaderUserProfile: Equatable {
    let username: String
    let displayName: String
    let avatarURL: URL?
    let siteURL: URL?
}

protocol ReaderUserProfileService {
    func fetchProfile(handle: String) async -> ReaderUserProfile?
}

final class WordPressComReaderUserProfileService: ReaderUserProfileService {
    private let wordPressComRestApi: WordPressComRestApi?

    init(coreDataStack: CoreDataStack) {
        self.wordPressComRestApi = coreDataStack.performQuery { context in
            try? WPAccount.defaultWordPressComAccountRestAPI(in: context)
        }
    }

    init(wordPressComRestApi: WordPressComRestApi?) {
        self.wordPressComRestApi = wordPressComRestApi
    }

    func fetchProfile(handle: String) async -> ReaderUserProfile? {
        guard let wordPressComRestApi,
            let encodedHandle = handle.addingPercentEncoding(withAllowedCharacters: Self.handleAllowedCharacters)
        else {
            return nil
        }

        let result = await wordPressComRestApi.perform(
            .get,
            URLString: "rest/v1.1/users/\(encodedHandle)",
            parameters: ["meta": "site"]
        )
        guard case .success(let response) = result else {
            return nil
        }
        return Self.mapProfile(from: response.body, requestedHandle: handle)
    }

    private static let handleAllowedCharacters = CharacterSet.alphanumerics.union(
        CharacterSet(charactersIn: "-._~")
    )

    private static func mapProfile(from response: AnyObject, requestedHandle: String) -> ReaderUserProfile? {
        guard let response = response as? [String: Any],
            let username = response["user_login"] as? String,
            username.caseInsensitiveCompare(requestedHandle) == .orderedSame
        else {
            return nil
        }

        let displayName = (response["display_name"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let avatarURL = (response["avatar_URL"] as? String).flatMap(URL.init(string:))
        let siteURL = (response["primary_blog"] as? [String: Any])?["URL"] as? String

        return ReaderUserProfile(
            username: username,
            displayName: displayName?.nilIfEmpty ?? username,
            avatarURL: avatarURL,
            siteURL: siteURL.flatMap(URL.init(string:))
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
