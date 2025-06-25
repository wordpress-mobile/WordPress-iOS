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

    private let post: AbstractPost
    private let onSelection: () -> Void
    private let currentAuthorID: NSNumber?

    init(post: AbstractPost, onSelection: @escaping () -> Void) {
        self.post = post
        self.onSelection = onSelection
        self.currentAuthorID = post.authorID

        loadAuthors()
    }

    func selectAuthor(_ author: AuthorItem) {
        guard !post.isFault, post.managedObjectContext != nil else { return }

        post.authorID = author.id
        post.author = author.displayName
        post.authorAvatarURL = author.avatarURL?.absoluteString

        onSelection()
    }

    func isSelected(_ author: AuthorItem) -> Bool {
        author.id == currentAuthorID
    }

    private func loadAuthors() {
        authors = (post.blog.authors ?? [])
            .filter { !$0.deletedFromBlog }
            .map(AuthorItem.init)
            .sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
    }
}
