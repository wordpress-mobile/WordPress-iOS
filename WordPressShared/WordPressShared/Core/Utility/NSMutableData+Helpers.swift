import Foundation


/// Encapsulates all of the NSMutableData Helper Methods.
///
extension NSMutableData {

    /// Encodes a raw String into UTF8, and appends it to the current instance.
    ///
    /// - Parameter string: The raw String to be UTF8-Encoded, and appended
    ///
    @objc public func appendString(_ string: String) {
        if let data = string.data(using: String.Encoding.utf8) {
            append(data)
        }
    }
}
