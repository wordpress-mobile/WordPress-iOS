import AppIntents
import Foundation
import WordPressData

/// A post from the user's Reader, as exposed to the system via App Intents.
///
/// The identifier is the same composite string the Spotlight index uses, so a Spotlight
/// item and its associated app entity always name the same post.
struct ReaderPostEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource(
            "ios-appintents.readerPostEntity.typeName",
            defaultValue: "Reader Post",
            table: "AppIntents",
            comment: "Type name of the Reader post entity in the Shortcuts app, e.g. shown when picking a post."
        )
    )

    static var defaultQuery: ReaderPostEntityQuery { ReaderPostEntityQuery() }

    let id: String
    let title: String
    let blogName: String?

    var displayRepresentation: DisplayRepresentation {
        guard let blogName else {
            return DisplayRepresentation(title: "\(title)")
        }
        return DisplayRepresentation(title: "\(title)", subtitle: "\(blogName)")
    }

    /// Fails for posts missing the site or post ID needed for a stable identifier.
    init?(post: ReaderPost) {
        guard let identifier = post.uniqueIdentifier else {
            return nil
        }
        self.id = identifier
        self.title = post.titleForDisplay()
        self.blogName = post.blogNameForDisplay()
    }

    /// A placeholder for a well-formed identifier whose post is no longer in
    /// the local store (Reader rows are purged routinely), so a saved
    /// shortcut keeps working; opening it navigates by the IDs alone.
    init?(identifier: String) {
        guard ReaderPost.AppIntentIdentifier(identifier: identifier) != nil else {
            return nil
        }
        self.id = identifier
        self.title = String(
            localized: LocalizedStringResource(
                "ios-appintents.readerPostEntity.placeholderTitle",
                defaultValue: "Reader Post",
                table: "AppIntents",
                comment:
                    "Generic title shown in the Shortcuts app for a Reader post in a saved shortcut that is no longer cached on this device."
            )
        )
        self.blogName = nil
    }
}

@available(iOS 18, *)
extension ReaderPostEntity: IndexedEntity {}
