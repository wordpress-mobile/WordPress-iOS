import Foundation

extension WPAccount {
    func applyChange(change: AccountSettingsChange) {
        switch change {
        case .DisplayName(let value):
            self.displayName = value
        case .PrimarySite(let value):
            let service = BlogService(managedObjectContext: managedObjectContext)
            defaultBlog = service.blogByBlogId(value)
        default:
            break
        }
    }
}
