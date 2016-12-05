import Foundation


extension UIImageView
{
    /// Downloads an image and updates the UIImageView Instance
    ///
    /// - Parameter url: The URL of the target image
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

        // Helpers
        let blavatarSizeInPoints = WPImageURLHelper.blavatarSizeInPoints(forImageViewBounds: self.bounds)
        let size = CGSize(width: blavatarSizeInPoints, height: blavatarSizeInPoints)

        // Hit the Backend
        let request = NSMutableURLRequest(URL: url)
        request.HTTPShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")

        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data, scale: UIScreen.mainScreen().scale) else {
                return
            }

            dispatch_async(dispatch_get_main_queue()) {
                // Resize if needed!
                var resizedImage = image

                if image.size.height > size.height || image.size.width > size.width {
                    resizedImage = image.resizedImageWithContentMode(.ScaleAspectFit,
                                                                     bounds: size,
                                                                     interpolationQuality: .High)
                }

                // Update the Cache
                Downloader.cache.setObject(resizedImage, forKey: url)
                self?.image = resizedImage
            }
        }

        downloadTask = task
        task.resume()
    }

    /// Stores the current DataTask, in charge of downloading the remote Image
    ///
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
    ///
    private struct Downloader
    {

        /// Stores all of the previously downloaded images
        ///
        static let cache = NSCache()

        /// Key used to associate a Download task to the current instance
        ///
        static let taskKey = "downloadTaskKey"
    }
}
