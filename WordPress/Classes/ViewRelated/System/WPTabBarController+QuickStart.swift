private var spotlightView: QuickStartSpotlightView?
private let spotlightViewOffset: CGFloat = -5.0
private var quickStartObserver: NSObject?

extension WPTabBarController {
    @objc func startWatchingQuickTours() {
        let observer = NotificationCenter.default.addObserver(forName: .QuickStartTourElementChangedNotification, object: nil, queue: nil) { [weak self] (notification) in
            spotlightView?.removeFromSuperview()
            spotlightView = nil

            guard let userInfo = notification.userInfo,
                let element = userInfo[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement,
                [.newpost, .readerTab].contains(element),
                let tabBar = self?.tabBar else {
                    return
            }

            let newSpotlight = QuickStartSpotlightView()
            tabBar.addSubview(newSpotlight)

            let x: CGFloat
            if element == .newpost {
                x = tabBar.bounds.size.width / 2.0
            } else {
                x = tabBar.bounds.size.width * 0.40 - newSpotlight.frame.size.width
            }
            newSpotlight.frame = CGRect(x: x, y: spotlightViewOffset, width: newSpotlight.frame.width, height: newSpotlight.frame.height)
            spotlightView = newSpotlight
        }

        quickStartObserver = observer as? NSObject
    }

    @objc func alertQuickStartThatWriteWasTapped() {
        QuickStartTourGuide.find()?.visited(.newpost)
    }

    @objc func alertQuickStartThatReaderWasTapped() {
        QuickStartTourGuide.find()?.visited(.readerTab)
    }

    @objc func stopWatchingQuickTours() {
        NotificationCenter.default.removeObserver(quickStartObserver as Any)
        quickStartObserver = nil
    }
}
