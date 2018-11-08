import Foundation


/// Encapsulates all of the NSURLCache Helpers
///
extension URLCache {
    /// Private Constants
    ///
    fileprivate struct Constants {
        static let statusCodeOK     = 200
        static let httpVersion      = "1.1"
        static let expirationKey    = "Expires"
        static let expirationTime   = TimeInterval(3600)
        static let contentTypeKey   = "Content-Type"
        static let contentTypePNG   = "image/png"
    }


    /// Updates the cache contents for a given request, and stores the specified image.
    ///
    /// - Parameters:
    ///     - image: the image that should be stored on top of (whatever) is currently cached
    ///     - request: the request that should produce the given image
    ///
    @objc func cacheImage(_ image: UIImage, forRequest request: URLRequest) {
        guard let URL = request.url,
            let responseData = image.pngData() else {
            return
        }

        // First: Prepare the Response Headers
        let headerFields = [
            Constants.contentTypeKey: Constants.contentTypePNG,
            Constants.expirationKey: Date(timeIntervalSinceNow: Constants.expirationTime).toStringAsRFC1123()
        ]

        // Second: Construct a proper NSHTTPURLResponse
        guard let response = HTTPURLResponse(url: URL,
                                               statusCode: Constants.statusCodeOK,
                                               httpVersion: Constants.httpVersion,
                                               headerFields: headerFields) else {
            return
        }

        // Third: Proceed storing the cache
        let cached = CachedURLResponse(response: response, data: responseData, userInfo: nil, storagePolicy: .allowed)
        storeCachedResponse(cached, for: request)
    }
}
