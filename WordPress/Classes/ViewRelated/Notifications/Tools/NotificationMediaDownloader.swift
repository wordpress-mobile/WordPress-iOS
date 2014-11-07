import Foundation


@objc public class NotificationMediaDownloader : NSObject
{
    deinit {
        downloadQueue.cancelAllOperations()
    }
    
    public override init() {
        downloadQueue       = NSOperationQueue()
        mediaMap            = [NSURL: UIImage]()
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
            downloadImageWithURL(url, callback: { (NSError error, UIImage image) -> () in
                completion()
            })
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
                self?.mediaMap[url] = unwrappedImage
                callback(nil, unwrappedImage)
            }
            
        }, failure: {
            (AFHTTPRequestOperation operation, NSError error) -> Void in
            callback(error, nil)
        })
        
        downloadQueue.addOperation(operation)
    }
    
    private func shouldDownloadImageWithURL(url: NSURL!) -> Bool {
        // Download only if it's not cached, and if it's not being downloaded right now!
        if url == nil || mediaMap[url] != nil {
            return false
        }
        
        for operation in downloadQueue.operations as [AFHTTPRequestOperation] {
            if operation.request.URL.isEqual(url) {
                return false
            }
        }
        
        return true
    }

    
    // MARK: - Private Properties
    private let responseSerializer: AFHTTPResponseSerializer
    private let downloadQueue:      NSOperationQueue
    private var mediaMap:           [NSURL: UIImage]
}
