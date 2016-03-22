import Foundation


/// Encapsulates all of the NSMutableData Helper Methods.
///
extension NSMutableData {
    
    /// Encodes a raw String into UTF8, and appends it to the current instance.
    ///
    /// - Parameters:
    ///     - string: The raw String to be UTF8-Encoded, and appended
    ///
    func appendString(string: String) {
        if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
            appendData(data)
        }
    }
}
