import Foundation


extension UIDevice {
    public class func isPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    public class func isPhone() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    public class func isOS8() -> Bool {
        let systemVersion = UIDevice.current.systemVersion as NSString
        return systemVersion.doubleValue >= 8.0
    }
}
