import Foundation


extension NSIndexPath
{
    public func toString() -> String {
        // Padding: Make sure that, when sorted, there are no inconsistencies!
        let padding = 20
        return NSString(format: "%\(padding)d-%\(padding)d", section, row) as String
    }
}
