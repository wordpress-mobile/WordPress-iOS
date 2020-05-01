import Foundation

extension AbstractPost {
    /// Returns true if the post is a draft and has never been uploaded to the server.
    var isLocalDraft: Bool {
        return self.isDraft() && !self.hasRemote()
    }

    var isLocalRevision: Bool {
        return self.originalIsDraft() && self.isRevision() && self.remoteStatus == .local
    }
}
