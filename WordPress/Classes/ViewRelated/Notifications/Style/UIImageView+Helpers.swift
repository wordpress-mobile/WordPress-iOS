import Foundation


extension UIImageView
{
    public func downloadImage(url: NSURL, placeholderImage: UIImage?) {

        downloadImage(url, placeholderImage: placeholderImage, success: nil, failure: nil)
    }
        
    public func downloadImage(url: NSURL, placeholderImage: UIImage?, success: ((UIImage) -> ())?, failure: ((NSError!) -> ())?) {
        
        let request                     = NSMutableURLRequest(URL: url)
        request.HTTPShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")

        setImageWithURLRequest(request,
            placeholderImage: placeholderImage,
            success: {
                [weak self]
                (request: NSURLRequest!, response: NSHTTPURLResponse!, image: UIImage!) -> Void in
                
                if let theImage = image {
                    self?.image = theImage
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
