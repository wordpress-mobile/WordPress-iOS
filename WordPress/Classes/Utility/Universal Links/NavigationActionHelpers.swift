import Foundation
import WordPressFlux

extension NavigationAction {
    func defaultBlog() -> Blog? {
        let context = ContextManager.sharedInstance().mainContext
        return Blog.lastUsedOrFirst(in: context)
    }

    func blog(from values: [String: String]?) -> Blog? {
        guard let domain = values?["domain"] else {
            return nil
        }

        let context = ContextManager.sharedInstance().mainContext

        if let blog = Blog.lookup(hostname: domain, in: context) {
            return blog
        }

        // Some stats URLs use a site ID instead
        if let siteIDValue = Int(domain) {
            return try? Blog.lookup(withID: siteIDValue, in: context)
        }

        return nil
    }

    func postFailureNotice(title: String, message: String? = nil) {
        let notice = Notice(title: title,
                            message: message,
                            feedbackType: .error,
                            notificationInfo: nil)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }
}
