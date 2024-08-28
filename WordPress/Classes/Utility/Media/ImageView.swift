import UIKit
import Gifu

/// A simple image view that supports rendering both static and animated images
/// (see ``AnimatedImage``).
@MainActor
final class ImageView: UIView {
    let imageView = GIFImageView()

    private var errorView: UIImageView?
    private var spinner: UIActivityIndicatorView?
    private let downloader: ImageDownloader = .shared
    private var task: Task<Void, Never>?

    enum LoadingStyle {
        case background
        case spinner
    }

    var loadingStyle = LoadingStyle.background

    override init(frame: CGRect) {
        super.init(frame: frame)

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

    deinit {
        task?.cancel()
    }

    func prepareForReuse() {
        task?.cancel()
        task = nil

        if imageView.isAnimatingGIF {
            imageView.prepareForReuse()
        } else {
            imageView.image = nil
        }
    }

    // MARK: - Sources

    func setImage(with imageURL: URL, host: MediaHost? = nil, size: CGSize? = nil) {
        task?.cancel()
        task = Task { [downloader, weak self] in

            if let image = await downloader.cachedImage(for: imageURL, size: size) {
                self?.setState(.success(image))
            } else {
                self?.setState(.loading)
                    do {
                        let options = ImageRequestOptions(size: size)
                        let image: UIImage
                        if let host {
                            image = try await downloader.image(from: imageURL, host: host, options: options)
                        } else {
                        image = try await downloader.image(from: imageURL, options: options)
                        }
                        guard !Task.isCancelled else { return }
                        self?.setState(.success(image))
                    } catch {
                        guard !Task.isCancelled else { return }
                        self?.setState(.failure)
                    }
                }
        }
    }

    // MARK: - State

    enum State {
        case loading
        case success(UIImage)
        case failure
    }

    func setState(_ state: State) {
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
            makeErrorView().isHidden = false
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
