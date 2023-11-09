import UIKit
import Combine
import Gifu

final class SiteMediaCollectionCell: UICollectionViewCell, Reusable {
    private let imageContainerView = UIView()
    private let imageView = GIFImageView()
    private let overlayView = CircularProgressView()
    private let placeholderView = UIView()
    private var durationView: SiteMediaVideoDurationView?
    private var documentInfoView: SiteMediaDocumentInfoView?
    private var selectionView: SiteMediaCollectionCellSelectionOverlayView?

    private var viewModel: SiteMediaCollectionCellViewModel?
    private var cancellables: [AnyCancellable] = []
    private var aspectRatioConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)

        placeholderView.backgroundColor = .secondarySystemBackground

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.accessibilityIgnoresInvertColors = true

        contentView.addSubview(imageContainerView)
        imageContainerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageContainerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        NSLayoutConstraint.activate([
            imageContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        ].map {
            $0.priority = .init(rawValue: 900)
            return $0
        })

        overlayView.backgroundColor = .neutral(.shade70).withAlphaComponent(0.5)

        imageContainerView.addSubview(placeholderView)
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        imageContainerView.pinSubviewToAllEdges(placeholderView)

        imageContainerView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageContainerView.pinSubviewToAllEdges(imageView)

        imageContainerView.addSubview(overlayView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        imageContainerView.pinSubviewToAllEdges(overlayView)
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
        selectionView?.isHidden = true
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

        viewModel.$badge.combineLatest(viewModel.$durationText)
            .sink { [weak self] in self?.didUpdate(badge: $0, durationText: $1) }
            .store(in: &cancellables)

        viewModel.$documentInfo
            .sink { [weak self] in self?.didUpdateDocumentInfo($0) }
            .store(in: &cancellables)

        configureAccessibility(viewModel)

        viewModel.onAppear()
    }

    func configure(isAspectRatioModeEnabled: Bool) {
        aspectRatioConstraint?.isActive = false
        aspectRatioConstraint = nil

        if isAspectRatioModeEnabled, let aspectRatio = viewModel?.aspectRatio {
            let aspectRatioConstraint = imageContainerView.widthAnchor.constraint(equalTo: imageContainerView.heightAnchor, multiplier: aspectRatio)
            aspectRatioConstraint.isActive = true
            self.aspectRatioConstraint = aspectRatioConstraint
        }
    }

    // MARK: - Refresh

    private func didUpdate(badge: SiteMediaCollectionCellViewModel.BadgeType?, durationText: String?) {
        if let badge {
            let selectionView = getSelectionView()
            selectionView.isHidden = false
            selectionView.setBadge(badge)
        } else {
            selectionView?.isHidden = true
        }

        if let durationText, badge == nil {
            let durationView = getDurationView()
            durationView.isHidden = false
            durationView.textLabel.text = durationText
        } else {
            durationView?.isHidden = true
        }
    }

    private func didUpdateOverlayState(_ state: CircularProgressView.State?) {
        if let state {
            overlayView.state = state
            overlayView.isHidden = false
        } else {
            overlayView.isHidden = true
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
        imageContainerView.addSubview(documentInfoView)
        documentInfoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            documentInfoView.centerXAnchor.constraint(equalTo: imageContainerView.centerXAnchor, constant: 0),
            documentInfoView.centerYAnchor.constraint(equalTo: imageContainerView.centerYAnchor, constant: 0),
            documentInfoView.leadingAnchor.constraint(greaterThanOrEqualTo: imageContainerView.leadingAnchor, constant: 4),
            documentInfoView.trailingAnchor.constraint(lessThanOrEqualTo: imageContainerView.trailingAnchor, constant: -4)
        ])
        self.documentInfoView = documentInfoView
        return documentInfoView
    }

    private func getDurationView() -> SiteMediaVideoDurationView {
        if let durationView {
            return durationView
        }
        let durationView = SiteMediaVideoDurationView()
        imageContainerView.addSubview(durationView)
        durationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            durationView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor, constant: 0),
            durationView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor, constant: 0)
        ])
        self.durationView = durationView
        return durationView
    }

    private func getSelectionView() -> SiteMediaCollectionCellSelectionOverlayView {
        if let selectionView {
            return selectionView
        }
        let selectionView = SiteMediaCollectionCellSelectionOverlayView()
        imageContainerView.addSubview(selectionView)
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(selectionView)
        self.selectionView = selectionView
        return selectionView
    }
}
