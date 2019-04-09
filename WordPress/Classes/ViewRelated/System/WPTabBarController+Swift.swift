
// MARK: - Tracking

extension WPTabBarController {
    private static let tabIndexToStatMap: [WPTabType: WPAnalyticsStat] = [
        .mySites: .mySitesTabAccessed,
        .reader: .readerAccessed,
        .me: .meTabAccessed
    ]

    @objc func startObserversForTracking() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(trackEventsForAppForeground(_:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    @objc func trackEventsForAppForeground(_ notification: Notification) {
        guard let tabType = WPTabType(rawValue: UInt(selectedIndex)),
            let stat = WPTabBarController.tabIndexToStatMap[tabType] else {
            return
        }

        WPAppAnalytics.track(stat)
    }
}
