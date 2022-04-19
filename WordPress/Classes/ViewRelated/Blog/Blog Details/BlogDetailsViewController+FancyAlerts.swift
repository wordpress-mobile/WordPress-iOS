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
            self?.configureTableViewData()
            self?.reloadTableViewPreservingSelection()

            if let info = notification.userInfo?[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement {
                switch info {
                case .pages, .editHomepage, .sharing, .stats:
                    self?.scroll(to: info)
                case .viewSite:
                    self?.scroll(to: info)

                    guard let self = self,
                        let navigationController = self.navigationController,
                        navigationController.visibleViewController != self else {
                        return
                    }

                    self.dismiss(animated: true) {
                        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                        self.shouldScrollToViewSite = true

                        navigationController.popToRootViewController(animated: true)
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
            self?.showNoticeAsNeeded()
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

    private func showNoticeAsNeeded() {
        let quickStartGuide = QuickStartTourGuide.shared
        guard let tourToSuggest = quickStartGuide.tourToSuggest(for: blog) else {
            return
        }

        if quickStartGuide.tourInProgress {
            // If tour is in progress, show notice regardless of quickstart is shown in dashboard or my site
            quickStartGuide.suggest(tourToSuggest, for: blog)
        }
        else {
            guard shouldShowQuickStartChecklist() else {
                return
            }
            // Show initial notice only if quick start is shown in my site
            quickStartGuide.suggest(tourToSuggest, for: blog)
        }
    }

    @objc func shouldShowDashboard() -> Bool {
        guard let parentVC = parent as? MySiteViewController, isDashboardEnabled() else {
            return false
        }

        return parentVC.mySiteSettings.defaultSection == .dashboard
    }

    @objc func shouldShowQuickStartChecklist() -> Bool {
        if isDashboardEnabled() {

            guard let parentVC = parent as? MySiteViewController else {
                return false
            }

            return QuickStartTourGuide.shouldShowChecklist(for: blog) && parentVC.mySiteSettings.defaultSection == .siteMenu
        }

        return QuickStartTourGuide.shouldShowChecklist(for: blog)
    }

    @objc func showQuickStart() {
        let currentCollections = QuickStartToursCollection.collections(for: blog)
        guard let collectionToShow = currentCollections.first else {
            return
        }
        let checklist = QuickStartChecklistViewController(blog: blog, collection: collectionToShow)
        let navigationViewController = UINavigationController(rootViewController: checklist)
        present(navigationViewController, animated: true)

        QuickStartTourGuide.shared.visited(.checklist)

        createButtonCoordinator?.hideCreateButtonTooltip()    }

    @objc func cancelCompletedToursIfNeeded() {
        if shouldShowQuickStartChecklist() && blog.homepagePageID == nil {
            // Ends the tour Edit Homepage if the site doesn't have a homepage set or uses the blog.
            QuickStartTourGuide.shared.complete(tour: QuickStartEditHomepageTour(), for: blog, postNotification: false)
        }
    }

    @objc func quickStartSectionViewModel() -> BlogDetailsSection {
        let row = BlogDetailsRow()
        row.callback = {}

        let sectionTitle = NSLocalizedString("Next Steps", comment: "Table view title for the quick start section.")
        let section = BlogDetailsSection(title: sectionTitle,
                                         rows: [row],
                                         footerTitle: nil,
                                         category: .quickStart)
        section.showQuickStartMenu = true
        return section
    }
}
