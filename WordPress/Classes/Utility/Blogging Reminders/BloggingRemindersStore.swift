import Foundation

/// Store for the blogging reminders.  This class should not be interacted with directly other than to pass
/// to the initializer of `BloggingRemindersScheduler`.
///
class BloggingRemindersStore {

    /// I'm intentionally making the naming and definition of the blog identifier a bit generic because right now we're using
    /// a `URIRepresentation`, but I'm not sure this is going to stay this way.
    ///
    typealias BlogIdentifier = URL

    enum Error: Swift.Error {
        case configurationDecodingFailed(error: Swift.Error)
        case configurationEncodingFailed(error: Swift.Error)
        case configurationFileCreationFailed(url: URL, data: Data)
    }

    /// Represents user-defined reminders for which notifications have been scheduled.
    ///
    enum ScheduledReminders {
        /// No reminders scheduled.
        ///
        case none

        /// Scheduled weekday reminders.
        ///
        case weekdays(_ days: [ScheduledWeekday])

        /// Scheduled weekday reminders with time of the day
        ///
        case weekDaysWithTime(_ daysWithTime: ScheduledWeekdaysWithTime)
    }

    struct ScheduledWeekdaysWithTime: Codable {
        let time: Date
        let days: [ScheduledWeekday]
    }

    /// A weekday with an associated notification that has already been scheduled.
    ///
    struct ScheduledWeekday: Codable {
        let weekday: BloggingRemindersScheduler.Weekday
        let notificationID: String
    }

    private let fileManager: FileManager
    private let dataFileURL: URL

    /// The blogging reminders configuration for all blogs.
    ///
    private(set) var configuration: [BlogIdentifier: ScheduledReminders]

    // MARK: - Initializers

    private init(
        fileManager: FileManager,
        configuration: [BlogIdentifier: ScheduledReminders],
        dataFileURL: URL) {

        self.dataFileURL = dataFileURL
        self.configuration = configuration
        self.fileManager = fileManager
    }

    convenience init(fileManager: FileManager = .default, dataFileURL url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            self.init(fileManager: fileManager, configuration: [:], dataFileURL: url)
            try save()
            return
        }

        let decoder = PropertyListDecoder()
        do {
            let data = try Data(contentsOf: url)
            let configuration = try decoder.decode([BlogIdentifier: ScheduledReminders].self, from: data)
            self.init(fileManager: fileManager, configuration: configuration, dataFileURL: url)
        } catch {
            throw Error.configurationDecodingFailed(error: error)
            self.init(fileManager: fileManager, configuration: [:], dataFileURL: url)
        }
    }

    // MARK: - Configurations

    func scheduledReminders(for blogIdentifier: BlogIdentifier) -> ScheduledReminders {
        configuration[blogIdentifier] ?? .none
    }

    func save(scheduledReminders: ScheduledReminders, for blogIdentifier: BlogIdentifier) throws {
        switch scheduledReminders {
        case .none:
            configuration.removeValue(forKey: blogIdentifier)
        case .weekdays, .weekDaysWithTime:
            configuration[blogIdentifier] = scheduledReminders
        }
        try save()
    }

    private func save() throws {
        let data: Data

        do {
            data = try PropertyListEncoder().encode(configuration)
        } catch {
            throw Error.configurationEncodingFailed(error: error)
        }

        guard fileManager.createFile(atPath: dataFileURL.path, contents: data, attributes: nil) else {
            throw Error.configurationFileCreationFailed(url: dataFileURL, data: data)
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
    typealias ScheduledWeekdaysWithTime = BloggingRemindersStore.ScheduledWeekdaysWithTime

    private enum CodingKeys: String, CodingKey {
        case none
        case weekdays
        case weekDaysWithTime
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
                DDLogError("Failed to decode days from Blogging Reminders store :\(error)")
                self = .none
            }
        case .weekDaysWithTime:
            do {
                let daysWithTime = try container.decode(ScheduledWeekdaysWithTime.self, forKey: .weekDaysWithTime)
                self = .weekDaysWithTime(daysWithTime)
            } catch {
                DDLogError("Failed to decode days from Blogging Reminders store :\(error)")
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
        case .weekDaysWithTime(let daysWithTime):
            try container.encode(daysWithTime, forKey: .weekDaysWithTime)

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
