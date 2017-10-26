import Foundation

open class RemoteActivity {
    public let activityID: String
    public let summary: String
    public let name: String
    public let type: String
    public let gridicon: String
    public let status: String
    public let rewindable: Bool
    public let published: Date?
    public let actor: RemoteActivityActor?
    public let object: RemoteActivityObject?
    public let target: RemoteActivityObject?
    public let items: [RemoteActivityObject]?

    init(dictionary: [String: AnyObject]) {
        activityID = dictionary["activity_id"] as? String ?? ""
        summary = dictionary["summary"] as? String ?? ""
        name = dictionary["name"] as? String ?? ""
        type = dictionary["type"] as? String ?? ""
        gridicon = dictionary["gridicon"] as? String ?? ""
        status = dictionary["status"] as? String ?? ""
        rewindable = dictionary["is_rewindable"] as? Bool ?? false
        let dateFormatter = ISO8601DateFormatter()
        if let publishedString = dictionary["published"] as? String {
            published = dateFormatter.date(from: publishedString)
        } else {
            published = nil
        }
        if let actorData = dictionary["actor"] as? [String: AnyObject] {
            actor = RemoteActivityActor.init(dictionary: actorData)
        } else {
            actor = nil
        }
        if let objectData = dictionary["object"] as? [String: AnyObject] {
            object = RemoteActivityObject.init(dictionary: objectData)
        } else {
            object = nil
        }
        if let targetData = dictionary["actor"] as? [String: AnyObject] {
            target = RemoteActivityObject.init(dictionary: targetData)
        } else {
            target = nil
        }
        if let orderedItems = dictionary["items"] as? [[String: AnyObject]] {
            items = orderedItems.map { item -> RemoteActivityObject in
                return RemoteActivityObject(dictionary: item)
            }
        } else {
            items = nil
        }
    }
}

open class RemoteActivityActor {
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

open class RemoteActivityObject {
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

extension RemoteActivity: CustomDebugStringConvertible {
    public var debugDescription: String {
        let dateFormatter = ISO8601DateFormatter()
        let publishedDate = published != nil ? dateFormatter.string(from: published!) : ""
        return "<RemoteActivity: (activityID: \(activityID), summary: \(summary), name: \(name), type: \(type) " +
               "gridicon: \(gridicon), status: \(status), rewindable: \(rewindable), published: \(publishedDate) " +
               "actor: \(actor.debugDescription), object: \(object.debugDescription), " +
               "target: \(target.debugDescription), items: \(items != nil ? items.debugDescription : "[]")>";
    }
}

extension RemoteActivityActor: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "<RemoteActivityActor(displayName: \(displayName), type: \(type), wpcomUserID: \(wpcomUserID) " +
               "avatarURL: \(avatarURL), role: \(role)>"
    }
}

extension RemoteActivityObject: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "<RemoteActivityObject(name: \(name), type: \(type), attributes: \(attributes.debugDescription)>"
    }
}
