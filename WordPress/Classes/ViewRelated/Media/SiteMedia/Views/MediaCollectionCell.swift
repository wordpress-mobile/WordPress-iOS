import UIKit
import Combine

final class MediaCollectionCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let overlayView = CircularProgressView()
    private let placeholderView = UIView()
    private var viewModel: MediaCollectionCellViewModel?
    private var badgeView: MediaCollectionCellBadgeView?
    private var cancellables: [AnyCancellable] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        placeholderView.backgroundColor = .secondarySystemBackground

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.accessibilityIgnoresInvertColors = true

        overlayView.backgroundColor = .neutral(.shade70).withAlphaComponent(0.5)

        contentView.addSubview(placeholderView)
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdges(placeholderView)

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
        imageView.alpha = 0
        placeholderView.alpha = 1
        badgeView?.isHidden = true
    }

    func configure(viewModel: MediaCollectionCellViewModel) {
        self.viewModel = viewModel

        if let image = viewModel.getCachedThubmnail() {
            // Display with no animations. It should happen often thanks to prefetchig
            imageView.image = image
            imageView.alpha = 1
            placeholderView.alpha = 0
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

        viewModel.$badgeText.sink { [weak self] text in
            guard let self else { return }
            if let text {
                let badgeView = self.getBadgeView()
                badgeView.isHidden = false
                badgeView.textLabel.text = text
            } else {
                self.badgeView?.isHidden = true
            }
        }.store(in: &cancellables)

        viewModel.onAppear()
    }

    private func didLoadImage(_ image: UIImage, for mediaID: TaggedManagedObjectID<Media>) {
        assert(Thread.isMainThread)

        guard viewModel?.mediaID == mediaID else { return }

        // TODO: Display an asset-specific placeholder on error
        imageView.image = image
        UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            self.imageView.alpha = 1
            self.placeholderView.alpha = 0
        }
    }

    private func getBadgeView() -> MediaCollectionCellBadgeView {
        if let badgeView {
            return badgeView
        }
        let badgeView = MediaCollectionCellBadgeView()
        contentView.addSubview(badgeView)
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badgeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            badgeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
        self.badgeView = badgeView
        return badgeView
    }
}
