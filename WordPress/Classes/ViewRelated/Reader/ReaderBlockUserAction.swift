/// Encapsulates a command to block a user
final class ReaderBlockUserAction {
    private let asBlocked: Bool

    init(asBlocked: Bool) {
        self.asBlocked = asBlocked
    }

    func execute(with post: ReaderPost, context: NSManagedObjectContext, completion: (() -> Void)? = nil, failure: ((Error?) -> Void)? = nil) {
        completion?()
    }
}
