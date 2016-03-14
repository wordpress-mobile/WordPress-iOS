import Foundation


extension UIImageView
{
    /// Downloads an image and updates the UIImageView Instance
    ///
    /// - Parameters:
    ///     - url: The URL of the target image
    ///
    public func downloadImage(url: NSURL) {
        // Hit the cache
        if let cachedImage = Downloader.cache.objectForKey(url) as? UIImage {
            self.image = cachedImage
            return
        }
        
        // Cancel any previous OP's
        if let task = downloadTask {
            task.cancel()
            downloadTask = nil
        }
        
        // Hit the Backend
        let request = NSMutableURLRequest(URL: url)
        request.HTTPShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        let scale = mainScreenScale
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data, scale: scale) else {
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                // Update the Cache
                Downloader.cache.setObject(image, forKey: url)
                
                // Refresh!
                self?.image = image
            }
        }
        
        downloadTask = task
        task.resume()
    }
    
    
    /// Downloads a resized Blavatar, meant to perfectly fit the UIImageView's Dimensions
    ///
    /// - Parameters:
    ///     - url: The URL of the target blavatar
    ///
    public func downloadBlavatar(url: NSURL) {
        let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: true)
        components?.query = String(format: Downloader.blavatarResizeFormat, blavatarSize())
        
        if let updatedURL = components?.URL {
            downloadImage(updatedURL)
        }
    }
    
    
    /// Returns the desired Blavatar Side-Size
    private func blavatarSize() -> Int {
        var size = Downloader.defaultImageSize
        
        if !CGSizeEqualToSize(bounds.size, CGSizeZero) {
            size = max(bounds.width, bounds.height);
        }

        size *= mainScreenScale
    
        return Int(size)
    }
    
    /// Returns the Main Screen Scale
    private var mainScreenScale : CGFloat {
        return UIScreen.mainScreen().scale
    }
    
    
    /// Stores the current DataTask, in charge of downloading the remote Image
    private var downloadTask : NSURLSessionDataTask? {
        get {
            return objc_getAssociatedObject(self, Downloader.taskKey) as? NSURLSessionDataTask
        }
        set {
            let policy = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            objc_setAssociatedObject(self, Downloader.taskKey, newValue, policy)
        }
    }
    
    
    /// Private helper structure
    private struct Downloader
    {
        /// Default Blavatar Image Size
        static let defaultImageSize = CGFloat(40)
        
        /// Blavatar Resize Query FormatString
        static let blavatarResizeFormat = "d=404&s=%d"
        
        /// Stores all of the previously downloaded images
        static let cache = NSCache()
        
        /// Key used to associate a Download task to the current instance
        static let taskKey = "downloadTaskKey"
    }
}
