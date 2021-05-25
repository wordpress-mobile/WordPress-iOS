import Combine

/// Store for the blogging reminders.  This class should not be used directly.  Please refer to `BloggingReminders` instead.
///
class BloggingRemindersStore {
    /// An enum that describes a user-defined reminder schedule.
    ///
    enum Schedule {
        /// No reminder schedule.
        ///
        case none

        /// Weekdays reminders
        ///
        case weekdays(_ days: [ReminderScheduleWeekday])
    }

    enum Weekday {
        case monday(notificationID: String)
        case tuesday(notificationID: String)
        case wednesday(notificationID: String)
        case thursday(notificationID: String)
        case friday(notificationID: String)
        case saturday(notificationID: String)
        case sunday(notificationID: String)

        var notificationID: String {
            switch self {
            case .monday(let notificationID),
                 .tuesday(let notificationID),
                 .wednesday(let notificationID),
                 .thursday(let notificationID),
                 .friday(let notificationID),
                 .saturday(let notificationID),
                 .sunday(let notificationID):

                return notificationID
            }
        }

        /// The weekday identifier.
        ///
        var identifier: BloggingReminders.Weekday {
            switch self {
            case .sunday:
                return .sunday
            case .monday:
                return .monday
            case .tuesday:
                return .tuesday
            case .wednesday:
                return .wednesday
            case .thursday:
                return .thursday
            case .friday:
                return .friday
            case .saturday:
                return .saturday
            }
        }
    }

    private let dataFileURL: URL?

    var schedule: Schedule {
        didSet {
            persistChanges()
        }
    }

    // MARK: - Default Singleton

    static let `default`: BloggingRemindersStore = {
        guard let dataFileURL = defaultDataFileURL else {
            // In this scenario, nothing will be persisted, but at least the App won't crash due to
            // blogging reminders.  We raise an assertion failure so that if this is failing in developer
            // builds we'll spot the issue.
            assertionFailure()
            return BloggingRemindersStore(schedule: .none)
        }

        return BloggingRemindersStore(dataFileURL: dataFileURL)
    }()

    private static var dataFileName = "BloggingReminders.plist"

    private static var defaultDataFileURL: URL? {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WPAppGroupName) else {
            // In this scenario, nothing will be persisted, but at least the App won't crash due to
            // blogging reminders.  We raise an assertion failure so that if this is failing in developer
            // builds we'll spot the issue.
            DDLogError("BloggingRemindersStore: unable to get file URL for \(WPAppGroupName).")
            assertionFailure()
            return nil
        }

        return url.appendingPathComponent(dataFileName)
    }

    // MARK: - Initializers

    private init(schedule: Schedule, dataFileURL: URL? = nil) {
        self.dataFileURL = dataFileURL
        self.schedule = schedule
    }

    convenience init(fileManager: FileManager = .default, dataFileURL url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            self.init(schedule: .none, dataFileURL: url)
            persistChanges()
            return
        }

        let decoder = PropertyListDecoder()
        do {
            let data = try Data(contentsOf: url)
            let schedule = try decoder.decode(Schedule.self, from: data)
            self.init(schedule: schedule, dataFileURL: url)
        } catch {
            DDLogError("Error: \(error)")
            self.init(schedule: .none, dataFileURL: url)
        }
    }

    // MARK: - Persistance Logic

    private func persistChanges() {
        guard let url = dataFileURL ?? Self.defaultDataFileURL else {
            // In this scenario, nothing will be persisted, but at least the App won't crash due to
            // blogging reminders.  We raise an assertion failure so that if this is failing in developer
            // builds we'll spot the issue.
            assertionFailure()
            return
        }

        let data: Data

        do {
            data = try PropertyListEncoder().encode(schedule)
        } catch {
            DDLogError("Error!")
            return
        }

        guard FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil) else {
            DDLogError("Error!")
            return
        }
    }
}

// MARK: - ReminderSchedule: Equatable

extension BloggingRemindersStore.Schedule: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.weekdays(let left), .weekdays(let right)):
            return left == right
        default:
            return false
        }
    }
}

// MARK: - ReminderSchedule: Codable

extension BloggingRemindersStore.Schedule: Codable {
    typealias ReminderScheduleWeekday = BloggingRemindersStore.Weekday

    private enum CodingKeys: String, CodingKey {
        case none
        case weekdays
    }

    private enum Error: Swift.Error {
        case cantFindKeyForDecoding
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let key = container.allKeys.first else {
            throw Error.cantFindKeyForDecoding
        }

        switch key {
        case CodingKeys.none:
            self = .none
        case .weekdays:
            do {
                let days = try container.decode([ReminderScheduleWeekday].self, forKey: .weekdays)
                self = .weekdays(days)
            } catch {
                print(error)
                self = .none
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .none:
            try container.encode(true, forKey: .none)
        case .weekdays(let days):
            try container.encode(days, forKey: .weekdays)
        }
    }
}



// MARK: - ReminderScheduleWeekday: Equatable

extension BloggingRemindersStore.Weekday: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.monday(let left), .monday(let right)),
             (.tuesday(let left), .tuesday(let right)),
             (.wednesday(let left), .wednesday(let right)),
             (.thursday(let left), .thursday(let right)),
             (.friday(let left), .friday(let right)),
             (.saturday(let left), .saturday(let right)),
             (.sunday(let left), .sunday(let right)):

            return left == right
        default:
            return false
        }
    }
}

// MARK: - ReminderScheduleWeekday: Codable

extension BloggingRemindersStore.Weekday: Codable {
    private enum CodingKeys: String, CodingKey {
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday
        case sunday
    }

    private enum Error: Swift.Error {
        case cantFindKeyForDecoding
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let key = container.allKeys.first else {
            throw Error.cantFindKeyForDecoding
        }

        switch key {
        // It's important to be explicit, as .none needs disambiguation
        case .monday:
            let notificationID = try container.decode(String.self, forKey: .monday)
            self = .monday(notificationID: notificationID)
        case .tuesday:
            let notificationID = try container.decode(String.self, forKey: .tuesday)
            self = .tuesday(notificationID: notificationID)
        case .wednesday:
            let notificationID = try container.decode(String.self, forKey: .wednesday)
            self = .wednesday(notificationID: notificationID)
        case .thursday:
            let notificationID = try container.decode(String.self, forKey: .thursday)
            self = .thursday(notificationID: notificationID)
        case .friday:
            let notificationID = try container.decode(String.self, forKey: .friday)
            self = .friday(notificationID: notificationID)
        case .saturday:
            let notificationID = try container.decode(String.self, forKey: .saturday)
            self = .saturday(notificationID: notificationID)
        case .sunday:
            let notificationID = try container.decode(String.self, forKey: .sunday)
            self = .sunday(notificationID: notificationID)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .monday(let notificationID):
            try container.encode(notificationID, forKey: .monday)
        case .tuesday(let notificationID):
            try container.encode(notificationID, forKey: .tuesday)
        case .wednesday(let notificationID):
            try container.encode(notificationID, forKey: .wednesday)
        case .thursday(let notificationID):
            try container.encode(notificationID, forKey: .thursday)
        case .friday(let notificationID):
            try container.encode(notificationID, forKey: .friday)
        case .saturday(let notificationID):
            try container.encode(notificationID, forKey: .saturday)
        case .sunday(let notificationID):
            try container.encode(notificationID, forKey: .sunday)
        }
    }
}
