private var alertWorkItem: DispatchWorkItem?
private var observer: NSObjectProtocol?

extension BlogDetailsViewController {
    @objc func startObservingQuickStart() {
        observer = NotificationCenter.default.addObserver(forName: .QuickStartTourElementChangedNotification, object: nil, queue: nil) { [weak self] (notification) in
            self?.configureTableViewData()
            self?.reloadTableViewPreservingSelection()
        }
    }

    @objc func stopObservingQuickStart() {
        NotificationCenter.default.removeObserver(observer as Any)
    }

    @objc func startAlertTimer() {
        let newWorkItem = DispatchWorkItem { [weak self] in
            self?.showNoticeOrAlertAsNeeded()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: newWorkItem)
        alertWorkItem = newWorkItem
    }

    @objc func stopAlertTimer() {
        alertWorkItem?.cancel()
        alertWorkItem = nil
    }

    private var noPresentedViewControllers: Bool {
        guard let window = WordPressAppDelegate.sharedInstance().window,
            let rootViewController = window.rootViewController,
            rootViewController.presentedViewController != nil else {
            return true
        }
        return false
    }

    private func showNoticeOrAlertAsNeeded() {
        if let tourGuide = QuickStartTourGuide.find(),
            let tourToSuggest = tourGuide.tourToSuggest(for: blog) {
            tourGuide.suggest(tourToSuggest, for: blog)
        } else {
            showNotificationPrimerAlert()
        }
    }

    @objc func shouldShowQuickStartChecklist() -> Bool {
        return QuickStartTourGuide.shouldShowChecklist(for: blog)
    }

    @objc func showQuickStartV1() {
        showQuickStart()
    }

    @objc func showQuickStartCustomize() {
        let tasksCompleteScreen = TasksCompleteScreenConfiguration(title: Constants.tasksCompleteScreenTitle,
                                                                   subtitle: Constants.tasksCompleteScreenSubtitle,
                                                                   imageName: "wp-illustration-tasks-complete-site")
        showQuickStart(configuration: QuickStartChecklistConfiguration(title: Constants.customizeYourSite,
                                                                       list: QuickStartTourGuide.customizeListTours,
                                                                       tasksCompleteScreen: tasksCompleteScreen))
    }

    @objc func showQuickStartGrow() {
        let tasksCompleteScreen = TasksCompleteScreenConfiguration(title: Constants.tasksCompleteScreenTitle,
                                                                   subtitle: Constants.tasksCompleteScreenSubtitle,
                                                                   imageName: "wp-illustration-tasks-complete-audience")
        showQuickStart(configuration: QuickStartChecklistConfiguration(title: Constants.growYourAudience,
                                                                       list: QuickStartTourGuide.growListTours,
                                                                       tasksCompleteScreen: tasksCompleteScreen))
    }

    private func showQuickStart(configuration: QuickStartChecklistConfiguration? = nil) {
        let checklist: UIViewController

        if let configuration = configuration, Feature.enabled(.quickStartV2) {
            checklist = QuickStartChecklistViewController(blog: blog, configuration: configuration)
        } else {
            checklist = QuickStartChecklistViewControllerV1(blog: blog)
        }

        navigationController?.showDetailViewController(checklist, sender: self)

        QuickStartTourGuide.find()?.visited(.checklist)
    }

    private func showNotificationPrimerAlert() {
        guard noPresentedViewControllers else {
            return
        }

        guard !UserDefaults.standard.notificationPrimerAlertWasDisplayed else {
            return
        }

        let mainContext = ContextManager.shared.mainContext
        let accountService = AccountService(managedObjectContext: mainContext)

        guard accountService.defaultWordPressComAccount() != nil else {
            return
        }

        PushNotificationsManager.shared.loadAuthorizationStatus { [weak self] (enabled) in
            guard enabled == .notDetermined else {
                return
            }

            UserDefaults.standard.notificationPrimerAlertWasDisplayed = true

            let alert = FancyAlertViewController.makeNotificationPrimerAlertController { (controller) in
                InteractiveNotificationsManager.shared.requestAuthorization {
                    controller.dismiss(animated: true)
                }
            }
            alert.modalPresentationStyle = .custom
            alert.transitioningDelegate = self
            self?.tabBarController?.present(alert, animated: true)
        }
    }

    private enum Constants {
        static let customizeYourSite = NSLocalizedString("Customize Your Site", comment: "Title of the Quick Start Checklist that guides users through a few tasks to customize their new website.")
        static let growYourAudience = NSLocalizedString("Grow Your Audience", comment: "Title of the Quick Start Checklist that guides users through a few tasks to grow the audience of their new website.")
        static let tasksCompleteScreenTitle = NSLocalizedString("All tasks complete", comment: "Title of the congratulation screen that appears when all the tasks are completed")
        static let tasksCompleteScreenSubtitle = NSLocalizedString("Congratulations on completing your list. A job well done.", comment: "Subtitle of the congratulation screen that appears when all the tasks are completed")
    }
}
