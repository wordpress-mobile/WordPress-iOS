public protocol NotificationSyncMediatorProtocol {
    func updateLastSeen(_ timestamp: String, completion: ((Error?) -> Void)?)

    func toggleLikeForPostNotification(
        isLike: Bool,
        postID: UInt,
        siteID: UInt,
        completion: @escaping (Result<Bool, Error>) -> Void
    )

    func toggleLikeForCommentNotification(
        isLike: Bool,
        commentID: UInt,
        siteID: UInt,
        completion: @escaping (Result<Bool, Error>) -> Void
    )
}
