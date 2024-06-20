import Foundation

public struct Activity: Decodable {

    private enum CodingKeys: String, CodingKey {
        case activityId = "activity_id"
        case summary
        case content
        case published
        case name
        case type
        case gridicon
        case status
        case isRewindable = "is_rewindable"
        case rewindId = "rewind_id"
        case actor
        case object
        case items
    }

    public let activityID: String
    public let summary: String
    public let text: String
    public let name: String
    public let type: String
    public let gridicon: String
    public let status: String
    public let rewindID: String?
    public let published: Date
    public let actor: ActivityActor?
    public let object: ActivityObject?
    public let target: ActivityObject?
    public let items: [ActivityObject]?
    public let content: [String: Any]?

    private let rewindable: Bool

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let id = try container.decodeIfPresent(String.self, forKey: .activityId) else {
            throw Error.missingActivityId
        }
        guard let summaryText = try container.decodeIfPresent(String.self, forKey: .summary) else {
            throw Error.missingSummary
        }
        guard let content = try container.decodeIfPresent([String: Any].self, forKey: .content),
              let contentText = content["text"] as? String else {
            throw Error.missingContentText
        }
        guard
            let publishedString = try container.decodeIfPresent(String.self, forKey: .published),
            let published = Date.dateWithISO8601WithMillisecondsString(publishedString) else {
            throw Error.missingPublishedDate
        }

        self.activityID = id
        self.summary = summaryText
        self.content = content
        self.text = contentText
        self.published = published
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        self.gridicon = try container.decodeIfPresent(String.self, forKey: .gridicon) ?? ""
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        self.rewindable = try container.decodeIfPresent(Bool.self, forKey: .isRewindable) ?? false
        self.rewindID = try container.decodeIfPresent(String.self, forKey: .rewindId)

        if let actorData = try container.decodeIfPresent([String: Any].self, forKey: .actor) {
            self.actor = ActivityActor(dictionary: actorData)
        } else {
            self.actor = nil
        }

        if let objectData = try container.decodeIfPresent([String: Any].self, forKey: .object) {
            self.object = ActivityObject(dictionary: objectData)
        } else {
            self.object = nil
        }

        if let targetData = try container.decodeIfPresent([String: Any].self, forKey: .actor) {
            self.target = ActivityObject(dictionary: targetData)
        } else {
            self.target = nil
        }

        if let orderedItems = try container.decodeIfPresent(Array<Any>.self, forKey: .items) as? [[String: Any]] {
            self.items = orderedItems.map { ActivityObject(dictionary: $0) }
        } else {
            self.items = nil
        }
    }

    public var isRewindComplete: Bool {
        return self.name == ActivityName.rewindComplete
    }

    public var isFullBackup: Bool {
        return self.name == ActivityName.fullBackup
    }

    public var isRewindable: Bool {
        return rewindID != nil && rewindable
    }
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

public struct ActivityActor {
    public let displayName: String
    public let type: String
    public let wpcomUserID: String
    public let avatarURL: String
    public let role: String

    init(dictionary: [String: Any]) {
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

public struct ActivityObject {
    public let name: String
    public let type: String
    public let attributes: [String: Any]

    init(dictionary: [String: Any]) {
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

public class ActivityGroup {
    public let key: String
    public let name: String
    public let count: Int

    init(_ groupKey: String, dictionary: [String: AnyObject]) throws {
        guard let groupName = dictionary["name"] as? String else {
            throw Error.missingName
        }
        guard let groupCount = dictionary["count"] as? Int else {
            throw Error.missingCount
        }

        key = groupKey
        name = groupName
        count = groupCount
    }
}

private extension ActivityGroup {
    enum Error: Swift.Error {
        case missingName
        case missingCount
    }
}

public class RewindStatus {
    public let state: State
    public let lastUpdated: Date
    public let reason: String?
    public let restore: RestoreStatus?

    internal init(state: State) {
        // FIXME: A hack to support free WPCom sites and Rewind. Should be obsolote as soon as the backend
        // stops returning 412's for those sites.
        self.state = state
        self.lastUpdated = Date()
        self.reason = nil
        self.restore = nil
    }

    init(dictionary: [String: AnyObject]) throws {
        guard let rewindState = dictionary["state"] as? String else {
            throw Error.missingState
        }
        guard let rewindStateEnum = State(rawValue: rewindState) else {
            throw Error.invalidRewindState
        }
        guard let lastUpdatedString = dictionary["last_updated"] as? String else {
            throw Error.missingLastUpdatedDate
        }
        guard let lastUpdatedDate = Date.dateWithISO8601WithMillisecondsString(lastUpdatedString) else {
            throw Error.incorrectLastUpdatedDateFormat
        }

        state = rewindStateEnum
        lastUpdated = lastUpdatedDate
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
        case awaitingCredentials = "awaiting_credentials"
        case provisioning
    }
}

private extension RewindStatus {
    enum Error: Swift.Error {
        case missingState
        case missingLastUpdatedDate
        case incorrectLastUpdatedDateFormat
        case invalidRewindState
    }
}

public class RestoreStatus {
    public let id: String
    public let status: Status
    public let progress: Int
    public let message: String?
    public let currentEntry: String?
    public let errorCode: String?
    public let failureReason: String?

    init(dictionary: [String: AnyObject]) throws {
        guard let restoreId = dictionary["rewind_id"] as? String else {
            throw Error.missingRestoreId
        }
        guard let restoreStatus = dictionary["status"] as? String else {
            throw Error.missingRestoreStatus
        }
        guard let restoreStatusEnum = Status(rawValue: restoreStatus) else {
            throw Error.invalidRestoreStatus
        }

        id = restoreId
        status = restoreStatusEnum
        progress = dictionary["progress"] as? Int ?? 0
        message = dictionary["message"] as? String
        currentEntry = dictionary["current_entry"] as? String
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
