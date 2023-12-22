import UIKit
import Gifu

final class SiteMediaPreviewViewController: UIViewController {
    private let imageView = GIFImageView()
    private let media: Media
    private let service = MediaImageService.shared

    init(media: Media) {
        self.media = media
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .secondarySystemBackground

        switch media.mediaType {
        case .image, .video:
            configureImagePreview()
        case .document, .audio:
            configureDocumentPreview()
        default:
            break
        }
    }

    private func configureImagePreview() {
        imageView.accessibilityIgnoresInvertColors = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        view.pinSubviewToAllEdges(imageView)

        preferredContentSize = MediaImageService.getThumbnailSize(for: media, size: .large)

        Task { await loadImage(size: .small) }
        Task { await loadImage(size: .large) }
    }

    private func configureDocumentPreview() {
        preferredContentSize = CGSize(width: 180, height: 180)

        let infoView = SiteMediaDocumentInfoView()
        infoView.configureLargeStyle()
        infoView.configure(.make(with: media))

        let container = UIStackView(arrangedSubviews: [infoView])
        container.alignment = .center
        container.layoutMargins = UIEdgeInsets(allEdges: 8)
        container.isLayoutMarginsRelativeArrangement = true
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        view.pinSubviewToAllEdges(container)
    }

    private func loadImage(size: MediaImageService.ImageSize) async {
        guard let image = try? await service.image(for: media, size: size) else {
            return
        }
        if size == .small && imageView.image != nil {
            return // Loaded the larger image first
        }
        imageView.configure(image: image)
        view.backgroundColor = .clear
    }
}
