import CoreData
import WordPressKit

class BloggingPromptsService {
    let siteID: NSNumber

    private let contextManager: CoreDataStackSwift
    private let remote: BloggingPromptsServiceRemote // TODO: Remove once the settings logic is ported.
    private let api: WordPressComRestApi
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

        fetchRemotePrompts(number: number, fromDate: fromDate, ignoresYear: true) { result in
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

    /// Initializes a service for blogging prompts.
    ///
    /// - Parameters:
    ///   - contextManager: The CoreDataStack instance.
    ///   - remote: When supplied, the service will use the specified remote service.
    ///     Otherwise, a remote service with the default account's credentials will be used.
    ///   - blog: When supplied, the service will perform blogging prompts requests for this specified blog.
    ///     Otherwise, this falls back to the default account's primary blog.
    required init?(contextManager: CoreDataStackSwift = ContextManager.shared,
                   api: WordPressComRestApi? = nil,
                   remote: BloggingPromptsServiceRemote? = nil,
                   blog: Blog? = nil) {
        let blogObjectID = blog?.objectID
        let (siteID, remoteInstance, api) = contextManager.performQuery { mainContext in
            // if a blog exists, then try to use the blog's ID.
            var blogInContext: Blog? = nil
            if let blogObjectID {
                blogInContext = (try? mainContext.existingObject(with: blogObjectID)) as? Blog
            }

            // fetch the default account and fall back to default values as needed.
            guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: mainContext) else {
                return (
                    blogInContext?.dotComID,
                    remote,
                    api ?? WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress(),
                                                            localeKey: WordPressComRestApi.LocaleKeyV2)
                )
            }

            return (
                blogInContext?.dotComID ?? account.primaryBlogID,
                remote ?? .init(wordPressComRestApi: api ?? account.wordPressComRestV2Api),
                api ?? account.wordPressComRestV2Api
            )
        }

        guard let siteID,
              let remoteInstance else {
            return nil
        }

        self.contextManager = contextManager
        self.siteID = siteID
        self.remote = remoteInstance
        self.api = api
    }
}

// MARK: - Service Factory

/// Convenience factory to generate `BloggingPromptsService` for different blogs.
///
class BloggingPromptsServiceFactory {
    let contextManager: CoreDataStackSwift
    let remote: BloggingPromptsServiceRemote?

