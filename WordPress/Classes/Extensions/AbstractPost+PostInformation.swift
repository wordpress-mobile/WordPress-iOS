
extension AbstractPost: PostInformation {
    var isPrivateSite: Bool {
        return isPrivate() && blog.isHostedAtWPcom
    }

    var isBlogSelfHostedWithCredentials: Bool {
        return !blog.isHostedAtWPcom && blog.isBasicAuthCredentialStored()
    }
}
