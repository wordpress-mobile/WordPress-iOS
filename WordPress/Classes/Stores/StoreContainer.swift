import Foundation

class StoreContainer {
    static let shared = StoreContainer()

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }

    @objc fileprivate func applicationWillResignActive() {
        try? plugin.persistState()
    }

    let plugin = PluginStore()
    let notice = NoticeStore()
    let timezone = TimeZoneStore()
    let activity = ActivityStore()
    let jetpackInstall = JetpackInstallStore()
    let statsWidgets = StatsWidgetsStore()
}
