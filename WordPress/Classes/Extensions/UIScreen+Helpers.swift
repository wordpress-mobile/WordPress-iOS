import Foundation


extension UIScreen
{
    public func screenWidthAtCurrentOrientation() -> CGFloat {
        let screenBounds = UIScreen.mainScreen().bounds
        if UIDevice.isOS8() {
            return screenBounds.width
        }
        
        let statusBarOrientation = UIApplication.sharedApplication().statusBarOrientation
        return statusBarOrientation.isPortrait ? screenBounds.width : screenBounds.height
    }
}
