import Foundation
import WordPressFlux

extension NavigationAction {
    func defaultBlog() -> Blog? {
        let context = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: context)

        return service.lastUsedOrFirstBlog()
    }

    func blog(from values: [String: String]?) -> Blog? {
        guard let domain = values?["domain"] else {
            return nil
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: context)

        if let blog = service.blog(byHostname: domain) {
            return blog
        }

        // Some stats URLs use a site ID instead
        if let siteIDValue = Int(domain) {
            return try? Blog.lookup(withID: siteIDValue, in: context)
        }

        return nil
    }

    func postFailureNotice(title: String) {
        let notice = Notice(title: title,
                            feedbackType: .error,
                            notificationInfo: nil)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }
}
