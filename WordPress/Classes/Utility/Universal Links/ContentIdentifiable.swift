import Foundation

/// A protocol representing a content identifier – it could be a URL, ISBN, etc
///
/// More than one object might share a content identifier – two objects with the same identifier represent the same content.
///
public protocol ContentIdentifiable {
    var contentIdentifier: String? { get }
}
