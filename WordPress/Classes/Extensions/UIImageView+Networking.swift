import Foundation


extension UIImageView
{
    public func downloadImage(url: NSURL?, placeholderImage: UIImage?) {
        downloadImage(url, placeholderImage: placeholderImage, success: nil, failure: nil)
    }
        
    public func downloadImage(url: NSURL?, placeholderImage: UIImage?, success: ((UIImage) -> ())?, failure: ((NSError!) -> ())?) {
        // Failsafe: Halt if the URL is empty
        guard let unwrappedUrl = url else {
            image = placeholderImage
            return
        }

        let request = NSMutableURLRequest(URL: unwrappedUrl)
        request.HTTPShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        setImageWithURLRequest(request,
            placeholderImage: placeholderImage,
            success: { [weak self]
                (request: NSURLRequest, response: NSHTTPURLResponse?, image: UIImage) -> Void in
                
                self?.image = image
                success?(image)
            },
            failure: {
                (request: NSURLRequest, response: NSHTTPURLResponse?, error: NSError) -> Void in
                failure?(error)
            }
        )
    }
}
