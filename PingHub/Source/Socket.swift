import Foundation

internal protocol Socket: class {
    func connect()
    func disconnect()
    var onConnect: (() -> Void)? { get set }
    var onDisconnect: ((NSError?) -> Void)? { get set }
    var onText: ((String) -> Void)? { get set }
    var onData: ((NSData) -> Void)? { get set }
}
