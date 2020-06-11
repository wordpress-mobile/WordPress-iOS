import Foundation
import UIKit

extension Data {
    /// Returns the contained data represented as an hexadecimal string
    ///
    public var hexString: String {
        return reduce("") { (output, byte) -> String in
            output + String(format: "%02x", byte)
        }
    }
}
