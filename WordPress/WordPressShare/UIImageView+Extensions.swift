import Foundation


extension UIImageView
{
    /// Stores all of the previously downloaded images
    private static var downloadedImagesCache = [NSURL : UIImage]()
    
    /// Downloads an image and updates the UIImageView Instance
    ///
    /// - Parameters:
    ///     - url: The URL of the target image
    ///     - placeholderImage: Image to be displayed, temporarily, while the Download OP is executed
    ///
    public func downloadImage(url: NSURL?, placeholderImage: UIImage?) {
        image = placeholderImage
        
        // Failsafe: Halt if the URL is empty
        guard let unwrappedUrl = url else {
            return
        }
        
        // Hit the cache
        if let cachedImage = UIImageView.downloadedImagesCache[unwrappedUrl] {
            self.image = cachedImage
            return
        }
        
        // Hit the Backend
        let request = NSMutableURLRequest(URL: unwrappedUrl)
        request.HTTPShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { [weak self] (data, response, error) -> Void in
            guard let data = data, let image = UIImage(data: data) else {
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                // Update the Cache
                UIImageView.downloadedImagesCache[unwrappedUrl] = image
                
                // Refresh!
                self?.image = image
            }
        }
        
        task.resume()
    }

}
