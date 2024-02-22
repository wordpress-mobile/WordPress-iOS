/// Encapsulates a command to toggle a post's liked status
final class ReaderLikeAction {
    private let service: ReaderPostService

    init(service: ReaderPostService = ReaderPostService(coreDataStack: ContextManager.shared)) {
        self.service = service
    }

    func execute(with post: ReaderPost, completion: ((Result<Bool, Error>) -> Void)? = nil) {
        if !post.isLiked {
            // Consider a like from the list to be enough to push a page view.
            // Solves a long-standing question from folks who ask 'why do I
            // have more likes than page views?'.
            ReaderHelpers.bumpPageViewForPost(post)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        self.service.toggleLiked(for: post, success: { liked in
            completion?(.success(liked))
        }, failure: { (error: Error) in
            let error = error
            DDLogError("Error (un)liking post: \(error.localizedDescription)")
            completion?(.failure(error))
        })
    }
}
