import Foundation
import CoreData

final class CommentEditViewModel {
    let suggestionsViewModel: SuggestionsListViewModel?

    private let comment: Comment
    private let siteID: NSNumber
    private let context =  ContextManager.shared.mainContext

    var isGutenbergEnabled: Bool {
        FeatureFlag.readerGutenbergCommentComposer.enabled
    }

    /// Edit an existing comment.
    init(comment: Comment) {
        self.comment = comment
        self.siteID = comment.associatedSiteID ?? 0
        wpAssert(siteID != 0, "missing required parameter siteID")

        self.suggestionsViewModel = SuggestionsListViewModel.make(siteID: siteID)
        self.suggestionsViewModel?.enableProminentSuggestions(
            postAuthorID: comment.post?.authorID,
            commentAuthorID: comment.commentID as NSNumber
        )
    }

    var originalContent: String {
        comment.rawContent
    }

    @MainActor
    func save(content: String) async throws {
        let commentID = comment.commentID as NSNumber
        let service = CommentService(coreDataStack: ContextManager.shared)

        let remoteComment = try await withUnsafeThrowingContinuation { continuation in
            service.updateComment(withID: commentID, siteID: siteID, content: content, success: {
                continuation.resume(returning: $0)
            }, failure: { error in
                continuation.resume(throwing: error ?? URLError(.unknown))
            })
        }

        if let remoteComment {
            let objectID = TaggedManagedObjectID(comment)
            try await ContextManager.shared.performAndSave { context in
                let comment = try context.existingObject(with: objectID)
                comment.content = remoteComment.content
                comment.rawContent = remoteComment.rawContent
            }
        } else {
            wpAssertionFailure("comment missing from the response")
        }

        CommentAnalytics.trackCommentEdited(comment: comment)
    }
}
