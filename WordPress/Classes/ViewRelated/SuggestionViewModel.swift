import Foundation

@objc final class SuggestionViewModel: NSObject {

    @objc let title: String?
    @objc let subtitle: String?
    @objc let imageURL: URL?

    init(suggestion: UserSuggestion) {
        self.title = suggestion.username
        self.subtitle = suggestion.displayName
        self.imageURL = suggestion.imageURL
    }

    init(suggestion: SiteSuggestion) {
        self.title = suggestion.subdomain
        self.subtitle = suggestion.title
        self.imageURL = suggestion.blavatarURL
    }

}
