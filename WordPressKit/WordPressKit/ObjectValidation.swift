import Foundation


@objc public extension NSObject {
    
    /// Validate if a class is a valid NSObject and if it's not nil
    ///
    /// - Returns: Bool value
    @objc public func wp_isValidObject() -> Bool {
        return !(self is NSNull)
    }
}


@objc public extension NSString {
    
    ///  Validate if a class is a valid NSString and if it's not nil
    ///
    /// - Returns: Bool value
    @objc public func wp_isValidString() -> Bool {
        return wp_isValidObject() && self != ""
    }
}
