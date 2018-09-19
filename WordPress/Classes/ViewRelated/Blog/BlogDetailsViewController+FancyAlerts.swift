private var alertWorkItem: DispatchWorkItem?

extension BlogDetailsViewController {

    @objc func startAlertTimer() {
        let newWorkItem = DispatchWorkItem { [weak self] in
            self?.showNotificationPrimerAlert()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: newWorkItem)
        alertWorkItem = newWorkItem
    }

    @objc func stopAlertTimer() {
        alertWorkItem?.cancel()
        alertWorkItem = nil
    }

    fileprivate var noPresentedViewControllers: Bool {
        guard let window = WordPressAppDelegate.sharedInstance().window,
            let rootViewController = window.rootViewController,
            rootViewController.presentedViewController != nil else {
            return true
        }
        return false
    }

    func showNotificationPrimerAlert() {
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
}
