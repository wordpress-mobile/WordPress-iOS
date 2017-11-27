import Foundation


extension UIScreen {
    @objc public func screenWidthAtCurrentOrientation() -> CGFloat {
        let screenBounds = UIScreen.main.bounds
        if UIDevice.isOS8() {
            return screenBounds.width
        }

        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        return statusBarOrientation.isPortrait ? screenBounds.width : screenBounds.height
    }
}
