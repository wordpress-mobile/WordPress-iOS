import BackgroundTasks

/// Events during the execution of background tasks.
///
enum BackgroundTaskEvent {
    case start(identifier: String)
    case error(identifier: String, error: Error)
    case expirationHandlerCalled(identifier: String)
    case taskCompleted(identifier: String, cancelled: Bool)
    case rescheduled(identifier: String)
}

protocol BackgroundTask {
    static var identifier: String { get }
    //var log: (String) -> Void { get set }

    // MARK: - Scheduling

    /// Returns a schedule request for this task, so it can be scheduled by the coordinator.
    ///
    func request(completion: @escaping (Result<BGAppRefreshTaskRequest, Error>) -> Void)

    /// This method allows the task to perform extra processing after it's been scheduled.
    ///
    func scheduled(completion: @escaping (Result<Void, Error>) -> Void)

    // MARK: - Execution

    func expirationHandler()

    /// Runs the background task.
    ///
    /// - Parameters:
    ///     - osTask: the `BGTask` associated with this `BackgroundTask`.
    ///     - event: called for important events in the background tasks execution.
    ///
    func run(onError: @escaping (Error) -> Void, completion: @escaping (_ cancelled: Bool) -> Void)
}

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
    }

    enum NotificationSchedulingError: Error {
        case staticNotificationAlreadyDelivered
        case earliestBeginDateMissing
        case staticNotificationSchedulingError(error: Error)
        case dynamicNotificationSchedulingError(error: Error)
    }

    func expirationHandler() {
        operationQueue.cancelAllOperations()
    }

    func request(completion: @escaping (Result<BGAppRefreshTaskRequest, Error>) -> Void) {
        let request = BGAppRefreshTaskRequest(identifier: Self.identifier)
        let date = Calendar.current.nextDate(after: Date(), matching: dynamicNotificationDateComponents, matchingPolicy: .nextTime)

        request.earliestBeginDate = date

        completion(.success(request))
    }

    func scheduled(completion: @escaping (Result<Void, Error>) -> Void) {
        // We're scheduling a static notification in case the BG task won't run.
        // This will happen when the App has been explicitly killed by the user as of 2021/08/03,
        // as Apple doesn't let background tasks run in this scenario.
        scheduleStaticNotification(completion: completion)
    }

    func run(onError: @escaping (Error) -> Void, completion: @escaping (Bool) -> Void) {

        // We use multiple operations in series so that if the expiration handler is
        // called, the operation queue will cancell any pending operations, ensuring
        // that the task will exit as soon as possible.

        let cancelStaticNotification = BlockOperation {
            let group = DispatchGroup()
            group.enter()

            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                // Whatever exit path this method takes, we need to ensure we leave the dispatch group.
                defer {
                    group.leave()
                }

                guard requests.contains( where: { $0.identifier == self.staticNotificationIdentifier }) else {
                    // The reason why we're cancelling the background task if there's no static notification scheduled is because
                    // it means we've already shown the static notification to the user.  Since iOS doesn't ensure an execution time
                    // for background tasks, we assume this is the case where the static notification was shown before the dynamic
                    // task was run.
                    onError(NotificationSchedulingError.staticNotificationAlreadyDelivered)
                    self.operationQueue.cancelAllOperations()
                    return
                }

                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.staticNotificationIdentifier])
            }

            group.wait()
        }

        let requestData = BlockOperation {
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
                DDLogError("Error fetching blogs list: \(error)")
                return
            }

            guard let blogs = controller.fetchedObjects?.filter({ (blog: Blog) in
                blog.capabilities?["own_site"] as? Bool == true
            }), blogs.count > 0 else {
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

                        onError(error)
                        return
                    }

                    guard let lastResult = timeStats.summaryData.last else {
                        // No stats for this site!  This could mean the site
                        return
                    }

                    timeStats.summaryData
                }
            }
        }

        let scheduleNotification = BlockOperation {
            let group = DispatchGroup()
            group.enter()

            self.scheduleDynamicNotification(views: 5, comments: 10, likes: 15) { result in
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

    private func scheduleDynamicNotification(views: Int, comments: Int, likes: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let title = "Weekly Roundup"
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

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                completion(.failure(error))
                return
            }

            completion(.success(()))
        }
    }
}

