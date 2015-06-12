import Foundation


/**
*  @class           NotificationMediaDownloader
*  @brief           The purpose of this class is to provide a simple API to download assets from the web.
*  @details         Assets are downloaded, and resized to fit a maximumWidth, specified in the initial download call.
*                   Internally, images get downloaded and resized: both copies of the image get cached.
*                   Since the user may rotate the device, we also provide a second helper (resizeMediaWithIncorrectSize),
*                   which will take care of resizing the original image, to fit the new orientation.
*/

@objc public class NotificationMediaDownloader : NSObject
{
    //
    // MARK: - Public Methods
    //
    deinit {
        downloadQueue.cancelAllOperations()
    }
    
    /**
    *  @brief       Downloads a set of assets, resizes them (if needed), and hits a completion block.
    *  @details     The completion block will get called multiple times (once every time a new asset is
    *               ready for usage), so that the interface can get gradually populated.
    *
    *  @param       urls            Is the collection of unique Image URL's we'd need to download.
    *  @param       maximumWidth    Represents the maximum width that a returned image should have
    *  @param       completion      Is a closure that will get executed each time a new asset is available
    */
    public func downloadMedia(#urls: Set<NSURL>, maximumWidth: CGFloat, completion: SuccessBlock) {
        let missingUrls = filter(urls) { self.shouldDownloadImage(url: $0) }

        for url in missingUrls {
            downloadImage(url) {
                self.originalImagesMap[url] = $0
                
                self.resizeImageIfNeeded($0, maximumWidth: maximumWidth) {
                    self.resizedImagesMap[url] = $0
                    completion()
                }
            }
        }
    }
    
    /**
    *  @brief       Resizes the downloaded media to fit a "new" maximumWidth, if needed.
    *  @details     This method will check the cache of "resized images", and will verify if the original image
    *               *could* be resized again, so that it better fits the *maximumWidth* received.
    *               Useful to handle rotation events: the downloaded images may need to be resized, again, to 
    *               fit onscreen.
    *
    *  @param       maximumWidth    Represents the maximum width that a returned image should have
    *  @param       completion      Is a closure that will get executed each time a new asset is available
    */
    public func resizeMediaWithIncorrectSize(maximumWidth: CGFloat, completion: SuccessBlock) {
        for (url, originalImage) in originalImagesMap {
            let targetSize = cappedImageSize(originalImage.size, maximumWidth: maximumWidth)

            if resizedImagesMap[url]?.size == targetSize {
                continue
            }

            resizeImageIfNeeded(originalImage, maximumWidth: maximumWidth) {
                self.resizedImagesMap[url] = $0
                completion()
            }
        }
    }

    /**
    *  @brief       Returns a collection of images, ready to be displayed onscreen.
    *  @details     For convenience, we return a map with URL as Key, and Image as Value, so that each asset can be
    *               easily addressed.
    *
    *  @param       urls            The collection of URL's of the assets you'd need.
    *  @returns     A dictionary with URL as Key, and Image as Value.
    */
    public func imagesForUrls(urls: [NSURL]) -> [NSURL: UIImage] {
        var filtered = [NSURL: UIImage]()
        
        for (url, image) in resizedImagesMap {
            if contains(urls, url) {
                filtered[url] = image
            }
        }
        
        return filtered
    }
    
    
    //
    // MARK: - Private Helpers
    //
    
    
    /**
    *  @brief       Downloads an asset, given its URL
    *
    *  @param       url             The URL of the media we should download
    *  @param       success         A closure to be executed, on success.
    */
    private func downloadImage(url: NSURL, success: (UIImage -> ())) {
        let request                     = NSMutableURLRequest(URL: url)
        request.HTTPShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        let operation                   = AFHTTPRequestOperation(request: request)
        operation.responseSerializer    = responseSerializer
        operation.setCompletionBlockWithSuccess({
            (AFHTTPRequestOperation operation, AnyObject responseObject) -> Void in
            
            if let unwrappedImage = responseObject as? UIImage {
                success(unwrappedImage)
            }
            
        }, failure: nil)
        
        downloadQueue.addOperation(operation)
        increaseRetryCount(url)
    }
    
    /**
    *  @brief       Checks if an image should be downloaded, or not.
    *  @details     An image should be downloaded if:
    *
    *               -   It's not already being downloaded
    *               -   Isn't already in the cache!
    *               -   Hasn't exceeded the retry count
    *
    *  @param       urls            The collection of URL's of the assets you'd need.
    *  @returns     A dictionary with URL as Key, and Image as Value.
    */
    private func shouldDownloadImage(#url: NSURL) -> Bool {
        let operations  = downloadQueue.operations as? [AFHTTPRequestOperation]
        let filtered    = operations?.filter { $0.request.URL!.isEqual(url) } ?? [AFHTTPRequestOperation]()
        
        return originalImagesMap[url] == nil && checkRetryCount(url) < maximumRetryCount && filtered.isEmpty
    }
    
    /**
    *  @brief       Increases the retry count for a given URL
    *
    *  @param       urls            The URL we're tracking
    */
    private func increaseRetryCount(url: NSURL) {
        retryMap[url] = checkRetryCount(url) + 1
    }

    /**
    *  @brief       Returns the current retry count for a given URL
    *
    *  @param       urls            The URL we're tracking
    *  @return      The current retry count
    */
    private func checkRetryCount(url: NSURL) -> Int {
        return retryMap[url] ?? 0
    }
    
    
    /**
    *  @brief       Resizes -in background- a given image, if needed, to fit a maximum width
    *
    *  @param       image           The image to resize
    *  @param       maximumWidth    The maximum width in which the image should fit
    *  @param       callback        A closure to be called, on the main thread, on completion
    */
    private func resizeImageIfNeeded(image: UIImage, maximumWidth: CGFloat, callback: ((UIImage) -> ())) {
        let targetSize = cappedImageSize(image.size, maximumWidth: maximumWidth)
        if image.size == targetSize {
            callback(image)
            return
        }
        
        dispatch_async(resizeQueue) {
            let resizedImage = image.resizedImage(targetSize, interpolationQuality: kCGInterpolationHigh)
            dispatch_async(dispatch_get_main_queue()) {
                callback(resizedImage)
            }
        }
    }

    /**
    *  @brief       Returns the scaled size, scaled down proportionally (if needed) to fit a maximumWidth
    *
    *  @param       originalSize    The original size of the image
    *  @param       maximumWidth    The maximum width we've got available
    *  @return      The size, scaled down proportionally (if needed) to fit a maximum width
    */
    private func cappedImageSize(originalSize: CGSize, maximumWidth: CGFloat) -> CGSize {
        var targetSize = originalSize

        if targetSize.width > maximumWidth {
            targetSize.height   = round(maximumWidth * targetSize.height / targetSize.width)
            targetSize.width    = maximumWidth
        }
        
        return targetSize
    }
    
    
    // MARK: - Public Aliases
    public typealias SuccessBlock   = (Void -> Void)
    
    // MARK: - Private Constants
    private let maximumRetryCount   = 3
    
    // MARK: - Private Properties
    private let responseSerializer  = AFImageResponseSerializer()
    private let downloadQueue       = NSOperationQueue()
    private let resizeQueue         = dispatch_queue_create("notifications.media.resize", DISPATCH_QUEUE_CONCURRENT)
    private var originalImagesMap   = [NSURL: UIImage]()
    private var resizedImagesMap    = [NSURL: UIImage]()
    private var retryMap            = [NSURL: Int]()
}
