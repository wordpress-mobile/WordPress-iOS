import UIKit

private var observer: NSObjectProtocol?

extension MySiteViewController {

    func startObservingQuickStart() {
        observer = NotificationCenter.default.addObserver(forName: .QuickStartTourElementChangedNotification, object: nil, queue: nil) { [weak self] (notification) in

            if let info = notification.userInfo,
               let element = info[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement {
                switch element {
                case .siteMenu:
                    self?.siteMenuSpotlightIsShown = true
                default:
                    self?.siteMenuSpotlightIsShown = false
                }
            }

        }
    }

}
