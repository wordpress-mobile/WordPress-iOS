import Foundation


extension BlogService {
    @objc func blogAuthors(for blog: Blog, with remoteUsers: [RemoteUser]) {
        do {
            guard let blog = try managedObjectContext.existingObject(with: blog.objectID) as? Blog else {
                return
            }

            remoteUsers.forEach {
                let blogAuthor = findBlogAuthor(with: $0.userID)
                blogAuthor.userID = $0.userID
                blogAuthor.username = $0.username
                blogAuthor.email = $0.email
                blogAuthor.displayName = $0.displayName
                blogAuthor.primaryBlogID = $0.primaryBlogID
                blogAuthor.avatarURL = $0.avatarURL
                blogAuthor.linkedUserID = $0.linkedUserID

                blog.addToAuthors(blogAuthor)
            }
        } catch {
            return
        }
    }
}


private extension BlogService {
    private func findBlogAuthor(with userId: NSNumber) -> BlogAuthor {
        return managedObjectContext.entity(of: BlogAuthor.self,
                                           with: NSPredicate(format: "\(#keyPath(BlogAuthor.userID)) = %@", userId))
    }
}
