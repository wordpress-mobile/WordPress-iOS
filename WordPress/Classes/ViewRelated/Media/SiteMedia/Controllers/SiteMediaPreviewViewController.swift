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

        imageView.accessibilityIgnoresInvertColors = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        view.pinSubviewToAllEdges(imageView)

        preferredContentSize = MediaImageService.getThumbnailSize(for: media, size: .large)

        Task { await loadImage(size: .small) }
        Task { await loadImage(size: .large) }
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
