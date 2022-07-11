import Foundation

protocol PostListReachabilityProvider {
    func performActionIfConnectionAvailable(_ action: (( ) -> Void))
    func isInternetReachable() -> Bool
    func showNoInternetConnectionNotice(message: String)
}

final class PostListReachabilityUtility: PostListReachabilityProvider {
    func performActionIfConnectionAvailable(_ action: (( ) -> Void)) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            action()
        }
    }

    func isInternetReachable() -> Bool {
        ReachabilityUtils.isInternetReachable()
    }

    func showNoInternetConnectionNotice(message: String) {
        ReachabilityUtils.showNoInternetConnectionNotice(message: message)
    }
}
