import UIKit
import Combine

final class MediaCollectionCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let overlayView = CircularProgressView()
    private var viewModel: MediaCollectionCellViewModel?
    private var cancellables: [AnyCancellable] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .secondarySystemBackground

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.accessibilityIgnoresInvertColors = true

        overlayView.backgroundColor = .neutral(.shade70).withAlphaComponent(0.5)

        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdges(imageView)

        contentView.addSubview(overlayView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdges(overlayView)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        cancellables = []
        viewModel?.onDisappear()
        viewModel = nil

        imageView.image = nil
        backgroundColor = .secondarySystemBackground
    }

    func configure(viewModel: MediaCollectionCellViewModel) {
        self.viewModel = viewModel

        if let image = viewModel.getCachedThubmnail() {
            // Display with no animations. It should happen often thanks to prefetchig
            imageView.image = image
            backgroundColor = .clear
        } else {
            let mediaID = viewModel.mediaID
            viewModel.onImageLoaded = { [weak self] in
                self?.didLoadImage($0, for: mediaID)
            }
        }

        viewModel.$overlayState.sink { [overlayView] in
            if let state = $0 {
                overlayView.state = state
                overlayView.isHidden = false
            } else {
                overlayView.isHidden = true
            }
        }.store(in: &cancellables)

        viewModel.onAppear()
    }

    private func didLoadImage(_ image: UIImage, for mediaID: TaggedManagedObjectID<Media>) {
        assert(Thread.isMainThread)

        guard viewModel?.mediaID == mediaID else { return }

        // TODO: Display an asset-specific placeholder on error
        imageView.alpha = 0
        UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction]) {
            self.imageView.image = image
            self.imageView.alpha = 1
            self.backgroundColor = .clear
        }
    }
}
