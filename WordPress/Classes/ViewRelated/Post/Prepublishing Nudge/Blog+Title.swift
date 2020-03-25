import Foundation

extension Blog {

    /// The title of the blog
    var title: String? {
        let blogName = settings?.name
        let title = blogName != nil && blogName?.isEmpty == false ? blogName : displayURL as String?
        return title
    }
}
