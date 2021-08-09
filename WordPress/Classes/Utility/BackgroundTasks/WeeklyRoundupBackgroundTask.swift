import Foundation

class WeeklyRoundupBackgroundTask: BackgroundTask {
    static let identifier = "org.wordpress.bgtask.weeklyroundup"

    private lazy var staticNotificationIdentifier: String = {
        "\(Self.identifier)-static"
    }()

    private var lastSuccessfulRun = Date()
    private let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    let dynamicNotificationDateComponents: DateComponents
    let staticNotificationDateComponents: DateComponents

    let userNotificationCenter: UNUserNotificationCenter

    init(
        userNotificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current(),
        dynamicNotificationDateComponents: DateComponents? = nil,
        staticNotificationDateComponents: DateComponents? = nil) {

        self.dynamicNotificationDateComponents = dynamicNotificationDateComponents ?? {
            var dateComponents = DateComponents()

            dateComponents.calendar = Calendar.current

            // `DateComponent`'s weekday uses a 1-based index.
            dateComponents.weekday = 1
            dateComponents.hour = 9

            return dateComponents
        }()

        self.staticNotificationDateComponents = staticNotificationDateComponents ?? {
            var dateComponents = DateComponents()

            dateComponents.calendar = Calendar.current

            // `DateComponent`'s weekday uses a 1-based index.
            dateComponents.weekday = 1
            dateComponents.hour = 18

            return dateComponents
        }()

        self.userNotificationCenter = userNotificationCenter
    }

    func nextRunDate() -> Date? {
        Calendar.current.nextDate(after: Date(), matching: dynamicNotificationDateComponents, matchingPolicy: .nextTime)
    }

    func scheduled(success: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        // We're scheduling a static notification in case the BG task won't run.
        // This will happen when the App has been explicitly killed by the user as of 2021/08/03,
        // as Apple doesn't let background tasks run in this scenario.
        scheduleStaticNotification(completion: completion)
    }

    func expirationHandler() {
        cancelExecution()
    }

    func cancelExecution() {
        operationQueue.cancelAllOperations()
    }

    // MARK: - Running the Background Task

    func run(onError: @escaping (Error) -> Void, completion: @escaping (Bool) -> Void) {

        // We use multiple operations in series so that if the expiration handler is
        // called, the operation queue will cancell any pending operations, ensuring
        // that the task will exit as soon as possible.

        let cancelStaticNotification = BlockOperation {
            let group = DispatchGroup()
            group.enter()

            self.cancelStaticNotification { cancelled in
                defer {
                    group.leave()
                }

                guard cancelled else {
                    onError(NotificationSchedulingError.staticNotificationAlreadyDelivered)
                    self.operationQueue.cancelAllOperations()
                    return
                }
            }

            group.wait()
        }

        var site: Blog? = nil
        var stats: StatsSummaryData? = nil

        let requestData = BlockOperation {
            let group = DispatchGroup()
            group.enter()

            self.getTopSiteStats { result in
                defer {
                    group.leave()
                }

                switch result {
                case .success(let siteAndStats):
                    guard let (topSite, topStats) = siteAndStats else {
                        self.cancelExecution()
                        return
                    }

                    site = topSite
                    stats = topStats
                case .failure(let error):
                    onError(error)
                    self.cancelExecution()
                }
            }

            group.wait()
        }

        let scheduleNotification = BlockOperation {
            let group = DispatchGroup()
            group.enter()

            guard let siteName = site?.title,
                  let stats = stats else {

                // Error?
                self.cancelExecution()
                return
            }

            self.scheduleDynamicNotification(siteName: siteName, views: stats.viewsCount, comments: stats.commentsCount, likes: stats.likesCount) { result in
                switch result {
                case .success:
                    self.lastSuccessfulRun = Date()
                case .failure(let error):
                    onError(error)
                }

                group.leave()
            }

            group.wait()
        }

        // no-op: the reason we're adding this block is to get the completion handler below.
        // This closure may not be executed if the task is cancelled (through the operation queue)
        // but the completion closure below should always be called regardless.
        let completionOperation = BlockOperation {}

        completionOperation.completionBlock = {
            completion(completionOperation.isCancelled)
        }

        operationQueue.addOperation(cancelStaticNotification)
        operationQueue.addOperation(requestData)
        operationQueue.addOperation(scheduleNotification)
        operationQueue.addOperation(completionOperation)
    }

    // MARK: - Scheduling Notifications

    enum NotificationSchedulingError: Error {
        case staticNotificationAlreadyDelivered
        case earliestBeginDateMissing
        case staticNotificationSchedulingError(error: Error)
        case dynamicNotificationSchedulingError(error: Error)
    }

