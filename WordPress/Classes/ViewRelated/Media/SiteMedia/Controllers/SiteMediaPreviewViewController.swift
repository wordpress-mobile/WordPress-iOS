import UIKit
import Gifu
import AVKit
import SwiftUI
import WordPressData

struct SiteMediaPreviewView: UIViewControllerRepresentable {
    let media: Media

    func makeUIViewController(context: Context) -> SiteMediaPreviewViewController {
        // TODO: Modernization - The preview size is derived from `UIScreen.main` inside the
        // deprecated `init(media:)`. Read the available size with `GeometryReader` in the
        // SwiftUI view that presents this preview (`PostMediaUploadsView`) and pass it via
        // `init(media:bounds:)`.
        SiteMediaPreviewViewController(media: media)
    }

    func updateUIViewController(_ vc: SiteMediaPreviewViewController, context: Context) {
        // Do nothing
    }
}

final class SiteMediaPreviewViewController: UIViewController {
    private let imageView = GIFImageView()
    private let media: Media
    private let bounds: CGRect
    private let service = MediaImageService.shared

    @available(*, deprecated, message: "use init(media:bounds:) and pass the bounds of the presenting view")
    convenience init(media: Media) {
        // TODO: Modernization - `UIScreen.main` assumes a single, fixed display. Pass the
        // presenting view's bounds via `init(media:bounds:)` instead.
        self.init(media: media, bounds: UIScreen.main.bounds)
    }

    /// - parameter bounds: The bounds of the view that presents the preview.
    /// They determine the size of the thumbnail the preview loads.
    init(media: Media, bounds: CGRect) {
        self.media = media
        self.bounds = bounds
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
            preferredContentSize = MediaImageService.getThumbnailSize(
                for: media,
                size: .large,
                bounds: bounds,
                traitCollection: traitCollection
            )
            configureImagePreview()
        case .video:
            preferredContentSize = MediaImageService.getThumbnailSize(
                for: media,
                size: .large,
                bounds: bounds,
                traitCollection: traitCollection
            )
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
            if let asset {
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
        container.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        container.isLayoutMarginsRelativeArrangement = true
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        view.pinSubviewToAllEdges(container)
    }
}
