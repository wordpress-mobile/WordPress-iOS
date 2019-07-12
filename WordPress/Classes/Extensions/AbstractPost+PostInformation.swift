
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

}
