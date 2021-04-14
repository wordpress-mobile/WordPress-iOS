import UIKit

@objc class PostAuthorSelectorViewController: SettingsSelectionViewController {
    /// The post to change the author
    private var post: AbstractPost!

    /// A completion block that is called after the user select an option
    @objc var completion: (() -> Void)?

    // MARK: - Constructors

    @objc init(_ post: AbstractPost) {
        self.post = post

        guard let authors = post.blog.authors, let currentAuthorID = post.authorID else {
            super.init(style: .plain)
            return
        }

        // Sort authors by their display name.
        let sortedAuthors: [(displayName: String, authorID: NSNumber)] = authors.compactMap {
            guard let displayName = $0.displayName else {
                return nil
            }

            return (displayName, $0.userID)
        }.sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })


        let authorsDict: [AnyHashable: Any] = [
            "DefaultValue": currentAuthorID,
            "Title": NSLocalizedString("Author", comment: "Author label."),
            "Titles": sortedAuthors.map { $0.displayName },
            "Values": sortedAuthors.map { $0.authorID },
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
}
