import Foundation

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
    public static func from(message message: [String: AnyObject]) -> Action? {
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
