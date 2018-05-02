
extension AbstractPost: PostInformation {
    var isPostPrivate: Bool {
        return isPrivate() && blog.isHostedAtWPcom
    }

    var isBlogSelfHostedWithCredentials: Bool {
        return !blog.isHostedAtWPcom && blog.isBasicAuthCredentialStored()
    }
}
