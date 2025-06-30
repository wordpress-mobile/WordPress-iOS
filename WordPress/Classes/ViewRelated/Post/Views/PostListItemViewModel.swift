import Foundation
import WordPressData
import WordPressShared

final class PostListItemViewModel {
    let post: Post
    let title: NSAttributedString
    let excerpt: NSAttributedString
    let imageURL: URL?
    let badges: NSAttributedString
    let syncStateViewModel: PostSyncStateViewModel
    private let statusViewModel: PostCardStatusViewModel

    var status: String { statusViewModel.statusAndBadges(separatedBy: " · ")}
    var statusColor: UIColor { statusViewModel.statusColor }
    var accessibilityLabel: String? { makeAccessibilityLabel(for: post, statusViewModel: statusViewModel) }

    init(post: Post, shouldHideAuthor: Bool = false) {
        self.post = post
        self.imageURL = post.featuredImageURL
        self.statusViewModel = PostCardStatusViewModel(post: post)
        self.syncStateViewModel = PostSyncStateViewModel(post: post)
        self.badges = makeBadgesString(for: post, syncStateViewModel: syncStateViewModel, shouldHideAuthor: shouldHideAuthor)
        self.title = makeTitleString(for: post, isDisabled: !syncStateViewModel.isEditable)
        self.excerpt = makeExcerptString(for: post, isDisabled: !syncStateViewModel.isEditable)
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

private func makeTitleString(for post: Post, isDisabled: Bool) -> NSAttributedString {
    let title = post.titleForDisplay()

    let foregroundColor = isDisabled ? UIColor.tertiaryLabel : UIColor.label

    let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.preferredFont(forTextStyle: .headline),
        .foregroundColor: foregroundColor
    ]

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineBreakMode = .byTruncatingTail

    let string = NSMutableAttributedString(string: title, attributes: attributes)
    string.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: string.length))

    return string
}

private func makeExcerptString(for post: Post, isDisabled: Bool) -> NSAttributedString {
    let excerpt = post.contentPreviewForDisplay()

    let foregroundColor = isDisabled ? UIColor.tertiaryLabel : UIColor.secondaryLabel

    let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.preferredFont(forTextStyle: .subheadline),
        .foregroundColor: foregroundColor
    ]

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineBreakMode = .byTruncatingTail

    let string = NSMutableAttributedString(string: excerpt, attributes: attributes)
    string.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: string.length))

    return string
}

private func makeBadgesString(for post: Post, syncStateViewModel: PostSyncStateViewModel, shouldHideAuthor: Bool) -> NSAttributedString {
    var badges: [(String, UIColor?)] = []
    if let statusMessage = syncStateViewModel.statusMessage {
        badges.append((statusMessage, nil))
    } else if let date = AbstractPostHelper.getLocalizedStatusWithDate(for: post) {
        let color: UIColor? = post.status == .trash ? .systemRed : nil
        badges.append((date, color))
    }
    if !shouldHideAuthor, let author = post.authorForDisplay() {
        badges.append((author, nil))
    }
    if !syncStateViewModel.isEditable {
        badges = badges.map { ($0.0, UIColor.tertiaryLabel) }
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
