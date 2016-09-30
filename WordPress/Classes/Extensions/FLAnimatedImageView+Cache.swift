import Foundation
import FLAnimatedImage

public class CachedAnimatedImageView: FLAnimatedImageView {

    var currentTask: NSURLSessionTask?

    func setAnimatedImage(urlRequest: NSURLRequest,
                          placeholderImage: UIImage?,
                          success:((FLAnimatedImage) -> ())? ,
                          failure:((NSError?) -> ())? )
    {
        if let ongoingTask = currentTask {
            ongoingTask.cancel()
        }
        currentTask = AnimatedImageCache.shared.animatedImage(urlRequest,
                                                placeholderImage: placeholderImage,
                                                success: { [weak self](animatedImage) in
                                                    guard let strongSelf = self else {
                                                        return
                                                    }
                                                    dispatch_async(dispatch_get_main_queue(), {
                                                        strongSelf.animatedImage = animatedImage
                                                    })
                                                },
                                                failure: failure)
    }
}

class AnimatedImageCache {

    static let shared: AnimatedImageCache = AnimatedImageCache()

    private lazy var session: NSURLSession = {
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfiguration)
        return session
    }()

    private lazy var cache: NSCache = {
        return NSCache()
    }()

    func animatedImage(urlRequest: NSURLRequest,
                       placeholderImage: UIImage?,
                       success:((FLAnimatedImage) -> ())? ,
                       failure:((NSError?) -> ())? ) -> NSURLSessionTask?
    {
        if  let key = urlRequest.URL,
            let animatedImage = cache.objectForKey(key) as? FLAnimatedImage {
            success?(animatedImage)
            return nil
        }
        let task = session.dataTaskWithRequest(urlRequest, completionHandler:{ [weak self](data, response, error) in
            //check if view is still here
            guard let strongSelf = self else {
                return
            }
            // check if there is an error
            if let error = error {
                failure?(error)
                return
            }
            // check if data is here and is animated gif
            guard
                let data = data,
                let animatedImage = FLAnimatedImage(animatedGIFData: data)
                else {
                    failure?(nil)
                    return
            }

            if  let key = urlRequest.URL {
                strongSelf.cache.setObject(animatedImage, forKey: key)
            }
            success?(animatedImage)

            })
        task.resume()
        return task
    }


}
