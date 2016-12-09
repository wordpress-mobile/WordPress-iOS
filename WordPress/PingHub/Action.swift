import Foundation

public enum Action {
    case push(noteID: Int, userID: Int, date: NSDate, type: String)
    case delete(noteID: Int)

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
