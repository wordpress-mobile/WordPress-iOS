import Foundation
import Starscream

internal func starscreamSocket(url: NSURL, token: String) -> Socket {
    let socket = WebSocket(url: PinghubClient.endpoint)
    socket.origin = nil
    socket.headers = ["Authorization" : "Bearer \(token)"]
    return socket
}

extension WebSocket: Socket {
    func disconnect() {
        disconnect(forceTimeout: nil)
    }
}
