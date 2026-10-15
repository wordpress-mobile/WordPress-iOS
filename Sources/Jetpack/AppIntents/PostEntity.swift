import AppIntents
import Foundation
import WordPressData

/// A post or page on one of the user's sites, as exposed to the system via App Intents.
///
/// The identifier is the same composite string the Spotlight index uses, so a Spotlight
/// item and its associated app entity always name the same post.
struct PostEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource(
            "ios-appintents.postEntity.typeName",
            defaultValue: "Post",
            table: "AppIntents",
            comment: "Type name of the post entity in the Shortcuts app, e.g. shown when picking a post."
        )
    )

    static var defaultQuery: PostEntityQuery { PostEntityQuery() }

    let id: String
    let title: String
    let siteName: String?
    let isPage: Bool

    var displayRepresentation: DisplayRepresentation {
        let subtitle = [isPage ? Self.pageLabel : nil, siteName].compactMap { $0 }.joined(separator: " · ")
        guard !subtitle.isEmpty else {
            return DisplayRepresentation(title: "\(title)")
        }
        return DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }

    private static let pageLabel = String(
        localized: LocalizedStringResource(
            "Page",
            defaultValue: "Page",
            table: "Localizable",
            comment:
                "Label shown next to a post's site name in the Shortcuts app when the item is a page rather than a post."
        )
    )

    /// Fails for posts that only exist locally: without a remote post ID there
    /// is no stable identifier to expose.
    init?(post: AbstractPost) {
        guard let identifier = post.uniqueIdentifier else {
            return nil
        }
        self.id = identifier
        self.title = post.titleForDisplay()
        self.siteName = post.blog.settings?.name ?? post.blog.displayURL as String?
        self.isPage = post is Page
    }

    /// A placeholder for a well-formed identifier whose post is no longer in
    /// the local store (e.g. evicted from the cache), so a saved shortcut
    /// keeps working; opening it falls back to a remote fetch.
    init?(identifier: String) {
        guard AbstractPost.AppIntentIdentifier(identifier: identifier) != nil else {
            return nil
        }
        self.id = identifier
        self.title = String(
            localized: LocalizedStringResource(
                "ios-appintents.postEntity.placeholderTitle",
                defaultValue: "Post",
                table: "AppIntents",
                comment:
                    "Generic title shown in the Shortcuts app for a post in a saved shortcut that is no longer cached on this device."
            )
        )
        self.siteName = nil
        self.isPage = false
    }
}

@available(iOS 18, *)
extension PostEntity: IndexedEntity {}
