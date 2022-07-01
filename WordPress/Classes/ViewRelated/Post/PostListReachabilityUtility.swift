import Foundation

protocol PostListReachabilityProvider {
    func performActionIfConnectionAvailable(_ action: (( ) -> Void))
}

final class PostListReachabilityUtility: PostListReachabilityProvider {
    func performActionIfConnectionAvailable(_ action: (( ) -> Void)) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            action()
        }
    }
}
