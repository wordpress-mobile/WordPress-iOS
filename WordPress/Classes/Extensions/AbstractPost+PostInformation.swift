
extension AbstractPost: ImageSourceInformation {
    var isPrivateOnWPCom: Bool {
        return isPrivate() && blog.isHostedAtWPcom
    }

    var isSelfHostedWithCredentials: Bool {
        return blog.isSelfHostedWithCredentials
    }

    var isLocalRevision: Bool {
        return self.originalIsDraft() && self.isRevision() && self.remoteStatus == .local
    }

    /// Returns true if the post is a draft and has never been uploaded to the server.
    var isLocalDraft: Bool {
        return self.isDraft() && !self.hasRemote()
    }
}
