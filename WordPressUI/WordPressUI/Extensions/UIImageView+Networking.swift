import Foundation


public extension UIImageView {

    /// Downloads an image and updates the UIImageView Instance
    ///
    /// - Parameter url: The URL of the target image
    ///
    public func downloadImage(_ url: URL, pointSize: CGSize? = nil) {
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

        // Hit the Backend
        var request = URLRequest(url: url)
        request.httpShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")

        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data, scale: UIScreen.main.scale) else {
                return
            }

            DispatchQueue.main.async {
                // Resize if needed!
                var resizedImage = image
                if let pointSize = pointSize, image.size.height > pointSize.height || image.size.width > pointSize.width {
                    resizedImage = image.resizedImage(with: .scaleAspectFit, bounds: pointSize, interpolationQuality: .high)
                }

                // Update the Cache
                Downloader.cache.setObject(resizedImage, forKey: url as AnyObject)
                self?.image = resizedImage
            }
        })

        downloadTask = task
        task.resume()
    }


    /// Stores the current DataTask, in charge of downloading the remote Image
    ///
    private var downloadTask: URLSessionDataTask? {
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
    private struct Downloader {

        /// Stores all of the previously downloaded images
        ///
        static let cache = NSCache<AnyObject, AnyObject>()

        /// Key used to associate a Download task to the current instance
        ///
        static let taskKey = "downloadTaskKey"
    }
}
