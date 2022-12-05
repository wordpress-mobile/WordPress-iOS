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
        self.imageURL = suggestion.imageURL
    }

    init(suggestion: SiteSuggestion) {
        if let subdomain = suggestion.subdomain {
            self.title = "\(SuggestionType.xpost.trigger)\(subdomain)"
        }
        self.subtitle = suggestion.title
        self.imageURL = suggestion.blavatarURL
    }
}
