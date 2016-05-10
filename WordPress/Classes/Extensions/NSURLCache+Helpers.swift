import Foundation


/// Encapsulates all of the NSURLCache Helpers
///
extension NSURLCache
{
    /// Private Constants
    ///
    private struct Constants {
        static let statusCodeOK     = 200
        static let httpVersion      = "1.1"
        static let expirationKey    = "Expires"
        static let expirationTime   = NSTimeInterval(3600)
        static let contentTypeKey   = "Content-Type"
        static let contentTypePNG   = "image/png"
    }


    /// Updates the cache contents for a given request, and stores the specified image.
    ///
    /// - Parameters:
    ///     - image: the image that should be stored on top of (whatever) is currently cached
    ///     - request: the request that should produce the given image
    ///
    func cacheImage(image: UIImage, forRequest request: NSURLRequest) {
        guard let URL = request.URL,
            let responseData = UIImagePNGRepresentation(image) else
        {
            return
        }

        // Fist: Prepare the Response Headers
        let headerFields = [
            Constants.contentTypeKey : Constants.contentTypePNG,
            Constants.expirationKey  : NSDate(timeIntervalSinceNow: Constants.expirationTime).toStringAsRFC1123()
        ]

        // Second: Construct a proper NSHTTPURLResponse
        guard let response = NSHTTPURLResponse(URL: URL,
                                               statusCode: Constants.statusCodeOK,
                                               HTTPVersion: Constants.httpVersion,
                                               headerFields: headerFields) else
        {
            return
        }

        // Third: Proceed storing the cache
        let cached = NSCachedURLResponse(response: response, data: responseData, userInfo: nil, storagePolicy: .Allowed)
        storeCachedResponse(cached, forRequest: request)
    }
}
