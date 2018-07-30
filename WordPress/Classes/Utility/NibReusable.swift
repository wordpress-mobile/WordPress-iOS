import Foundation

/// A protocol to add default reuse identifiers for reusable objects.
public protocol Reusable {

    /// Default reuse identifier.
    static var defaultReuseID: String { get }
}

public extension Reusable {
    static var defaultReuseID: String {
        return String(describing: self)
    }
}

/// Protocol to conform for both reusable and nib loadable views.
/// (`Reusable` + `NibLoadable`)
public protocol NibReusable: Reusable, NibLoadable { /* Convenience */ }
