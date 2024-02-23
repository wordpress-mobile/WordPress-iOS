import Foundation

protocol LikeableNotification {
    var liked: Bool { get set}
    func toggleLike(using notificationMediator: NotificationSyncMediatorProtocol,
                    like: Bool,
                    completion: @escaping (Result<Bool, Swift.Error>) -> Void)
}
