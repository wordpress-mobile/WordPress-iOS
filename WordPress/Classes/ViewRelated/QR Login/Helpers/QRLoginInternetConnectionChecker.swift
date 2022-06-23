import Foundation

struct QRLoginInternetConnectionChecker: QRLoginConnectionChecker {
    var connectionAvailable: Bool {
        let appDelegate = WordPressAppDelegate.shared

        guard let connectionAvailable = appDelegate?.connectionAvailable, connectionAvailable == true else {
            return false
        }

        return true
    }
}
