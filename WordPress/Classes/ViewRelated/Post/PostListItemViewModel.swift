import Foundation

struct PostListItemViewModel {
    let title: String?
    let snippet: String?
    let date: String?
    let accessibilityIdentifier: String?

    private var statusViewModel: PostCardStatusViewModel { .init(post: post) }

    var status: String { statusViewModel.statusAndBadges(separatedBy: " · ")}
    var statusColor: UIColor { statusViewModel.statusColor }
    var author: String { statusViewModel.author }

    private let post: Post

    init(post: Post) {
        self.post = post
        self.title = post.titleForDisplay()
        self.snippet = post.contentPreviewForDisplay()
        self.date = post.displayDate()
        self.accessibilityIdentifier = post.slugForDisplay()
    }
}
