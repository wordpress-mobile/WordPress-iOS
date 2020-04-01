import Foundation

class ReaderCardContent: ImageSourceInformation {
    private let originalProvider: ReaderPostContentProvider

    init(provider: ReaderPostContentProvider) {
        originalProvider = provider
    }

    var isAtomicOnWPCom: Bool {
        return originalProvider.isAtomic()
    }

    var isPrivateOnWPCom: Bool {
        return originalProvider.isPrivate() && originalProvider.isWPCom()
    }

    var isSelfHostedWithCredentials: Bool {
        return !originalProvider.isWPCom() && !originalProvider.isJetpack()
    }

    var siteID: NSNumber? {
        return originalProvider.siteID()
    }
}
