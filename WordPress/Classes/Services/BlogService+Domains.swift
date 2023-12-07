import Foundation

/// This extension is necessary because DomainsService is unavailable in ObjC.
///
extension BlogService {
    enum BlogServiceDomainError: Error {
        case noAccountForSpecifiedBlog(blog: Blog)
        case noSiteIDForSpecifiedBlog(blog: Blog)
        case noWordPressComRestApi(blog: Blog)
    }

    /// Convenience method to be able to refresh the blogs from ObjC.
    ///
    @objc
    func refreshDomains(for blog: Blog, success: (() -> Void)?, failure: ((Error) -> Void)?) {
        guard let account = blog.account else {
            failure?(BlogServiceDomainError.noAccountForSpecifiedBlog(blog: blog))
            return
        }

        guard let siteID = blog.dotComID?.intValue else {
            failure?(BlogServiceDomainError.noSiteIDForSpecifiedBlog(blog: blog))
            return
        }

        guard let service = DomainsService(coreDataStack: coreDataStack, account: account) else {
            failure?(BlogServiceDomainError.noWordPressComRestApi(blog: blog))
            return
        }

        service.refreshDomains(siteID: siteID) { result in
            switch result {
            case .success:
                success?()
            case .failure(let error):
                failure?(error)
            }
        }
    }
}
