import Foundation

open class FluxStore {
    typealias Listener = NSObjectProtocol
    private let changeNotification = NSNotification.Name("FluxStoreChanged")
    var listenerCount = 0

    func onChange(_ handler: @escaping Action) -> Listener {
        listenerCount += 1
        return NotificationCenter.default.addObserver(
            forName: changeNotification,
            object: self,
            queue: nil,
            using: { _ in
                handler()
        })
    }

    func removeListener(_ listener: Listener) {
        NotificationCenter.default.removeObserver(listener, name: changeNotification, object: self)
        listenerCount -= 1
    }

    func emitChange() {
        NotificationCenter.default.post(name: changeNotification, object: self)
    }
}

class StoreContainer {
    static let shared = StoreContainer()

    private init() {}

    let plugin = PluginStore()
}
