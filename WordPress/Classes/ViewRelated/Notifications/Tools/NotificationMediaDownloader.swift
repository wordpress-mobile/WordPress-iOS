import Foundation


@objc public class NotificationMediaDownloader : NSObject
{
    deinit {
        downloadQueue.cancelAllOperations()
    }
    
    // MARK: - Public Helpers
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
    
    public func imagesForUrls(urls: [NSURL]) -> [NSURL: UIImage] {
        var filtered = [NSURL: UIImage]()
        
        for (url, image) in resizedImagesMap {
            if contains(urls, url) {
                filtered[url] = image
            }
        }
        
        return filtered
    }
    
    
    // MARK: - Networking Wrappers
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
    
    private func shouldDownloadImage(#url: NSURL) -> Bool {
        let operations  = downloadQueue.operations as? [AFHTTPRequestOperation]
        let filtered    = operations?.filter { $0.request.URL!.isEqual(url) } ?? [AFHTTPRequestOperation]()
        
        return originalImagesMap[url] == nil && !exceededRetryCount(url) && filtered.isEmpty
    }
    
    
    // MARK: - Retry Helpers
    private func increaseRetryCount(url: NSURL) {
        retryMap[url] = currentRetryCount(url) + 1
    }
    
    private func currentRetryCount(url: NSURL) -> Int {
        return retryMap[url] ?? 0
    }
    
    private func exceededRetryCount(url: NSURL) -> Bool {
        return currentRetryCount(url) >= maximumRetryCount
    }
    
    
    // MARK: - Async Image Resizing Helpers
    private func resizeImageIfNeeded(image: UIImage, maximumWidth: CGFloat, callback: ((UIImage) -> ())) {
        let targetSize = cappedImageSize(image.size, maximumWidth: maximumWidth)
        if image.size == targetSize {
            callback(image)
            return
        }
        
        dispatch_async(resizeQueue) {
            let resizedImage = image.imageScaledToFitSize(targetSize, ignoreAlpha: false)
            dispatch_async(dispatch_get_main_queue()) {
                callback(resizedImage)
            }
        }
    }

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
