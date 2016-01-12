import Foundation
import RxSwift
import RxCocoa

extension AccountService {
    /// Observable that emits new values when the default account is set
    static var defaultAccountSwitched: Observable<WPAccount?> {
        return NSNotificationCenter.defaultCenter()
            .rx_notification(WPAccountDefaultWordPressComAccountChangedNotification)
            .map({ ($0.object as! WPAccount?) })
            .startWith(defaultWordPressComAccountInMainContext())
    }

    /// Observable that emits values when there is a change in the default account.
    /// This can be that the default account is set or removed, or one of its properties changes.
    /// 
    /// - warning: it might emit values even if the account hasn't changed.
    static var defaultAccountChanged: Observable<WPAccount?> {
        return defaultAccountSwitched
            .flatMapLatest({ (account) -> Observable<WPAccount?> in
                if account != nil {
                    return NSNotificationCenter.defaultCenter()
                        .rx_notification(NSManagedObjectContextObjectsDidChangeNotification, object: ContextManager.sharedInstance().mainContext)
                        .observeOn(MainScheduler.instance)
                        .map({ _ in defaultWordPressComAccountInMainContext() })
                } else {
                    return Observable.just(nil)
                }
            })
    }
}
