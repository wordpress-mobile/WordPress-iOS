import Foundation

final class PostListItemViewModel {
    let post: Post
    let content: NSAttributedString
    let imageURL: URL?
    let date: String?
    let accessibilityIdentifier: String?
    let statusViewModel: PostCardStatusViewModel

    var status: String { statusViewModel.statusAndBadges(separatedBy: " · ")}
    var statusColor: UIColor { statusViewModel.statusColor }
    var author: String { statusViewModel.author }

    init(post: Post) {
        self.post = post
        self.content = makeContentAttributedString(for: post)
        self.imageURL = post.featuredImageURL
        self.date = post.displayDate()?.capitalizeFirstWord
        self.statusViewModel = PostCardStatusViewModel(post: post)
        self.accessibilityIdentifier = post.slugForDisplay()
    }
}

private func makeContentAttributedString(for post: Post) -> NSAttributedString {
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

    return string
}

private extension String {
    var capitalizeFirstWord: String {
        let firstLetter = self.prefix(1).capitalized
        let remainingLetters = self.dropFirst()
        return firstLetter + remainingLetters
    }
}
