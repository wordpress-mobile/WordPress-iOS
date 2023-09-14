import UIKit

extension MySiteViewController {

    func startObservingQuickStart() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleQuickStartTourElementChangedNotification(_:)), name: .QuickStartTourElementChangedNotification, object: nil)
    }

    @objc private func handleQuickStartTourElementChangedNotification(_ notification: Foundation.Notification) {
        guard let info = notification.userInfo,
              let element = info[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement
        else {
            return
        }

        switch element {
        case .siteIcon, .siteTitle, .viewSite, .pages, .stats, .mediaScreen, .sharing:
            scrollView.scrollToTop(animated: true)
        default:
            break
        }

        switch element {
        case .noSuchElement, .newpost:
            additionalSafeAreaInsets = .zero

        case .siteIcon, .siteTitle, .viewSite, .siteMenu, .pages, .sharing, .stats, .readerTab, .notifications, .mediaScreen:
            additionalSafeAreaInsets = Constants.quickStartNoticeInsets

        default:
            break
        }
    }

    private enum Constants {
        static let quickStartNoticeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
    }
}
