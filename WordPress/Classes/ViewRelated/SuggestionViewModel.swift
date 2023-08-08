import Foundation

@objc final class SuggestionViewModel: NSObject {

    @objc private(set) var title: String?

    @objc let subtitle: String?
    @objc let imageURL: URL?

    init(suggestion: UserSuggestion) {
        if let username = suggestion.username {
            self.title = "\(SuggestionType.mention.trigger)\(username)"
        }
        self.subtitle = suggestion.displayName
        self.imageURL = suggestion.imageURL.map(SuggestionViewModel.preprocessAvatarURL)
    }

    init(suggestion: SiteSuggestion) {
        if let subdomain = suggestion.subdomain {
            self.title = "\(SuggestionType.xpost.trigger)\(subdomain)"
        }
        self.subtitle = suggestion.title
        self.imageURL = suggestion.blavatarURL
    }

    private static func preprocessAvatarURL(_ url: URL) -> URL {
        guard url.host?.contains("gravatar.com") ?? false else {
            return url
        }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        if let index = components.queryItems?.firstIndex(where: { $0.name == "s" }) {
            components.queryItems![index].value = String(Constants.avatarSize)
        }
        return components.url ?? url
    }

    private struct Constants {
        static let avatarSize = 96
    }
}
