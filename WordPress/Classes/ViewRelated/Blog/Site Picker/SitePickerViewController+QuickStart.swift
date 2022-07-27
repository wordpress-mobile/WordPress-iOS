import Foundation

private var alertWorkItem: DispatchWorkItem?

extension SitePickerViewController {

    // do not start alert timer if the themes modal is still being presented
    private var shouldStartAlertTimer: Bool {
        !((self.presentedViewController as? UINavigationController)?.visibleViewController is WebKitViewController)
    }

    func startObservingQuickStart() {
        NotificationCenter.default.addObserver(forName: .QuickStartTourElementChangedNotification, object: nil, queue: nil) { [weak self] (notification) in
            guard self?.blog.managedObjectContext != nil else {
                return
            }

            self?.blogDetailHeaderView.toggleSpotlightOnSiteTitle()
            self?.blogDetailHeaderView.toggleSpotlightOnSiteUrl()
            self?.blogDetailHeaderView.refreshIconImage()
        }
    }

    func stopObservingQuickStart() {
        NotificationCenter.default.removeObserver(self)
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
        blogDetailHeaderView.toggleSpotlightOnSiteUrl()
        blogDetailHeaderView.toggleSpotlightOnSiteIcon()
    }

    private func showNoticeAsNeeded() {
        if let tourToSuggest = QuickStartTourGuide.shared.tourToSuggest(for: blog) {
            QuickStartTourGuide.shared.suggest(tourToSuggest, for: blog)
        }
    }
}
