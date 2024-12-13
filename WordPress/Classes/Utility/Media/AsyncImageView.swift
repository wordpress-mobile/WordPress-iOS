import UIKit
import Gifu
import WordPressMedia

/// A simple image view that supports rendering both static and animated images
/// (see ``AnimatedImage``).
@MainActor
final class AsyncImageView: UIView {
    private let imageView = GIFImageView()
    private var errorView: UIImageView?
    private var spinner: UIActivityIndicatorView?
    private let controller = ImageViewController()

    enum LoadingStyle {
        /// Shows a secondary background color during the download.
        case background
        /// Shows a spinner during the download.
        case spinner
    }

    struct Configuration {
        /// Image tint color.
        var tintColor: UIColor?

        /// Image view content mode.
        var contentMode: UIView.ContentMode?

        /// Enabled by default and shows an error icon on failures.
        var isErrorViewEnabled = true

        /// By default, `background`.
        var loadingStyle = LoadingStyle.background
    }

    var configuration = Configuration() {
        didSet { didUpdateConfiguration(configuration) }
    }

    /// The currently displayed image. If the image is animated, returns an
    /// instance of ``AnimatedImage``.
    var image: UIImage? {
        didSet {
            if let image {
                imageView.configure(image: image)
            } else {
                imageView.prepareForReuse()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        controller.onStateChanged = { [weak self] in self?.setState($0) }

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(imageView)

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.accessibilityIgnoresInvertColors = true

        backgroundColor = .secondarySystemBackground
    }

    /// Removes the current image and stops the outstanding downloads.
    func prepareForReuse() {
        controller.prepareForReuse()
        image = nil
    }

    /// - parameter size: Target image size in pixels.
    func setImage(
        with imageURL: URL,
        host: MediaHost? = nil,
        size: CGSize? = nil,
        completion: (@MainActor (Result<UIImage, Error>) -> Void)? = nil
    ) {
        controller.setImage(with: imageURL, host: host, size: size, completion: completion)
    }

    private func setState(_ state: ImageViewController.State) {
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
        pinSubviewAtCenter(spinner)
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
        pinSubviewAtCenter(errorView)
        self.errorView = errorView
        return errorView
    }
}

extension GIFImageView {
    /// If the image is an instance of `AnimatedImage` type, plays it as an
    /// animated image.
    func configure(image: UIImage) {
        if let gif = image as? AnimatedImage, let data = gif.gifData {
            self.animate(withGIFData: data)
        } else {
            self.image = image
        }
    }

    private func prepareForReuse() {
        if isAnimatingGIF {
            prepareForReuse()
        } else {
            image = nil
        }
    }
}
