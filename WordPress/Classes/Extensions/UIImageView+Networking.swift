import Foundation


extension UIImageView
{
    public func downloadImage(url: NSURL?, placeholderName: String?) {

        downloadImage(url, placeholderName: placeholderName, success: nil, failure: nil)
    }
        
    public func downloadImage(url: NSURL?, placeholderName: String?, success: ((UIImage) -> ())?, failure: ((NSError!) -> ())?) {

        // Placeholder, if possible
        if let unwrappedPlaceholderName = placeholderName {
            image = UIImage(named: unwrappedPlaceholderName)
        }

        // Failsafe: Halt if the URL is empty
        if url == nil {
            return
        }

        let request                     = NSMutableURLRequest(URL: url!)
        request.HTTPShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")

        setImageWithURLRequest(request,
            placeholderImage: nil,
            success: {
                [weak self]
                (request: NSURLRequest!, response: NSHTTPURLResponse!, image: UIImage!) -> Void in
                
                if let unwrappedImage = image {
                    self?.image = unwrappedImage
                    success?(unwrappedImage)
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
