
extension AbstractPost: ImageSourceInformation {
    var isPrivateOnWPCom: Bool {
        return isPrivate() && blog.isHostedAtWPcom
    }

    var isSelfHostedWithCredentials: Bool {
        return !blog.isHostedAtWPcom && blog.isBasicAuthCredentialStored()
    }
}
