import UIKit
import Gifu

extension UIImageView {
    @MainActor
    public var wp: ImageViewExtensions { ImageViewExtensions(imageView: self) }
}

@MainActor
public struct ImageViewExtensions {
    var imageView: UIImageView

    public func prepareForReuse() {
        controller.prepareForReuse()

        if let gifView = imageView as? GIFImageView {
            gifView.reset()
        } else {
            imageView.image = nil
        }
    }

    /// The image the view displays.
    ///
    /// Setting it cancels a load started with `setImage(with:)`, so that the
    /// load can't replace the new image when it finishes. Use it instead of
    /// `UIImageView.image` on views that also load images with `setImage(with:)`.
    public var image: UIImage? {
        get { imageView.image }
        nonmutating set {
            controller.prepareForReuse()
            if let gifView = imageView as? GIFImageView {
                if let newValue {
                    gifView.configure(image: newValue)
                } else {
                    gifView.reset()
                }
            } else {
                imageView.image = newValue
            }
        }
    }

    public func setImage(with imageURL: URL, host: MediaHostProtocol? = nil, size: ImageSize? = nil) {
        setImage(with: ImageRequest(url: imageURL, host: host, options: ImageRequestOptions(size: size)))
    }

    public func setImage(with request: ImageRequest, completion: (@MainActor (Result<UIImage, Error>) -> Void)? = nil) {
        controller.setImage(with: request, completion: completion)
    }

    public var controller: ImageLoadingController {
        if let controller = objc_getAssociatedObject(imageView, ImageViewExtensions.controllerKey)
            as? ImageLoadingController
        {
            return controller
        }
        let controller = ImageLoadingController()
        // Capture only a weak image view. Capturing `self` would retain the image view
        // strongly, and the image view retains the controller: a retain cycle.
        controller.onStateChanged = { [weak imageView] in
            guard let imageView else { return }
            ImageViewExtensions.setState($0, for: imageView)
        }
        objc_setAssociatedObject(
            imageView,
            ImageViewExtensions.controllerKey,
            controller,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return controller
    }

    private static func setState(_ state: ImageLoadingController.State, for imageView: UIImageView) {
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
