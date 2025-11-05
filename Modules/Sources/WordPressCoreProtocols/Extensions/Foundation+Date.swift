import Foundation

public extension Date {
    /// Is this date in the past?
    var hasPast: Bool {
        Date.now > self
    }
}
