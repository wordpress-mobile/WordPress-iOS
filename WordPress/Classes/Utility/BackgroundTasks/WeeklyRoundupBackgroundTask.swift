import Foundation
import CoreData

/// The main data provider for Weekly Roundup information.
///
private class WeeklyRoundupDataProvider {

    // MARK: - Definitions

    typealias BlogManagedObjectID = NSManagedObjectID
    typealias SiteStats = [BlogManagedObjectID: StatsSummaryData]

    enum DataRequestError: Error {
        case dotComSiteWithoutDotComID(_ site: Blog)
        case siteFetchingError(_ error: Error)
        case unknownErrorRetrievingStats(_ site: Blog)
        case errorRetrievingStats(_ blogID: Int, error: Error)
        case filterWeeklyRoundupEnabledSitesError(_ error: NSError?)
    }

    // MARK: - Misc Properties

    private let coreDataStack: CoreDataStack

    /// Method to report errors that won't interrupt the execution.
    ///
    private let onError: (Error) -> Void

    /// Debug settings configured through the App's debug menu.
    ///
    private let debugSettings = WeeklyRoundupDebugScreen.Settings()

    init(coreDataStack: CoreDataStack, onError: @escaping (Error) -> Void) {
        self.coreDataStack = coreDataStack
        self.onError = onError
    }

    // MARK: API

    /// Fetches the top site statistics from all available sites in the provided context.
    ///
    /// This method retrieves all sites in the given context, then fetches the weekly stats
    /// for each site. The result, which includes the top 5 sites based on the received stats,
    /// is returned through the provided completion handler.
    ///
    /// **Note:** The completion handler is executed on a background queue.
    func getTopSiteStats(completion: @escaping (Result<SiteStats?, Error>) -> Void) {
        self.coreDataStack.performAndSave { [weak self] context in
            guard let self else {
                completion(.success(nil))
                return
            }
            self.getTopSiteStats(in: context, completion: completion)
        }
    }

    // MARK: Helpers

    /// Fetches the top site statistics from all available sites in the provided context.
    ///
    /// This method retrieves all sites in the given context, then fetches the weekly stats
    /// for each site. The result, which includes the top 5 sites based on the received stats,
    /// is returned through the provided completion handler.
    ///
    /// **Note:** The completion handler is executed on the context's queue.
    private func getTopSiteStats(in context: NSManagedObjectContext, completion: @escaping (Result<SiteStats?, Error>) -> Void) {
        getSites(in: context) { [weak self] sitesResult in
            guard let self = self else {
                return
            }

            switch sitesResult {
            case .success(let sites):
                guard sites.count > 0 else {
                    completion(.success(nil))
                    return
                }

                self.getTopSiteStats(from: sites, in: context, completion: completion)
            case .failure(let error):
                completion(.failure(error))
                return
            }
        }
    }

    /// Fetches the top site statistics for a given array of blogs.
    ///
    /// This method asynchronously fetches weekly statistics for each blog in the provided list.
    /// After all data has been fetched, it filters out the top 5 sites based on the received stats
    /// and returns the result through the provided completion handler.
    ///
    /// **Note:** The completion handler is executed on the context's queue.
    private func getTopSiteStats(
        from sites: [Blog],
        in context: NSManagedObjectContext,
        completion: @escaping (Result<SiteStats?, Error>) -> Void
    ) {
        guard let periodEndDate = getPeriodEndDate() else {
            DDLogError("Something's wrong with the period end date selection.")
            return
        }

        let group = DispatchGroup()
        var blogStats = SiteStats()

        for site in sites {
            guard let authToken = site.account?.authToken else {
                continue
            }

            group.enter()

            self.fetchStats(for: site, endingOn: periodEndDate, authToken: authToken, in: context) { [weak self] result in
                defer {
                    group.leave()
                }
                guard let self else {
                    return
                }
                switch result {
                case .failure(let error):
                    self.onError(error)
                case.success(let stats):
                    if let stats {
                        blogStats[site.objectID] = stats
                    }
                }
            }
        }

        group.notify(queue: .global()) {
            context.perform {
                let bestBlogStats = self.filterBest(5, from: blogStats)
                completion(.success(bestBlogStats))
            }
        }
    }

