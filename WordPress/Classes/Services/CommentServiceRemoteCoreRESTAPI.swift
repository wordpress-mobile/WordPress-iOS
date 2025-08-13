import Foundation
import WordPressCore
import WordPressAPI
import WordPressAPIInternal
import WordPressKit
import WordPressShared
import WordPressData

final class CommentServiceRemoteCoreRESTAPI: NSObject, CommentServiceRemote {
    private let client: WordPressClient

    init(client: WordPressClient) {
        self.client = client
    }

    func getCommentsWithMaximumCount(_ maximumComments: Int, success: (([Any]?) -> Void)?, failure: (((any Error)?) -> Void)?) {
        getCommentsWithMaximumCount(maximumComments, options: nil, success: success, failure: failure)
    }

    func getCommentsWithMaximumCount(_ maximumComments: Int, options: [AnyHashable: Any]? = [:], success: (([Any]?) -> Void)?, failure: (((any Error)?) -> Void)?) {
        Task { @MainActor in
            do {
                let params = CommentListParams(options: options, perPage: min(100, UInt32(maximumComments)))
                let sequence = await client.api.comments.sequenceWithEditContext(params: params)
                var all = [RemoteComment]()
                for try await page in sequence where maximumComments > all.count {
                    let comments = page.prefix(maximumComments - all.count).map { RemoteComment(comment: $0) }
                    all.append(contentsOf: comments)

                    if comments.isEmpty {
                        break
                    }
                }

                success?(all)
            } catch {
                failure?(error)
            }
        }
    }

    func getCommentWithID(_ commentID: NSNumber, success: ((RemoteComment?) -> Void)?, failure: (((any Error)?) -> Void)?) {
        Task { @MainActor in
            do {
                let comment = try await client.api.comments.retrieveWithEditContext(commentId: commentID.int64Value, params: .init()).data
                success?(RemoteComment(comment: comment))
            } catch {
                failure?(error)
            }
        }
    }

    func createComment(_ comment: RemoteComment, success: ((RemoteComment?) -> Void)?, failure: (((any Error)?) -> Void)?) {
        guard comment.postID != nil else {
            wpAssertionFailure("post id missing in the comment")
            failure?(URLError(.unknown))
            return
        }

        Task { @MainActor in
            do {
                let comment = try await client.api.comments.create(params: .init(comment: comment)).data
                success?(RemoteComment(comment: comment))
            } catch {
                failure?(error)
            }
        }
    }

    func update(_ comment: RemoteComment, success: ((RemoteComment?) -> Void)?, failure: (((any Error)?) -> Void)?) {
        guard let commentID = comment.commentID else {
            wpAssertionFailure("comment id missing in the comment")
            failure?(URLError(.unknown))
            return
        }

        Task { @MainActor in
            do {
                let comment = try await client.api.comments.update(commentId: commentID.int64Value, params: .init(comment: comment)).data
                success?(RemoteComment(comment: comment))
            } catch {
                failure?(error)
            }
        }
    }

    func moderateComment(_ comment: RemoteComment, success: ((RemoteComment?) -> Void)?, failure: (((any Error)?) -> Void)?) {
        guard let commentID = comment.commentID else {
            wpAssertionFailure("comment id missing in the comment")
            failure?(URLError(.unknown))
            return
        }

        guard let status = comment.commentStatus else {
            wpAssertionFailure("invalid comment status in the comment")
            failure?(URLError(.unknown))
            return
        }

        Task { @MainActor in
            do {
                let comment = try await client.api.comments.update(commentId: commentID.int64Value, params: .init(status: status)).data
                success?(RemoteComment(comment: comment))
            } catch {
                failure?(error)
            }
        }
    }

    func trashComment(_ comment: RemoteComment, success: (() -> Void)?, failure: (((any Error)?) -> Void)?) {
        guard let commentID = comment.commentID else {
            wpAssertionFailure("comment id missing in the comment")
            failure?(URLError(.unknown))
            return
        }

        Task { @MainActor in
            do {
                // The `WordPressAPI.comments.trash` moves comments to trash.
                // The `WordPressAPI.comments.delete` deletes comments  permanently.
                //
                // Even though this function here is called "trash comment", it's actually used to deleted
                // comments permanently.
                _ = try await client.api.comments.delete(commentId: commentID.int64Value, params: .init())
                success?()
            } catch {
                failure?(error)
            }
        }
    }
}

private extension RemoteComment {
    convenience init(comment: CommentWithEditContext) {
        self.init()

        self.commentID = NSNumber(value: comment.id)
        self.authorID = NSNumber(value: comment.author)
        self.author = comment.authorName
        self.authorEmail = comment.authorEmail
        self.authorUrl = comment.authorUrl
        self.authorAvatarURL = comment.authorAvatarUrls.avatarURL()?.absoluteString
        self.authorIP = comment.authorIp
        self.content = comment.content.raw
        self.rawContent = comment.content.raw
        self.date = comment.dateGmt
        self.link = comment.link
        self.parentID = NSNumber(value: comment.parent)
        self.postID = NSNumber(value: comment.post)

        self.status = comment.status.commentStatusType?.description
        self.type = comment.commentType.type

        if let ext = try? comment.additionalFields.parseWpcomCommentsExtension() {
            self.postTitle = ext.post?.title
            self.isLiked = ext.iLike
            self.likeCount = NSNumber(value: ext.likeCount)
        }

        // The following properties are not available in .org REST API.
        self.canModerate = false
    }

