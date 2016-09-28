import Foundation
import FLAnimatedImage

extension FLAnimatedImageView {

    func setAnimatedImage(urlRequest: NSURLRequest,
                          placeholderImage: UIImage?,
                          success:((FLAnimatedImage) -> ())? ,
                          failure:((NSError?) -> ())? )
    {
        let session = NSURLSession.sharedSession()
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
            dispatch_async(dispatch_get_main_queue(), {
                strongSelf.animatedImage = animatedImage
            })

            success?(animatedImage)

        })
        task.resume()
    }
}
