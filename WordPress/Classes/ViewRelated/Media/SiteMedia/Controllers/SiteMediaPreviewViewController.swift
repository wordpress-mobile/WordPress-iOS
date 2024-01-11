import UIKit
import Gifu
import AVKit

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
        case .image:
            preferredContentSize = MediaImageService.getThumbnailSize(for: media, size: .large)
            configureImagePreview()
        case .video:
            preferredContentSize = MediaImageService.getThumbnailSize(for: media, size: .large)
            configureVideoPreview()
        case .document, .audio:
            preferredContentSize = CGSize(width: 180, height: 180)
            configureDocumentPreview()
        default:
            break
        }
    }

    // MARK: - Image

    private func configureImagePreview() {
        imageView.accessibilityIgnoresInvertColors = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        view.pinSubviewToAllEdges(imageView)

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

    // MARK: - Video

    private func configureVideoPreview() {
        media.videoAsset { [weak self] asset, _ in
            if let asset = asset {
                self?.didLoadVideoAsset(asset)
            }
        }
    }
    private func didLoadVideoAsset(_ asset: AVAsset) {
        let controller = AVPlayerViewController()
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        player.isMuted = true
        player.preventsDisplaySleepDuringVideoPlayback = false

        controller.showsPlaybackControls = true
        controller.updatesNowPlayingInfoCenter = false
        controller.player = player

        addChild(controller)
        view.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(controller.view)
        controller.didMove(toParent: self)

        controller.player?.play()
    }

    // MARK: - Document

    private func configureDocumentPreview() {
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
}