    private func scheduleStaticNotification(completion: @escaping (Result<Void, Error>) -> Void) {
        let title = "Weekly Roundup"
        let body = "Your weekly roundup is ready, tap here to see the details!"

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

    private func scheduleDynamicNotification(siteName: String, views: Int, comments: Int, likes: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let title = "Weekly Roundup: \(siteName)"
        let body = "Last week you had \(views) views, \(comments) comments and \(likes) likes."

        // The dynamic notification date is defined by when the background task is run.
        // Since these lines of code execute when the BG Task is run, we can just schedule
        // the dynamic notification after a few seconds.
        let date = Date(timeIntervalSinceNow: 10)
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute, .second], from: date)

        scheduleNotification(
            identifier: Self.identifier,
            title: title,
            body: body,
            dateComponents: dateComponents) { result in

            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(NotificationSchedulingError.dynamicNotificationSchedulingError(error: error)))
            }
        }
    }

    private func scheduleNotification(identifier: String, title: String, body: String, dateComponents: DateComponents, completion: @escaping (Result<Void, Error>) -> Void) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = InteractiveNotificationsManager.NoteCategoryDefinition.weeklyRoundup.rawValue

        // We want to make sure all weekly roundup notifications are grouped together.
        content.threadIdentifier = "org.wordpress.notification.threadIdentifier.weeklyRoundup"

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

    private func cancelStaticNotification(completion: @escaping (Bool) -> Void) {
        userNotificationCenter.getPendingNotificationRequests { requests in
            guard requests.contains( where: { $0.identifier == self.staticNotificationIdentifier }) else {
                // The reason why we're cancelling the background task if there's no static notification scheduled is because
                // it means we've already shown the static notification to the user.  Since iOS doesn't ensure an execution time
                // for background tasks, we assume this is the case where the static notification was shown before the dynamic
                // task was run.
                completion(false)
                return
            }

            self.userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [self.staticNotificationIdentifier])
            completion(true)
        }
    }

    // MARK: - Sites Data Updates

    enum StatsUpdateError: Error {
        case blogFetchingError(Error)
    }

    func getTopSiteStats(completion: @escaping (Result<(Blog, StatsSummaryData)?, Error>) -> Void) {
        let context = ContextManager.sharedInstance().mainContext
        let request = NSFetchRequest<Blog>(entityName: NSStringFromClass(Blog.self))

        request.sortDescriptors = [
            NSSortDescriptor(key: "accountForDefaultBlog.userID", ascending: false),
            NSSortDescriptor(key: "settings.name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]

        let controller = NSFetchedResultsController<Blog>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try controller.performFetch()
        } catch {
            completion(.failure(StatsUpdateError.blogFetchingError(error)))
            return
        }

        guard let blogs = controller.fetchedObjects?.filter({ (blog: Blog) in
            blog.capabilities?["own_site"] as? Bool == true
        }), blogs.count > 0 else {
            // No blogs to report stats for
            completion(.success(nil))
            return
        }

        var endDateComponents = DateComponents()
        endDateComponents.weekday = 1
        endDateComponents.hour = 23
        endDateComponents.minute = 59
        endDateComponents.second = 59

        // The DateComponents timezone is ignored when calling `Calendar.current.nextDate(...)`, so we need to
        // create a GMT Calendar to perform the date search using it, instead.
        var gmtCalendar = Calendar(identifier: .gregorian)
        gmtCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        guard let periodEndDate = gmtCalendar.nextDate(after: Date(), matching: endDateComponents, matchingPolicy: .nextTime, direction: .backward) else {
            DDLogError("Something's wrong with the preiod end date selection.")
            return
        }

        var blogStats = [Blog: StatsSummaryData]()

        for blog in blogs {
            guard let authToken = blog.account?.authToken else {
                continue
            }

            let wpApi = WordPressComRestApi.defaultApi(oAuthToken: authToken, userAgent: WPUserAgent.wordPress())

            guard let dotComID = blog.dotComID?.intValue else {
                // Report a blog without a dotComID as an error
                continue
            }

            let statsServiceRemote = StatsServiceRemoteV2(wordPressComRestApi: wpApi, siteID: dotComID, siteTimezone: blog.timeZone)

            statsServiceRemote.getData(for: .week, endingOn: periodEndDate, limit: 1) { (timeStats: StatsSummaryTimeIntervalData?, error) in
                guard let timeStats = timeStats else {
                    guard let error = error else {
                        // Report unknown error

                        return
                    }

                    // Report known error
                    return
                }

                guard let stats = timeStats.summaryData.last else {
                    // No stats for this site!  This could mean the site simply has no stats
                    return
                }

                blogStats[blog] = stats
            }
        }

        guard let bestStats = blogStats.reduce(nil, { (result: (site: Blog, stats: StatsSummaryData)?, entry) in
            guard entry.value.viewsCount >= 5,
                  entry.value.viewsCount >= result?.stats.viewsCount ?? 0 else {
                return result
            }

            return (site: entry.key, stats: entry.value)
        }) else {
            // No blogs to report stats for
            completion(.success(nil))
            return
        }

        completion(.success(bestStats))
    }
}
