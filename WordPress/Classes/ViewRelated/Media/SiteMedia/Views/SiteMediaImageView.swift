import UIKit
import Gifu
import SwiftUI
import AsyncImageKit
import WordPressUI

struct SiteMediaImage: UIViewRepresentable {
    var media: Media
    var size: MediaImageService.ImageSize
    private var _loadingStyle = SiteMediaImageView.LoadingStyle.background

    init(media: Media, size: MediaImageService.ImageSize) {
        self.media = media
        self.size = size
    }

    func loadingStyle(_ style: SiteMediaImageView.LoadingStyle) -> SiteMediaImage {
        var copy = self
        copy._loadingStyle = style
        return copy
    }

    func makeUIView(context: Context) -> SiteMediaImageView {
        SiteMediaImageView()
    }

    func updateUIView(_ view: SiteMediaImageView, context: Context) {
        view.loadingStyle = _loadingStyle
        view.setImage(with: media, size: size)
    }
}

@MainActor
final class SiteMediaImageView: UIView {
    private let imageView = GIFImageView()
    private var spinner: UIActivityIndicatorView?
    private let controller = SiteMediaImageLoadingController()

    /// By default, `background`.
    var loadingStyle = LoadingStyle.background

    enum LoadingStyle {
        /// Shows a secondary background color during the download.
        case background
        /// Shows a spinner during the download.
        case spinner
    }

    /// The currently displayed image. If the image is animated, returns an
    /// instance of ``AnimatedImage``.
    var image: UIImage? {
        didSet {
            if let image {
                imageView.configure(image: image)
            } else {
                imageView.reset()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        controller.onStateChanged = { [weak self] in self?.setState($0) }

        addSubview(imageView)
        imageView.pinEdges()

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

    func setImage(with media: Media, size: MediaImageService.ImageSize) {
        controller.setImage(with: media, size: size)
    }

    private func setState(_ state: ImageLoadingController.State) {
        imageView.isHidden = true
        spinner?.stopAnimating()
        backgroundColor = .clear

        switch state {
        case .loading:
            switch loadingStyle {
            case .background:
                backgroundColor = .secondarySystemBackground
            case .spinner:
                makeSpinner().startAnimating()
            }
        case .success(let image):
            self.image = image
            imageView.isHidden = false
        case .failure:
            break
        }
    }

    private func makeSpinner() -> UIActivityIndicatorView {
        if let spinner {
            return spinner
        }
        let spinner = UIActivityIndicatorView()
        addSubview(spinner)
        spinner.pinCenter()
        self.spinner = spinner
        return spinner
    }
}
