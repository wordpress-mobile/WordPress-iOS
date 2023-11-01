import Foundation

final class PostListItemViewModel {
    let post: Post
    let content: NSAttributedString
    let imageURL: URL?
    let badges: NSAttributedString
    let accessibilityIdentifier: String?
    let isEnabled: Bool
    let statusViewModel: PostCardStatusViewModel

    var status: String { statusViewModel.statusAndBadges(separatedBy: " · ")}
    var statusColor: UIColor { statusViewModel.statusColor }

    init(post: Post) {
        self.post = post
        self.content = makeContentString(for: post)
        self.imageURL = post.featuredImageURL
        self.badges = makeBadgesString(for: post)
        self.statusViewModel = PostCardStatusViewModel(post: post)
        self.isEnabled = !PostCoordinator.shared.isDeleting(post)
        self.accessibilityIdentifier = post.slugForDisplay()
    }
}

private func makeContentString(for post: Post) -> NSAttributedString {
    let title = post.titleForDisplay()
    let snippet = post.contentPreviewForDisplay()

    let string = NSMutableAttributedString()
    if !title.isEmpty {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: WPStyleGuide.fontForTextStyle(.callout, fontWeight: .semibold),
            .foregroundColor: UIColor.text
        ]
        let titleAttributedString = NSAttributedString(string: title, attributes: attributes)
        string.append(titleAttributedString)
    }
    if !snippet.isEmpty {
        if string.length > 0 {
            string.append(NSAttributedString(string: "\n"))
        }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular),
            .foregroundColor: UIColor.textSubtle
        ]
        let snippetAttributedString = NSAttributedString(string: snippet, attributes: attributes)
        string.append(snippetAttributedString)
    }

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.paragraphSpacing = 4
    string.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: string.length))

    return string
}

private func makeBadgesString(for post: Post) -> NSAttributedString {
    var badges: [(String, UIColor?)] = []
    if let date = AbstractPostHelper.getLocalizedStatusWithDate(for: post) {
        let color: UIColor? = post.status == .trash ? .systemRed : nil
        badges.append((date, color))
    }
    if let author = post.authorForDisplay() {
        badges.append((author, nil))
    }
    return AbstractPostHelper.makeBadgesString(with: badges)
}
