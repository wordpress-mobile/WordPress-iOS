import Foundation
import Starscream

public protocol PinghubClientDelegate {
    func pingubConnected(client client: PinghubClient)
    func pinghubDisconnected(client client: PinghubClient, error: ErrorType?)
    func pinghubActionReceived(client client: PinghubClient, action: PinghubClient.Action)
}

public class PinghubClient {

    private let socket: WebSocket
    public var delegate: PinghubClientDelegate? = nil

    init(token: String) {
        socket = WebSocket(url: PinghubClient.endpoint)
        socket.origin = nil
        socket.delegate = self
        socket.headers = ["Authorization" : "Bearer \(token)"]
    }

    func connect() {
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }

    private static let endpoint = NSURL(string: "wss://public-api.wordpress.com/pinghub/wpcom/me/newest-note-data")!

    public enum Action {
        case push(noteID: Int, userID: Int, date: NSDate, type: String)
        case delete(noteID: Int)

        static func from(message message: [String: Any]) -> Action? {
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

extension PinghubClient: WebSocketDelegate {
    public func websocketDidConnect(socket: WebSocket) {
        delegate?.pingubConnected(client: self)
    }

    public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        delegate?.pinghubDisconnected(client: self, error: error)
    }

    public func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        let error = "PingHub received unexpected data: \(data)"
        assertionFailure(error)
        DDLogSwift.logError(error)
    }

    public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        guard let data = text.dataUsingEncoding(NSUTF8StringEncoding),
            let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
            let message = json as? [String: Any],
            let action = Action.from(message: message) else {
                let error = "PingHub received unexpected message: \(text)"
                assertionFailure(error)
                DDLogSwift.logError(error)
                return
        }
        delegate?.pinghubActionReceived(client: self, action: action)
    }
}
