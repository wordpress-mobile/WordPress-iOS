import UIKit

@objc class PostAuthorSelectorViewController: SettingsSelectionViewController {
    /// The post to change the author.
    private var post: AbstractPost!

    /// A completion block that is called after the user selects an option.
    @objc var completion: (() -> Void)?

    /// Representation of an Author used by the view.
    private typealias Author = (displayName: String, userID: NSNumber, avatarURL: String?)

    // MARK: - Constructors

    @objc init(_ post: AbstractPost) {
        self.post = post

        let authors = PostAuthorSelectorViewController.sortedActiveAuthors(for: post.blog)

        guard !authors.isEmpty, let currentAuthorID = post.authorID else {
            super.init(style: .plain)
            return
        }

        let authorsDict: [AnyHashable: Any] = [
            "DefaultValue": currentAuthorID,
            "Title": NSLocalizedString("Author", comment: "Author label."),
            "Titles": authors.map { $0.displayName },
            "Values": authors.map { $0.userID },
            "CurrentValue": currentAuthorID
        ]

        super.init(dictionary: authorsDict)

        onItemSelected = { [weak self] authorID in
            guard
                let authorID = authorID as? NSNumber,
                let author = authors.first(where: { $0.userID == authorID }),
                !post.isFault, post.managedObjectContext != nil
            else {
                return
            }

            post.authorID = author.userID
            post.author = author.displayName
            post.authorAvatarURL = author.avatarURL

            self?.completion?()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init!(style: UITableView.Style, andDictionary dictionary: [AnyHashable: Any]!) {
        super.init(style: style, andDictionary: dictionary)
    }

    override init(style: UITableView.Style) {
        super.init(style: style)
    }

    // MARK: - Class Methods

    /// Sort authors by their display name in lexicographical order, accounting for diacritical marks.
    private static func sortedActiveAuthors(for blog: Blog) -> [Author] {
        /// Don't include any deleted authors.
        guard let activeAuthors = blog.authors?.filter ({ !$0.deletedFromBlog }) else {
            return []
        }

        return activeAuthors.compactMap {
            /// Require a display name to be available.
            guard let displayName = $0.displayName else {
                return nil
            }

            return (displayName, $0.userID, $0.avatarURL)
        }.sorted(by: { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending })
    }
}
