import Foundation

class ReaderCardContent: ImageSourceInformation {
    private let originalProvider: ReaderPostContentProvider

    init(provider: ReaderPostContentProvider) {
        originalProvider = provider
    }

    var isAtomicOnWPCom: Bool {
        // Pinged @zieladam about this since the reader endpoint, ie:
        //
        // https://public-api.wordpress.com/rest/v1.2/read/sites/atomicdiegotravel.wpcomstaging.com/posts/
        //
        // provides no info on whether the post is from an atomic site.  Right now all we can do is
        // assume a default here until the endpoint offers this info.
        //
        return false
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
