import Foundation

/// This extension is necessary because DomainsService is unavailable in ObjC.
///
extension BlogService {
    enum BlogServiceDomainError: Error {
        case noAccountForSpecifiedBlog(blog: Blog)
        case noSiteIDForSpecifiedBlog(blog: Blog)
    }

    /// Convenience method to be able to refresh the blogs from ObjC.
    ///
    @objc
    func refreshDomains(for blog: Blog, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        guard let account = blog.account else {
            failure(BlogServiceDomainError.noAccountForSpecifiedBlog(blog: blog))
            return
        }

        guard let siteID = blog.dotComID?.intValue else {
            failure(BlogServiceDomainError.noSiteIDForSpecifiedBlog(blog: blog))
            return
        }

        let service = DomainsService(managedObjectContext: managedObjectContext, account: account)

        service.refreshDomains(siteID: siteID) { result in
            switch result {
            case .success:
                success()
            case .failure(let error):
                failure(error)
            }
        }
    }
}
