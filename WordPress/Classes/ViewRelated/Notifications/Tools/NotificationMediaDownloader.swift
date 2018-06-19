import Foundation


/// The purpose of this class is to provide a simple API to download assets from the web.
/// Assets are downloaded, and resized to fit a maximumWidth, specified in the initial download call.
/// Internally, images get downloaded and resized: both copies of the image get cached.
/// Since the user may rotate the device, we also provide a second helper (resizeMediaWithIncorrectSize),
/// which will take care of resizing the original image, to fit the new orientation.
///
class NotificationMediaDownloader: NSObject {

    /// Active Download Tasks
    ///
    private let imageDownloader = ImageDownloader()

    /// Resize OP's will never hit the main thread
    ///
    private let resizeQueue = DispatchQueue(label: "notifications.media.resize", attributes: .concurrent)

    /// Original Images Cache
    ///
    private var originalImagesMap = [URL: UIImage]()

    /// Resized Images Cache
    ///
    private var resizedImagesMap = [URL: UIImage]()

    /// Collection of the URL(S) with active downloads
    ///
    private var urlsBeingDownloaded = Set<URL>()

    /// Failed downloads collection
    ///
    private var urlsFailed = Set<URL>()



    /// Downloads a set of assets, resizes them (if needed), and hits a completion block.
    /// The completion block will get called just once all of the assets are downloaded, and properly sized.
    ///
    /// - Parameters:
    ///     - urls: Is the collection of unique Image URL's we'd need to download.
    ///     - maximumWidth: Represents the maximum width that a returned image should have.
    ///     - completion: Is a closure that will get executed once all of the assets are ready
    ///
    func downloadMedia(urls: Set<URL>, maximumWidth: CGFloat, completion: @escaping () -> Void) {
        let missingUrls         = urls.filter { self.shouldDownloadImage(url: $0) }
        let group               = DispatchGroup()
        let shouldHitCompletion = !missingUrls.isEmpty

        for url in missingUrls {

            group.enter()

            downloadImage(url) { (error, image) in
                guard let image = image else {
                    group.leave()
                    return
                }

                // On success: Cache the original image, and resize (if needed)
                self.originalImagesMap[url] = image

                self.resizeImageIfNeeded(image, maximumWidth: maximumWidth) {
                    self.resizedImagesMap[url] = $0
                    group.leave()
                }
            }
        }

        // When all of the workers are ready, hit the completion callback, *if needed*
        if !shouldHitCompletion {
            return
        }

        group.notify(queue: .main) {
            completion()
        }
    }

