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
        let tours = QuickStartTourGuide.checklistTours
        showQuickStart(list: tours)
    }

    @objc func showQuickStartCustomize() {
        let tours = QuickStartTourGuide.customizeListTours
        showQuickStart(list: tours)
    }

    @objc func showQuickStartGrow() {
        let tours = QuickStartTourGuide.growListTours
        showQuickStart(list: tours)
    }

    private func showQuickStart(list: [QuickStartTour]) {
        let checklist = QuickStartChecklistViewController(blog: blog, list: list)
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
}
