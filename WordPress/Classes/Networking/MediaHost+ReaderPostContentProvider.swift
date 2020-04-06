import Foundation

/// Extends `MediaRequestAuthenticator.MediaHost` so that we can easily
/// initialize it from a given `Blog`.
///
extension MediaHost {
    enum ReaderPostContentProviderError: Swift.Error {
        case baseInitializerError(error: Error, readerPostContentProvider: ReaderPostContentProvider)
    }

    init(with readerPostContentProvider: ReaderPostContentProvider, failure: (ReaderPostContentProviderError) -> ()) {
        let isAccessibleThroughWPCom = readerPostContentProvider.isWPCom() || readerPostContentProvider.isJetpack()

        self.init(isAccessibleThroughWPCom: isAccessibleThroughWPCom,
            isPrivate: readerPostContentProvider.isPrivate(),
            isAtomic: readerPostContentProvider.isAtomic(),
            siteID: readerPostContentProvider.siteID()?.intValue,
            failure: { error in
                // We just associate a ReaderPostContentProvider with the underlying error for simpler debugging.
                failure(ReaderPostContentProviderError.baseInitializerError(
                    error: error,
                    readerPostContentProvider: readerPostContentProvider))
        })
    }
}
