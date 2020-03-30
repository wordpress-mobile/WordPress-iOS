
extension AbstractPost: ImageSourceInformation {
    
    var isAtomicOnWPCom: Bool {
        return blog.isAtomic()
    }
    
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

    /// An autosave revision may include post title, content and/or excerpt.
    var hasAutosaveRevision: Bool {
        guard let autosaveRevisionIdentifier = autosaveIdentifier?.intValue else {
            return false
        }
        return autosaveRevisionIdentifier > 0
    }
}
