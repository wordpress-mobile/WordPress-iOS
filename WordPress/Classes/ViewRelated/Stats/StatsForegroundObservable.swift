protocol StatsForegroundObservable: AnyObject {
    func addWillEnterForegroundObserver()
    func removeWillEnterForegroundObserver()
    func reloadStatsData()
}

private var observerKey = 0

extension StatsForegroundObservable where Self: UIViewController {
    func addWillEnterForegroundObserver() {
        enterForegroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                               object: nil,
                                               queue: nil) { [weak self] _ in
            self?.reloadStatsData()
        }
    }

    func removeWillEnterForegroundObserver() {
        if let enterForegroundObserver {
            NotificationCenter.default.removeObserver(enterForegroundObserver)
        }
        enterForegroundObserver = nil
    }

    private var enterForegroundObserver: NSObjectProtocol? {
        get {
            objc_getAssociatedObject(self, &observerKey) as? NSObjectProtocol
        }
        set {
            objc_setAssociatedObject(self, &observerKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}
