import Foundation

extension Blog {

    /// The title of the blog
    var title: String? {
        let blogName = settings?.name

        guard let blogName = blogName, !blogName.isEmpty else {
            return displayURL as String?
        }

        return blogName
    }
}
