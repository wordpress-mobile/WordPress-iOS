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
    var identifier: String { get }
    //var log: (String) -> Void { get set }
    
    func expirationHandler()
    
    /// Returns a schedule request for this task, so it can be scheduled by the coordinator.
    ///
    func request(completion: @escaping (Result<BGAppRefreshTaskRequest, Error>) -> Void)
    
    /// Runs the background task.
    ///
    /// - Parameters:
    ///     - osTask: the `BGTask` associated with this `BackgroundTask`.
    ///     - event: called for important events in the background tasks execution.
    ///
    func run(onError: @escaping (Error) -> Void, completion: @escaping (_ cancelled: Bool) -> Void)
}

class WeeklyRoundupBackgroundTask: BackgroundTask {
    let identifier = "org.wordpress.bgtask.weeklyroundup"
    private var lastSuccessfulRun = Date()
    private let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    /*
    var logInfo: (String) -> Void
    var logError: (Error) -> Void
    
    init(logInfo: @escaping (String) -> Void, logError: @escaping (String) -> Void) {
        self.logInfo = logInfo
        self.logError = logError
    }*/
    
    enum NotificationSchedulingError: Error {
        case staticNotificationSchedulingError(error: Error)
        case dynamicNotificationSchedulingError(error: Error)
    }
    
    func expirationHandler() {
        operationQueue.cancelAllOperations()
    }
    
    func request(completion: @escaping (Result<BGAppRefreshTaskRequest, Error>) -> Void) {
        // We're scheduling a static notification in case the BG task won't run.
        // This will happen when the App has been explicitly killed by the user as of 2021/08/03,
        // as Apple doesn't let background tasks run in this scenario.
        scheduleStaticNotification { result in
            switch result {
            case .success():
                let request = BGAppRefreshTaskRequest(identifier: self.identifier)
                
                // Run no earlier than 30 secs from now.
                request.earliestBeginDate = Date(timeIntervalSinceNow: 5)
                
                completion(.success(request))
            case .failure(let error):
                completion(.failure(NotificationSchedulingError.staticNotificationSchedulingError(error: error)))
            }
        }
    }
    
    func run(onError: @escaping (Error) -> Void, completion: @escaping (Bool) -> Void) {
        
        // We use multiple operations in series so that if the expiration handler is
        // called, the operation queue will cancell any pending operations, ensuring
        // that the task will exit as soon as possible.
        
        let requestData = BlockOperation {
            // Request data
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

        operationQueue.addOperation(requestData)
        operationQueue.addOperation(scheduleNotification)
        operationQueue.addOperation(completionOperation)
    }
    
    private func scheduleStaticNotification(completion: @escaping (Result<Void, Error>) -> Void) {
        let title = "Weekly Roundup"
        let body = "Your weekly roundup is ready, tap here to see the details!"
        
        scheduleNotification(title: title, body: body, completion: { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(NotificationSchedulingError.staticNotificationSchedulingError(error: error)))
            }
        })
    }
    
    private func scheduleDynamicNotification(views: Int, comments: Int, likes: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let title = "Weekly Roundup"
        let body = "Last week you had \(views) views, \(comments) comments and \(likes) likes."
        
        scheduleNotification(title: title, body: body, completion:  { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(NotificationSchedulingError.dynamicNotificationSchedulingError(error: error)))
            }
        })
    }
    
    private func scheduleNotification(title: String, body: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let content = UNMutableNotificationContent()
        content.title = "Yes this works!"
        content.body = "Last week you had X views, N comments and Z likes."
        content.categoryIdentifier = InteractiveNotificationsManager.NoteCategoryDefinition.weeklyRoundup.rawValue
        
        // We want to make sure all weekly roundup notifications are grouped together.
        content.threadIdentifier = "org.wordpress.notification.threadIdentifier.weeklyRoundup"

        var dateComponents = DateComponents()
        let calendar = Calendar.current
        dateComponents.calendar = calendar
        
        // `DateComponent`'s weekday uses a 1-based index.
        dateComponents.weekday = calendar.component(.weekday, from: Date())
        dateComponents.hour = Date().dateAndTimeComponents().hour
        dateComponents.minute = Date().dateAndTimeComponents().minute
        dateComponents.second = ((Date().dateAndTimeComponents().second ?? 0) + 15) % 60

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
            scheduler.register(forTaskWithIdentifier: task.identifier, using: nil) { osTask in
                
                eventHandler.handle(.start(identifier: task.identifier))
                
                osTask.expirationHandler = {
                    eventHandler.handle(.expirationHandlerCalled(identifier: task.identifier))
                    task.expirationHandler()
                }
                    
                task.run(onError: { error in
                    eventHandler.handle(.error(identifier: task.identifier, error: error))
                }) { cancelled in
                    eventHandler.handle(.taskCompleted(identifier: task.identifier, cancelled: cancelled))
                    
                    self.schedule(task) { result in
                        switch result {
                        case .success:
                            eventHandler.handle(.rescheduled(identifier: task.identifier))
                        case .failure(let error):
                            eventHandler.handle(.error(identifier: task.identifier, error: error))
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
                    tasksAndErrors[task.identifier] = error
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
                } catch {
                    completion(.failure(SchedulingError.schedulingFailed(task: task.identifier, error: error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
