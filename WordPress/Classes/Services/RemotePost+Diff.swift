import WordPressKit

extension RemotePost {
    // TODO: Add remaning

    /// Returns a diff requires to update the given post to the reciever.
    func diff(from other: RemotePost) -> RemotePostUpdateParameters {
        let changes = RemotePostUpdateParameters()
        if self.title != other.title {
            changes.title = self.title
        }
        if self.content != other.content {
            changes.content = self.content
        }
        return changes
    }

    // TODO: should "publish" first upload the latest revision?
    // TODO: A temporary solution for applying the diff
    func apply(_ changes: RemotePostUpdateParameters) {
        if let status = changes.status {
            self.status = status
        }
        if let date = changes.date {
            self.date = date
        }
        //        if let authorID = changes.authorID {
        //            post.authorID = authorID
        //        }
        if let title = changes.title {
            self.title = title
        }
        if let content = changes.content {
            self.content = content
        }
        if let password = changes.password {
            self.password = password
        }
        // TODO: Update remaining options
    }
}
