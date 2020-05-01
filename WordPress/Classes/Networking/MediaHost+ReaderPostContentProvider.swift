import Foundation

/// Extends `MediaRequestAuthenticator.MediaHost` so that we can easily
/// initialize it from a given `Blog`.
///
extension MediaHost {
    enum ReaderPostContentProviderError: Swift.Error {
        case noDefaultWordPressComAccount
        case baseInitializerError(error: Error, readerPostContentProvider: ReaderPostContentProvider)
    }

    init(with readerPostContentProvider: ReaderPostContentProvider, failure: (ReaderPostContentProviderError) -> ()) {
        let isAccessibleThroughWPCom = readerPostContentProvider.isWPCom() || readerPostContentProvider.isJetpack()

        // This is the only way in which we can obtain the username and authToken here.
        // It'd be nice if all data was associated with an account instead, for transparency
        // and cleanliness of the code - but this'll have to do for now.
        let accountService = AccountService(managedObjectContext: ContextManager.shared.mainContext)

        // We allow a nil account in case the user connected only self-hosted sites.
        let account = accountService.defaultWordPressComAccount()
        let username = account?.username
        let authToken = account?.authToken

        self.init(isAccessibleThroughWPCom: isAccessibleThroughWPCom,
            isPrivate: readerPostContentProvider.isPrivate(),
            isAtomic: readerPostContentProvider.isAtomic(),
            siteID: readerPostContentProvider.siteID()?.intValue,
            username: username,
            authToken: authToken,
            failure: { error in
                // We just associate a ReaderPostContentProvider with the underlying error for simpler debugging.
                failure(ReaderPostContentProviderError.baseInitializerError(
                    error: error,
                    readerPostContentProvider: readerPostContentProvider))
        })
    }
}
