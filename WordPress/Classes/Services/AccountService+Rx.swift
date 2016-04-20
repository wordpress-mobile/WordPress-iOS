import Foundation
import RxSwift
import RxCocoa

extension AccountService {
    /// Observable that emits new values when the default account is set
    ///
    /// - warning: This should only be observed from the main thread, otherwise behavior is undefined
    var defaultAccountObjectID: Observable<NSManagedObjectID?> {
        return NSNotificationCenter.defaultCenter()
            .rx_notification(WPAccountDefaultWordPressComAccountChangedNotification)
            .map({ ($0.object as! WPAccount?)?.objectID })
            .startWith(defaultWordPressComAccount()?.objectID)
    }

    /// Observable that emits values when there is a change in the default account.
    /// This can be that the default account is set or removed, or one of its properties changes.
    ///
    /// - warning: This should only be observed from the main thread, otherwise behavior is undefined
    var defaultAccountChanged: Observable<WPAccount?> {
        // Keep a reference to the context to avoid having to reference self
        // within the closure
        let context = managedObjectContext

        return defaultAccountObjectID
            // When the default account is set return the values of this new signal
            .flatMapLatest({ (objectID) -> Observable<WPAccount?> in
                if let objectID = objectID,
                    let account = try? context.existingObjectWithID(objectID) as? WPAccount {

                    return NSNotificationCenter.defaultCenter()
                        .rx_notification(NSManagedObjectContextObjectsDidChangeNotification, object: context)
                        // Transform the notifications into the changed account if it changed
                        .map({ (note) -> WPAccount? in
                            guard let updatedObjects = note.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> else {
                                return nil
                            }

                            let matchingObject = updatedObjects.filter({ $0.objectID == objectID }).first
                            return matchingObject as? WPAccount
                        })
                        // A nil value here means the change didn't affect the current account
                        .filter({ $0 != nil })
                        .startWith(account)
                } else {
                    // If the default account was removed, just send a nil value
                    return Observable.just(nil)
                }
            })
    }
}
