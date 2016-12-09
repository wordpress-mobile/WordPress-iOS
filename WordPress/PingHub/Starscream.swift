import Foundation
import Starscream

extension WebSocket: Socket {
    func disconnect() {
        disconnect(forceTimeout: nil)
    }
}

extension PinghubClient {
    public convenience init(token: String) {
        let socket = WebSocket(url: PinghubClient.endpoint)
        socket.origin = nil
        socket.headers = ["Authorization" : "Bearer \(token)"]
        self.init(socket: socket)
    }
}
