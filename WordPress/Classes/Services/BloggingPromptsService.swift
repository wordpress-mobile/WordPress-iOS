import CoreData
import WordPressKit

class BloggingPromptsService {
    private let contextManager: CoreDataStack
    private let siteID: NSNumber
    private let remote: BloggingPromptsServiceRemote
    private let calendar: Calendar = .autoupdatingCurrent
    private let maxListPrompts = 11

    /// A UTC date formatter that ignores time information.
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.timeZone = .init(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter
    }()

    /// Convenience computed variable that returns today's prompt from local store.
    ///
    var localTodaysPrompt: BloggingPrompt? {
        loadPrompts(from: Date(), number: 1).first
    }

    /// Convenience computed variable that returns prompts for the prompts list from local store.
    ///
    var localListPrompts: [BloggingPrompt] {
        loadPrompts(from: listStartDate, number: maxListPrompts)
    }

    /// Fetches a number of blogging prompts starting from the specified date.
    /// When no parameters are specified, this method will attempt to return prompts from ten days ago and two weeks ahead.
    ///
    /// - Parameters:
    ///   - date: When specified, only prompts from the specified date will be returned. Defaults to 10 days ago.
    ///   - number: The amount of prompts to return. Defaults to 25 when unspecified (10 days back, today, 14 days ahead).
    ///   - success: Closure to be called when the fetch process succeeded.
    ///   - failure: Closure to be called when the fetch process failed.
    func fetchPrompts(from date: Date? = nil,
                      number: Int = 25,
                      success: @escaping ([BloggingPrompt]) -> Void,
                      failure: @escaping (Error?) -> Void) {
        let fromDate = date ?? defaultStartDate
        remote.fetchPrompts(for: siteID, number: number, fromDate: fromDate) { result in
            switch result {
            case .success(let remotePrompts):
                self.upsert(with: remotePrompts) { innerResult in
                    if case .failure(let error) = innerResult {
                        failure(error)
                        return
                    }

                    success(self.loadPrompts(from: fromDate, number: number))

                }
            case .failure(let error):
                failure(error)
            }
        }
    }

    /// Convenience method to fetch the blogging prompt for the current day.
    ///
    /// - Parameters:
    ///   - success: Closure to be called when the fetch process succeeded.
    ///   - failure: Closure to be called when the fetch process failed.
    func fetchTodaysPrompt(success: @escaping (BloggingPrompt?) -> Void,
                           failure: @escaping (Error?) -> Void) {
        fetchPrompts(from: Date(), number: 1, success: { (prompts) in
            success(prompts.first)
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
        fetchPrompts(from: listStartDate, number: maxListPrompts, success: success, failure: failure)
    }

    /// Convenience method to obtain the blogging prompts for the prompts list,
    /// either from local cache or remote.
    ///
    /// - Parameters:
    ///   - success: Closure to be called when the fetch process succeeded.
    ///   - failure: Closure to be called when the fetch process failed.
    func listPrompts(success: @escaping ([BloggingPrompt]) -> Void,
                     failure: @escaping (Error?) -> Void) {

        // If there aren't maxListPrompts cached, need to fetch more.
        guard localListPrompts.count < maxListPrompts else {
            success(localListPrompts)
            return
        }

        fetchListPrompts(success: success, failure: failure)
    }

    // MARK: - Settings

    func fetchSettings(success: @escaping () -> Void,
                       failure: @escaping (Error?) -> Void) {
        remote.fetchSettings(for: siteID) { result in
            switch result {
            case .success(_):
                success()
            case .failure(let error):
                failure(error)
            }
        }
    }

    func updateSettings(settings: RemoteBloggingPromptsSettings,
                        success: @escaping () -> Void,
                        failure: @escaping (Error?) -> Void) {
        remote.updateSettings(for: siteID, with: settings) { result in
            switch result {
            case .success(_):
                success()
            case .failure(let error):
                failure(error)
            }
        }
    }

    // MARK: - Init

    required init?(contextManager: CoreDataStack = ContextManager.shared,
                   remote: BloggingPromptsServiceRemote? = nil,
                   blog: Blog? = nil) {
        guard let account = AccountService(managedObjectContext: contextManager.mainContext).defaultWordPressComAccount(),
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
        calendar.date(byAdding: .day, value: -(maxListPrompts - 2), to: Date()) ?? Date()
    }

    /// Converts the given date to UTC and ignores the time information.
    /// Example: Given `2022-05-01 03:00:00 UTC-5`, this should return `2022-05-01 00:00:00 UTC`.
    ///
    /// - Parameter date: The date to convert.
    /// - Returns: The UTC date without the time information.
    func utcDateIgnoringTime(from date: Date) -> Date? {
        let utcDateString = Self.dateFormatter.string(from: date)
        return Self.dateFormatter.date(from: utcDateString)
    }

    /// Loads local prompts based on the given parameters.
    ///
    /// - Parameters:
    ///   - date: When specified, only prompts from the specified date will be returned.
    ///   - number: The amount of prompts to return.
    /// - Returns: An array of `BloggingPrompt` objects sorted descending by date.
    func loadPrompts(from date: Date, number: Int) -> [BloggingPrompt] {
        guard let utcDate = utcDateIgnoringTime(from: date) else {
            DDLogError("Error converting date to UTC: \(date)")
            return []
        }

        let fetchRequest = BloggingPrompt.fetchRequest()
        fetchRequest.predicate = .init(format: "\(#keyPath(BloggingPrompt.siteID)) = %@ AND \(#keyPath(BloggingPrompt.date)) >= %@", siteID, utcDate as NSDate)
        fetchRequest.fetchLimit = number
        fetchRequest.sortDescriptors = [.init(key: #keyPath(BloggingPrompt.date), ascending: false)]

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

        let derivedContext = contextManager.newDerivedContext()
        derivedContext.perform {
            do {
                // Update existing prompts
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

                self.contextManager.save(derivedContext) {
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                }

            } catch let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
