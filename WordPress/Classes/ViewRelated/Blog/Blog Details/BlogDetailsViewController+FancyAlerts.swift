import Gridicons

private var alertWorkItem: DispatchWorkItem?
private var observer: NSObjectProtocol?

extension BlogDetailsViewController {

    @objc static let bottomPaddingForQuickStartNotices: CGFloat = 80.0

    @objc func startObservingQuickStart() {
        observer = NotificationCenter.default.addObserver(forName: .QuickStartTourElementChangedNotification, object: nil, queue: nil) { [weak self] (notification) in
            guard self?.blog.managedObjectContext != nil else {
                return
            }
            self?.toggleSpotlightForSiteTitle()
            self?.refreshSiteIcon()
            self?.configureTableViewData()
            self?.reloadTableViewPreservingSelection()
            if let element = QuickStartTourElement(rawValue: QuickStartTourGuide.shared.currentElementInt()) {
                self?.scroll(to: element)
            }

            if let info = notification.userInfo?[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement {
                switch info {
                case .noSuchElement:
                    self?.additionalSafeAreaInsets = UIEdgeInsets.zero
                case .siteIcon, .siteTitle:
                    // handles the padding in case the element is not in the table view
                    self?.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: BlogDetailsViewController.bottomPaddingForQuickStartNotices, right: 0)
                case .viewSite:
                    guard let self = self,
                        let navigationController = self.navigationController,
                        navigationController.visibleViewController != self else {
                        return
                    }

                    self.dismiss(animated: true) {
                        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                        self.shouldScrollToViewSite = true
                        navigationController.popToViewController(self, animated: true)
                    }
                default:
                    break
                }
            }
        }
    }

    @objc func stopObservingQuickStart() {
        NotificationCenter.default.removeObserver(observer as Any)
    }

    @objc func startAlertTimer() {
        guard shouldStartAlertTimer else {
            return
        }
        let newWorkItem = DispatchWorkItem { [weak self] in
            self?.showNoticeOrAlertAsNeeded()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: newWorkItem)
        alertWorkItem = newWorkItem
    }
    // do not start alert timer if the themes modal is still being presented
    private var shouldStartAlertTimer: Bool {
        !((self.presentedViewController as? UINavigationController)?.visibleViewController is WebKitViewController)
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

        if QuickStartTourGuide.shared.shouldShowUpgradeToV2Notice(for: blog) {
            showUpgradeToV2Alert(for: blog)

            QuickStartTourGuide.shared.didShowUpgradeToV2Notice(for: blog)
        } else if let tourToSuggest = QuickStartTourGuide.shared.tourToSuggest(for: blog) {
            QuickStartTourGuide.shared.suggest(tourToSuggest, for: blog)
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
        present(navigationViewController, animated: true) { [weak self] in
            self?.toggleSpotlightOnHeaderView()
        }

        QuickStartTourGuide.shared.visited(.checklist)
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
        let customizeDetailCount = QuickStartTourGuide.shared.countChecklistCompleted(in: QuickStartTourGuide.customizeListTours, for: blog)
        customizeRow.detail = String(format: detailFormatStr, customizeDetailCount, QuickStartTourGuide.customizeListTours.count)
        customizeRow.quickStartTitleState = customizeDetailCount == QuickStartTourGuide.customizeListTours.count ? .completed : .customizeIncomplete

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
        let growDetailCount = QuickStartTourGuide.shared.countChecklistCompleted(in: QuickStartTourGuide.growListTours, for: blog)
        growRow.detail = String(format: detailFormatStr, growDetailCount, QuickStartTourGuide.growListTours.count)
        growRow.quickStartTitleState = growDetailCount == QuickStartTourGuide.growListTours.count ? .completed : .growIncomplete

        let sectionTitle = NSLocalizedString("Next Steps", comment: "Table view title for the quick start section.")
        let section = BlogDetailsSection(title: sectionTitle, andRows: [customizeRow, growRow], category: .quickStart)
        section.showQuickStartMenu = true
        return section
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
