
extension Blog: ImageSourceInformation {

    var isAtomicOnWPCom: Bool {
        return isAtomic()
    }

    var isPrivateOnWPCom: Bool {
        return isHostedAtWPcom && isPrivate()
    }

    var isSelfHostedWithCredentials: Bool {
        return !isHostedAtWPcom && isBasicAuthCredentialStored()
    }

    var siteID: NSNumber? {
        return dotComID
    }
}
