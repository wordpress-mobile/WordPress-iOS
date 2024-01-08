import UIKit

/// Helps manage the flow related to Blogging Prompts.
///
@objc class BloggingPromptCoordinator: NSObject {

    private let promptsServiceFactory: BloggingPromptsServiceFactory
    private let scheduler: PromptRemindersScheduler

    enum Errors: Error {
        case invalidSite
        case promptNotFound
        case unknown
    }

    /// Defines the interaction sources for Blogging Prompts.
    enum Source {
        case dashboard
        case featureIntroduction
        case actionSheetHeader
        case promptNotification
        case promptStaticNotification

        var editorEntryPoint: PostEditorEntryPoint {
            switch self {
            case .dashboard:
                return .dashboard
            case .featureIntroduction:
                return .bloggingPromptsFeatureIntroduction
            case .actionSheetHeader:
                return .bloggingPromptsActionSheetHeader
            case .promptNotification, .promptStaticNotification:
                return .bloggingPromptsNotification
            }
        }
    }

    // MARK: Public Method

    init(bloggingPromptsServiceFactory: BloggingPromptsServiceFactory = .init()) {
        self.promptsServiceFactory = bloggingPromptsServiceFactory
        self.scheduler = PromptRemindersScheduler(bloggingPromptsServiceFactory: bloggingPromptsServiceFactory)
    }

    /// Present the post creation flow to answer the prompt with `promptID`.
    ///
    /// - Note: When the `promptID` is nil, the coordinator will attempt to fetch and use today's prompt from remote.
    ///
    /// - Parameters:
    ///   - viewController: The view controller that will present the post creation flow.
    ///   - promptID: The ID of the blogging prompt. When nil, the method will use today's prompt.
    ///   - blog: The blog associated with the blogging prompt.
    ///   - completion: Closure invoked after the post creation flow is presented.
    func showPromptAnsweringFlow(from viewController: UIViewController,
                                 promptID: Int? = nil,
                                 blog: Blog,
                                 source: Source,
                                 completion: (() -> Void)? = nil) {
        fetchPrompt(with: promptID, blog: blog) { result in
            guard case .success(let prompt) = result else {
                completion?()
                return
            }

            // Present the post creation flow.
            let editor = EditPostViewController(blog: blog, prompt: prompt)
            editor.modalPresentationStyle = .fullScreen
            editor.entryPoint = source.editorEntryPoint
            viewController.present(editor, animated: true)
            completion?()
        }
    }

    /// Replaces the current blogging prompt notifications with a new timeframe that starts from today.
    ///
    /// - Parameters:
    ///   - blog: The blog associated with the blogging prompt.
    ///   - completion: Closure invoked after the scheduling process completes.
    func updatePromptsIfNeeded(for blog: Blog, completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard FeatureFlag.bloggingPrompts.enabled,
              let service = self.promptsServiceFactory.makeService(for: blog) else {
            return
        }

        // fetch and update local prompts.
        service.fetchPrompts { [weak self] _ in
            // try to reschedule prompts if the user has any active reminders.
            self?.reschedulePromptRemindersIfNeeded(for: blog) {
                completion?(.success(()))
            }
        } failure: { error in
            completion?(.failure(error ?? Errors.unknown))
        }
    }
}

// MARK: Private Helpers

private extension BloggingPromptCoordinator {
    /// Replaces the current blogging prompt notifications with a new timeframe that starts from today.
    ///
    /// Prompt notifications will eventually run out, so unless the user has explicitly disabled the reminders,
    /// we'll need to keep rescheduling the local notifications so the reminders can keep coming.
    ///
    /// - Parameters:
    ///   - blog: The blog associated with the blogging prompt.
    ///   - completion: Closure invoked after the scheduling process completes.
    func reschedulePromptRemindersIfNeeded(for blog: Blog, completion: @escaping () -> Void) {
        guard let context = blog.managedObjectContext else {
            completion()
            return
        }

        context.perform {
            self.reschedulePromptRemindersIfNeeded(for: blog, in: context, completion: completion)
        }
    }

    private func reschedulePromptRemindersIfNeeded(for blog: Blog, in context: NSManagedObjectContext, completion: @escaping () -> Void) {
        assert(blog.managedObjectContext == context)

        guard let settings = try? BloggingPromptSettings.of(blog),
              let activeWeekdays = settings.reminderDays?.getActiveWeekdays(),
              let reminderTimeDate = settings.reminderTimeDate(),
              settings.promptRemindersEnabled
        else {
            completion()
            return
        }

        // IMPORTANT: Ensure that push authorization is already granted before rescheduling.
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] notificationSettings in
            guard let self = self,
                  notificationSettings.authorizationStatus == .authorized else {
                completion()
                return
            }

            context.perform {
                // Reschedule the prompt reminders.
                let schedule = BloggingRemindersScheduler.Schedule.weekdays(activeWeekdays)
                self.scheduler.schedule(schedule, for: blog, time: reminderTimeDate) { result in
                    completion()
                }
            }
        }
    }

    func fetchPrompt(with localPromptID: Int? = nil, blog: Blog, completion: @escaping (Result<BloggingPrompt, Error>) -> Void) {
        guard let service = promptsServiceFactory.makeService(for: blog) else {
            completion(.failure(Errors.invalidSite))
            return
        }

        // When the promptID is specified, there may be a cached prompt available.
        if let promptID = localPromptID,
           let prompt = service.loadPrompt(with: promptID, in: blog) {
            completion(.success(prompt))
            return
        }

        // Otherwise, try to fetch today's prompt from remote.
        service.fetchTodaysPrompt { prompt in
            guard let prompt = prompt else {
                completion(.failure(Errors.promptNotFound))
                return
            }
            completion(.success(prompt))

        } failure: { error in
            completion(.failure(error ?? Errors.unknown))
        }
    }

}