    /// Resizes the downloaded media to fit a "new" maximumWidth ***if needed**.
    /// This method will check the cache of "resized images", and will verify if the original image *could*
    /// be resized again, so that it better fits the *maximumWidth* received.
    /// Once all of the images get resized, we'll hit the completion block
    ///
    /// Useful to handle rotation events: the downloaded images may need to be resized, again, to fit onscreen.
    ///
    /// - Parameters:
    ///     - maximumWidth: Represents the maximum width that a returned image should have
    ///     - completion: Is a closure that will get executed just one time, after all of the assets get resized
    ///
    func resizeMediaWithIncorrectSize(_ maximumWidth: CGFloat, completion: @escaping () -> Void) {
        let group               = DispatchGroup()
        var shouldHitCompletion = false

        for (url, originalImage) in originalImagesMap {
            let targetSize      = cappedImageSize(originalImage.size, maximumWidth: maximumWidth)
            let resizedImage    = resizedImagesMap[url]

            if resizedImage == nil || resizedImage?.size == targetSize {
                continue
            }

            group.enter()
            shouldHitCompletion = true

            resizeImageIfNeeded(originalImage, maximumWidth: maximumWidth) {
                self.resizedImagesMap[url] = $0
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if shouldHitCompletion {
                completion()
            }
        }
    }

    /// Returns a collection of images, ready to be displayed onscreen.
    /// For convenience, we return a map with URL as Key, and Image as Value, so that each asset can be easily
    /// addressed.
    ///
    /// - Parameter urls: The collection of URL's of the assets you'd need.
    ///
    /// - Returns: A dictionary with URL as Key, and Image as Value.
    ///
    func imagesForUrls(_ urls: [URL]) -> [URL: UIImage] {
        var filtered = [URL: UIImage]()

        for (url, image) in resizedImagesMap where urls.contains(url) {
            filtered[url] = image
        }

        return filtered
    }


    // MARK: - Private Helpers


    /// Downloads an asset, given its URL.
    /// - Note: On failure, this method will attempt the download *maximumRetryCount* times.
    ///         If the URL cannot be downloaded, it'll be marked to be skipped.
    ///
    /// - Parameters:
    ///     - url: The URL of the media we should download
    ///     - retryCount: Number of times the download has been attempted
    ///     - success: A closure to be executed, on success.
    ///
    private func downloadImage(_ url: URL, retryCount: Int = 0, completion: @escaping (Error?, UIImage?) -> Void) {
        guard retryCount < Constants.maximumRetryCount else {
            completion(NotificationMediaError.retryCountExceeded, nil)
            urlsBeingDownloaded.remove(url)
            urlsFailed.insert(url)
            return
        }

        imageDownloader.downloadImage(at: url) { (image, error) in
            guard let image = image else {
                self.downloadImage(url, retryCount: retryCount + 1, completion: completion)
                return
            }

            completion(nil, image)
            self.urlsBeingDownloaded.remove(url)
        }

        urlsBeingDownloaded.insert(url)
    }

    /// Checks if an image should be downloaded, or not. An image should be downloaded if:
    ///
    ///     - It's not already being downloaded
    ///     - Isn't already in the cache!
    ///     - Hasn't exceeded the retry count
    ///
    /// - Parameter urls: The collection of URL's of the assets you'd need.
    ///
    /// - Returns: A dictionary with URL as Key, and Image as Value.
    ///
    private func shouldDownloadImage(url: URL) -> Bool {
        return originalImagesMap[url] == nil && !urlsBeingDownloaded.contains(url) && !urlsFailed.contains(url)
    }

    /// Resizes -in background- a given image, if needed, to fit a maximum width
    ///
    /// - Parameters:
    ///     - image: The image to resize
    ///     - maximumWidth: The maximum width in which the image should fit
    ///     - callback: A closure to be called, on the main thread, on completion
    ///
    private func resizeImageIfNeeded(_ image: UIImage, maximumWidth: CGFloat, callback: @escaping (UIImage) -> Void) {
        let targetSize = cappedImageSize(image.size, maximumWidth: maximumWidth)
        if image.size == targetSize {
            callback(image)
            return
        }

        resizeQueue.async {
            let resizedImage = image.resizedImage(targetSize, interpolationQuality: .high)
            DispatchQueue.main.async {
                callback(resizedImage!)
            }
        }
    }

    /// Returns the scaled size, scaled down proportionally (if needed) to fit a maximumWidth
    ///
    /// - Parameters:
    ///     - originalSize: The original size of the image
    ///     - maximumWidth: The maximum width we've got available
    ///
    /// - Returns: The size, scaled down proportionally (if needed) to fit a maximum width
    ///
    private func cappedImageSize(_ originalSize: CGSize, maximumWidth: CGFloat) -> CGSize {
        var targetSize = originalSize

        if targetSize.width > maximumWidth {
            targetSize.height = round(maximumWidth * targetSize.height / targetSize.width)
            targetSize.width = maximumWidth
        }

        return targetSize
    }
}


// MARK: - Settings
//
private extension NotificationMediaDownloader {

    struct Constants {
        static let maximumRetryCount   = 3
    }
}


// MARK: - Errors
//
enum NotificationMediaError: Error {
    case retryCountExceeded
}
