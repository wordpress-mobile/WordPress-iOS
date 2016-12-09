import Foundation

public protocol PinghubClientDelegate {
    func pingubConnected(client client: PinghubClient)
    func pinghubDisconnected(client client: PinghubClient, error: ErrorType?)
    func pinghubActionReceived(client client: PinghubClient, action: Action)
    func pinghubUnexpectedDataReceived(client client: PinghubClient, message: String)
}


public class PinghubClient {

    private let socket: Socket
    public var delegate: PinghubClientDelegate? = nil

    internal init(socket: Socket) {
        self.socket = socket
        setupSocketCallbacks()
    }

    public func connect() {
        socket.connect()
    }

    public func disconnect() {
        socket.disconnect()
    }

    private func setupSocketCallbacks() {
        socket.onConnect = { [weak self] in
            guard let client = self else {
                return
            }
            client.delegate?.pingubConnected(client: client)
        }
        socket.onDisconnect = { [weak self] error in
            guard let client = self else {
                return
            }
            client.delegate?.pinghubDisconnected(client: client, error: error)
        }
        socket.onData = { [weak self] data in
            guard let client = self else {
                return
            }
            let error = "PingHub received unexpected data: \(data)"
            client.delegate?.pinghubUnexpectedDataReceived(client: client, message: error)
        }
        socket.onText = { [weak self] text in
            guard let client = self else {
                return
            }
            guard let data = text.dataUsingEncoding(NSUTF8StringEncoding),
                let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
                let message = json as? [String: AnyObject],
                let action = Action.from(message: message) else {
                    let error = "PingHub received unexpected message: \(text)"
                    client.delegate?.pinghubUnexpectedDataReceived(client: client, message: error)
                    return
            }
            client.delegate?.pinghubActionReceived(client: client, action: action)
        }
    }

    internal static let endpoint = NSURL(string: "wss://public-api.wordpress.com/pinghub/wpcom/me/newest-note-data")!
}
