import Foundation
import Gifu

public class CachedAnimatedImageView: UIImageView, GIFAnimatable {

    public lazy var animator: Gifu.Animator? = {
        return Gifu.Animator(withDelegate: self)
    }()

    override public func display(_ layer: CALayer) {
        updateImageIfNeeded()
    }

    @objc func setAnimatedImage(_ urlRequest: URLRequest,
                       placeholderImage: UIImage?,
                       success: ((FLAnimatedImage) -> ())? ,
                       failure: ((NSError?) -> ())? ) {

        if let ongoingTask = currentTask {
            ongoingTask.cancel()
        }

        currentTask = AnimatedImageCache.shared.animatedImage(
            urlRequest,
            placeholderImage: placeholderImage,
            success: { [weak self] (animatedImageData) in
                guard let strongSelf = self else {
                    return
                }
                DispatchQueue.main.async(execute: {
                    strongSelf.animate(withGIFData: animatedImageData)
                })
            },
            failure: failure)
    }


    @objc var currentTask: URLSessionTask?
}

class AnimatedImageCache {

    static let shared: AnimatedImageCache = AnimatedImageCache()

    fileprivate lazy var session: URLSession = {
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration)
        return session
    }()

    fileprivate lazy var cache: NSCache = {
        return NSCache<AnyObject, AnyObject>()
    }()

    func animatedImage(_ urlRequest: URLRequest,
                       placeholderImage: UIImage?,
                       success: ((Data) -> ())? ,
                       failure: ((NSError?) -> ())? ) -> URLSessionTask? {
        if  let key = urlRequest.url,
            let animatedImage = cache.object(forKey: key as AnyObject) as? Data {
            success?(animatedImage)
            return nil
        }
        let task = session.dataTask(with: urlRequest, completionHandler: { [weak self](data, response, error) in
            //check if view is still here
            guard let strongSelf = self else {
                return
            }
            // check if there is an error
            if let error = error {
                failure?(error as NSError?)
                return
            }
            // check if data is here and is animated gif
            guard let data = data else {
                    failure?(nil)
                    return
            }

            if  let key = urlRequest.url {
                strongSelf.cache.setObject(data as NSData, forKey: key as AnyObject)
            }
            success?(data)

            })
        task.resume()
        return task
    }


}
