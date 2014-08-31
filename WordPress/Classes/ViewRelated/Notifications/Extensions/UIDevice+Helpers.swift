import Foundation


extension UIDevice
{
    public class func isPad() -> Bool {
        return UIDevice.currentDevice().userInterfaceIdiom == .Pad
    }

    public class func isOS8() -> Bool {
        let systemVersion = UIDevice.currentDevice().systemVersion as NSString
        return systemVersion.doubleValue >= 8.0
    }
}
