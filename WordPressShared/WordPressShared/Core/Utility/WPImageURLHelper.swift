import Foundation

/// Helper class to create a WordPress URL for downloading images with size parameters.
open class WPImageURLHelper: NSObject {
    /**
     Adds to the provided url width and height parameters to allow the image to be resized on the server

     - parameter size: the required pixel size for the image.  If height is set to zero the
                       returned image will have a height proportional to the requested width and vice versa.
     - parameter url:  the original url for the image

     - returns: an URL with the added query parameters.

     - note: If there is any problem with the original URL parsing, the original URL is returned with no changes.
     */
    @objc open class func imageURLWithSize(_ size: CGSize, forImageURL url: URL) -> URL {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return url
        }
        var newQueryItems = [URLQueryItem]()
        if let queryItems = urlComponents.queryItems {
            for queryItem in queryItems {
                if queryItem.name != "w" && queryItem.name != "h" {
                    newQueryItems.append(queryItem)
                }
            }
        }
        let height = Int(size.height)
        let width = Int(size.width)
        if height != 0 {
            let heightItem = URLQueryItem(name: "h", value: "\(height)")
            newQueryItems.append(heightItem)
        }

        if width != 0 {
            let widthItem = URLQueryItem(name: "w", value: "\(width)")
            newQueryItems.append(widthItem)
        }

        urlComponents.queryItems = newQueryItems
        guard let resultURL = urlComponents.url else {
            return url
        }
        return resultURL
    }
}
