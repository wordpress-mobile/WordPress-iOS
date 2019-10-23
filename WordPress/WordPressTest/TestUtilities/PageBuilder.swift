
import Foundation

@testable import WordPress

class PageBuilder {
    private let page: Page

    init(_ context: NSManagedObjectContext) {
        page = NSEntityDescription.insertNewObject(forEntityName: Page.entityName(), into: context) as! Page

        // Non-null Core Data properties
        page.blog = BlogBuilder(context).build()
    }

    func with(status: BasePost.Status) -> Self {
        page.status = status
        return self
    }

    func with(remoteStatus: AbstractPostRemoteStatus) -> Self {
        page.remoteStatus = remoteStatus
        return self
    }

    func with(dateModified: Date) -> Self {
        page.dateModified = dateModified
        return self
    }

    /// Sets a random postID to emulate that self exists in the server.
    func withRemote() -> Self {
        page.postID = NSNumber(value: arc4random_uniform(UINT32_MAX))
        return self
    }

    func build() -> Page {
        return page
    }
}
