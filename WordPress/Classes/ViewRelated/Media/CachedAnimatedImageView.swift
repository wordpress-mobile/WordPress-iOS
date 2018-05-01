import Foundation
import Gifu

public class CachedAnimatedImageView: UIImageView, GIFAnimatable {

    @objc var currentTask: URLSessionTask?

    public lazy var animator: Gifu.Animator? = {
        return Gifu.Animator(withDelegate: self)
    }()

    override public func display(_ layer: CALayer) {
        updateImageIfNeeded()
    }

    @objc func setAnimatedImage(_ urlRequest: URLRequest,
                       placeholderImage: UIImage?,
                       success: (() -> Void)? ,
                       failure: ((NSError?) -> Void)? ) {

        if let ongoingTask = currentTask {
            ongoingTask.cancel()
        }

        let successBlock: (Data) -> Void = { [weak self] animatedImageData in
            guard let strongSelf = self else {
                return
            }
            DispatchQueue.main.async(execute: {
                strongSelf.animate(withGIFData: animatedImageData, loopCount: 0, completionHandler: {
                    success?()
                })
            })
        }

        currentTask = AnimatedImageCache.shared.animatedImage(urlRequest,
                                                              placeholderImage: placeholderImage,
                                                              success: successBlock,
                                                              failure: failure)
    }

    @objc func prepForReuse() {
        self.prepareForReuse()
    }
}

class AnimatedImageCache {

    static let shared: AnimatedImageCache = AnimatedImageCache()

    fileprivate lazy var session: URLSession = {
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration)
        return session
    }()

    fileprivate lazy var cache: NSCache<NSURL, NSData> = {
        return NSCache<NSURL, NSData>()
    }()

    func animatedImage(_ urlRequest: URLRequest,
                       placeholderImage: UIImage?,
                       success: ((Data) -> Void)? ,
                       failure: ((NSError?) -> Void)? ) -> URLSessionTask? {

        if  let key = urlRequest.url,
            let animatedImageData = cache.object(forKey: key as NSURL) {

            success?(animatedImageData as Data)
            return nil
        }

        let task = session.dataTask(with: urlRequest, completionHandler: { [weak self](data, response, error) in
            //check if view is still here
            guard let strongSelf = self else {
                return
            }
            // check if there is an error
            if let error = error {
                failure?(error as NSError)
                return
            }
            // check if data is here and is animated gif
            guard let data = data else {
                failure?(nil)
                return
            }

            if  let key = urlRequest.url {
                strongSelf.cache.setObject(data as NSData, forKey: key as NSURL)
            }
            success?(data)
        })

        task.resume()
        return task
    }
}
