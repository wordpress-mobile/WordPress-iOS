import UIKit
import Combine
import Gifu

final class SiteMediaCollectionCell: UICollectionViewCell, Reusable {
    private let imageView = GIFImageView()
    private let overlayView = CircularProgressView()
    private let placeholderView = UIView()
    private var durationView: SiteMediaVideoDurationView?
    private var documentInfoView: SiteMediaDocumentInfoView?
    private var badgeView: SiteMediaCollectionCellBadgeView?

    private var viewModel: SiteMediaCollectionCellViewModel?
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

        imageView.prepareForReuse()
        imageView.image = nil
        imageView.alpha = 0
        placeholderView.alpha = 1
        badgeView?.isHidden = true
        durationView?.isHidden = true
        documentInfoView?.isHidden = true
    }

    func configure(viewModel: SiteMediaCollectionCellViewModel) {
        self.viewModel = viewModel

        if let image = viewModel.getCachedThubmnail() {
            // Display with no animations. It should happen often thanks to prefetching.
            setImage(image)
        } else {
            let mediaID = viewModel.mediaID
            viewModel.onImageLoaded = { [weak self] in
                self?.didLoadImage($0, for: mediaID)
            }
        }

        viewModel.$overlayState
            .sink { [weak self] in self?.didUpdateOverlayState($0) }
            .store(in: &cancellables)

        viewModel.$badge
            .sink { [weak self] in self?.didUpdateBadge($0) }
            .store(in: &cancellables)

        viewModel.$durationText
            .sink { [weak self] in self?.didUpdateDurationText($0) }
            .store(in: &cancellables)

        viewModel.$documentInfo
            .sink { [weak self] in self?.didUpdateDocumentInfo($0) }
            .store(in: &cancellables)

        configureAccessibility(viewModel)

        viewModel.onAppear()
    }

    // MARK: - Refresh

    private func didUpdateOverlayState(_ state: CircularProgressView.State?) {
        if let state {
            overlayView.state = state
            overlayView.isHidden = false
        } else {
            overlayView.isHidden = true
        }
    }

    private func didUpdateBadge(_ badge: SiteMediaCollectionCellViewModel.BadgeType?) {
        if let badge {
            let badgeView = getBadgeView()
            badgeView.isHidden = false
            badgeView.setBadge(badge)
        } else {
            badgeView?.isHidden = true
        }
    }

    private func didUpdateDurationText(_ text: String?) {
        if let text {
            let durationView = getDurationView()
            durationView.isHidden = false
            durationView.textLabel.text = text
        } else {
            durationView?.isHidden = true
        }
    }

    private func didUpdateDocumentInfo(_ viewModel: SiteMediaDocumentInfoViewModel?) {
        if let viewModel {
            let documentInfoView = getDocumentInfoView()
            documentInfoView.isHidden = false
            documentInfoView.configure(viewModel)
        } else {
            documentInfoView?.isHidden = true
        }
    }

    // MARK: - Thumbnails

    private func didLoadImage(_ image: UIImage, for mediaID: TaggedManagedObjectID<Media>) {
        assert(Thread.isMainThread)

        guard viewModel?.mediaID == mediaID else { return }
        setImage(image)
    }

    private func setImage(_ image: UIImage) {
        if let gif = image as? AnimatedImageWrapper, let data = gif.gifData {
            imageView.animate(withGIFData: data)
        } else {
            imageView.image = image
        }
        imageView.alpha = 1
        placeholderView.alpha = 0
    }

    // MARK: - Accessibility

    private func configureAccessibility(_ viewModel: SiteMediaCollectionCellViewModel) {
        isAccessibilityElement = true
        accessibilityLabel = viewModel.accessibilityLabel
        accessibilityHint = viewModel.accessibilityHint
    }

    // MARK: - Helpers

    private func getDocumentInfoView() -> SiteMediaDocumentInfoView {
        if let documentInfoView {
            return documentInfoView
        }
        let documentInfoView = SiteMediaDocumentInfoView()
        contentView.addSubview(documentInfoView)
        documentInfoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            documentInfoView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 0),
            documentInfoView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
            documentInfoView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 4),
            documentInfoView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -4)
        ])
        self.documentInfoView = documentInfoView
        return documentInfoView
    }

    private func getDurationView() -> SiteMediaVideoDurationView {
        if let durationView {
            return durationView
        }
        let durationView = SiteMediaVideoDurationView()
        contentView.addSubview(durationView)
        durationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            durationView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            durationView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
        ])
        self.durationView = durationView
        return durationView
    }

    private func getBadgeView() -> SiteMediaCollectionCellBadgeView {
        if let badgeView {
            return badgeView
        }
        let badgeView = SiteMediaCollectionCellBadgeView()
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
