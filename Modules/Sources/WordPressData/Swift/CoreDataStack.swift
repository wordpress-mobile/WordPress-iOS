import CoreData

@objc public protocol CoreDataStack {

    var mainContext: NSManagedObjectContext { get }

    @available(*, deprecated, message: "Use `performAndSave` instead")
    func newDerivedContext() -> NSManagedObjectContext

    func saveContextAndWait(_ context: NSManagedObjectContext)

    @objc(saveContext:)
    func save(_ context: NSManagedObjectContext)

    @objc(saveContext:withCompletionBlock:onQueue:)
    func save(_ context: NSManagedObjectContext, completion: (() -> Void)?, on queue: DispatchQueue)

    @objc(performAndSaveUsingBlock:)
    func performAndSave(_ block: @escaping (NSManagedObjectContext) -> Void)

    @objc(performAndSaveUsingBlock:completion:onQueue:)
    func performAndSave(_ block: @escaping (NSManagedObjectContext) -> Void, completion: (() -> Void)?, on queue: DispatchQueue)
}

/// Swift-only `performAndSave` variants.
///
/// These cannot be protocol requirements: generic members are not allowed in an `@objc`
/// protocol, and `CoreDataStack` must stay `@objc` for the Objective-C services. They are
/// built on the `@objc` requirement `performAndSave(_:completion:on:)` instead, so every
/// conformer (including test mocks) gets them without extra work.
public extension CoreDataStack {

    /// Execute the given block with a background context and save the changes.
    ///
    /// This function _does not block_ its running thread. The block is executed in background and its return value
    /// is passed onto the `completion` block which is executed on the given `queue`.
    ///
    /// - Parameters:
    ///   - block: A closure which uses the given `NSManagedObjectContext` to make Core Data model changes.
    ///   - completion: A closure which is called with the return value of the `block`, after the changed made
    ///         by the `block` is saved.
    ///   - queue: A queue on which to execute the completion block.
    func performAndSave<T>(
        _ block: @escaping (NSManagedObjectContext) -> T,
        completion: ((T) -> Void)?,
        on queue: DispatchQueue
    ) {
        performAndSave(
            block,
            completion: { (result: Result<T, Error>) in
                // It's safe to force-unwrap here, since the `block` does not throw an error.
                completion?(try! result.get())
            },
            on: queue
        )
    }

    /// Execute the given block with a background context and save the changes _if the block does not throw an error_.
    ///
    /// This function _does not block_ its running thread. The block is executed in background and the return value
    /// (or an error) is passed onto the `completion` block which is executed on the given `queue`.
    ///
    /// - Parameters:
    ///   - block: A closure that uses the given `NSManagedObjectContext` to make Core Data model changes. The changes
    ///         are only saved if the block does not throw an error.
    ///   - completion: A closure which is called with the `block`'s execution result, which is either an error thrown
    ///         by the `block` or the return value of the `block`.
    ///   - queue: A queue on which to execute the completion block.
    func performAndSave<T>(
        _ block: @escaping (NSManagedObjectContext) throws -> T,
        completion: ((Result<T, Error>) -> Void)?,
        on queue: DispatchQueue
    ) {
        var result: Result<T, Error>?
        performAndSave(
            { context in
                let blockResult = Result(catching: { try block(context) })
                if case .failure = blockResult {
                    // The underlying `@objc` variant always saves. Discarding the changes makes
                    // that save a no-op, which keeps the "not saved on error" contract.
                    context.rollback()
                }
                result = blockResult
            },
            completion: {
                // `result` is always set: the block above runs before this completion.
                completion?(result!)
            },
            on: queue
        )
    }

    /// Execute the given block with a background context and save the changes _if the block does not throw an error_.
    ///
    /// - Parameter block: A closure that uses the given `NSManagedObjectContext` to make Core Data model changes.
    ///     The changes are only saved if the block does not throw an error.
    /// - Returns: The value returned by the `block`
    /// - Throws: The error thrown by the `block`, in which case the Core Data changes made by the `block` is discarded.
    func performAndSave<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            performAndSave(block, completion: { continuation.resume(with: $0) }, on: DispatchQueue.global())
        }
    }
}
