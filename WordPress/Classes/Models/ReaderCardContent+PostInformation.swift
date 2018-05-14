import Foundation

class ReaderCardContent: PostInformation {
    private let originalProvider: ReaderPostContentProvider

    init(provider: ReaderPostContentProvider) {
        originalProvider = provider
    }

    var isPrivateOnWPCom: Bool {
        return originalProvider.isPrivate() && originalProvider.isWPCom()
    }

    var isBlogSelfHostedWithCredentials: Bool {
        return !originalProvider.isWPCom() && !originalProvider.isJetpack()
    }
}
