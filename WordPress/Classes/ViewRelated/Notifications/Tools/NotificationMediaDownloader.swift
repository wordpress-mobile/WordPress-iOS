import Foundation


@objc public class NotificationMediaDownloader : NSObject
{
    deinit {
        downloadQueue.cancelAllOperations()
    }
    
    public init(maximumImageWidth: CGFloat) {
        maxImageWidth = maximumImageWidth
        super.init()
    }
    
    // MARK: - Public Helpers
    public typealias SuccessBlock = (Void -> Void)
    
    public func downloadMediaWithUrls(urls: NSSet, completion: SuccessBlock) {
        let allUrls     = urls.allObjects as? [NSURL]
        let missingUrls = allUrls?.filter { self.shouldDownloadImageWithURL($0) }

        missingUrls?.map { (url) in
            self.downloadImage(url) {
                self.resizeImageIfNeeded($0, maxImageWidth: self.maxImageWidth) {
                    self.mediaMap[url] = $0
                    completion()
                }
            }
        }
    }
    
    public func imagesForUrls(urls: [NSURL]) -> [NSURL: UIImage] {
        var filtered = [NSURL: UIImage]()
        
        for (url, image) in mediaMap {
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
            [weak self]
            (AFHTTPRequestOperation operation, AnyObject responseObject) -> Void in
            
            if let unwrappedImage = responseObject as? UIImage {
                success(unwrappedImage)
            }
            
        }, failure: nil)
        
        downloadQueue.addOperation(operation)
        retryMap[url] = retryCount(url) + 1
    }
    
    private func shouldDownloadImageWithURL(url: NSURL) -> Bool {
        if mediaMap[url] != nil || retryCount(url) > maximumRetryCount {
            return false
        }

        let operations  = downloadQueue.operations as? [AFHTTPRequestOperation]
        let filtered    = operations?.filter { $0.request.URL!.isEqual(url) }
        
        return filtered?.count == 0
    }    
    
    private func retryCount(url: NSURL) -> Int {
        return retryMap[url] ?? 0
    }
    
    
    // MARK: - Async Image Resizing Helpers
    private func resizeImageIfNeeded(image: UIImage, maxImageWidth: CGFloat, callback: ((UIImage) -> ())) {
        if image.size.width <= maxImageWidth {
            callback(image)
            return
        }

        var targetSize      = image.size
        targetSize.height   = round(maxImageWidth * targetSize.height / targetSize.width)
        targetSize.width    = maxImageWidth
        
        dispatch_async(resizeQueue) {
            let resizedImage = image.imageCroppedToFitSize(targetSize, ignoreAlpha: false)
            dispatch_async(dispatch_get_main_queue()) {
                callback(resizedImage)
            }
        }
    }
    
    // MARK: - Constants
    private let maximumRetryCount   = 3
    
    // MARK: - Private Properties
    private let responseSerializer  = AFImageResponseSerializer()
    private let downloadQueue       = NSOperationQueue()
    private let resizeQueue         = dispatch_queue_create("notifications.media.resize", DISPATCH_QUEUE_CONCURRENT)
    private var mediaMap            = [NSURL: UIImage]()
    private var retryMap            = [NSURL: Int]()
    private let maxImageWidth:      CGFloat
}
