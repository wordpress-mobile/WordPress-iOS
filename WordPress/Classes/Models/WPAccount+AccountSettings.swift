import Foundation

extension WPAccount {
    func applyChange(_ change: AccountSettingsChange) {
        switch change {
        case .displayName(let value):
            self.displayName = value
        case .primarySite(let value):
            let service = BlogService(managedObjectContext: managedObjectContext!)
            defaultBlog = service.blog(byBlogId: NSNumber(value: value))
        default:
            break
        }
    }
}
