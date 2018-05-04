
extension AbstractPost: PostInformation {
    var isPrivateOnWPCom: Bool {
        return isPrivate() && blog.isHostedAtWPcom
    }

    var isBlogSelfHostedWithCredentials: Bool {
        return !blog.isHostedAtWPcom && blog.isBasicAuthCredentialStored()
    }
}
