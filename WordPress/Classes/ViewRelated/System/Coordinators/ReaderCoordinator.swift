import UIKit

@objc
class ReaderCoordinator: NSObject {

    func showReaderTab() {
        WPTabBarController.sharedInstance().showReaderTab()
    }
}
