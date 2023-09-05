import BackgroundTasks

protocol BackgroundTask {
    static var identifier: String { get }

    // MARK: - Scheduling

    /// Returns a schedule request for this task, so it can be scheduled by the coordinator.
    ///
    func nextRunDate() -> Date?

    /// This method allows the task to perform extra processing after scheduling the BG Task.
    ///
    func didSchedule(completion: @escaping (Result<Void, Error>) -> Void)

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

/// Events during the execution of background tasks.
///
enum BackgroundTaskEvent {
    case start(identifier: String)
    case error(identifier: String, error: Error)
    case expirationHandlerCalled(identifier: String)
    case taskCompleted(identifier: String, cancelled: Bool)
    case rescheduled(identifier: String)
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
            // https://github.com/wordpress-mobile/WordPress-iOS/issues/18156
            // we still need to register to handle the old identifier = "org.wordpress.bgtask.weeklyroundup"
            // in order to handle previously scheduled app refresh tasks before this enhancement.
            //
            // When the old identifier AppRefreshTask is triggered this will re-schedule using the new identifier going forward
            // at some point in future when this FeatureFlag is removed and most users are on new version of app this can be removed
            scheduler.register(forTaskWithIdentifier: WeeklyRoundupBackgroundTask.Constants.taskIdentifier, using: nil) { osTask in
                self.schedule(task) { [weak self] result in
                    self?.taskScheduledCompleted(osTask, identifier: type(of: task).identifier, result: result, cancelled: false)
                }
            }

            scheduler.register(forTaskWithIdentifier: type(of: task).identifier, using: nil) { osTask in
                guard JetpackNotificationMigrationService.shared.shouldPresentNotifications() else {
                    osTask.setTaskCompleted(success: false)
                    eventHandler.handle(.taskCompleted(identifier: type(of: task).identifier, cancelled: true))
                    return
                }

                eventHandler.handle(.start(identifier: type(of: task).identifier))

                osTask.expirationHandler = {
                    eventHandler.handle(.expirationHandlerCalled(identifier: type(of: task).identifier))
                    task.expirationHandler()
                }

                task.run(onError: { error in
                    eventHandler.handle(.error(identifier: type(of: task).identifier, error: error))
                }) { cancelled in
                    eventHandler.handle(.taskCompleted(identifier: type(of: task).identifier, cancelled: cancelled))

                    self.schedule(task) { [weak self] result in
                        self?.taskScheduledCompleted(osTask, identifier: type(of: task).identifier, result: result, cancelled: cancelled)
                    }
                }
            }
        }
    }

    func taskScheduledCompleted(_ osTask: BGTask, identifier: String, result: Result<Void, Error>, cancelled: Bool) {
        switch result {
        case .success:
            eventHandler.handle(.rescheduled(identifier: identifier))
        case .failure(let error):
            eventHandler.handle(.error(identifier: identifier, error: error))
        }

        osTask.setTaskCompleted(success: !cancelled)
    }

    /// Schedules the registered tasks.  The reason this step is separated from the registration of the tasks, is that we need
    /// to make sure the task registration completes before the App finishes launching, while scheduling can be taken care
    /// of separately.
    ///
    /// Ref: https://developer.apple.com/documentation/backgroundtasks/bgtaskscheduler
    ///
    func scheduleTasks(completion: @escaping (Result<Void, Error>) -> Void) {
        var tasksAndErrors = [String: Error]()

        scheduler.getPendingTaskRequests { [weak self] scheduledRequests in
            guard let self = self else {
                return
            }

            let tasksToSchedule = self.registeredTasks.filter { task in
                !scheduledRequests.contains { request in
                    request.identifier == type(of: task).identifier
                }
            }

            for task in tasksToSchedule {
                self.schedule(task) { result in
                    if case .failure(let error) = result {
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
    }

    func schedule(_ task: BackgroundTask, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let nextDate = task.nextRunDate() else {
            return
        }

        let request = createBGTaskRequest(task, beginDate: nextDate)

        do {
            try self.scheduler.submit(request)
            task.didSchedule(completion: completion)
        } catch {
            completion(.failure(SchedulingError.schedulingFailed(task: type(of: task).identifier, error: error)))
        }
    }

    func createBGTaskRequest(_ task: BackgroundTask, beginDate: Date) -> BGTaskRequest {
        let bgProcessingTaskRequest = BGProcessingTaskRequest(identifier: type(of: task).identifier)
        bgProcessingTaskRequest.requiresNetworkConnectivity = true
        bgProcessingTaskRequest.earliestBeginDate = beginDate
        return bgProcessingTaskRequest
    }


    // MARK: - Querying Data

    func getScheduledExecutionDate(taskIdentifier: String, completion: @escaping (Date?) -> Void) {
        scheduler.getPendingTaskRequests { requests in
            guard let weeklyRoundupRequest = requests.first(where: { $0.identifier == taskIdentifier }) else {
                completion(nil)
                return
            }

            return completion(weeklyRoundupRequest.earliestBeginDate)
        }
    }
}
