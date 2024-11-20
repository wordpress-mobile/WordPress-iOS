import UIKit
import Gifu

/// A simple image view that supports rendering both static and animated images
/// (see ``AnimatedImage``).
@MainActor
final class AsyncImageView: UIView {
    let imageView = GIFImageView()

    private var errorView: UIImageView?
    private var spinner: UIActivityIndicatorView?
    private let controller = ImageViewController()

    enum LoadingStyle {
        case background
        case spinner
    }

    var isErrorViewEnabled = true
    var loadingStyle = LoadingStyle.background

    override init(frame: CGRect) {
        super.init(frame: frame)

        controller.onStateChanged = { [weak self] in self?.setState($0) }

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(imageView)

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.accessibilityIgnoresInvertColors = true

        backgroundColor = .secondarySystemBackground
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForReuse() {
        controller.prepareForReuse()

        if imageView.isAnimatingGIF {
            imageView.prepareForReuse()
        } else {
            imageView.image = nil
        }
    }

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
            switch loadingStyle {
            case .background:
                backgroundColor = .secondarySystemBackground
            case .spinner:
                makeSpinner().startAnimating()
            }
        case .success(let image):
            imageView.configure(image: image)
            imageView.isHidden = false
            backgroundColor = .clear
        case .failure:
            if isErrorViewEnabled {
                makeErrorView().isHidden = false
            }
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
}
