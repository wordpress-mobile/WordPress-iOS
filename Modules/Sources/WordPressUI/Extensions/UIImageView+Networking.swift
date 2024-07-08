import Foundation
import UIKit

#if SWIFT_PACKAGE
import WordPressUIObjC
#endif

public extension UIImageView {
    enum ImageDownloadError: Error {
        case noURLSpecifiedInRequest
        case urlMismatch
    }

    /// Downloads an image and updates the current UIImageView Instance.
    ///
    /// - Parameters:
    ///     -   url: The target Image's URL.
    ///     -   placeholderImage: Image to be displayed while the actual asset gets downloaded.
    ///     -   pointSize: *Maximum* allowed size. if the actual asset exceeds this size, we'll shrink it down.
    ///
    @objc func downloadResizedImage(from url: URL?, placeholderImage: UIImage? = nil, pointSize: CGSize) {
        downloadImage(from: url, placeholderImage: placeholderImage, success: { [weak self] image in
            guard image.size.height > pointSize.height || image.size.width > pointSize.width else {
                self?.image = image
                return
            }

            self?.image = image.resizedImage(with: .scaleAspectFit, bounds: pointSize, interpolationQuality: .high)
        })
    }

    /// Downloads an image and updates the current UIImageView Instance.
    ///
    /// - Parameters:
    ///     -   url: The URL of the target image
    ///     -   placeholderImage: Image to be displayed while the actual asset gets downloaded.
    ///     -   success: Closure to be executed on success.
    ///     -   failure: Closure to be executed upon failure.
    ///
    @objc func downloadImage(from url: URL?, placeholderImage: UIImage? = nil, success: ((UIImage) -> Void)? = nil, failure: ((Error?) -> Void)? = nil) {
        // Ideally speaking, this method should *not* receive an Optional URL. But we're doing so, for convenience.
        // If the actual URL was nil, at least we set the Placeholder Image. Capicci?
        guard let url = url else {
            cancelImageDownload()

            if let placeholderImage = placeholderImage {
                self.image = placeholderImage
            }

            return
        }

        let request = self.request(for: url)
        downloadImage(usingRequest: request, placeholderImage: placeholderImage, success: success, failure: failure)
    }

    /// Downloads an image and updates the current UIImageView Instance.
    ///
    /// - Parameters:
    ///     -   request: The request for the target image
    ///     -   placeholderImage: Image to be displayed while the actual asset gets downloaded.
    ///     -   success: Closure to be executed on success.
    ///     -   failure: Closure to be executed upon failure.
    ///
    @objc func downloadImage(usingRequest request: URLRequest, placeholderImage: UIImage? = nil, success: ((UIImage) -> Void)? = nil, failure: ((Error?) -> Void)? = nil) {
        cancelImageDownload()

        let handleSuccess = { [weak self] (image: UIImage, _: URL) in
            self?.image = image
            success?(image)
        }

        guard let url = request.url else {
            if let placeholderImage = placeholderImage {
                image = placeholderImage
            }

            failure?(ImageDownloadError.noURLSpecifiedInRequest)
            return
        }

        if let cachedImage = ImageCache.shared.getImage(forKey: url.absoluteString) {
            handleSuccess(cachedImage, url)
            return
        }

        // Using the placeholder only makes sense if we know we're going to download an image
        // that's not immediately available to us.
        if let placeholderImage = placeholderImage {
            self.image = placeholderImage
        }

        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data, scale: UIScreen.main.scale) else {
                DispatchQueue.main.async {
                    failure?(error)
                    self?.downloadTask = nil
                }
                return
            }

            DispatchQueue.main.async {
                if response?.url == url {
                    ImageCache.shared.setImage(image, forKey: url.absoluteString)
                    handleSuccess(image, url)
                } else {
                    failure?(ImageDownloadError.urlMismatch)
                }

                self?.downloadTask = nil
            }
        })

        downloadTask = task
        task.resume()
    }

    /// Overrides the cached UIImage, for a given URL. This is useful for whenever we've just updated a remote resource,
    /// and we need to prevent returning the (old) cached entry.
    ///
    @objc func overrideImageCache(for url: URL, with image: UIImage) {
        ImageCache.shared.setImage(image, forKey: url.absoluteString)

        // Remove all cached responses - removing an individual response does not work since iOS 7.
        // This feels hacky to do but what else can we do...
        //
        // Update: Years have gone by (iOS 11 era). Still broken. Still ashamed about this. Thank you, Apple.
        //
        URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
    }

    /// Cancels the current download task and clear the downloadURL
    ///
    @objc func cancelImageDownload() {
        downloadTask?.cancel()
        downloadTask = nil
    }

    /// Returns a URLRequest for an image, hosted at the specified URL.
    ///
    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")

        return request
    }

    /// Stores the current DataTask, in charge of downloading the remote Image.
    ///
    private var downloadTask: URLSessionDataTask? {
        get {
            return objc_getAssociatedObject(self, &Downloader.taskKey) as? URLSessionDataTask
        }
        set {
            objc_setAssociatedObject(self, &Downloader.taskKey, newValue as AnyObject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Private helper structure
    ///
    private struct Downloader {
        /// Key used to associate the current URL.
        ///
        static var urlKey = 0x1000

        /// Key used to associate a Download task to the current instance.
        ///
        static var taskKey = 0x1001
    }
}

public protocol ImageCaching {
    func setImage(_ image: UIImage, forKey key: String)
    func getImage(forKey key: String) -> UIImage?
}

public class ImageCache: ImageCaching {
    private let cache = NSCache<NSString, UIImage>()

    /// Changes the default cache used by the image dowloader.
    public static var shared: ImageCaching = ImageCache()

    public func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    public func getImage(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
}
