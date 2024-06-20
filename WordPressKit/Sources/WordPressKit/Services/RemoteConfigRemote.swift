import Foundation

open class RemoteConfigRemote: ServiceRemoteWordPressComREST {

    public typealias RemoteConfigDictionary = [String: Any]
    public typealias RemoteConfigResponseCallback = (Result<RemoteConfigDictionary, Error>) -> Void

    public enum RemoteConfigRemoteError: Error {
        case InvalidDataError
    }

    open func getRemoteConfig(callback: @escaping RemoteConfigResponseCallback) {

        let endpoint = "mobile/remote-config"
        let path = self.path(forEndpoint: endpoint, withVersion: ._2_0)

        wordPressComRESTAPI.get(path,
                                parameters: nil,
                                success: { response, _ in
            if let remoteConfigDictionary = response as? [String: Any] {
                callback(.success(remoteConfigDictionary))
            } else {
                callback(.failure(RemoteConfigRemoteError.InvalidDataError))
            }

        }, failure: { error, response in
            WPKitLogError("Error retrieving remote config values")
            WPKitLogError("\(error)")

            if let response = response {
                WPKitLogDebug("Response Code: \(response.statusCode)")
            }

            callback(.failure(error))
        })
    }
}
