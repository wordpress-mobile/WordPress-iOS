
import Foundation

@testable import WordPress

class PageBuilder {
    private let page: Page

    init(_ context: NSManagedObjectContext) {
        page = NSEntityDescription.insertNewObject(forEntityName: Page.entityName(), into: context) as! Page

        // Non-null Core Data properties
        page.blog = BlogBuilder(context).build()
    }

    func with(autoUploadAttemptsCount: Int) -> Self {
        page.autoUploadAttemptsCount = NSNumber(value: autoUploadAttemptsCount)
        return self
    }

    /// - Important: Since this method refreshes the auto-upload hash, any changes after calling this
    ///             method will invalidate that hash.
    ///
    func with(shouldAttemptAutoUpload: Bool) -> Self {
        page.shouldAttemptAutoUpload = shouldAttemptAutoUpload
        return self
    }

    func with(title: String) -> Self {
        page.postTitle = title
        return self
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
    func with(remote: Bool) -> Self {
        if remote {
            page.postID = NSNumber(value: arc4random_uniform(UINT32_MAX))
        } else {
            page.postID = nil
        }
        return self
    }

    func withRemote() -> Self {
        return with(remote: true)
    }

    func build() -> Page {
        return page
    }
}
