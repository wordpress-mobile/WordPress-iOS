import Foundation
import WordPressAPI
import WordPressAPIInternal
@testable import WordPressComments

func makeComment(
    id: Int64 = 1,
    authorName: String = "Author",
    avatar: String? = "https://example.com/avatar.png",
    content: String = "<p>Hello <strong>world</strong></p>",
    post: Int64 = 10,
    status: CommentStatus = .approved,
    date: Date = Date(timeIntervalSince1970: 1_700_000_000)
) -> CommentWithViewContext {
    CommentWithViewContext(
        id: id,
        author: 1,
        authorName: authorName,
        authorUrl: "",
        content: CommentContentWithViewContext(rendered: content),
        date: "2023-11-14T22:13:20",
        dateGmt: date,
        link: "https://example.com/?p=\(post)#comment-\(id)",
        parent: 0,
        post: post,
        status: status,
        commentType: .comment,
        authorAvatarUrls: avatar.map { [.size96: $0] } ?? [:],
        additionalFields: WpAdditionalFields()
    )
}

func makeItem(
    id: Int64 = 1,
    authorName: String = "Author",
    post: Int64 = 10,
    status: CommentStatus = .approved
) -> CommentListItem {
    CommentListItem(comment: makeComment(id: id, authorName: authorName, post: post, status: status))
}
