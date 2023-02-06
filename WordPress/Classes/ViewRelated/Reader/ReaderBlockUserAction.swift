import Foundation

/// Encapsulates a command to block a user
final class ReaderBlockUserAction {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Execution

    func execute(with post: ReaderPost, blocked: Bool, completion: CompletionHandler? = nil) {
        completion?(.success(()))
    }

    // MARK: - Types

    typealias CompletionHandler = (Result<Void, Error>) -> Void
}
