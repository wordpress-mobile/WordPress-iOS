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
        if let cachedImage = Downloader.imagesCache[unwrappedUrl] {
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
        
        let scale = mainScreenScale
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data, scale: scale) else {
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                // Update the Cache
                Downloader.imagesCache[unwrappedUrl] = image
                
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
    ///     - placeholderImage: Image to be displayed, temporarily, while the Download OP is executed
    ///
    public func downloadBlavatar(url: NSURL?, placeholderImage: UIImage?) {
        guard let unwrappedURL = url else {
            image = placeholderImage
            return
        }
        
        let components = NSURLComponents(URL: unwrappedURL, resolvingAgainstBaseURL: true)
        components?.query = String(format: Downloader.blavatarResizeFormat, blavatarSize())
        downloadImage(components?.URL, placeholderImage: placeholderImage)
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
        static var imagesCache = [NSURL : UIImage]()
        
        /// Key used to associate a Download task to the current instance
        static let taskKey = "downloadTaskKey"
    }
}
