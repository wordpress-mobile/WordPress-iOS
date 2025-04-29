import Foundation

/// A data blob stored that uses external storage and is loaded on demand.
@objc(BlobEntity)
public final class BlobEntity: NSManagedObject {
    @NSManaged public var data: Data
}
