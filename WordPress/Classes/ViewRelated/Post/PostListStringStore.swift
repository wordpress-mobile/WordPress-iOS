import Foundation

enum PostListStringStore {
    enum PostRestoredPrompt {
        static func message(filter: PostListFilter) -> String {
            switch filter.filterType {
            case .published:
                return NSLocalizedString(
                    "Post Restored to Published",
                    comment: "Prompts the user that a restored post was moved to the published list."
                )
            case .scheduled:
                return NSLocalizedString(
                    "Post Restored to Scheduled",
                    comment: "Prompts the user that a restored post was moved to the scheduled list."
                )
            default:
                return NSLocalizedString(
                    "Post Restored to Drafts",
                    comment: "Prompts the user that a restored post was moved to the drafts list."
                )
            }
        }

        static func cancelText() -> String {
            NSLocalizedString(
                "OK",
                comment: "Title of an OK button. Pressing the button acknowledges and dismisses a prompt."
            )
        }
    }

//    enum
}
