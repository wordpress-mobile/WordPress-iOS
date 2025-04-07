import Foundation
import CoreData

extension PublicizeInfo {
    /// The maximum number of Social shares for the associated `blog`.
    @NSManaged public var shareLimit: Int64

    /// The number of Social sharing to be published in the future.
    @NSManaged public var toBePublicizedCount: Int64

    /// The number of posts that have been auto-shared.
    @NSManaged public var sharedPostsCount: Int64

    /// The remaining Social shares available for the associated `blog`.
    @NSManaged public var sharesRemaining: Int64

    /// The associated Blog instance.
    @NSManaged public var blog: Blog?
}
