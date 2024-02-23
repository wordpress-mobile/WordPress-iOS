import Foundation

enum JetpackNativeConnectionURLError: Error {
    case jetpackSiteNotRegistered
    case remote(String)
}

enum JetpackNativeConnectionDataError: Error {
    case parsingError
    case remote(String)
}

struct JetpackUserData: Codable {
    let currentUser: JetpackUser
}

struct JetpackUser: Codable {
    let isConnected: Bool
}

final class JetpackNativeConnectionService: NSObject {
    private let api: WordPressOrgRestApi

    init(api: WordPressOrgRestApi) {
        self.api = api
    }

    private struct Constants {
        static let jetpackAccountConnectionURL = "https://jetpack.wordpress.com/jetpack.authorize"
    }

    private struct Path {
        static let getConnectionURL = "jetpack/v4/connection/url"
        static let getJetpackUserData = "jetpack/v4/connection/data"
    }

    /// Fetches Jetpack Connection URL that can be used to start Jetpack plugin connection process using Jetpack REST API
    /// https://github.com/Automattic/jetpack/blob/trunk/docs/rest-api.md#get-wp-jsonjetpackv4connectionurl
    ///
    /// - Parameter completion: Result with either Jetpack connection URL or JetpackNativeConnectionURLError
    ///
    func fetchJetpackConnectionURL(completion: @escaping (Result<URL, JetpackNativeConnectionURLError>) -> ()) {
        Task { @MainActor in
            let result = await self.api.get(path: Path.getConnectionURL, type: String.self)
                .mapError { JetpackNativeConnectionURLError.remote($0.localizedDescription) }
                .flatMap { urlString in
                    if let url = URL(string: urlString),
                       urlString.hasPrefix(Constants.jetpackAccountConnectionURL) {
                        return .success(url)
                    } else {
                        /// If the site didn't implement the site-level connection, the URL would be at the form: https://{site_url}/wp-admin/admin.php?page=jetpack&action=register&_wpnonce={nonce}
                        /// In this case, we need to take cookies from current response, call the returned URL,
                        /// and get the connection URL through redirection (See https://github.com/woocommerce/woocommerce-android/issues/7525)

                        /// When site-level connection is not implemented, JetpackConnectionWebViewController
                        /// does not use JetpackNativeConnectionService so this case is ignored for now
                        return .failure(.jetpackSiteNotRegistered)
                    }
                }
            completion(result)
        }
    }

    /// Fetches Jetpack User that contains Jetpack plugin connection information using Jetpack REST API
    /// https://github.com/Automattic/jetpack/blob/trunk/docs/rest-api.md#get-wp-jsonjetpackv4connectiondata
    ///
    /// - Parameter completion: Result with either JetpackUser or JetpackNativeConnectionDataError
    ///
    func fetchJetpackUser(completion: @escaping (Result<JetpackUser, JetpackNativeConnectionDataError>) -> ()) {
        Task { @MainActor in
            let result = await self.api.get(path: Path.getJetpackUserData, type: JetpackUserData.self)
                .map { $0.currentUser }
                .flatMapError { original in
                    if case let .unparsableResponse(response, _, underlyingError) = original, response?.statusCode == 200, underlyingError is DecodingError {
                        return .failure(JetpackNativeConnectionDataError.parsingError)
                    }
                    return .failure(.remote(original.localizedDescription))
                }
        }
    }
}
