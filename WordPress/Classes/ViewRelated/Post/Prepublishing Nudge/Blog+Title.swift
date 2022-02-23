import Foundation

extension Blog {

    /// The title of the blog
    var title: String? {
        guard let blogName = settings?.name, !blogName.isEmpty else {
            return displayURL as String?
        }

        return blogName
    }
}