    /// When `RemoteComment` is created by the app to send to API, some properties are set to default values (like
    /// empty string, 0). We should treat those values as `nil`, because wordpress-rs emits nil values in request body,
    /// but keeps them if they are "" or 0.
    ///
    /// We'll treat each property case by case, but in general it's safe to treat "" or 0 as nil. For example, there is
    /// no post whose id is 0, and there is no email address is an empty string.
    func resetDefaultValuesToNil() {
        if self.commentID?.intValue == 0 { self.commentID = nil }
        if self.authorID?.intValue == 0 { self.authorID = nil }
        if self.author?.isEmpty == true { self.author = nil }
        if self.authorEmail?.isEmpty == true { self.authorEmail = nil }
        if self.authorUrl?.isEmpty == true { self.authorUrl = nil }
        if self.authorAvatarURL?.isEmpty == true { self.authorAvatarURL = nil }
        if self.authorIP?.isEmpty == true { self.authorIP = nil }
        if self.content?.isEmpty == true { self.content = nil }
        if self.rawContent?.isEmpty == true { self.rawContent = nil }
        if self.link?.isEmpty == true { self.link = nil }
        if self.parentID?.intValue == 0 { self.parentID = nil }
        if self.postID?.intValue == 0 { self.postID = nil }
        if self.postTitle?.isEmpty == true { self.postTitle = nil }
        if self.status?.isEmpty == true { self.status = nil }
        if self.type?.isEmpty == true { self.type = nil }

        // The following properties are not updated:
        // - likeCount
    }

    /// The `status: String` property value does not match the `CommentStatus` values. This variable provides a safe
    /// way to cast the `status` property to a `CommentStatus` instance.
    var commentStatus: CommentStatus? {
        if let status = CommentStatusType.typeForStatus(status) {
            return CommentStatus(status)
        }

        return nil
    }
}

extension CommentUpdateParams {
    init(comment: RemoteComment) {
        comment.resetDefaultValuesToNil()
        self.init(
            author: nil,
            authorEmail: comment.authorEmail,
            authorIp: comment.authorIP,
            authorName: comment.author,
            authorUrl: comment.authorUrl,
            authorUserAgent: nil,
            content: comment.content,
            date: nil,
            dateGmt: comment.date,
            parent: comment.parentID?.int64Value,
            post: comment.postID?.int64Value,
            status: comment.commentStatus
        )
    }
}

extension CommentCreateParams {
    init(comment: RemoteComment) {
        comment.resetDefaultValuesToNil()
        self.init(
            post: comment.postID.int64Value,
            author: nil,
            authorEmail: comment.authorEmail,
            authorIp: comment.authorIP,
            authorName: comment.author,
            authorUrl: comment.authorUrl,
            authorUserAgent: nil,
            content: comment.content,
            date: nil,
            dateGmt: comment.date,
            parent: comment.parentID?.int64Value,
            status: comment.commentStatus
        )
    }
}

private extension CommentListParams {
    init(options: [AnyHashable: Any]?, perPage: UInt32) {
        guard var options else {
            self = .init()
            return
        }

        // Here are all supported options:
        // - status: CommentStatusFilter
        // - before: date string
        // - order: "desc"
        // - offset: NSUInteger

        var status: CommentStatus?
        if let value = options.removeValue(forKey: "status") as? NSNumber {
            switch CommentStatusFilter(rawValue: value.uint32Value) {
            case CommentStatusFilterUnapproved:
                status = .hold
            case CommentStatusFilterApproved:
                status = .approved
            case CommentStatusFilterTrash:
                status = .trash
            case CommentStatusFilterSpam:
                status = .spam
            default:
                status = .custom("all")
            }
        }

        var before: Date?
        if let value = options.removeValue(forKey: "before") {
            if let value = value as? Date {
                before = value
            } else if let value = value as? String {
                before = NSDate.with(wordPressComJSONString: value)
            }
        }

        let orderBy = WpApiParamCommentsOrderBy.dateGmt
        let order: WpApiParamOrder =
            if let value = options.removeValue(forKey: "order") as? String, value == "asc" {
                .asc
            } else {
                .desc
            }

        var offset: UInt32?
        if let value = options.removeValue(forKey: "offset") as? NSNumber {
            offset = value.uint32Value
        }

        wpAssert(options.isEmpty)

        self = .init(
            perPage: perPage,
            before: before,
            offset: offset,
            order: order,
            orderby: orderBy,
            status: status,
            commentType: .custom("all")
        )
    }
}

private extension CommentStatus {
    init?(_ commentStatusType: CommentStatusType) {
        switch commentStatusType {
        case .pending:
            self = .hold
        case .approved:
            self = .approved
        case .unapproved:
            self = .trash
        case .spam:
            self = .spam
        case .draft:
            return nil
        }
    }

    var commentStatusType: CommentStatusType? {
        switch self {
        case .hold:
            return .pending
        case .approved:
            return .approved
        case .spam:
            return .spam
        case .trash:
            return .unapproved
        case let .custom(other):
            return other == "draft" ? .draft : nil
        }
    }
}
