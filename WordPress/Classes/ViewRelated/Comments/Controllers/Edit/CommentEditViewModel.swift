import Foundation
import CoreData

@MainActor
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
        self.siteID = comment.associatedSiteID ?? -1
        wpAssert(siteID != -1, "missing required parameter siteID")

        self.suggestionsViewModel = SuggestionsListViewModel.make(siteID: siteID)
        self.suggestionsViewModel?.enableProminentSuggestions(
            postAuthorID: comment.post?.authorID,
            commentAuthorID: comment.commentID as NSNumber
        )
    }

    func save(content: String, comment: Comment) async throws {
        let commentID = comment.commentID as NSNumber

        try await withUnsafeThrowingContinuation { continuation in
            let service = CommentService(coreDataStack: ContextManager.shared)
            service.updateComment(withID: commentID, siteID: siteID, content: content, success: {
                continuation.resume(returning: ())
            }, failure: { error in
                continuation.resume(throwing: error ?? URLError(.unknown))
            })
        }

        let objectID = TaggedManagedObjectID(comment)
        try await ContextManager.shared.performAndSave { context in
            let comment = try context.existingObject(with: objectID)
            comment.content = content
        }

        CommentAnalytics.trackCommentEdited(comment: comment)
    }
}
