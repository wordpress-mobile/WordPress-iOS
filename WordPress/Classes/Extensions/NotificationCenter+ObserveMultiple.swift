
import Foundation

extension NotificationCenter {
    /// Adds an observer for all the given `NSNotification.Name`
    ///
    func addObserver(_ observer: Any, selector aSelector: Selector,
                     names: [NSNotification.Name], object anObject: Any?) {
        names.forEach {
            addObserver(observer, selector: aSelector, name: $0, object: anObject)
        }
    }
}
