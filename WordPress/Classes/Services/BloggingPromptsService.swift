import CoreData
import WordPressKit

class BloggingPromptsService {
    private let contextManager: CoreDataStack
    private let siteID: NSNumber
    private let remote: BloggingPromptsServiceRemote
    private let calendar: Calendar = .autoupdatingCurrent
    private let maxListPrompts = 11

    /// A UTC date formatter that ignores time information.
    private static var utcDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.timeZone = .init(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter
    }()

    /// A date formatter using the local timezone that ignores time information.
    private static var localDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter
    }()

    /// Convenience computed variable that returns today's prompt from local store.
    ///
    var localTodaysPrompt: BloggingPrompt? {
        loadPrompts(from: Date(), number: 1).first
    }

    /// Convenience computed variable that returns prompt settings from the local store.
    ///
    var localSettings: BloggingPromptSettings? {
        loadSettings(context: contextManager.mainContext)
    }

    /// Fetches a number of blogging prompts starting from the specified date.
    /// When no parameters are specified, this method will attempt to return prompts from ten days ago and two weeks ahead.
    ///
    /// - Parameters:
    ///   - startDate: When specified, only prompts after the specified date will be returned. Defaults to 10 days ago.
    ///   - endDate: When specified, only prompts before the specified date will be returned.
    ///   - number: The amount of prompts to return. Defaults to 25 when unspecified (10 days back, today, 14 days ahead).
    ///   - success: Closure to be called when the fetch process succeeded.
    ///   - failure: Closure to be called when the fetch process failed.
    func fetchPrompts(from startDate: Date? = nil,
                      to endDate: Date? = nil,
                      number: Int = 25,
                      success: (([BloggingPrompt]) -> Void)? = nil,
                      failure: ((Error?) -> Void)? = nil) {
        let fromDate = startDate ?? defaultStartDate
        remote.fetchPrompts(for: siteID, number: number, fromDate: fromDate) { result in
            switch result {
            case .success(let remotePrompts):
                self.upsert(with: remotePrompts) { innerResult in
                    if case .failure(let error) = innerResult {
                        failure?(error)
                        return
                    }

                    success?(self.loadPrompts(from: fromDate, to: endDate, number: number))
                }
            case .failure(let error):
                failure?(error)
            }
        }
    }

    /// Convenience method to fetch the blogging prompt for the current day.
    ///
    /// - Parameters:
    ///   - success: Closure to be called when the fetch process succeeded.
    ///   - failure: Closure to be called when the fetch process failed.
    func fetchTodaysPrompt(success: ((BloggingPrompt?) -> Void)? = nil,
                           failure: ((Error?) -> Void)? = nil) {
        fetchPrompts(from: Date(), number: 1, success: { (prompts) in
            success?(prompts.first)
        }, failure: failure)
    }

    /// Convenience method to obtain the blogging prompt for the current day,
    /// either from local cache or remote.
    ///
    /// - Parameters:
    ///   - success: Closure to be called when the fetch process succeeded.
    ///   - failure: Closure to be called when the fetch process failed.
    func todaysPrompt(success: @escaping (BloggingPrompt?) -> Void,
                      failure: @escaping (Error?) -> Void) {
        guard localTodaysPrompt == nil else {
            success(localTodaysPrompt)
            return
        }

        fetchTodaysPrompt(success: success, failure: failure)
    }

    /// Convenience method to fetch the blogging prompts for the Prompts List.
    /// Fetches 11 prompts - the current day and 10 previous.
    ///
    /// - Parameters:
    ///   - success: Closure to be called when the fetch process succeeded.
    ///   - failure: Closure to be called when the fetch process failed.
    func fetchListPrompts(success: @escaping ([BloggingPrompt]) -> Void,
                          failure: @escaping (Error?) -> Void) {
        fetchPrompts(from: listStartDate, to: Date(), number: maxListPrompts, success: success, failure: failure)
    }

    /// Loads a single prompt with the given `promptID`.
    ///
    /// - Parameters:
    ///   - promptID: The unique ID for the blogging prompt.
    ///   - blog: The blog associated with the prompt.
    /// - Returns: The blogging prompt object if it exists, or nil otherwise.
    func loadPrompt(with promptID: Int, in blog: Blog) -> BloggingPrompt? {
        guard let siteID = blog.dotComID else {
            return nil
        }

        let fetchRequest = BloggingPrompt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "\(#keyPath(BloggingPrompt.siteID)) = %@ AND \(#keyPath(BloggingPrompt.promptID)) = %@", siteID, NSNumber(value: promptID))
        fetchRequest.fetchLimit = 1

        return (try? self.contextManager.mainContext.fetch(fetchRequest))?.first
    }

    // MARK: - Settings

    /// Fetches the blogging prompt settings for the configured `siteID`.
    ///
    /// - Parameters:
    ///   - success: Closure to be called on success with an optional `BloggingPromptSettings` object.
    ///   - failure: Closure to be called on failure with an optional `Error` object.
    func fetchSettings(success: @escaping (BloggingPromptSettings?) -> Void,
                       failure: @escaping (Error?) -> Void) {
        remote.fetchSettings(for: siteID) { result in
            switch result {
            case .success(let remoteSettings):
                self.saveSettings(remoteSettings) {
                    let settings = self.loadSettings(context: self.contextManager.mainContext)
                    success(settings)
                }
            case .failure(let error):
                failure(error)
            }
        }
    }

    /// Updates the blogging prompt settings for the configured `siteID`.
    ///
    /// - Parameters:
    ///   - settings: The new settings to update the remote with
    ///   - success: Closure to be called on success with an optional `BloggingPromptSettings` object. `nil` is passed
    ///              when the call is successful but there were no updated settings on the remote.
    ///   - failure: Closure to be called on failure with an optional `Error` object.
    func updateSettings(settings: RemoteBloggingPromptsSettings,
                        success: @escaping (BloggingPromptSettings?) -> Void,
                        failure: @escaping (Error?) -> Void) {
        remote.updateSettings(for: siteID, with: settings) { result in
            switch result {
            case .success(let remoteSettings):
                guard let updatedSettings = remoteSettings else {
                    success(nil)
                    return
                }
                self.saveSettings(updatedSettings) {
                    let settings = self.loadSettings(context: self.contextManager.mainContext)
                    success(settings)
                }
            case .failure(let error):
                failure(error)
            }
        }
    }

    // MARK: - Init

    required init?(contextManager: CoreDataStack = ContextManager.shared,
                   remote: BloggingPromptsServiceRemote? = nil,
                   blog: Blog? = nil) {
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext),
              let siteID = blog?.dotComID ?? account.primaryBlogID else {
            return nil
        }

        self.contextManager = contextManager
        self.siteID = siteID
        self.remote = remote ?? .init(wordPressComRestApi: account.wordPressComRestV2Api)
    }
}