    /// Fetches weekly stats data for a given site.
    ///
    /// This function fetches the stats for a single site and passes the result to a completion handler.
    /// If it encounters any error during fetching, it calls the completion handler with an appropriate error object.
    /// The completion handler is executed in the same queue as the provided `NSManagedObjectContext`.
    ///
    /// **Note:** The completion handler is executed on the context's queue.
    private func fetchStats(
        for site: Blog,
        endingOn periodEndDate: Date,
        authToken: String,
        in context: NSManagedObjectContext,
        completion: @escaping (Result<StatsSummaryData?, Error>) -> Void
    ) {
        guard let dotComID = site.dotComID?.intValue else {
            completion(.failure(DataRequestError.dotComSiteWithoutDotComID(site)))
            return
        }
        let wpApi = WordPressComRestApi.defaultApi(oAuthToken: authToken, userAgent: WPUserAgent.wordPress())
        let statsServiceRemote = StatsServiceRemoteV2(wordPressComRestApi: wpApi, siteID: dotComID, siteTimezone: site.timeZone)
        statsServiceRemote.getData(for: .week, endingOn: periodEndDate, limit: 1) { (timeStats: StatsSummaryTimeIntervalData?, error) in
            context.perform {
                guard let timeStats = timeStats else {
                    if let error = error {
                        completion(.failure(DataRequestError.errorRetrievingStats(dotComID, error: error)))
                    } else {
                        completion(.failure(DataRequestError.unknownErrorRetrievingStats(site)))
                    }
                    return
                }
                completion(.success(timeStats.summaryData.first))
            }
        }
    }

    /// Returns the end date for the period (the start of the current week).
    /// This function creates a calendar with a GMT timezone and specifies that it needs a date representing the start of the current week.
    /// If it can't find a valid date, it returns nil.
    private func getPeriodEndDate() -> Date? {
        var gmtCalendar = Calendar(identifier: .gregorian)
        gmtCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var endDateComponents = DateComponents()
        endDateComponents.weekday = 1
        return gmtCalendar.nextDate(after: Date(), matching: endDateComponents, matchingPolicy: .nextTime, direction: .backward)
    }

    /// Filters the "best" count sites from the provided dictionary of sites and stats.  This method implicitly implements the
    /// definition of "best" through a sorting mechanism where the "best" sites are placed first.
    ///
    private func filterBest(_ count: Int, minimumViewsCount: Int = 5, from blogStats: SiteStats) -> SiteStats {
        let filteredAndSorted = blogStats.filter { (site, stats) in
            stats.viewsCount >= minimumViewsCount
        }.sorted { (first: (_, value: StatsSummaryData), second: (_, value: StatsSummaryData)) in
            first.value.viewsCount >= second.value.viewsCount
        }

        return filteredAndSorted
            .dropLast(filteredAndSorted.count > count ? filteredAndSorted.count - count : 0)
            .reduce(into: [:]) { $0[$1.key] = $1.value }
    }

    /// Retrieves the sites considered by Weekly Roundup for reporting.
    ///
    /// - Returns: the requested sites (could be an empty array if there's none) or an error if there is one.
    ///
    private func getSites(in context: NSManagedObjectContext, result: @escaping (Result<[Blog], Error>) -> Void) {

        switch getAllSites(in: context) {
        case .success(let sites):
            filterCandidateSites(sites, in: context, result: result)
        case .failure(let error):
            result(.failure(error))
        }
    }

    /// Filters the candidate sites for the Weekly Roundup notification
    ///
    private func filterCandidateSites(_ sites: [Blog], in context: NSManagedObjectContext, result: @escaping (Result<[Blog], Error>) -> Void) {
        let administeredSites = sites.filter { site in
            site.isAdmin && ((FeatureFlag.debugMenu.enabled && debugSettings.isEnabledForA8cP2s) || !site.isAutomatticP2)
        }

        guard administeredSites.count > 0 else {
            result(.success([]))
            return
        }

        filterWeeklyRoundupEnabledSites(administeredSites, in: context, result: result)
    }

    /// Filters the sites that have the Weekly Roundup notification setting enabled.
    ///
    private func filterWeeklyRoundupEnabledSites(_ sites: [Blog], in context: NSManagedObjectContext, result: @escaping (Result<[Blog], Error>) -> Void) {
        let noteService = NotificationSettingsService(coreDataStack: coreDataStack)

        noteService.getAllSettings { settings in
            context.perform {
                let weeklyRoundupEnabledSites = Self.weeklyRoundupEnabledSites(settings: settings, sites: sites, in: context)
                result(.success(weeklyRoundupEnabledSites))
            }
        } failure: { (error: NSError?) in
            let error = DataRequestError.filterWeeklyRoundupEnabledSitesError(error)
            result(.failure(error))
        }
    }

