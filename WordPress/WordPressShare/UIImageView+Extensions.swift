import Foundation


extension UIImageView
{
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
        if let cachedImage = Downloader.downloadedImagesCache[unwrappedUrl] {
            self.image = cachedImage
            return
        }
        
        // Cancel any previous OP's
        if let task = downloadTask {
            task.cancel()
            downloadTask = nil
        }
        
        // Hit the Backend
        let request = NSMutableURLRequest(URL: unwrappedUrl)
        request.HTTPShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data) else {
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                // Update the Cache
                Downloader.downloadedImagesCache[unwrappedUrl] = image
                
                // Refresh!
                self?.image = image
            }
        }
        
        downloadTask = task
        task.resume()
    }
    
    
    /// Stores the current DataTask, in charge of downloading the remote Image
    private var downloadTask : NSURLSessionDataTask? {
        get {
            return objc_getAssociatedObject(self, Downloader.downloadTaskKey) as? NSURLSessionDataTask
        }
        set {
            let policy = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            objc_setAssociatedObject(self, Downloader.downloadTaskKey, newValue, policy)
        }
    }
    
    
    /// Private helper structure
    private struct Downloader
    {
        /// Stores all of the previously downloaded images
        static var downloadedImagesCache = [NSURL : UIImage]()
        
        /// Key used to associate a Download task to the current instance
        static let downloadTaskKey = "downloadTaskKey"
    }
}
