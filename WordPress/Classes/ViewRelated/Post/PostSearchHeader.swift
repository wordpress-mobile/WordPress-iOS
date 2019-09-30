import Foundation

enum PostSearchHeader {
    static let published = NSLocalizedString("Published", comment: "Title of the published header in search list.")
    static let drafts = NSLocalizedString("Drafts", comment: "Title of the drafts header in search list.")

    static func title(forStatus rawStatus: String) -> String {
        var title: String

        switch rawStatus {
        case AbstractPost.Status.publish.rawValue:
            title = PostSearchHeader.published
        case AbstractPost.Status.draft.rawValue:
            title = PostSearchHeader.drafts
        default:
            title = rawStatus
        }

        return title.uppercased()
    }
}