// MARK: - Service Factory

/// Convenience factory to generate `BloggingPromptsService` for different blogs.
///
class BloggingPromptsServiceFactory {
    let contextManager: CoreDataStack
    let remote: BloggingPromptsServiceRemote?

    init(contextManager: CoreDataStack = ContextManager.shared, remote: BloggingPromptsServiceRemote? = nil) {
        self.contextManager = contextManager
        self.remote = remote
    }

    func makeService(for blog: Blog) -> BloggingPromptsService? {
        return .init(contextManager: contextManager, remote: remote, blog: blog)
    }
}

// MARK: - Private Helpers

private extension BloggingPromptsService {

    var defaultStartDate: Date {
        calendar.date(byAdding: .day, value: -10, to: Date()) ?? Date()
    }

    var listStartDate: Date {
        calendar.date(byAdding: .day, value: -(maxListPrompts - 1), to: Date()) ?? Date()
    }

    /// Converts the given date to UTC preserving the date and ignores the time information.
    /// Examples:
    ///   Given `2022-05-01 23:00:00 UTC-4` (`2022-05-02 03:00:00 UTC`), this should return `2022-05-01 00:00:00 UTC`.
    ///
    ///   Given `2022-05-02 05:00:00 UTC+9` (`2022-05-01 20:00:00 UTC`), this should return `2022-05-02 00:00:00 UTC`.
    ///
    /// - Parameter date: The date to convert.
    /// - Returns: The UTC date without the time information.
    func utcDateIgnoringTime(from date: Date?) -> Date? {
        guard let date = date else {
            return nil
        }
        let dateString = Self.localDateFormatter.string(from: date)
        return Self.utcDateFormatter.date(from: dateString)
    }

