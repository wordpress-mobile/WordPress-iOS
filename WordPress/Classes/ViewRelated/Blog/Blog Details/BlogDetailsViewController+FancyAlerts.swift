import Gridicons

private var alertWorkItem: DispatchWorkItem?
private var observer: NSObjectProtocol?

extension BlogDetailsViewController {

    @objc func startObservingQuickStart() {
        observer = NotificationCenter.default.addObserver(forName: .QuickStartTourElementChangedNotification, object: nil, queue: nil) { [weak self] (notification) in
            guard self?.blog.managedObjectContext != nil else {
                return
            }
            self?.configureTableViewData()
            self?.reloadTableViewPreservingSelection()

            if let info = notification.userInfo?[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement {
                switch info {
                case .stats, .mediaScreen:
                    guard QuickStartTourGuide.shared.entryPointForCurrentTour == .blogDetails else {
                        return
                    }
                    fallthrough
                case .pages, .sharing:
                    self?.scroll(to: info)
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
            quickStartGuide.showCongratsNoticeIfNeeded(for: blog)
            return
        }

        if quickStartGuide.tourInProgress {
            // If tour is in progress, show notice regardless of quickstart is shown in dashboard or my site
            quickStartGuide.suggest(tourToSuggest, for: blog)
        } else {
            guard shouldShowQuickStartChecklist() else {
                return
            }
            // Show initial notice only if quick start is shown in my site
            quickStartGuide.suggest(tourToSuggest, for: blog)
        }
    }

    @objc func shouldShowDashboard() -> Bool {
        isDashboardEnabled()
    }

    @objc func shouldShowQuickStartChecklist() -> Bool {
        !isDashboardEnabled() && QuickStartTourGuide.quickStartEnabled(for: blog)
    }

    @objc func showQuickStart() {
        let currentCollections = QuickStartFactory.collections(for: blog)
        guard let collectionToShow = currentCollections.first else {
            return
        }
        let checklist = QuickStartChecklistViewController(blog: blog, collection: collectionToShow)
        let navigationViewController = UINavigationController(rootViewController: checklist)
        present(navigationViewController, animated: true)

        QuickStartTourGuide.shared.visited(.checklist)

        createButtonCoordinator?.hideCreateButtonTooltip()
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
