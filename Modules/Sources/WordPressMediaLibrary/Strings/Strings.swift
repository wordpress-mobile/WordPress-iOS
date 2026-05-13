import Foundation

enum Strings {
    static let title = NSLocalizedString(
        "mediaLibrary.screen.title",
        value: "Media",
        comment: "Title for the Media Library V2 screen"
    )

    static let empty = NSLocalizedString(
        "mediaLibrary.empty.message",
        value: "No media yet",
        comment: "Message shown when the Media Library has no items"
    )

    static let errorRetry = NSLocalizedString(
        "mediaLibrary.error.retry",
        value: "Try again",
        comment: "Button label to retry loading after an error"
    )

    static let untitled = NSLocalizedString(
        "mediaLibrary.row.untitled",
        value: "(no title)",
        comment: "Placeholder shown for media items with no title"
    )
}
