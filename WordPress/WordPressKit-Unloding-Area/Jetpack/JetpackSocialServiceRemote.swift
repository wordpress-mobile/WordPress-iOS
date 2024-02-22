import WordPressKit

/// Encapsulates remote service logic related to Jetpack Social.
public class JetpackSocialServiceRemote: ServiceRemoteWordPressComREST {

    /// Retrieves the Publicize information for the given site.
    ///
    /// Note: Sites with disabled share limits will return success with nil value.
    ///
    /// - Parameters:
    ///   - siteID: The target site's dotcom ID.
    ///   - completion: Closure to be called once the request completes.
    public func fetchPublicizeInfo(for siteID: Int,
                                   completion: @escaping (Result<RemotePublicizeInfo?, Error>) -> Void) {
        let path = path(forEndpoint: "sites/\(siteID)/jetpack-social", withVersion: ._2_0)
        Task { @MainActor in
            await self.wordPressComRestApi
                .perform(
                    .get,
                    URLString: path,
                    jsonDecoder: .apiDecoder,
                    type: RemotePublicizeInfo.self
                )
                .map { $0.body }
                .flatMapError { original -> Result<RemotePublicizeInfo?, Error> in
                    if case let .endpointError(endpointError) = original, endpointError.response?.statusCode == 200, endpointError.code == .responseSerializationFailed {
                        return .success(nil)
                    }
                    return .failure(original.asNSError())
                }
                .execute(completion)
        }
    }
}
