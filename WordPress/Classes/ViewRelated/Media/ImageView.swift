import UIKit
import Gifu

/// A simple image view that supports rendering both static and animated images
/// (see ``AnimatedImageWrapper``).
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

    func setImage(with imageURL: URL, size: CGSize? = nil) {
        task?.cancel()

        if let image = downloader.cachedImage(for: imageURL, size: size) {
            setState(.success(image))
        } else {
            setState(.loading)
            task = Task { [downloader, weak self] in
                do {
                    let options = ImageRequestOptions(size: size)
                    let image = try await downloader.image(from: imageURL, options: options)
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
            if let gif = image as? AnimatedImageWrapper, let data = gif.gifData {
                imageView.animate(withGIFData: data)
            } else {
                imageView.image = image
            }
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
