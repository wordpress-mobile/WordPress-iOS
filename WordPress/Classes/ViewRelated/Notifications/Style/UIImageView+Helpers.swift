import Foundation


extension UIImageView
{
    public func downloadImage(url: NSURL, placeholderImage: UIImage!, success: ((UIImage) -> ())?, failure: ((NSError!) -> ())?) {
        let urlRequest                     = NSMutableURLRequest(URL: url)
        urlRequest.HTTPShouldHandleCookies = false
        urlRequest.addValue("image/*", forHTTPHeaderField: "Accept")

        setImageWithURLRequest(urlRequest,
            placeholderImage: placeholderImage,
            success: {
                [weak self]
                (request: NSURLRequest!, response: NSHTTPURLResponse!, image: UIImage!) -> Void in
                
                if let theImage = image {
                    success?(theImage)
                }
            },
            failure: {
                (request: NSURLRequest!, response: NSHTTPURLResponse!, error: NSError!) -> Void in
                // Xcode 6 Beta 5 Bug: If there's no single if let here, it won't build
                if let handler = failure { }
                failure?(error)
            }
        )
    }
}
