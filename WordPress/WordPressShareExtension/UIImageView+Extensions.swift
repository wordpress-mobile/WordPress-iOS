import Foundation


extension UIImageView
{
    /// Downloads an image and updates the UIImageView Instance
    ///
    /// - Parameter url: The URL of the target image
    ///
    public func downloadImage(_ url: URL) {
        // Hit the cache
        if let cachedImage = Downloader.cache.object(forKey: url as AnyObject) as? UIImage {
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
        var request = URLRequest(url: url)
        request.httpShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")

        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data, scale: scale) else {
                return
            }

            DispatchQueue.main.async {
                // Resize if needed!
                var resizedImage = image

                if image.size.height > size.height || image.size.width > size.width {
                    resizedImage = image.resizedImage(with: .scaleAspectFit,
                                                                     bounds: size,
                                                                     interpolationQuality: .high)
                }

                // Update the Cache
                Downloader.cache.setObject(resizedImage, forKey: url as AnyObject)
                self?.image = resizedImage
            }
        })

        downloadTask = task
        task.resume()
    }


    /// Downloads a resized Blavatar, meant to perfectly fit the UIImageView's Dimensions
    ///
    /// - Parameter url: The URL of the target blavatar
    ///
    public func downloadBlavatar(_ url: URL) {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.query = String(format: Downloader.blavatarResizeFormat, blavatarSize)

        if let updatedURL = components?.url {
            downloadImage(updatedURL)
        }
    }


    /// Returns the desired Blavatar Side-Size, in pixels
    ///
    fileprivate var blavatarSize : Int {
        return blavatarSizeInPoints * Int(mainScreenScale)
    }

    /// Returns the desired Blavatar Side-Size, in points
    ///
    fileprivate var blavatarSizeInPoints : Int {
        var size = Downloader.defaultImageSize

        if !bounds.size.equalTo(CGSize.zero) {
            size = max(bounds.width, bounds.height)
        }

        return Int(size)
    }

    /// Returns the Main Screen Scale
    ///
    fileprivate var mainScreenScale : CGFloat {
        return UIScreen.main.scale
    }


    /// Stores the current DataTask, in charge of downloading the remote Image
    ///
    fileprivate var downloadTask : URLSessionDataTask? {
        get {
            return objc_getAssociatedObject(self, Downloader.taskKey) as? URLSessionDataTask
        }
        set {
            let policy = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            objc_setAssociatedObject(self, Downloader.taskKey, newValue, policy)
        }
    }


    /// Private helper structure
    ///
    fileprivate struct Downloader
    {
        /// Default Blavatar Image Size
        ///
        static let defaultImageSize = CGFloat(40)

        /// Blavatar Resize Query FormatString
        ///
        static let blavatarResizeFormat = "d=404&s=%d"

        /// Stores all of the previously downloaded images
        ///
        static let cache = NSCache<AnyObject, AnyObject>()

        /// Key used to associate a Download task to the current instance
        ///
        static let taskKey = "downloadTaskKey"
    }
}
