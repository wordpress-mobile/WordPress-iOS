import Foundation
import AFNetworking

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
    *  @details     The completion block will get called just once all of the assets are downloaded, and properly sized.
    *
    *  @param       urls            Is the collection of unique Image URL's we'd need to download.
    *  @param       maximumWidth    Represents the maximum width that a returned image should have
    *  @param       completion      Is a closure that will get executed once all of the assets are ready
    */
    public func downloadMedia(urls urls: Set<NSURL>, maximumWidth: CGFloat, completion: SuccessBlock) {
        let missingUrls         = urls.filter { self.shouldDownloadImage(url: $0) }
        let group               = dispatch_group_create()
        let shouldHitCompletion = !missingUrls.isEmpty

        for url in missingUrls {
            
            dispatch_group_enter(group)
            
            downloadImage(url) { (error: NSError?, image: UIImage?) in
                
                // On error: Don't proceed any further
                if error != nil || image == nil {
                    dispatch_group_leave(group)
                    return
                }
                
                // On success: Cache the original image, and resize (if needed)
                self.originalImagesMap[url] = image!
                
                self.resizeImageIfNeeded(image!, maximumWidth: maximumWidth) {
                    self.resizedImagesMap[url] = $0
                    dispatch_group_leave(group)
                }
            }
        }
        
        // When all of the workers are ready, hit the completion callback, *if needed*
        if !shouldHitCompletion {
            return
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            completion()
        }
    }
    
    /**
    *  @brief       Resizes the downloaded media to fit a "new" maximumWidth ***if needed**.
    *  @details     This method will check the cache of "resized images", and will verify if the original image
    *               *could* be resized again, so that it better fits the *maximumWidth* received.
    *               Once all of the images get resized, we'll hit the completion block
    *
    *               Useful to handle rotation events: the downloaded images may need to be resized, again, to 
    *               fit onscreen.
    *
    *  @param       maximumWidth    Represents the maximum width that a returned image should have
    *  @param       completion      Is a closure that will get executed just one time, after all of the assets get resized
    */
    public func resizeMediaWithIncorrectSize(maximumWidth: CGFloat, completion: SuccessBlock) {
        let group               = dispatch_group_create()
        var shouldHitCompletion = false
        
        for (url, originalImage) in originalImagesMap {
            let targetSize      = cappedImageSize(originalImage.size, maximumWidth: maximumWidth)
            let resizedImage    = resizedImagesMap[url]
            
            if resizedImage == nil || resizedImage?.size == targetSize {
                continue
            }
            
            dispatch_group_enter(group)
            shouldHitCompletion = true
            
            resizeImageIfNeeded(originalImage, maximumWidth: maximumWidth) {
                self.resizedImagesMap[url] = $0
                dispatch_group_leave(group)
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            if shouldHitCompletion {
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
            if urls.contains(url) {
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
    *  @details     On failure, this method will attempt the download *maximumRetryCount* times.
    *               If the URL cannot be downloaded, it'll be marked to be skipped.
    *
    *  @param       url             The URL of the media we should download
    *  @param       retryCount      Number of times the download has been attempted
    *  @param       success         A closure to be executed, on success.
    */
    private func downloadImage(url: NSURL, retryCount: Int = 0, completion: ((NSError?, UIImage?) -> ())) {
        let request                     = NSMutableURLRequest(URL: url)
        request.HTTPShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        let operation                   = AFHTTPRequestOperation(request: request)
        operation.responseSerializer    = responseSerializer
        operation.setCompletionBlockWithSuccess({
            (operation, responseObject) -> Void in
            
            if let unwrappedImage = responseObject as? UIImage {
                completion(nil, unwrappedImage)
            } else {
                let error = NSError(domain: self.downloaderDomain, code: self.emptyMediaErrorCode, userInfo: nil)
                completion(error, nil)
            }
            
            self.urlsBeingDownloaded.remove(url)
        }, failure: {
            (operation, error) -> Void in
            
            // If possible, retry
            if retryCount < self.maximumRetryCount {
                self.downloadImage(url, retryCount: retryCount + 1, completion: completion)
                
            // Otherwise, we just failed!
            } else {
                completion(error, nil)
                self.urlsBeingDownloaded.remove(url)
                self.urlsFailed.insert(url)
            }
        })
        
        downloadQueue.addOperation(operation)
        urlsBeingDownloaded.insert(url)
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
    private func shouldDownloadImage(url url: NSURL) -> Bool {
        return originalImagesMap[url] == nil && !urlsBeingDownloaded.contains(url) && !urlsFailed.contains(url)
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
            let resizedImage = image.resizedImage(targetSize, interpolationQuality: .High)
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
    private let emptyMediaErrorCode = -1
    private let downloaderDomain    = "notifications.media.downloader"
    
    // MARK: - Private Properties
    private let responseSerializer  = AFImageResponseSerializer()
    private let downloadQueue       = NSOperationQueue()
    private let resizeQueue         = dispatch_queue_create("notifications.media.resize", DISPATCH_QUEUE_CONCURRENT)
    private var originalImagesMap   = [NSURL: UIImage]()
    private var resizedImagesMap    = [NSURL: UIImage]()
    private var urlsBeingDownloaded = Set<NSURL>()
    private var urlsFailed          = Set<NSURL>()
}
