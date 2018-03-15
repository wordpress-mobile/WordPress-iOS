import UIKit

struct PostNoticeViewModel {
    let post: AbstractPost

    private var title: String {
        if let page = post as? Page {
            return title(for: page)
        } else {
            return title(for: post)
        }
    }

    private func title(for page: Page) -> String {
        let status = page.status ?? .publish

        switch status {
        case .draft:
            return NSLocalizedString("Page draft uploaded", comment: "Title of notification displayed when a page has been successfully saved as a draft.")
        case .scheduled:
            return NSLocalizedString("Page scheduled", comment: "Title of notification displayed when a page has been successfully scheduled.")
        case .pending:
            return NSLocalizedString("Page pending review", comment: "Title of notification displayed when a page has been successfully saved as a draft.")
        default:
            return NSLocalizedString("Page published", comment: "Title of notification displayed when a page has been successfully published.")
        }
    }

    private func title(for post: AbstractPost) -> String {
        let status = post.status ?? .publish

        switch status {
        case .draft:
            return NSLocalizedString("Post draft uploaded", comment: "Title of notification displayed when a post has been successfully saved as a draft.")
        case .scheduled:
            return NSLocalizedString("Post scheduled", comment: "Title of notification displayed when a post has been successfully scheduled.")
        case .pending:
            return NSLocalizedString("Post pending review", comment: "Title of notification displayed when a post has been successfully saved as a draft.")
        default:
            return NSLocalizedString("Post published", comment: "Title of notification displayed when a post has been successfully published.")
        }
    }

    private var actionTitle: String {
        if post.status == .draft {
            return "Publish"
        }

        return "View"
    }

    var notice: Notice {
        return Notice(title: title,
                      message: nil,
                      feedbackType: .success,
                      actionTitle: actionTitle,
                      actionHandler: {
                        
        })
    }
}
