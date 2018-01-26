import Foundation

public class Activity {
    public let activityID: String
    public let summary: String
    public let text: String
    public let name: String
    public let type: String
    public let gridicon: String
    public let status: String
    public let rewindable: Bool
    public let rewindID: String?
    public let published: Date
    public var isDiscarded: Bool
    public let actor: ActivityActor?
    public let object: ActivityObject?
    public let target: ActivityObject?
    public let items: [ActivityObject]?

    init(dictionary: [String: AnyObject]) throws {
        guard let id = dictionary["activity_id"] as? String else {
            throw Error.missingActivityId
        }
        guard let summaryText = dictionary["summary"] as? String else {
            throw Error.missingSummary
        }
        guard let contentDictionary = dictionary["content"] as? [String: AnyObject],
              let contentText = contentDictionary["text"] as? String else {
            throw Error.missingContentText
        }
        guard let publishedString = dictionary["published"] as? String else {
            throw Error.missingPublishedDate
        }
        let dateFormatter = ISO8601DateFormatter()
        guard let publishedDate = dateFormatter.date(from: publishedString) else {
            throw Error.incorrectPusblishedDateFormat
        }
        activityID = id
        summary = summaryText
        text = contentText
        published = publishedDate
        name = dictionary["name"] as? String ?? ""
        type = dictionary["type"] as? String ?? ""
        gridicon = dictionary["gridicon"] as? String ?? ""
        status = dictionary["status"] as? String ?? ""
        rewindable = dictionary["is_rewindable"] as? Bool ?? false
        isDiscarded = dictionary["is_discarded"] as? Bool ?? false
        rewindID = dictionary["rewind_id"] as? String
        if let actorData = dictionary["actor"] as? [String: AnyObject] {
            actor = ActivityActor(dictionary: actorData)
        } else {
            actor = nil
        }
        if let objectData = dictionary["object"] as? [String: AnyObject] {
            object = ActivityObject(dictionary: objectData)
        } else {
            object = nil
        }
        if let targetData = dictionary["actor"] as? [String: AnyObject] {
            target = ActivityObject(dictionary: targetData)
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

    public lazy var isRewindComplete: Bool = {
        return self.name == ActivityName.rewindComplete
    }()

    public lazy var isFullBackup: Bool = {
        return self.name == ActivityName.fullBackup
    }()

    public lazy var publishedDateUTCWithoutTime: String = {
        return self.published.longUTCStringWithoutTime()
    }()

}

private extension Activity {
    enum Error: Swift.Error {
        case missingActivityId
        case missingSummary
        case missingContentText
        case missingPublishedDate
        case incorrectPusblishedDateFormat
    }
}

public class ActivityActor {
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

    public lazy var isJetpack: Bool = {
        return self.type == ActivityActorType.application &&
               self.displayName == ActivityActorApplicationType.jetpack
    }()
}

public class ActivityObject {
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

public struct ActivityName {
    public static let fullBackup = "rewind__backup_complete_full"
    public static let rewindComplete = "rewind__complete"
}

public struct ActivityActorType {
    public static let person = "Person"
    public static let application = "Application"
}

public struct ActivityActorApplicationType {
    public static let jetpack = "Jetpack"
}

public struct ActivityStatus {
    public static let error = "error"
    public static let success = "success"
    public static let warning = "warning"
}

public class RewindStatus {
    public let state: State
    public let reason: String?
    public let restore: RestoreStatus?

    init(dictionary: [String: AnyObject]) throws {
        guard let rewindState = dictionary["state"] as? String else {
            throw Error.missingState
        }
        guard let rewindStateEnum = State(rawValue: rewindState) else {
            throw Error.invalidRewindState
        }

        state = rewindStateEnum
        reason = dictionary["reason"] as? String
        if let rawRestore = dictionary["rewind"] as? [String: AnyObject] {
            restore = try RestoreStatus(dictionary: rawRestore)
        } else {
            restore = nil
        }
    }
}

public extension RewindStatus {
    enum State: String {
        case active
        case inactive
        case unavailable
        case awaitingCredentials
        case provisioning
    }
}

private extension RewindStatus {
    enum Error: Swift.Error {
        case missingState
        case invalidRewindState
    }
}

public class RestoreStatus {
    public let id: String
    public let status: Status
    public let progress: Int
    public let message: String?
    public let errorCode: String?
    public let failureReason: String?

    init(dictionary: [String: AnyObject]) throws {
        print(dictionary.description)
        guard let restoreId = dictionary["restore_id"] as? Int else {
            throw Error.missingRestoreId
        }
        guard let restoreStatus = dictionary["status"] as? String else {
            throw Error.missingRestoreStatus
        }
        guard let restoreStatusEnum = Status(rawValue: restoreStatus) else {
            throw Error.invalidRestoreStatus
        }

        id = String(restoreId)
        status = restoreStatusEnum
        progress = dictionary["progress"] as? Int ?? 0
        message = dictionary["message"] as? String
        errorCode = dictionary["error_code"] as? String
        failureReason = dictionary["reason"] as? String
    }
}

public extension RestoreStatus {
    enum Status: String {
        case queued
        case finished
        case running
        case fail
    }
}

extension RestoreStatus {
    enum Error: Swift.Error {
        case missingRestoreId
        case missingRestoreStatus
        case invalidRestoreStatus
    }
}