    static private func weeklyRoundupEnabledSites(
        settings: [NotificationSettings],
        sites: [Blog],
        in context: NSManagedObjectContext) -> [Blog] {
        return sites.filter { site in
            guard let siteSettings = settings.first(where: { $0.blogManagedObjectID == site.objectID }),
                  let pushNotificationsStream = siteSettings.streams.first(where: { $0.kind == .Device }),
                  let sitePreferences = pushNotificationsStream.preferences else {
                return false
            }
            return sitePreferences["weekly_roundup"] ?? true
        }
    }

    private func getAllSites(in context: NSManagedObjectContext) -> Result<[Blog], Error> {
        let request = NSFetchRequest<Blog>(entityName: NSStringFromClass(Blog.self))

        request.sortDescriptors = [
            NSSortDescriptor(key: "accountForDefaultBlog.userID", ascending: false),
            NSSortDescriptor(key: "settings.name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]

        do {
            let result = try context.fetch(request)
            return .success(result)
        } catch {
            return .failure(DataRequestError.siteFetchingError(error))
        }
    }
}

class WeeklyRoundupBackgroundTask: BackgroundTask {

    // MARK: - Store

    class Store {

        private let userDefaults: UserDefaults

        init(userDefaults: UserDefaults = .standard) {
            self.userDefaults = userDefaults
        }

        // Mark - User Defaults Storage

        private let lastRunDateKey = "weeklyRoundup.lastExecutionDate"

        func getLastRunDate() -> Date? {
            UserPersistentStoreFactory.instance().object(forKey: lastRunDateKey) as? Date
        }

        func setLastRunDate(_ date: Date) {
            UserPersistentStoreFactory.instance().set(date, forKey: lastRunDateKey)
        }
    }

    // MARK: - Misc Properties

    static var identifier: String {
        if FeatureFlag.weeklyRoundupBGProcessingTask.enabled {
            return Constants.taskIdentifierProcessing
        }

        return Constants.taskIdentifier
    }
    static private let secondsPerDay = 24 * 60 * 60

    private let store: Store

    private let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    enum RunError: Error {
        case staticNotificationAlreadyDelivered
    }

    private let eventTracker: NotificationEventTracker
    let runDateComponents: DateComponents
    let notificationScheduler: WeeklyRoundupNotificationScheduler
    let coreDataStack: ContextManager

    init(
        eventTracker: NotificationEventTracker = NotificationEventTracker(),
        runDateComponents: DateComponents? = nil,
        staticNotificationDateComponents: DateComponents? = nil,
        store: Store = Store(),
        coreDataStack: ContextManager = .shared
    ) {
        self.coreDataStack = coreDataStack
        self.eventTracker = eventTracker
        self.notificationScheduler = WeeklyRoundupNotificationScheduler(staticNotificationDateComponents: staticNotificationDateComponents)
        self.store = store
        self.runDateComponents = runDateComponents ?? {
            var dateComponents = DateComponents()

            dateComponents.calendar = Calendar.current

            // `DateComponent`'s weekday uses a 1-based index.
            dateComponents.weekday = 2
            dateComponents.hour = 10

            return dateComponents
        }()
    }

    /// Just a convenience method to know then this task is run, what run date to use as "current".
    ///
    private func currentRunPeriodEndDate() -> Date {
        let runDate = Calendar.current.nextDate(
            after: Date(),
            matching: runDateComponents,
            matchingPolicy: .nextTime,
            direction: .backward) ?? Date()

        // The run date is when the task is scheduled to run, but the period end date is actually
        // the previous day at 24:59:59.
        let periodEndDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: runDate)!.addingTimeInterval(TimeInterval.init(-1))

        return periodEndDate
    }

    private func secondsInDays(_ numberOfDays: Int) -> Int {
        numberOfDays * Self.secondsPerDay
    }

    /// This method checks if we skipped a Weekly Roundup run, and if we're within 2 days of that skipped Weekly Roundup run date.
    /// If all is true, it returns the date of the last skipped Weekly Roundup.
    ///
    /// If Weekly Roundup has never been run this will always return `nil` as we haven't skipped any date.
    ///
    /// - Returns: the date of the last skipped Weekly Roundup, or `nil` if the conditions aren't met.
    ///
    private func skippedWeeklyRoundupDate() -> Date? {
        let today = Date()

        if let lastRunDate = store.getLastRunDate(),
           Int(today.timeIntervalSinceReferenceDate - lastRunDate.timeIntervalSinceReferenceDate) > secondsInDays(6),
           let lastValidDate = Calendar.current.nextDate(
            after: Date(),
            matching: runDateComponents,
            matchingPolicy: .nextTime,
            direction: .backward),
           lastValidDate > lastRunDate,
           Int(today.timeIntervalSinceReferenceDate - lastValidDate.timeIntervalSinceReferenceDate) <= secondsInDays(2) {

            return lastValidDate
        }

        return nil
    }

    func nextRunDate() -> Date? {
        // If we're within 2 days of a skipped Weekly Roundup date, we can show it.
        if let skippedRunDate = skippedWeeklyRoundupDate() {
            return skippedRunDate
        }

        return Calendar.current.nextDate(
            after: Date(),
            matching: runDateComponents,
            matchingPolicy: .nextTime)
    }

    func didSchedule(completion: @escaping (Result<Void, Error>) -> Void) {
        if Feature.enabled(.weeklyRoundupStaticNotification) {
            // We're scheduling a static notification in case the BG task won't run.
            // This will happen when the App has been explicitly killed by the user as of 2021/08/03,
            // as Apple doesn't let background tasks run in this scenario.
            notificationScheduler.scheduleStaticNotification(completion: completion)
        }

        completion(.success(()))
    }

    func expirationHandler() {
        cancelExecution()
    }

    private func cancelExecution() {
        operationQueue.cancelAllOperations()
    }

    // MARK: - Running the Background Task

    func run(onError: @escaping (Error) -> Void, completion: @escaping (Bool) -> Void) {

        // This will no longer run for WordPress as part of Jetpack migration.
        // This can be removed once Jetpack migration is complete.
        guard JetpackNotificationMigrationService.shared.shouldPresentNotifications() else {
            notificationScheduler.cancellAll()
            notificationScheduler.cancelStaticNotification()
            return
        }

        // We use multiple operations in series so that if the expiration handler is
        // called, the operation queue will cancell any pending operations, ensuring
        // that the task will exit as soon as possible.

        let cancelStaticNotification = BlockOperation {
            if Feature.enabled(.weeklyRoundupStaticNotification) {
                let group = DispatchGroup()
                group.enter()

                self.notificationScheduler.cancelStaticNotification { cancelled in
                    defer {
                        group.leave()
                    }

                    guard cancelled else {
                        onError(RunError.staticNotificationAlreadyDelivered)
                        self.operationQueue.cancelAllOperations()
                        return
                    }
                }

                group.wait()
            }
        }

        let dataProvider = WeeklyRoundupDataProvider(coreDataStack: coreDataStack, onError: onError)
        var siteStats: WeeklyRoundupDataProvider.SiteStats? = nil

        let requestData = BlockOperation {
            let group = DispatchGroup()
            group.enter()

            dataProvider.getTopSiteStats { result in
                defer {
                    group.leave()
                }

                switch result {
                case .success(let topSiteStats):
                    guard let topSiteStats = topSiteStats else {
                        self.cancelExecution()
                        return
                    }

                    siteStats = topSiteStats
                case .failure(let error):
                    onError(error)
                    self.cancelExecution()
                }
            }

            group.wait()
        }

        let scheduleNotification = BlockOperation {
            let group = DispatchGroup()

            guard let siteStats = siteStats else {
                self.cancelExecution()
                return
            }

            for (siteID, stats) in siteStats {
                group.enter()
                self.coreDataStack.performAndSave { context in
                    guard let site = try? context.existingObject(with: siteID) as? Blog else {
                        group.leave()
                        return
                    }
                    self.scheduleDynamicNotification(site: site, stats: stats) { result in
                        if case let .failure(error) = result {
                            onError(error)
                        }
                        group.leave()
                    }
                }
            }

            group.wait()
        }

        // no-op: the reason we're adding this block is to get the completion handler below.
        // This closure may not be executed if the task is cancelled (through the operation queue)
        // but the completion closure below should always be called regardless.
        let completionOperation = BlockOperation {}

        completionOperation.completionBlock = {
            self.store.setLastRunDate(Date())
            completion(completionOperation.isCancelled)
        }

        operationQueue.addOperation(cancelStaticNotification)
        operationQueue.addOperation(requestData)
        operationQueue.addOperation(scheduleNotification)
        operationQueue.addOperation(completionOperation)
    }

    // MARK: - Helpers

    private func scheduleDynamicNotification(site: Blog, stats: StatsSummaryData, completion: @escaping (Result<Void, Error>) -> Void) {
        let dotComID = site.dotComID?.intValue
        self.notificationScheduler.scheduleDynamicNotification(
            site: site,
            views: stats.viewsCount,
            comments: stats.commentsCount,
            likes: stats.likesCount,
            periodEndDate: self.currentRunPeriodEndDate()
        ) { result in
            switch result {
            case .success:
                self.eventTracker.notificationScheduled(type: .weeklyRoundup, siteId: dotComID)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    enum Constants {
        static let taskIdentifier = "org.wordpress.bgtask.weeklyroundup"
        static let taskIdentifierProcessing = "org.wordpress.bgtask.weeklyroundup.processing"
    }
}

class WeeklyRoundupNotificationScheduler {

    // MARK: - Identifiers

    static let notificationIdentifier = "org.wordpress.notification.identifier.weeklyRoundup"
    static let threadIdentifier = "org.wordpress.notification.threadIdentifier.weeklyRoundup"

    private lazy var staticNotificationIdentifier: String = {
        "\(Self.notificationIdentifier).static"
    }()

    func dynamicNotificationIdentifier(for blogID: Int) -> String {
        "\(Self.notificationIdentifier).\(blogID)"
    }

    // MARK: - Initialization

    init(
        staticNotificationDateComponents: DateComponents? = nil,
        userNotificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()) {

        self.userNotificationCenter = userNotificationCenter
        self.staticNotificationDateComponents = staticNotificationDateComponents ?? {
            var dateComponents = DateComponents()

            dateComponents.calendar = Calendar.current

            // `DateComponent`'s weekday uses a 1-based index.
            dateComponents.weekday = 2
            dateComponents.hour = 18

            return dateComponents
        }()
    }

    // MARK: - Scheduling Notifications

    let staticNotificationDateComponents: DateComponents
    let userNotificationCenter: UNUserNotificationCenter

    enum NotificationSchedulingError: Error {
        case staticNotificationSchedulingError(error: Error)
        case dynamicNotificationSchedulingError(error: Error)
    }

    func scheduleStaticNotification(completion: @escaping (Result<Void, Error>) -> Void) {
        let title = TextContent.staticNotificationTitle
        let body = TextContent.staticNotificationBody

        scheduleNotification(
            identifier: staticNotificationIdentifier,
            title: title,
            body: body,
            dateComponents: staticNotificationDateComponents) { result in

            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(NotificationSchedulingError.staticNotificationSchedulingError(error: error)))
            }
        }
    }

    func scheduleDynamicNotification(
        site: Blog,
        views: Int,
        comments: Int,
        likes: Int,
        periodEndDate: Date,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        var siteTitle = site.title
        var dotComID = site.dotComID?.intValue

        guard let dotComID = dotComID else {
            fatalError("The argument site is not a WordPress.com site. Site: \(site)")
        }

        let title = notificationTitle(siteTitle)
        let body = notificationBodyWith(views: views, comments: likes, likes: comments)

        // The dynamic notification date is defined by when the background task is run.
        // Since these lines of code execute when the BG Task is run, we can just schedule
        // the dynamic notification after a few seconds.
        let date = Date(timeIntervalSinceNow: 10)
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute, .second], from: date)

        let identifier = dynamicNotificationIdentifier(for: dotComID)
        let userInfo: [AnyHashable: Any] = [
            InteractiveNotificationsManager.blogIDKey: dotComID,
            InteractiveNotificationsManager.dateKey: periodEndDate,
            PushNotificationsManager.Notification.typeKey: NotificationEventTracker.NotificationType.weeklyRoundup.rawValue
        ]

        scheduleNotification(
            identifier: identifier,
            title: title,
            body: body,
            userInfo: userInfo,
            dateComponents: dateComponents) { result in

                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(NotificationSchedulingError.dynamicNotificationSchedulingError(error: error)))
                }
            }
    }

    func notificationBodyWith(views: Int, comments: Int, likes: Int) -> String {
        var body = ""
        let hideLikesCount = likes <= 0
        let hideCommentsCount = comments <= 0

        switch (hideLikesCount, hideCommentsCount) {
        case (true, true):
            body = String(format: TextContent.dynamicNotificationBodyViewsOnly, views.abbreviatedString())
        case (false, true):
            body = String(format: TextContent.dynamicNotificationBodyViewsAndLikes, views.abbreviatedString(), likes.abbreviatedString())
        case (true, false):
            body = String(format: TextContent.dynamicNotificationBodyViewsAndComments, views.abbreviatedString(), comments.abbreviatedString())
        default:
            body = String(format: TextContent.dynamicNotificationBodyAll, views.abbreviatedString(), comments.abbreviatedString(), likes.abbreviatedString())
        }

        return body
    }

    private func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        userInfo: [AnyHashable: Any] = [:],
        dateComponents: DateComponents,
        completion: @escaping (Result<Void, Error>) -> Void) {

        guard JetpackNotificationMigrationService.shared.shouldPresentNotifications() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = InteractiveNotificationsManager.NoteCategoryDefinition.weeklyRoundup.rawValue

        // We want to make sure all weekly roundup notifications are grouped together.
        content.threadIdentifier = Self.threadIdentifier
        content.userInfo = userInfo

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        userNotificationCenter.add(request) { error in
            if let error = error {
                completion(.failure(error))
                return
            }

            completion(.success(()))
        }
    }

    // MARK: - Cancelling Notifications

    /// Useful for cancelling all of the Weekly Roundup notifications.
    ///
    func cancellAll() {
        userNotificationCenter.getPendingNotificationRequests { requests in
            let notifications = requests.filter({ $0.content.threadIdentifier == Self.threadIdentifier })

            guard notifications.count > 0 else {
                return
            }

            self.userNotificationCenter.removePendingNotificationRequests(withIdentifiers: notifications.map({ $0.identifier }))
        }
    }

    func cancelStaticNotification(completion: @escaping (Bool) -> Void = { _ in }) {
        userNotificationCenter.getPendingNotificationRequests { requests in
            if Feature.enabled(.weeklyRoundupStaticNotification) {
                guard requests.contains( where: { $0.identifier == self.staticNotificationIdentifier }) else {
                    // The reason why we're cancelling the background task if there's no static notification scheduled is because
                    // it means we've already shown the static notification to the user.  Since iOS doesn't ensure an execution time
                    // for background tasks, we assume this is the case where the static notification was shown before the dynamic
                    // task was run.
                    completion(false)
                    return
                }

                self.userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [self.staticNotificationIdentifier])
            }

            completion(true)
        }
    }

    func notificationTitle(_ siteTitle: String?) -> String {
        if let siteTitle = siteTitle {
            return String(format: TextContent.dynamicNotificationTitle, siteTitle)
        } else {
            return TextContent.staticNotificationTitle
        }
    }

    enum TextContent {
        static let staticNotificationTitle = NSLocalizedString("Weekly Roundup", comment: "Title of Weekly Roundup push notification")
        static let dynamicNotificationTitle = NSLocalizedString("Weekly Roundup: %@", comment: "Title of Weekly Roundup push notification. %@ is a placeholder and will be replaced with the title of one of the user's websites.")
        static let staticNotificationBody = NSLocalizedString("Your weekly roundup is ready, tap here to see the details!", comment: "Prompt displayed as part of the stats Weekly Roundup push notification.")
        static let dynamicNotificationBodyViewsOnly = NSLocalizedString("Last week you had %@ views.", comment: "Content of a weekly roundup push notification containing stats about the user's site. The % marker is a placeholder and will be replaced by the appropriate number of views")
        static let dynamicNotificationBodyViewsAndLikes = NSLocalizedString("Last week you had %1$@ views and %2$@ likes.", comment: "Content of a weekly roundup push notification containing stats about the user's site. The % markers are placeholders and will be replaced by the appropriate number of views and likes. The numbers indicate the order, so they can be rearranged if necessary – 1 is views, 2 is likes.")
        static let dynamicNotificationBodyViewsAndComments = NSLocalizedString("Last week you had %1$@ views and %2$@ comments.", comment: "Content of a weekly roundup push notification containing stats about the user's site. The % markers are placeholders and will be replaced by the appropriate number of views and comments. The numbers indicate the order, so they can be rearranged if necessary – 1 is views, 2 is comments.")
        static let dynamicNotificationBodyAll = NSLocalizedString("Last week you had %1$@ views, %2$@ comments and %3$@ likes.", comment: "Content of a weekly roundup push notification containing stats about the user's site. The % markers are placeholders and will be replaced by the appropriate number of views, comments, and likes. The numbers indicate the order, so they can be rearranged if necessary – 1 is views, 2 is comments, 3 is likes.")
    }
}
