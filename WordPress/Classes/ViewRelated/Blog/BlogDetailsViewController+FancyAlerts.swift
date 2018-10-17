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
        NotificationCenter.default.removeObserver(observer)
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
        if shouldSuggestQuickStartTour() {
            suggestAQuickStartTour()
        } else {
            showNotificationPrimerAlert()
        }
    }

    @objc func shouldShowQuickStartChecklist() -> Bool {
        guard Feature.enabled(.quickStart) else {
            return false
        }
        let count = blog.completedQuickStartTours?.count ?? 0
        return count > 0
    }

    private func shouldSuggestQuickStartTour() -> Bool {
        // there must be at least one completed tour for quick start to be enabled
        guard let completedCount = blog.completedQuickStartTours?.count, completedCount > 0 else {
            return false
        }

        let skippedCount = blog.skippedQuickStartTours?.count ?? 0

        // don't suggest a tour if they've completed them all or skipped the rest
        guard completedCount + skippedCount < QuickStartTourGuide.checklistTours.count else {
            return false
        }

        // don't suggest a tour if they've skipped the max
        guard skippedCount < Constants.maxSkippedTours else {
            return false
        }

        return true
    }

    private func suggestAQuickStartTour() {
        guard let tourGuide = QuickStartTourGuide.find() else {
            return
        }
        let tour = QuickStartViewTour()
        tourGuide.suggest(tour, for: blog)
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
                    controller.dismiss(animated: true, completion: nil)
                }
            }
            alert.modalPresentationStyle = .custom
            alert.transitioningDelegate = self
            self?.tabBarController?.present(alert, animated: true, completion: nil)
        }
    }

    private struct Constants {
        static let maxSkippedTours = 3
    }
}
