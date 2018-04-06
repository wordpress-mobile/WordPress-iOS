import Foundation

class StoreContainer {
    static let shared = StoreContainer()

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: .UIApplicationWillResignActive, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc fileprivate func applicationWillResignActive() {
        plugin.storeCachedState()
    }

    let plugin = PluginStore()
    let notice = NoticeStore()
    let timezone = TimeZoneStore()
}