/// An event handler for background task events.
///
protocol BackgroundTaskEventHandler {
    func handle(_ event: BackgroundTaskEvent)
}

/// The task coordinator.  This is the entry point for registering and scheduling background tasks.
///
class BackgroundTasksCoordinator {

    enum SchedulingError: Error {
        case schedulingFailed(tasksAndErrors: [String: Error])
        case schedulingFailed(task: String, error: Error)
    }

    /// Event handler.  Useful for logging or tracking purposes.
    ///
    private let eventHandler: BackgroundTaskEventHandler

    /// The task scheduler.  It's a weak reference because the scheduler retains the coordinator through the
    ///
    private let scheduler: BGTaskScheduler

    /// The tasks that were registered through this coordinator on initialization.
    ///
    private let registeredTasks: [BackgroundTask]

    /// Default initializer.  Immediately registers the task handlers with the scheduler.
    ///
    /// - Parameters:
    ///     - scheduler: The scheduler to use.
    ///     - tasks: The tasks that this coordinator will manage.
    ///
    init(
        scheduler: BGTaskScheduler = BGTaskScheduler.shared,
        tasks: [BackgroundTask],
        eventHandler: BackgroundTaskEventHandler) {

        self.eventHandler = eventHandler
        self.scheduler = scheduler
        self.registeredTasks = tasks

        for task in tasks {
            scheduler.register(forTaskWithIdentifier: type(of: task).identifier, using: nil) { osTask in

                eventHandler.handle(.start(identifier: type(of: task).identifier))

                osTask.expirationHandler = {
                    eventHandler.handle(.expirationHandlerCalled(identifier: type(of: task).identifier))
                    task.expirationHandler()
                }

                task.run(onError: { error in
                    eventHandler.handle(.error(identifier: type(of: task).identifier, error: error))
                }) { cancelled in
                    eventHandler.handle(.taskCompleted(identifier: type(of: task).identifier, cancelled: cancelled))

                    self.schedule(task) { result in
                        switch result {
                        case .success:
                            eventHandler.handle(.rescheduled(identifier: type(of: task).identifier))
                        case .failure(let error):
                            eventHandler.handle(.error(identifier: type(of: task).identifier, error: error))
                        }

                        osTask.setTaskCompleted(success: !cancelled)
                    }
                }
            }
        }
    }

    /// Schedules the registered tasks.  The reason this step is separated from the registration of the tasks, is that we need
    /// to make sure the task registration completes before the App finishes launching, while scheduling can be taken care
    /// of separately.
    ///
    /// Ref: https://developer.apple.com/documentation/backgroundtasks/bgtaskscheduler
    ///
    func scheduleTasks(completion: (Result<Void, Error>) -> Void) {
        var tasksAndErrors = [String: Error]()

        scheduler.cancelAllTaskRequests()

        for task in registeredTasks {
            schedule(task) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    tasksAndErrors[type(of: task).identifier] = error
                }
            }
        }

        if tasksAndErrors.isEmpty {
            completion(.success(()))
        } else {
            completion(.failure(SchedulingError.schedulingFailed(tasksAndErrors: tasksAndErrors)))
        }
    }

    func schedule(_ task: BackgroundTask, completion: @escaping (Result<Void, Error>) -> Void) {
        task.request { result in
            switch result {
            case .success(let request):
                do {
                    try self.scheduler.submit(request)
                    task.scheduled(completion: completion)
                } catch {
                    completion(.failure(SchedulingError.schedulingFailed(task: type(of: task).identifier, error: error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
