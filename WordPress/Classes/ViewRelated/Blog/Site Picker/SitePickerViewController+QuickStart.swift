import Foundation

private var alertWorkItem: DispatchWorkItem?
private var observer: NSObjectProtocol?

extension SitePickerViewController {

    // do not start alert timer if the themes modal is still being presented
    private var shouldStartAlertTimer: Bool {
        !((self.presentedViewController as? UINavigationController)?.visibleViewController is WebKitViewController)
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
