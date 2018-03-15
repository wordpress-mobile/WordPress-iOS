import UIKit

struct PostNoticeViewModel {
    let post: AbstractPost

    private var title: String {
        let isPage = post is Page
        let isDraft = post.isDraft()

        switch (isPage, isDraft) {
        case (true, true):
            return NSLocalizedString("Page draft uploaded.", comment: "Title of notification displayed when a page has been successfully saved as a draft.")
        case (false, true):
            return NSLocalizedString("Post draft uploaded.", comment: "Title of notification displayed when a post has been successfully saved as a draft.")
        case (true, false):
            return NSLocalizedString("Page published.", comment: "Title of notification displayed when a page has been successfully published.")
        case (false, false):
            return NSLocalizedString("Post published.", comment: "Title of notification displayed when a post has been successfully published.")
        }
    }

    var notice: Notice {
        return Notice(title: title,
                      message: nil,
                      feedbackType: .success)
    }
}
