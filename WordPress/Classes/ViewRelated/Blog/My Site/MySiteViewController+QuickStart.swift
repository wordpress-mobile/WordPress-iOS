import UIKit

extension MySiteViewController {

    func startObservingQuickStart() {
        NotificationCenter.default.addObserver(forName: .QuickStartTourElementChangedNotification, object: nil, queue: nil) { [weak self] (notification) in

            if let info = notification.userInfo,
               let element = info[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement {

                self?.siteMenuSpotlightIsShown = element == .siteMenu

                switch element {
                case .noSuchElement, .newpost:
                    self?.additionalSafeAreaInsets = .zero

                case .siteIcon, .siteTitle, .viewSite:
                    self?.scrollView.scrollToTop(animated: true)
                    fallthrough

                case .siteMenu, .pages, .sharing, .stats, .readerTab, .notifications, .mediaScreen:
                    self?.additionalSafeAreaInsets = Constants.quickStartNoticeInsets

                default:
                    break
                }
            }
        }
    }

    private enum Constants {
        static let quickStartNoticeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
    }
}
