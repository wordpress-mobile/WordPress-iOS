import Foundation


extension UIDevice {
    @objc public class func isPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    @objc public var systemMajorVersion: Int {
        let versionString = UIDevice.current.systemVersion as NSString
        return versionString.integerValue
    }

    @objc public func isSimulator() -> Bool {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return true
        #else
            return false
        #endif
    }
}
