import Foundation


extension UIImageView
{
    public func downloadImage(url: NSURL?, placeholderImage: UIImage?) {
        downloadImage(url, placeholderImage: placeholderImage, success: nil, failure: nil, processImage: nil)
    }

    public func downloadResizedImage(url: NSURL?, placeholderImage: UIImage?, pointSize size: CGSize) {
        let processor: UIImage -> UIImage = { image in
            return image.resizedImageWithContentMode(.ScaleAspectFill, bounds: size, interpolationQuality: .High)
        }
        downloadImage(url, placeholderImage: placeholderImage, success: nil, failure: nil, processImage: processor)
    }

    public func downloadImage(url: NSURL?, placeholderImage: UIImage?, success: ((UIImage) -> ())?, failure: ((NSError!) -> ())?, processImage processor: (UIImage -> UIImage)? = nil) {
        // Failsafe: Halt if the URL is empty
        guard let unwrappedUrl = url else {
            image = placeholderImage
            return
        }

        let request = NSMutableURLRequest(URL: unwrappedUrl)
        request.HTTPShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")

        setImageWithURLRequest(request,
            placeholderImage: placeholderImage,
            success: { [weak self]
                (request: NSURLRequest, response: NSHTTPURLResponse?, image: UIImage) -> Void in

                let processedImage: UIImage
                if let imageProcessor = processor {
                    processedImage = imageProcessor(image)
                } else {
                    processedImage = image
                }

                self?.image = processedImage
                success?(processedImage)
            },
            failure: {
                (request: NSURLRequest, response: NSHTTPURLResponse?, error: NSError) -> Void in
                failure?(error)
            }
        )
    }
}
