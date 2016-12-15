import Foundation

/// The delegate of a PinghubClient must adopt the PinghubClientDelegate
/// protocol. The client will inform the delegate of any relevant events.
///
public protocol PinghubClientDelegate {
    /// The client connected successfully.
    ///
    func pingubConnected(client client: PinghubClient)

    /// The client disconnected. This might be intentional or due to an error.
    /// The optional error argument will contain the error if there is one.
    ///
    func pinghubDisconnected(client client: PinghubClient, error: ErrorType?)

    /// The client received an action.
    ///
    func pinghubActionReceived(client client: PinghubClient, action: Action)

    /// The client received some data that it didn't look like a known action.
    ///
    func pinghubUnexpectedDataReceived(client client: PinghubClient, message: String)
}


/// Encapsulates a PingHub connection.
///
public class PinghubClient {

    /// The client's delegate.
    ///
    public var delegate: PinghubClientDelegate? = nil

    /// The web socket to use for communication with the PingHub server.
    ///
    private let socket: Socket

    /// Initializes the client with an already configured token.
    ///
    internal init(socket: Socket) {
        self.socket = socket
        setupSocketCallbacks()
    }

    /// Initializes the client with an OAuth2 token.
    ///
    public convenience init(token: String) {
        let socket = starscreamSocket(PinghubClient.endpoint, token: token)
        self.init(socket: socket)
    }

    /// Connects the client to the server.
    ///
    public func connect() {
        socket.connect()
    }

    /// Disconnects the client from the server.
    ///
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
