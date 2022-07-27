import Foundation
import Starscream


// MARK: Client


/// The delegate of a PinghubClient must adopt the PinghubClientDelegate
/// protocol. The client will inform the delegate of any relevant events.
///
public protocol PinghubClientDelegate: AnyObject {
    /// The client connected successfully.
    ///
    func pingubDidConnect(_ client: PinghubClient)

    /// The client disconnected. This might be intentional or due to an error.
    /// The optional error argument will contain the error if there is one.
    ///
    func pinghubDidDisconnect(_ client: PinghubClient, error: Error?)

    /// The client received an action.
    ///
    func pinghub(_ client: PinghubClient, actionReceived action: PinghubClient.Action)

    /// The client received some data that it didn't look like a known action.
    ///
    func pinghub(_ client: PinghubClient, unexpected message: PinghubClient.Unexpected)
}


/// Encapsulates a PingHub connection.
///
public class PinghubClient {

    /// The client's delegate.
    ///
    public weak var delegate: PinghubClientDelegate?

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
        let socket = starscreamSocket(url: PinghubClient.endpoint, token: token)
        self.init(socket: socket)
    }

    /// Connects the client to the server.
    ///
    public func connect() {
        #if DEBUG
            guard !Debug._simulateUnreachableHost else {
                DispatchQueue.main.async { [weak self] in
                    guard let client = self else { return }
                    client.delegate?.pinghubDidDisconnect(client, error: Debug.unreachableHostError)
                }
                return
            }
        #endif
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
            client.delegate?.pingubDidConnect(client)
        }
        socket.onDisconnect = { [weak self] error in
            guard let client = self else {
                return
            }
            let error = error as NSError?
            let filteredError: NSError? = error.flatMap({ error in
                // Filter out normal disconnects that we initiated
                if error.domain == WebSocket.ErrorDomain && error.code == Int(CloseCode.normal.rawValue) {
                    return nil
                }
                return error
            })
            client.delegate?.pinghubDidDisconnect(client, error: filteredError)
        }
        socket.onData = { [weak self] data in
            guard let client = self else {
                return
            }
            client.delegate?.pinghub(client, unexpected: .data(data))
        }
        socket.onText = { [weak self] text in
            guard let client = self else {
                return
            }
            guard let data = text.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let message = json as? [String: AnyObject],
                let action = Action.from(message: message) else {
                    client.delegate?.pinghub(client, unexpected: .action(text))
                    return
            }
            client.delegate?.pinghub(client, actionReceived: action)
        }
    }

    public enum Unexpected {
        /// The client received some data that was not a valid message
        ///
        case data(Data)

        /// The client received a valid message that represented an unknown action
        ///
        case action(String)

        var description: String {
            switch self {
            case .data(let data):
                return "PingHub received unexpected data: \(data)"
            case .action(let text):
                return "PingHub received unexpected message: \(text)"
            }
        }
    }

    internal static let endpoint = URL(string: "https://public-api.wordpress.com/pinghub/wpcom/me/newest-note-data")!
}





// MARK: - Debug


#if DEBUG
extension PinghubClient {
    enum Debug {
        fileprivate static var _simulateUnreachableHost = false
        static func simulateUnreachableHost(_ simulate: Bool) {
            _simulateUnreachableHost = simulate
        }

        fileprivate static let unreachableHostError = NSError(domain: kCFErrorDomainCFNetwork as String, code: Int(CFNetworkErrors.cfHostErrorUnknown.rawValue), userInfo: nil)
    }
}

@objc class PinghubDebug: NSObject {
    static func simulateUnreachableHost(_ simulate: Bool) {
        PinghubClient.Debug._simulateUnreachableHost = simulate
    }
}
#endif




// MARK: - Action


extension PinghubClient {
    /// An action received through the PingHub protocol.
    ///
    /// This enum represents all the known possible actions that we can receive
    /// through a PingHub client.
    ///
    public enum Action {

        /// A note was Added or Updated
        ///
        case push(noteID: Int, userID: Int, date: NSDate, type: String)

        /// A note was Deleted
        ///
        case delete(noteID: Int)

        /// Creates an action from a received message, if it represents a known
        /// action. Otherwise, it returns `nil`
        ///
        public static func from(message: [String: AnyObject]) -> Action? {
            guard let action = message["action"] as? String else {
                return nil
            }
            switch action {
            case "push":
                guard let noteID = message["note_id"] as? Int,
                    let userID = message["user_id"] as? Int,
                    let timestamp = message["newest_note_time"] as? Int,
                    let type = message["newest_note_type"] as? String else {
                        return nil
                }
                let date = NSDate(timeIntervalSince1970: Double(timestamp))
                return .push(noteID: noteID, userID: userID, date: date, type: type)
            case "delete":
                guard let noteID = message["note_id"] as? Int else {
                    return nil
                }
                return .delete(noteID: noteID)
            default:
                return nil
            }
        }
    }
}




// MARK: - Socket


internal protocol Socket: AnyObject {
    func connect()
    func disconnect()
    var onConnect: (() -> Void)? { get set }
    var onDisconnect: ((Error?) -> Void)? { get set }
    var onText: ((String) -> Void)? { get set }
    var onData: ((Data) -> Void)? { get set }
}




// MARK: - Starscream


private func starscreamSocket(url: URL, token: String) -> Socket {
    var request = URLRequest(url: PinghubClient.endpoint)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    return WebSocket(request: request)
}

extension WebSocket: Socket {
    @objc func disconnect() {
        disconnect(forceTimeout: nil)
    }
}
