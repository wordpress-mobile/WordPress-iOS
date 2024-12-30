import Foundation
import UIKit
import Gifu
import WordPressMedia

extension UIImageView {
    @MainActor
    var wp: ImageViewExtensions { ImageViewExtensions(imageView: self) }
}

@MainActor
struct ImageViewExtensions {
    var imageView: UIImageView

    func prepareForReuse() {
        controller.prepareForReuse()

        if let gifView = imageView as? GIFImageView, gifView.isAnimatingGIF {
            gifView.prepareForReuse()
        } else {
            imageView.image = nil
        }
    }

    func setImage(with imageURL: URL, host: MediaHost? = nil, size: ImageSize? = nil) {
        setImage(with: ImageRequest(url: imageURL, host: host, options: ImageRequestOptions(size: size)))
    }

    func setImage(with request: ImageRequest, completion: (@MainActor (Result<UIImage, Error>) -> Void)? = nil) {
        controller.setImage(with: request, completion: completion)
    }

    var controller: ImageLoadingController {
        if let controller = objc_getAssociatedObject(imageView, ImageViewExtensions.controllerKey) as? ImageLoadingController {
            return controller
        }
        let controller = ImageLoadingController()
        controller.onStateChanged = { [weak imageView] in
            guard let imageView else { return }
            setState($0, for: imageView)
        }
        objc_setAssociatedObject(imageView, ImageViewExtensions.controllerKey, controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return controller
    }

    private func setState(_ state: ImageLoadingController.State, for imageView: UIImageView) {
        switch state {
        case .loading:
            break
        case .success(let image):
            if let gifView = imageView as? GIFImageView {
                gifView.configure(image: image)
            } else {
                imageView.image = image
            }
        case .failure:
            break
        }
    }

    private static let controllerKey = malloc(1)!
}
