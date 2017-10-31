import Foundation

open class FluxStore {
    private let changeNotification = NSNotification.Name("FluxStoreChanged")
    var listenerCount = 0

    func onChange(_ handler: @escaping Action) -> Listener {
        listenerCount += 1
        let notificationObserver = NotificationCenter.default.addObserver(
            forName: changeNotification,
            object: self,
            queue: nil,
            using: { _ in
                handler()
        })
        return Listener(notificationObserver: notificationObserver, store: self)
    }

    func removeListener(_ listener: Listener) {
        guard let notificationObserver = listener.notificationObserver else {
            assertionFailure("Attempting to remove a listener that has already stopped listening.")
            return
        }
        NotificationCenter.default.removeObserver(notificationObserver, name: changeNotification, object: self)
        listenerCount -= 1
    }

    func emitChange() {
        NotificationCenter.default.post(name: changeNotification, object: self)
    }
}

extension FluxStore {
    class Listener {
        var notificationObserver: NSObjectProtocol?
        weak var store: FluxStore?

        fileprivate init(notificationObserver: NSObjectProtocol, store: FluxStore) {
            self.notificationObserver = notificationObserver
            self.store = store
        }

        deinit {
            stopListening()
        }

        func stopListening() {
            store?.removeListener(self)
        }
    }
}

class StoreContainer {
    static let shared = StoreContainer()

    private init() {}

    let plugin = PluginStore()
}
