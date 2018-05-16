
extension Blog: ImageSourceInformation {
    var isPrivateOnWPCom: Bool {
        return isHostedAtWPcom && isPrivate()
    }

    var isSelfHostedWithCredentials: Bool {
        return !isHostedAtWPcom && isBasicAuthCredentialStored()
    }
}
