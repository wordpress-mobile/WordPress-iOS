import Foundation

private class OneTimeObserver {
    var observer: NSObjectProtocol?
    let action: (Foundation.Notification) -> Void

    init(action: @escaping (Foundation.Notification) -> Void) {
        self.action = action
    }

    func run(_ notification: Foundation.Notification) {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
        action(notification)
    }
}

extension NotificationCenter {
    /// Adds a notification observer that ensures the callback block will be
    /// called only once.
    ///
    /// If you specify a filter, this will only dispatch the first notification
    /// that matches the filter.
    /// For other parameters, see addObserver(forName:object:queue:using:)
    ///
    @discardableResult
    @objc
    func observeOnce(forName name: NSNotification.Name?, object: Any?, queue: OperationQueue?, using block: @escaping (Foundation.Notification) -> Swift.Void, filter: ((Foundation.Notification) -> Bool)? = nil) -> NSObjectProtocol {
        let oneTimeObserver = OneTimeObserver(action: block)

        let observer = NotificationCenter.default.addObserver(
            forName: name,
            object: object,
            queue: queue,
            using: { (notification) in
                guard filter?(notification) ?? true else {
                    return
                }
                oneTimeObserver.run(notification)
        })
        oneTimeObserver.observer = observer

        return observer
    }
}
