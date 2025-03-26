import UIKit
import Gifu

/// A simple image view that supports rendering both static and animated images
/// (see ``AnimatedImage``).
@MainActor
public final class AsyncImageView: UIView {
    private let imageView = GIFImageView()
    private var errorView: UIImageView?
    private var spinner: UIActivityIndicatorView?
    private let controller = ImageLoadingController()

    public enum LoadingStyle {
        /// Shows a secondary background color during the download.
        case background
        /// Shows a spinner during the download.
        case spinner
    }

    public struct Configuration {
        /// Image tint color.
        public var tintColor: UIColor?

        /// Image view content mode.
        public var contentMode: UIView.ContentMode?

        /// Enabled by default and shows an error icon on failures.
        public var isErrorViewEnabled = true

        /// By default, `background`.
        public var loadingStyle = LoadingStyle.background

        public init() {}
    }

    public var configuration = Configuration() {
        didSet { didUpdateConfiguration(configuration) }
    }

    /// The currently displayed image. If the image is animated, returns an
    /// instance of ``AnimatedImage``.
    public var image: UIImage? {
        didSet {
            if let image {
                imageView.configure(image: image)
            } else {
                imageView.reset()
            }
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        controller.onStateChanged = { [weak self] in self?.setState($0) }

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
        ])

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.accessibilityIgnoresInvertColors = true

        backgroundColor = .secondarySystemBackground
    }

    /// Removes the current image and stops the outstanding downloads.
    public func prepareForReuse() {
        controller.prepareForReuse()
        image = nil
    }

    /// - parameter size: Target image size in pixels.
    public func setImage(
        with imageURL: URL,
        host: MediaHostProtocol? = nil,
        size: ImageSize? = nil
    ) {
        let request = ImageRequest(url: imageURL, host: host, options: ImageRequestOptions(size: size))
        controller.setImage(with: request)
    }

    public func setImage(with request: ImageRequest, completion: (@MainActor (Result<UIImage, Error>) -> Void)? = nil) {
        controller.setImage(with: request, completion: completion)
    }

    private func setState(_ state: ImageLoadingController.State) {
        imageView.isHidden = true
        errorView?.isHidden = true
        spinner?.stopAnimating()

        switch state {
        case .loading:
            switch configuration.loadingStyle {
            case .background:
                backgroundColor = .secondarySystemBackground
            case .spinner:
                makeSpinner().startAnimating()
            }
        case .success(let image):
            self.image = image
            imageView.isHidden = false
            backgroundColor = .clear
        case .failure:
            if configuration.isErrorViewEnabled {
                makeErrorView().isHidden = false
            }
        }
    }

    private func didUpdateConfiguration(_ configuration: Configuration) {
        if let tintColor = configuration.tintColor {
            imageView.tintColor = tintColor
        }
        if let contentMode = configuration.contentMode {
            imageView.contentMode = contentMode
        }
    }

    private func makeSpinner() -> UIActivityIndicatorView {
        if let spinner {
            return spinner
        }
        let spinner = UIActivityIndicatorView()
        addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        self.spinner = spinner
        return spinner
    }

    private func makeErrorView() -> UIImageView {
        if let errorView {
            return errorView
        }
        let errorView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))
        errorView.tintColor = .separator
        addSubview(errorView)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            errorView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        self.errorView = errorView
        return errorView
    }
}

extension GIFImageView {
    /// If the image is an instance of `AnimatedImage` type, plays it as an
    /// animated image.
    public func configure(image: UIImage) {
        if let gif = image as? AnimatedImage, let data = gif.gifData {
            self.animate(withGIFData: data)
        } else {
            self.image = image
        }
    }

    public func reset() {
        if isAnimatingGIF {
            prepareForReuse()
        } else {
            image = nil
        }
    }
}
