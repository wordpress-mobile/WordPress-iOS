import Foundation


extension UIDevice {
    @objc public class func isPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    @objc public class func isPhone() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    @objc public class func isOS8() -> Bool {
        let systemVersion = UIDevice.current.systemVersion as NSString
        return systemVersion.doubleValue >= 8.0
    }

    @objc public var systemMajorVersion: Int {
        let versionString = UIDevice.current.systemVersion as NSString
        return versionString.integerValue
    }
}
