import Foundation


// MARK: - Dictionary Helper Methods
//
extension Dictionary {
    /// This method attempts to convert a given value into a String, if it's not already the
    /// case. Initial implementation supports only NSNumber. This is meant for bulletproof parsing,
    /// in which a String value might be serialized, backend side, as a Number.
    ///
    /// - Parameter key: The key to retrieve.
    ///
    /// - Returns: Value as a String (when possible!)
    ///
    func valueAsString(forKey key: Key) -> String? {
        let value = self[key]
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number.description
        default:
            return nil
        }
    }
}
