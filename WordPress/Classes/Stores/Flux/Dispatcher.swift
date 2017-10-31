import Foundation

class Dispatcher<Payload> {
    typealias DispatchToken = UUID
    typealias Callback = (Payload) -> Void

    private let queue = DispatchQueue(label: "org.wordpress.dispatcher")
    private var observers = [DispatchToken: Callback]()
    var observerCount: Int {
        return observers.count
    }

    func register(callback: @escaping Callback) -> DispatchToken {
        let token = DispatchToken()
        queue.sync {
            observers[token] = callback
        }
        return token
    }

    func unregister(token: DispatchToken) {
        queue.sync {
            observers[token] = nil
        }
    }

    func dispatch(_ payload: Payload) {
        queue.async {
            self.observers.forEach { (_, callback) in
                DispatchQueue.main.sync {
                    callback(payload)
                }
            }
        }
    }
}
