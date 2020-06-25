import Gridicons

private var alertWorkItem: DispatchWorkItem?
private var observer: NSObjectProtocol?

extension BlogDetailsViewController {
    @objc func startObservingQuickStart() {
        observer = NotificationCenter.default.addObserver(forName: .QuickStartTourElementChangedNotification, object: nil, queue: nil) { [weak self] (notification) in
            guard self?.blog.managedObjectContext != nil else {
                return
            }
            self?.toggleSpotlightForSiteTitle()
            self?.refreshSiteIcon()
            self?.configureTableViewData()
            self?.reloadTableViewPreservingSelection()
            if let index = QuickStartTourGuide.find()?.currentElementInt(),
                let element = QuickStartTourElement(rawValue: index) {
                self?.scroll(to: element)
            }
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
        guard let window = WordPressAppDelegate.shared?.window,
            let rootViewController = window.rootViewController,
            rootViewController.presentedViewController != nil else {
            return true
        }
        return false
    }

    private func showNoticeOrAlertAsNeeded() {
        guard let tourGuide = QuickStartTourGuide.find() else {
            return
        }

        if shouldShowCreateButtonAnnouncement() {
            showCreateButtonAnnouncementAlert()
        } else if tourGuide.shouldShowUpgradeToV2Notice(for: blog) {
            showUpgradeToV2Alert(for: blog)

            tourGuide.didShowUpgradeToV2Notice(for: blog)
        } else if let tourToSuggest = tourGuide.tourToSuggest(for: blog) {
            tourGuide.suggest(tourToSuggest, for: blog)
        }
    }

    @objc func shouldShowQuickStartChecklist() -> Bool {
        return QuickStartTourGuide.shouldShowChecklist(for: blog)
    }

    @objc func showQuickStartCustomize() {
        showQuickStart(with: .customize)
    }

    @objc func showQuickStartGrow() {
        showQuickStart(with: .grow)
    }

    private func showQuickStart(with type: QuickStartType) {
        let checklist = QuickStartChecklistViewController(blog: blog, type: type)
        let navigationViewController = UINavigationController(rootViewController: checklist)
        present(navigationViewController, animated: true, completion: nil)

        QuickStartTourGuide.find()?.visited(.checklist)
    }

    @objc func quickStartSectionViewModel() -> BlogDetailsSection {
        let detailFormatStr = NSLocalizedString("%1$d of %2$d completed",
                                                comment: "Format string for displaying number of completed quickstart tutorials. %1$d is number completed, %2$d is total number of tutorials available.")

        let customizeTitle = NSLocalizedString("Customize Your Site",
                                               comment: "Name of the Quick Start list that guides users through a few tasks to customize their new website.")
        let customizeHint = NSLocalizedString("A series of steps showing you how to add a theme, site icon and more.",
                                              comment: "A VoiceOver hint to explain what the user gets when they select the 'Customize Your Site' button.")
        let customizeRow = BlogDetailsRow(title: customizeTitle,
                                          identifier: QuickStartListTitleCell.reuseIdentifier,
                                          accessibilityIdentifier: "Customize Your Site Row",
                                          accessibilityHint: customizeHint,
                                          image: .gridicon(.customize)) { [weak self] in
                                            self?.showQuickStartCustomize()
                                           }
        customizeRow.quickStartIdentifier = .checklist
        customizeRow.showsSelectionState = false
         if let customizeDetailCount = QuickStartTourGuide.find()?.countChecklistCompleted(in: QuickStartTourGuide.customizeListTours, for: blog) {
             customizeRow.detail = String(format: detailFormatStr, customizeDetailCount, QuickStartTourGuide.customizeListTours.count)
             customizeRow.quickStartTitleState = customizeDetailCount == QuickStartTourGuide.customizeListTours.count ? .completed : .customizeIncomplete
        }

        let growTitle = NSLocalizedString("Grow Your Audience",
                                          comment: "Name of the Quick Start list that guides users through a few tasks to customize their new website.")
        let growHint = NSLocalizedString("A series of steps to assist with growing your site's audience.",
                                         comment: "A VoiceOver hint to explain what the user gets when they select the 'Grow Your Audience' button.")
        let growRow = BlogDetailsRow(title: growTitle,
                                     identifier: QuickStartListTitleCell.reuseIdentifier,
                                     accessibilityIdentifier: "Grow Your Audience Row",
                                     accessibilityHint: growHint,
                                     image: .gridicon(.multipleUsers)) { [weak self] in
                                        self?.showQuickStartGrow()
                                     }
        growRow.quickStartIdentifier = .checklist
        growRow.showsSelectionState = false
         if let growDetailCount = QuickStartTourGuide.find()?.countChecklistCompleted(in: QuickStartTourGuide.growListTours, for: blog) {
             growRow.detail = String(format: detailFormatStr, growDetailCount, QuickStartTourGuide.growListTours.count)
             growRow.quickStartTitleState = growDetailCount == QuickStartTourGuide.growListTours.count ? .completed : .growIncomplete
        }

        let sectionTitle = NSLocalizedString("Next Steps", comment: "Table view title for the quick start section.")
        let section = BlogDetailsSection(title: sectionTitle, andRows: [customizeRow, growRow], category: .quickStart)
        section.showQuickStartMenu = true
        return section
    }

    private func shouldShowCreateButtonAnnouncement() -> Bool {
        return AppRatingUtility.shared.didUpgradeVersion && !UserDefaults.standard.createButtonAlertWasDisplayed
    }

    private func showCreateButtonAnnouncementAlert() {
        guard noPresentedViewControllers else {
            return
        }

        UserDefaults.standard.createButtonAlertWasDisplayed = true

        let alert = FancyAlertViewController.makeCreateButtonAnnouncementAlertController { [weak self] (controller) in
            controller.dismiss(animated: true)
            if let url = URL(string: "https://wordpress.com/blog/2020/06/01/improved-navigation-in-the-wordpress-apps/") {
                let webViewController = WebViewControllerFactory.controller(url: url)
                let navController = LightNavigationController(rootViewController: webViewController)
                self?.tabBarController?.present(navController, animated: true)
            }
        }
        alert.modalPresentationStyle = .custom
        alert.transitioningDelegate = self
        tabBarController?.present(alert, animated: true)
    }

    private func showUpgradeToV2Alert(for blog: Blog) {
        guard noPresentedViewControllers else {
            return
        }

        let alert = FancyAlertViewController.makeQuickStartUpgradeToV2AlertController(blog: blog)
        alert.modalPresentationStyle = .custom
        alert.transitioningDelegate = self
        tabBarController?.present(alert, animated: true)

        WPAnalytics.track(.quickStartMigrationDialogViewed)
    }
}
