import Combine

/// Store for the blogging reminders.  This class should not be used directly.  Please refer to `BloggingReminders` instead.
///
class BloggingRemindersStore {
    /// Represents user-defined reminders for which notifications have been scheduled.
    ///
    enum ScheduledReminders {
        /// No reminders scheduled.
        ///
        case none

        /// Scheduled weekday reminders.
        ///
        case weekdays(_ days: [ScheduledWeekday])
    }

    /// A weekday with an associated notification that has already been scheduled.
    ///
    struct ScheduledWeekday: Codable {
        let weekday: BloggingReminders.Weekday
        let notificationID: String
    }

    private let dataFileURL: URL?

    var scheduledReminders: ScheduledReminders {
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
            return BloggingRemindersStore(scheduledReminders: .none)
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

    private init(scheduledReminders: ScheduledReminders, dataFileURL: URL? = nil) {
        self.dataFileURL = dataFileURL
        self.scheduledReminders = scheduledReminders
    }

    convenience init(fileManager: FileManager = .default, dataFileURL url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            self.init(scheduledReminders: .none, dataFileURL: url)
            persistChanges()
            return
        }

        let decoder = PropertyListDecoder()
        do {
            let data = try Data(contentsOf: url)
            let schedule = try decoder.decode(ScheduledReminders.self, from: data)
            self.init(scheduledReminders: schedule, dataFileURL: url)
        } catch {
            DDLogError("Error: \(error)")
            self.init(scheduledReminders: .none, dataFileURL: url)
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
            data = try PropertyListEncoder().encode(scheduledReminders)
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

extension BloggingRemindersStore.ScheduledReminders: Equatable {
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

extension BloggingRemindersStore.ScheduledReminders: Codable {
    typealias ScheduledWeekday = BloggingRemindersStore.ScheduledWeekday

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
                let days = try container.decode([ScheduledWeekday].self, forKey: .weekdays)
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

// MARK: - ScheduledWeekday: Equatable

extension BloggingRemindersStore.ScheduledWeekday: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.weekday == rhs.weekday
            && lhs.notificationID == rhs.notificationID
    }
}
