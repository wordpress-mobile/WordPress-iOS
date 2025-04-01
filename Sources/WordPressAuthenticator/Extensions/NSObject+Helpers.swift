import Foundation

// MARK: - NSObject Helper Methods
//
extension NSObject {

    /// Returns the receiver's classname as a string, not including the namespace.
    ///
    class var classNameWithoutNamespaces: String {
        return String(describing: self)
    }
}