    /// Loads local prompts based on the given parameters.
    ///
    /// - Parameters:
    ///   - startDate: Only prompts after the specified date will be returned.
    ///   - endDate: When specified, only prompts before the specified date will be returned.
    ///   - number: The amount of prompts to return.
    /// - Returns: An array of `BloggingPrompt` objects sorted ascending by date.
    func loadPrompts(from startDate: Date, to endDate: Date? = nil, number: Int) -> [BloggingPrompt] {
        guard let utcStartDate = utcDateIgnoringTime(from: startDate) else {
            DDLogError("Error converting date to UTC: \(startDate)")
            return []
        }

        let fetchRequest = BloggingPrompt.fetchRequest()
        if let utcEndDate = utcDateIgnoringTime(from: endDate) {
            let format = "\(#keyPath(BloggingPrompt.siteID)) = %@ AND \(#keyPath(BloggingPrompt.date)) >= %@ AND \(#keyPath(BloggingPrompt.date)) <= %@"
            fetchRequest.predicate = NSPredicate(format: format, siteID, utcStartDate as NSDate, utcEndDate as NSDate)
        } else {
            let format = "\(#keyPath(BloggingPrompt.siteID)) = %@ AND \(#keyPath(BloggingPrompt.date)) >= %@"
            fetchRequest.predicate = NSPredicate(format: format, siteID, utcStartDate as NSDate)
        }
        fetchRequest.fetchLimit = number
        fetchRequest.sortDescriptors = [.init(key: #keyPath(BloggingPrompt.date), ascending: true)]

        return (try? self.contextManager.mainContext.fetch(fetchRequest)) ?? []
    }

    /// Find and update existing prompts, or insert new ones if they don't exist.
    ///
    /// - Parameters:
    ///   - remotePrompts: An array containing prompts obtained from remote.
    ///   - completion: Closure to be called after the process completes. Returns an array of prompts when successful.
    func upsert(with remotePrompts: [RemoteBloggingPrompt], completion: @escaping (Result<Void, Error>) -> Void) {
        if remotePrompts.isEmpty {
            completion(.success(()))
            return
        }

        let remoteIDs = Set(remotePrompts.map { Int32($0.promptID) })
        let remotePromptsDictionary = remotePrompts.reduce(into: [Int32: RemoteBloggingPrompt]()) { partialResult, remotePrompt in
            partialResult[Int32(remotePrompt.promptID)] = remotePrompt
        }

        let predicate = NSPredicate(format: "\(#keyPath(BloggingPrompt.siteID)) = %@ AND \(#keyPath(BloggingPrompt.promptID)) IN %@", siteID, remoteIDs)
        let fetchRequest = BloggingPrompt.fetchRequest()
        fetchRequest.predicate = predicate

        contextManager.performAndSave { derivedContext in
            var foundExistingIDs = [Int32]()
            let results = try derivedContext.fetch(fetchRequest)
            results.forEach { prompt in
                guard let remotePrompt = remotePromptsDictionary[prompt.promptID] else {
                    return
                }

                foundExistingIDs.append(prompt.promptID)
                prompt.configure(with: remotePrompt, for: self.siteID.int32Value)
            }

            // Insert new prompts
            let newPromptIDs = remoteIDs.subtracting(foundExistingIDs)
            newPromptIDs.forEach { newPromptID in
                guard let remotePrompt = remotePromptsDictionary[newPromptID],
                      let newPrompt = BloggingPrompt.newObject(in: derivedContext) else {
                    return
                }
                newPrompt.configure(with: remotePrompt, for: self.siteID.int32Value)
            }
        } completion: { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    /// Updates existing settings or creates new settings from the remote prompt settings.
    ///
    /// - Parameters:
    ///   - remoteSettings: The blogging prompt settings from the remote.
    ///   - completion: Closure to be called on completion.
    func saveSettings(_ remoteSettings: RemoteBloggingPromptsSettings, completion: @escaping () -> Void) {
        contextManager.performAndSave { derivedContext in
            let settings = self.loadSettings(context: derivedContext) ?? BloggingPromptSettings(context: derivedContext)
            settings.configure(with: remoteSettings, siteID: self.siteID.int32Value, context: derivedContext)
        } completion: {
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func loadSettings(context: NSManagedObjectContext) -> BloggingPromptSettings? {
        let fetchRequest = BloggingPromptSettings.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "\(#keyPath(BloggingPromptSettings.siteID)) = %@", siteID)
        fetchRequest.fetchLimit = 1
        return (try? context.fetch(fetchRequest))?.first
    }

}