    init(contextManager: CoreDataStackSwift = ContextManager.shared, remote: BloggingPromptsServiceRemote? = nil) {
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

    // MARK: Prompts

    /// Fetches a number of blogging prompts for the specified site from the v3 endpoint.
    ///
    /// - Parameters:
    ///   - number: The number of prompts to query. When not specified, this will default to remote implementation.
    ///   - fromDate: When specified, this will fetch prompts from the given date. When not specified, this will default to remote implementation.
    ///   - ignoresYear: When set to true, this will convert the date to a custom format that ignores the year part. Defaults to true.
    ///   - forceYear: Forces the year value on the prompt's date to the specified value. Defaults to the current year.
    ///   - completion: A closure that will be called when the fetch request completes.
    func fetchRemotePrompts(number: Int? = nil,
                            fromDate: Date? = nil,
                            ignoresYear: Bool = true,
                            forceYear: Int? = nil,
                            completion: @escaping (Result<[BloggingPromptRemoteObject], Error>) -> Void) {
        let path = "wpcom/v3/sites/\(siteID)/blogging-prompts"
        let requestParameter: [String: AnyHashable] = {
            var params = [String: AnyHashable]()

            if let number, number > 0 {
                params["per_page"] = number
            }

            if let fromDate {
                // convert to yyyy-MM-dd format in UTC timezone so users would get the same prompts everywhere.
                var dateString = Self.utcDateFormatter.string(from: fromDate)

                // when the year needs to be ignored, we'll transform the dateString to match the "--mm-dd" format.
                if ignoresYear, !dateString.isEmpty {
                    dateString = "-" + dateString.dropFirst(4)
                }

                params["after"] = dateString
            }

            if let forceYear = forceYear ?? fromDate?.dateAndTimeComponents().year {
                params["force_year"] = forceYear
            }

            return params
        }()

        api.GET(path, parameters: requestParameter as [String: AnyObject]) { result, _ in
            switch result {
            case .success(let responseObject):
                do {
                    let data = try JSONSerialization.data(withJSONObject: responseObject, options: [])
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.supportMultipleDateFormats
                    decoder.keyDecodingStrategy = .useDefaultKeys

                    let remotePrompts = try decoder.decode([BloggingPromptRemoteObject].self, from: data)
                    completion(.success(remotePrompts))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
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
    func upsert(with remotePrompts: [BloggingPromptRemoteObject], completion: @escaping (Result<Void, Error>) -> Void) {
        if remotePrompts.isEmpty {
            completion(.success(()))
            return
        }

        // incoming remote prompts should have unique dates.
        // fetch requests require the date to be `NSDate` specifically, hence the cast.
        let incomingDates = Set(remotePrompts.map(\.date))
        let promptsByDate = remotePrompts.reduce(into: [Date: BloggingPromptRemoteObject]()) { partialResult, remotePrompt in
            partialResult[remotePrompt.date] = remotePrompt
        }

        let predicate = NSPredicate(format: "\(#keyPath(BloggingPrompt.siteID)) = %@ AND \(#keyPath(BloggingPrompt.date)) IN %@",
                                    siteID,
                                    incomingDates.map { $0 as NSDate })
        let fetchRequest = BloggingPrompt.fetchRequest()
        fetchRequest.predicate = predicate

        contextManager.performAndSave({ derivedContext in
            /// Try to overwrite prompts that have the same dates.
            ///
            /// Perf. notes: since we're at most updating 25 entries, it should be acceptable to update them one by one.
            /// However, if requirements change and we need to work through a larger data set, consider switching to
            /// a drop-and-replace strategy with `NSBatchDeleteRequest` as it's more performant.
            var updatedExistingDates = Set<Date>()
            let results = try derivedContext.fetch(fetchRequest)
            results.forEach { prompt in
                guard let incoming = promptsByDate[prompt.date] else {
                    return
                }

                // ensure that there's only one prompt for each date.
                // if the prompt with this date has been updated before, then it's a duplicate. Let's delete it.
                if updatedExistingDates.contains(prompt.date) {
                    derivedContext.deleteObject(prompt)
                    return
                }

                // otherwise, we can update the prompt matching the date with the incoming prompt.
                prompt.configure(with: incoming, for: self.siteID.int32Value)
                updatedExistingDates.insert(incoming.date)
            }

            // process the remaining new prompts.
            let datesToInsert = incomingDates.subtracting(updatedExistingDates)
            datesToInsert.forEach { date in
                guard let incoming = promptsByDate[date],
                      let newPrompt = BloggingPrompt.newObject(in: derivedContext) else {
                    return
                }
                newPrompt.configure(with: incoming, for: self.siteID.int32Value)
            }
        }, completion: completion, on: .main)
    }

    // MARK: Prompt Settings

    /// Updates existing settings or creates new settings from the remote prompt settings.
    ///
    /// - Parameters:
    ///   - remoteSettings: The blogging prompt settings from the remote.
    ///   - completion: Closure to be called on completion.
    func saveSettings(_ remoteSettings: RemoteBloggingPromptsSettings, completion: @escaping () -> Void) {
        contextManager.performAndSave({ derivedContext in
            let settings = self.loadSettings(context: derivedContext) ?? BloggingPromptSettings(context: derivedContext)
            settings.configure(with: remoteSettings, siteID: self.siteID.int32Value, context: derivedContext)
        }, completion: completion, on: .main)
    }

    private func loadSettings(context: NSManagedObjectContext) -> BloggingPromptSettings? {
        let fetchRequest = BloggingPromptSettings.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "\(#keyPath(BloggingPromptSettings.siteID)) = %@", siteID)
        fetchRequest.fetchLimit = 1
        return (try? context.fetch(fetchRequest))?.first
    }

}
