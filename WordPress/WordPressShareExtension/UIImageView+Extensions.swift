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
        let scale = mainScreenScale
        let size = CGSize(width: blavatarSizeInPoints, height: blavatarSizeInPoints)

        // Hit the Backend
        let request = NSMutableURLRequest(URL: url)
        request.HTTPShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")

        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data, scale: scale) else {
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


    /// Downloads a resized Blavatar, meant to perfectly fit the UIImageView's Dimensions
    ///
    /// - Parameter url: The URL of the target blavatar
    ///
    public func downloadBlavatar(url: NSURL) {
        let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: true)
        components?.query = String(format: Downloader.blavatarResizeFormat, blavatarSize)

        if let updatedURL = components?.URL {
            downloadImage(updatedURL)
        }
    }


    /// Returns the desired Blavatar Side-Size, in pixels
    ///
    private var blavatarSize : Int {
        return blavatarSizeInPoints * Int(mainScreenScale)
    }

    /// Returns the desired Blavatar Side-Size, in points
    ///
    private var blavatarSizeInPoints : Int {
        var size = Downloader.defaultImageSize

        if !CGSizeEqualToSize(bounds.size, CGSizeZero) {
            size = max(bounds.width, bounds.height)
        }

        return Int(size)
    }

    /// Returns the Main Screen Scale
    ///
    private var mainScreenScale : CGFloat {
        return UIScreen.mainScreen().scale
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
        /// Default Blavatar Image Size
        ///
        static let defaultImageSize = CGFloat(40)

        /// Blavatar Resize Query FormatString
        ///
        static let blavatarResizeFormat = "d=404&s=%d"

        /// Stores all of the previously downloaded images
        ///
        static let cache = NSCache()

        /// Key used to associate a Download task to the current instance
        ///
        static let taskKey = "downloadTaskKey"
    }
}
