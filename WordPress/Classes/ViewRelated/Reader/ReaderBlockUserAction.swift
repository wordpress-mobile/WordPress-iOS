import Foundation

/// Encapsulates a command to block a user
final class ReaderBlockUserAction {

    private let context: NSManagedObjectContext

    private var defaultAccount: WPAccount? {
        let context = ContextManager.shared.mainContext
        do {
            let account = try WPAccount.lookupDefaultWordPressComAccount(in: context)
            return account
        } catch let error {
            DDLogError("Couldn't fetch default account: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Init

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Execution

    func execute(with post: ReaderPost, blocked: Bool, completion: CompletionHandler? = nil) {
        guard let authorID = post.authorID,
              let accountID = defaultAccount?.userID
        else {
            return
        }
        if blocked {
            let blocked = BlockedAuthor.insert(into: context)
            blocked.authorID = authorID
            blocked.accountID = accountID
        } else {
            let predicate = NSPredicate(format: "\(#keyPath(BlockedAuthor.authorID)) = %@ AND \(#keyPath(BlockedAuthor.accountID)) = %@", authorID, accountID)
            BlockedAuthor.delete(.predicate(predicate), context: context)
        }
        do {
            try context.save()
            completion?(.success(()))
        } catch let error {
            let operation = blocked ? "block" : "unblock"
            DDLogError("Couldn't \(operation) author: \(error.localizedDescription)")
            completion?(.failure(error))
        }
    }

    // MARK: - Types

    typealias CompletionHandler = (Result<Void, Error>) -> Void
}
