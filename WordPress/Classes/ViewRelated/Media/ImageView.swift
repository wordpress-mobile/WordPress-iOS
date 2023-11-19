import UIKit
import Gifu

/// A simple image view that supports rendering both static and animated images
/// (see ``AnimatedImageWrapper``).
@MainActor
final class ImageView: UIView {
    private let imageView = GIFImageView()
    private var errorView: UIImageView?
    private let service: MediaImageService = .shared
    private var task: Task<Void, Never>?

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

    func setImage(with imageURL: URL) {
        task?.cancel()

        if let image = service.cachedImage(for: imageURL) {
            setState(.success(image))
        } else {
            setState(.loading)
            task = Task { [service, weak self] in
                do {
                    let image = try await service.image(from: imageURL)
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
        errorView?.isHidden = true
        imageView.isHidden = true
        backgroundColor = .secondarySystemBackground

        switch state {
        case .loading:
            break
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

    private func makeErrorView() -> UIImageView {
        if let errorView {
            return errorView
        }
        let errorView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))
        errorView.tintColor = .secondaryLabel
        addSubview(errorView)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewAtCenter(errorView)
        self.errorView = errorView
        return errorView
    }
}
