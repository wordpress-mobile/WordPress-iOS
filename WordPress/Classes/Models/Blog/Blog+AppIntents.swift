import Foundation
import WordPressData

extension Blog {
    /// Resolves the blog an App Intent should act on.
    ///
    /// An explicit site identifier must resolve to its own blog: falling back to
    /// another site would silently act on the wrong one, so unresolvable
    /// identifiers return `nil`. Only when no identifier is given does the
    /// resolution fall back to the last used or first blog.
    static func forAppIntent(siteIdentifier: String?, in context: NSManagedObjectContext) -> Blog? {
        guard let siteIdentifier else {
            return lastUsedOrFirst(in: context)
        }
        guard let siteID = Int(siteIdentifier) else {
            return nil
        }
        return try? lookup(withID: siteID, in: context)
    }
}
