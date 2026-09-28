/// Kept so existing call sites compile unchanged. `CoreDataStack` now carries the generic
/// and async `performAndSave` variants as Swift-only extension members, so a second
/// protocol is no longer needed.
public typealias CoreDataStackSwift = CoreDataStack
