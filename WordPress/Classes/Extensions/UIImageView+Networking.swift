import Foundation


extension UIImageView {
    @objc public func downloadImage(_ url: URL?, placeholderImage: UIImage?) {
        downloadImage(url, placeholderImage: placeholderImage, success: nil, failure: nil, processImage: nil)
    }

    @objc public func downloadResizedImage(_ url: URL?, placeholderImage: UIImage?, pointSize size: CGSize) {
        let processor: (UIImage) -> UIImage = { image in
            return image.resizedImage(with: .scaleAspectFill, bounds: size, interpolationQuality: .high)
        }
        downloadImage(url, placeholderImage: placeholderImage, success: nil, failure: nil, processImage: processor)
    }

    @objc public func downloadImage(_ url: URL?, placeholderImage: UIImage? = nil, success: ((UIImage) -> ())?, failure: ((Error?) -> ())? = nil, processImage processor: ((UIImage) -> UIImage)? = nil) {
        // Failsafe: Halt if the URL is empty
        guard let unwrappedUrl = url else {
            image = placeholderImage
            return
        }

        let request = NSMutableURLRequest(url: unwrappedUrl)
        request.httpShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")

        setImageWith(request as URLRequest,
            placeholderImage: placeholderImage,
            success: { [weak self]
                (request: URLRequest, response: HTTPURLResponse?, image: UIImage) -> Void in

                let processedImage: UIImage
                if let imageProcessor = processor {
                    processedImage = imageProcessor(image)
                } else {
                    processedImage = image
                }

                self?.image = processedImage
                success?(processedImage)
            },
            failure: { (urlRequest, response: HTTPURLResponse?, error) in
                failure?(error as Error)
            }
        )
    }
}
