import UIKit

extension MySiteViewController {

    func startObservingQuickStart() {
        NotificationCenter.default.addObserver(forName: .QuickStartTourElementChangedNotification, object: nil, queue: nil) { [weak self] (notification) in

            if let info = notification.userInfo,
               let element = info[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement {

                switch element {
                case .noSuchElement:
                    self?.additionalSafeAreaInsets = .zero
                case .siteIcon, .siteTitle, .viewSite:
                    self?.scrollView.scrollToTop(animated: true)

                    self?.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: Constants.bottomPaddingForQuickStartNotices, right: 0)
                case .siteMenu:
                    self?.siteMenuSpotlightIsShown = true

                    self?.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: Constants.bottomPaddingForQuickStartNotices, right: 0)
                default:
                    break
                }
            }
        }
    }

    private enum Constants {
        static let bottomPaddingForQuickStartNotices: CGFloat = 80.0
    }
}
