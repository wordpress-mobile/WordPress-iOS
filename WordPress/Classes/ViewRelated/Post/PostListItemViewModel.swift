import Foundation

final class PostListItemViewModel {
    let post: Post
    let content: NSAttributedString
    let imageURL: URL?
    let badges: NSAttributedString
    let isEnabled: Bool
    let statusViewModel: PostCardStatusViewModel

    var status: String { statusViewModel.statusAndBadges(separatedBy: " · ")}
    var statusColor: UIColor { statusViewModel.statusColor }
    var accessibilityLabel: String? { makeAccessibilityLabel(for: post, statusViewModel: statusViewModel) }

    init(post: Post) {
        self.post = post
        self.content = makeContentString(for: post)
        self.imageURL = post.featuredImageURL
        self.badges = makeBadgesString(for: post)
        self.statusViewModel = PostCardStatusViewModel(post: post)
        self.isEnabled = !PostCoordinator.shared.isDeleting(post)
    }
}

private func makeAccessibilityLabel(for post: Post, statusViewModel: PostCardStatusViewModel) -> String? {
    let titleAndDateChunk: String = {
        return String(format: Strings.Accessibility.titleAndDateChunkFormat, post.titleForDisplay(), post.dateStringForDisplay())
    }()

    let authorChunk: String? = {
        let author = statusViewModel.author
        guard !author.isEmpty else {
            return nil
        }
        return String(format: Strings.Accessibility.authorChunkFormat, author)
    }()

    let stickyChunk = post.isStickyPost ? Strings.Accessibility.sticky : nil

    let statusChunk: String? = {
        guard let status = statusViewModel.status else {
            return nil
        }

        return "\(status)."
    }()

    let excerptChunk: String? = {
        let excerpt = post.contentPreviewForDisplay()
        guard !excerpt.isEmpty else {
            return nil
        }
        return String(format: Strings.Accessibility.exerptChunkFormat, excerpt)
    }()

    return [titleAndDateChunk, authorChunk, stickyChunk, statusChunk, excerptChunk]
        .compactMap { $0 }
        .joined(separator: " ")
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

private enum Strings {

    enum Accessibility {
        static let titleAndDateChunkFormat = NSLocalizedString(
            "postList.a11y.titleAndDateChunkFormat",
            value: "%1$@, %2$@.",
            comment: "Accessibility label for a post in the post list. The first placeholder is the post title. The second placeholder is the date."
        )

        static let authorChunkFormat = NSLocalizedString(
            "postList.a11y.authorChunkFormat",
            value: "By %@.",
            comment: "Accessibility label for the post author in the post list. The parameter is the author name. For example, \"By Elsa.\""
        )

        static let exerptChunkFormat = NSLocalizedString(
            "postList.a11y.exerptChunkFormat",
            value: "Excerpt. %@.",
            comment: "Accessibility label for a post's excerpt in the post list. The parameter is the post excerpt. For example, \"Excerpt. This is the first paragraph.\""
        )

        static let sticky = NSLocalizedString(
            "postList.a11y.sticky",
            value: "Sticky.",
            comment: "Accessibility label for a sticky post in the post list."
        )
    }
}
