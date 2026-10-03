import CoreData

public protocol CoreDataStackSwift: CoreDataStack {

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
    func performAndSave<T>(_ block: @escaping (NSManagedObjectContext) -> T, completion: ((T) -> Void)?, on queue: DispatchQueue)

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
    func performAndSave<T>(_ block: @escaping (NSManagedObjectContext) throws -> T, completion: ((Result<T, Error>) -> Void)?, on queue: DispatchQueue)

    /// Execute the given block with a background context and save the changes _if the block does not throw an error_.
    ///
    /// - Parameter block: A closure that uses the given `NSManagedObjectContext` to make Core Data model changes.
    ///     The changes are only saved if the block does not throw an error.
    /// - Returns: The value returned by the `block`
    /// - Throws: The error thrown by the `block`, in which case the Core Data changes made by the `block` is discarded.
    func performAndSave<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T

    /// Perform a query using the `mainContext` and return the result.
    ///
    /// - Warning: Do not return `NSManagedObject` instances from the closure.
    func performQuery<T>(_ block: @escaping (NSManagedObjectContext) -> T) -> T

    /// Perform a query on a fresh background context and return the result.
    ///
    /// The changes made by the closure are not saved. Provide a throwing closure
    /// to select this background overload over the `mainContext` one above.
    ///
    /// - Warning: Do not return `NSManagedObject` instances from the closure.
    func performQuery<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) rethrows -> T

    /// Perform an asynchronous query on a fresh background context and return the result.
    ///
    /// The changes made by the closure are not saved.
    ///
    /// - Warning: Do not return `NSManagedObject` instances from the closure.
    func performQuery<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async rethrows -> T
}
