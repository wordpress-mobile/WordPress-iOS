import Foundation

public struct Activity {
    public let activityID: String
    public let summary: String
    public let name: String
    public let type: String
    public let gridicon: String
    public let status: String
    public let rewindable: Bool
    public let rewindID: String?
    public let published: Date
    public let actor: ActivityActor?
    public let object: ActivityObject?
    public let target: ActivityObject?
    public let items: [ActivityObject]?

    init(dictionary: [String: AnyObject]) throws {
        guard let id = dictionary["activity_id"] as? String else {
            throw RemoteActivityError.missingActivityId
        }
        guard let publishedString = dictionary["published"] as? String else {
            throw RemoteActivityError.missingPublishedDate
        }
        let dateFormatter = ISO8601DateFormatter()
        guard let publishedDate = dateFormatter.date(from: publishedString) else {
            throw RemoteActivityError.incorrectPusblishedDateFormat
        }
        activityID = id
        published = publishedDate
        summary = dictionary["summary"] as? String ?? ""
        name = dictionary["name"] as? String ?? ""
        type = dictionary["type"] as? String ?? ""
        gridicon = dictionary["gridicon"] as? String ?? ""
        status = dictionary["status"] as? String ?? ""
        rewindable = dictionary["is_rewindable"] as? Bool ?? false
        rewindID = dictionary["rewind_id"] as? String
        if let actorData = dictionary["actor"] as? [String: AnyObject] {
            actor = ActivityActor.init(dictionary: actorData)
        } else {
            actor = nil
        }
        if let objectData = dictionary["object"] as? [String: AnyObject] {
            object = ActivityObject.init(dictionary: objectData)
        } else {
            object = nil
        }
        if let targetData = dictionary["actor"] as? [String: AnyObject] {
            target = ActivityObject.init(dictionary: targetData)
        } else {
            target = nil
        }
        if let orderedItems = dictionary["items"] as? [[String: AnyObject]] {
            items = orderedItems.map { item -> ActivityObject in
                return ActivityObject(dictionary: item)
            }
        } else {
            items = nil
        }
    }
}

public struct ActivityActor {
    public let displayName: String
    public let type: String
    public let wpcomUserID: String
    public let avatarURL: String
    public let role: String

    init(dictionary: [String: AnyObject]) {
        displayName = dictionary["name"] as? String ?? ""
        type = dictionary["type"] as? String ?? ""
        wpcomUserID = dictionary["wp_com_user_id"] as? String ?? ""
        if let iconInfo = dictionary["icon"] as? [String: AnyObject] {
            avatarURL = iconInfo["url"] as? String ?? ""
        } else {
            avatarURL = ""
        }
        role = dictionary["role"] as? String ?? ""
    }
}

public struct ActivityObject {
    public let name: String
    public let type: String
    public let attributes: [String: Any]

    init(dictionary: [String: AnyObject]) {
        name = dictionary["name"] as? String ?? ""
        type = dictionary["type"] as? String ?? ""
        let mutableDictionary = NSMutableDictionary(dictionary: dictionary)
        mutableDictionary.removeObjects(forKeys: ["name", "type"])
        if let extraAttributes = mutableDictionary as? [String: Any] {
            attributes = extraAttributes
        } else {
            attributes = [:]
        }
    }
}

enum RemoteActivityError: Error {
    case missingActivityId
    case missingPublishedDate
    case incorrectPusblishedDateFormat
}

public struct ActivityName {
    public static let fullBackup = "rewind__backup_complete_full"
}

extension Activity: CustomDebugStringConvertible {
    public var debugDescription: String {
        let dateFormatter = ISO8601DateFormatter()
        return "<Activity: (activityID: \(activityID), summary: \(summary), name: \(name), type: \(type) " +
               "gridicon: \(gridicon), status: \(status), rewindable: \(rewindable), " +
               "published: \(dateFormatter.string(from: published)) actor: \(actor.debugDescription), " +
               "object: \(object.debugDescription), target: \(target.debugDescription), " +
               "items: \(items != nil ? items.debugDescription : "[]")>";
    }
}

extension ActivityActor: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "<ActivityActor(displayName: \(displayName), type: \(type), wpcomUserID: \(wpcomUserID) " +
               "avatarURL: \(avatarURL), role: \(role)>"
    }
}

extension ActivityObject: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "<ActivityObject(name: \(name), type: \(type), attributes: \(attributes.debugDescription)>"
    }
}
