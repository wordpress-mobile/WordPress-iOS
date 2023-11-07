import Foundation

protocol PostSearchToken {
    var icon: UIImage? { get }
    var value: String { get }
    var id: AnyHashable { get }
}

extension PostSearchToken {
    func asSearchToken() -> UISearchToken {
        let token = UISearchToken(icon: icon, text: value)
        token.representedObject = self
        return token
    }
}

struct PostSearchAuthorToken: Hashable, PostSearchToken {
    let authorID: NSNumber
    let displayName: String?

    var icon: UIImage? { UIImage(named: "comment-author-gravatar") }
    var value: String { displayName ?? "" }
    var id: AnyHashable { self }

    init(author: BlogAuthor) {
        self.authorID = author.userID
        self.displayName = author.displayName
    }
}

struct PostSearchTagToken: Hashable, PostSearchToken {
    let tag: String

    var icon: UIImage? { UIImage(named: "block-tag-cloud") }
    var value: String { tag }
    var id: AnyHashable { self }
}
