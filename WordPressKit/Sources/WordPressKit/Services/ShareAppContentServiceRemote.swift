/// Encapsulates logic for fetching content to be shared by the user.
///
open class ShareAppContentServiceRemote: ServiceRemoteWordPressComREST {
    /// Fetch content to be shared by the user, based on the provided `appName`.
    ///
    /// - Parameters:
    ///   - appName: An enum that identifies the app to be shared.
    ///   - completion: A closure that will be called when the fetch request completes.
    open func getContent(for appName: ShareAppName, completion: @escaping (Result<RemoteShareAppContent, Error>) -> Void) {
        let endpoint = "mobile/share-app-link"
        let requestURLString = path(forEndpoint: endpoint, withVersion: ._2_0)
        let params: [String: AnyObject] = [Constants.appNameParameterKey: appName.rawValue as AnyObject]

        Task { @MainActor in
            await self.wordPressComRestApi
                .perform(
                    .get,
                    URLString: requestURLString,
                    parameters: params,
                    jsonDecoder: .apiDecoder,
                    type: RemoteShareAppContent.self
                )
                .map { $0.body }
                .mapError { error -> Error in error.asNSError() }
                .execute(completion)
        }
    }
}

/// Defines a list of apps that can fetch share contents from the API.
public enum ShareAppName: String {
    case wordpress
    case jetpack
}

// MARK: - Private Helpers

private extension ShareAppContentServiceRemote {
    struct Constants {
        static let appNameParameterKey = "app"
    }
}
