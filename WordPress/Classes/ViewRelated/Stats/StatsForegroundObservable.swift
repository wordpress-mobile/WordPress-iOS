protocol StatsForegroundObservable: class {
    func addWillEnterForegroundObserver()
    func removeWillEnterForegroundObserver()
    func reloadStatsData()
}

extension StatsForegroundObservable where Self: UIViewController {
    func addWillEnterForegroundObserver() {
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                               object: nil,
                                               queue: nil) { [weak self] _ in
            self?.reloadStatsData()
        }
    }

    func removeWillEnterForegroundObserver() {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.willEnterForegroundNotification,
                                                  object: nil)
    }
}
