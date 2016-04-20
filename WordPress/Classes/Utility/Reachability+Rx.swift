import Foundation
import Reachability
import RxSwift

extension Reachability {
    static let internetConnection = Observable<Bool>.create { observer in
        let reach = Reachability.reachabilityForInternetConnection()
        reach.reachableBlock = { _ in
            observer.onNext(true)
        }
        reach.unreachableBlock = { _ in
            observer.onNext(false)
        }
        observer.onNext(reach.isReachable())
        reach.startNotifier()
        return AnonymousDisposable() {
            reach.stopNotifier()
        }
    }.shareReplayLatestWhileConnected()
}
