import Foundation


extension BlogService {
    /// Synchronizes authors for a `Blog` from an array of `RemoteUser`s.
    /// - Parameters:
    ///   - blog: Blog object.
    ///   - remoteUsers: Array of `RemoteUser`s.
    @objc func updateBlogAuthors(for blog: Blog, with remoteUsers: [RemoteUser]) {
        do {
            guard let blog = try managedObjectContext.existingObject(with: blog.objectID) as? Blog else {
                return
            }

            remoteUsers.forEach {
                let blogAuthor = findBlogAuthor(with: $0.userID, and: blog)
                blogAuthor.userID = $0.userID
                blogAuthor.username = $0.username
                blogAuthor.email = $0.email
                blogAuthor.displayName = $0.displayName
                blogAuthor.primaryBlogID = $0.primaryBlogID
                blogAuthor.avatarURL = $0.avatarURL
                blogAuthor.linkedUserID = $0.linkedUserID

                blog.addToAuthors(blogAuthor)
            }

            // Clean up old authors who weren't in the remote array.
            let remoteUserIDs = Set(remoteUsers.map { $0.userID })
            let oldAuthors = blog.authors?.filter { !remoteUserIDs.contains($0.userID) }

            if let oldAuthors = oldAuthors {
                blog.removeFromAuthors(oldAuthors)
            }
        } catch {
            return
        }
    }
}


private extension BlogService {
    private func findBlogAuthor(with userId: NSNumber, and blog: Blog) -> BlogAuthor {
        return managedObjectContext.entity(of: BlogAuthor.self,
                                           with: NSPredicate(format: "\(#keyPath(BlogAuthor.userID)) = %@ AND \(#keyPath(BlogAuthor.blog)) = %@", userId, blog))
    }
}
