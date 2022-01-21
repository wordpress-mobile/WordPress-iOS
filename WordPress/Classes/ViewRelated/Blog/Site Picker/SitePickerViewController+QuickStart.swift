import Foundation

private var alertWorkItem: DispatchWorkItem?
private var observer: NSObjectProtocol?

extension SitePickerViewController {

    // do not start alert timer if the themes modal is still being presented
    private var shouldStartAlertTimer: Bool {
        !((self.presentedViewController as? UINavigationController)?.visibleViewController is WebKitViewController)
    }

    func startObservingQuickStart() {
        observer = NotificationCenter.default.addObserver(forName: .QuickStartTourElementChangedNotification, object: nil, queue: nil) { [weak self] (notification) in
            guard self?.blog.managedObjectContext != nil else {
                return
            }

            self?.blogDetailHeaderView.toggleSpotlightOnSiteTitle()
            self?.blogDetailHeaderView.refreshIconImage()

            if let info = notification.userInfo?[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement {
                switch info {
                case .noSuchElement:
                    self?.additionalSafeAreaInsets = UIEdgeInsets.zero
                case .siteIcon, .siteTitle:
                    // handles the padding in case the element is not in the table view
                    self?.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: BlogDetailsViewController.bottomPaddingForQuickStartNotices, right: 0)
                default:
                    break
                }
            }
        }
    }

    func stopObservingQuickStart() {
        NotificationCenter.default.removeObserver(observer as Any)
    }

    func startAlertTimer() {
        guard shouldStartAlertTimer else {
            return
        }
        let newWorkItem = DispatchWorkItem { [weak self] in
            self?.showNoticeAsNeeded()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: newWorkItem)
        alertWorkItem = newWorkItem
    }

    func toggleSpotlightOnHeaderView() {
        blogDetailHeaderView.toggleSpotlightOnSiteTitle()
        blogDetailHeaderView.toggleSpotlightOnSiteIcon()
    }

    private func showNoticeAsNeeded() {
        if let tourToSuggest = QuickStartTourGuide.shared.tourToSuggest(for: blog) {
            QuickStartTourGuide.shared.suggest(tourToSuggest, for: blog)
        }
    }
}
