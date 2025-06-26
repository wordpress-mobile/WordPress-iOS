import Foundation
import WordPressData
import Combine

@MainActor
final class PostAuthorPickerViewModel: ObservableObject {
    struct AuthorItem: Identifiable {
        let id: NSNumber
        let displayName: String
        let username: String?
        let avatarURL: URL?

        init(from blogAuthor: BlogAuthor) {
            self.id = blogAuthor.userID
            self.displayName = blogAuthor.displayName ?? ""
            self.username = blogAuthor.username
            self.avatarURL = blogAuthor.avatarURL.flatMap { URL(string: $0) }
        }
    }

    @Published private(set) var authors: [AuthorItem] = []

    private let blog: Blog
    private let onSelection: (AuthorItem) -> Void
    private let currentAuthorID: Int?

    init(blog: Blog, currentAuthorID: Int?, onSelection: @escaping (AuthorItem) -> Void) {
        self.blog = blog
        self.currentAuthorID = currentAuthorID
        self.onSelection = onSelection

        loadAuthors()
    }

    func selectAuthor(_ author: AuthorItem) {
        onSelection(author)
    }

    func isSelected(_ author: AuthorItem) -> Bool {
        author.id.intValue == currentAuthorID
    }

    private func loadAuthors() {
        authors = (blog.authors ?? [])
            .filter { !$0.deletedFromBlog }
            .map(AuthorItem.init)
            .sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
    }
}
