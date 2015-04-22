import Foundation


@objc public class NotificationMediaDownloader : NSObject
{
    deinit {
        downloadQueue.cancelAllOperations()
    }
    
    public init(maximumImageWidth: CGFloat) {
        downloadQueue       = NSOperationQueue()
        resizeQueue         = dispatch_queue_create("org.wordpress.notifications.media-downloader", DISPATCH_QUEUE_CONCURRENT)
        mediaMap            = [NSURL: UIImage]()
        retryMap            = [NSURL: Int]()
        maxImageWidth       = maximumImageWidth
        responseSerializer  = AFImageResponseSerializer() as AFImageResponseSerializer
        super.init()
    }
    
    // MARK: - Public Helpers
    public typealias SuccessBlock = (()->())
    
    public func downloadMediaWithUrls(urls: NSSet, completion: SuccessBlock) {
        let allUrls = urls.allObjects as? [NSURL]
        if allUrls == nil {
            return
        }
        
        let missingUrls = allUrls!.filter { self.shouldDownloadImageWithURL($0) }
        if missingUrls.count == 0 {
            return
        }
        
        for url in missingUrls {
            downloadImageWithURL(url) { (NSError error, UIImage downloadedImage) -> () in
                if error != nil || downloadedImage == nil {
                    return
                }
                
                self.resizeImageIfNeeded(downloadedImage!, maxImageWidth: self.maxImageWidth) {
                    (UIImage resizedImage) -> () in
                    self.mediaMap[url] = resizedImage
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
    private func downloadImageWithURL(url: NSURL, callback: ((NSError?, UIImage?) -> ())) {
        let request                     = NSMutableURLRequest(URL: url)
        request.HTTPShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        let operation                   = AFHTTPRequestOperation(request: request)
        operation.responseSerializer    = responseSerializer
        operation.setCompletionBlockWithSuccess({
            [weak self]
            (AFHTTPRequestOperation operation, AnyObject responseObject) -> Void in
            
            if let unwrappedImage = responseObject as? UIImage {
                callback(nil, unwrappedImage)
            }
            
        }, failure: {
            (AFHTTPRequestOperation operation, NSError error) -> Void in
            callback(error, nil)
        })
        
        downloadQueue.addOperation(operation)
        retryMap[url] = retryCountForURL(url) + 1
    }
    
    private func retryCountForURL(url: NSURL) -> Int {
        return retryMap[url] ?? 0
    }
    
    private func shouldDownloadImageWithURL(url: NSURL!) -> Bool {
        // Download only if it's not cached, and if it's not being downloaded right now!
        if url == nil || mediaMap[url] != nil {
            return false
        }
        
        if retryCountForURL(url) > maximumRetryCount {
            return false
        }
        
        for operation in downloadQueue.operations as! [AFHTTPRequestOperation] {
            if operation.request.URL!.isEqual(url) {
                return false
            }
        }
        
        return true
    }    
    
    // MARK: - Async Image Resizing Helpers
    private func resizeImageIfNeeded(image: UIImage, maxImageWidth: CGFloat, callback: ((UIImage) -> ())) {
        if image.size.width <= maxImageWidth {
            callback(image)
            return
        }
        
        // Calculate the target size + Process in BG!
        var targetSize      = image.size
        targetSize.height   = round(maxImageWidth * targetSize.height / targetSize.width)
        targetSize.width    = maxImageWidth
        
        dispatch_async(resizeQueue, { () -> Void in
            let resizedImage = image.imageCroppedToFitSize(targetSize, ignoreAlpha: false)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                callback(resizedImage)
            })
        })
    }
    
    // MARK: - Constants
    private let maximumRetryCount:  Int = 3
    
    // MARK: - Private Properties
    private let responseSerializer: AFHTTPResponseSerializer
    private let downloadQueue:      NSOperationQueue
    private let resizeQueue:        dispatch_queue_t
    private var mediaMap:           [NSURL: UIImage]
    private var retryMap:           [NSURL: Int]
    private let maxImageWidth:      CGFloat
}
