import UIKit
import Gridicons
import WordPressShared

final class MediaItemHeaderView: UIView {
    private let imageView = CachedAnimatedImageView()
    private let errorView = UIImageView()
    private let videoIconView = PlayIconView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private var aspectRatioConstraint: NSLayoutConstraint?
    private var imageSizeConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupImageView()
        setupVideoIconView()
        setupLoadingIndicator()
        setupErrorView()
        setupAccessibility()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    private func setupImageView() {
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 20),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -24),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: readableContentGuide.leadingAnchor, constant: 0),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: readableContentGuide.trailingAnchor, constant: 0),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: 20)
        ])

        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true

        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    private func setupVideoIconView() {
        addSubview(videoIconView)
        videoIconView.isHidden = true
    }

    private func setupLoadingIndicator() {
        addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func setupErrorView() {
        let configuration = UIImage.SymbolConfiguration(pointSize: 42)
        errorView.image = UIImage(systemName: "exclamationmark.triangle", withConfiguration: configuration)
        errorView.tintColor = .secondaryLabel
        errorView.isHidden = true

        addSubview(errorView)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            errorView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func setupAccessibility() {
        accessibilityTraits = .button
        accessibilityLabel = Strings.accessibilityLabel
        accessibilityHint = Strings.accessibilityHint
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        videoIconView.center = center // `PlayIconView` doesn't support constraints
    }

    // MARK: - Media

    func configure(with media: Media) {
        NSLayoutConstraint.deactivate(imageSizeConstraints)
        imageSizeConstraints = []

        switch media.mediaType {
        case .image, .video:
            setImageConstraints(with: media)

            loadingIndicator.startAnimating()
            errorView.isHidden = true

            Task {
                let image = try? await MediaImageService.shared.thumbnail(for: media, size: .medium)
                loadingIndicator.stopAnimating()

                if let gif = image as? AnimatedImageWrapper, let data = gif.gifData {
                    imageView.animate(withGIFData: data)
                } else {
                    imageView.image = image
                }

                errorView.isHidden = image != nil
            }

            videoIconView.isHidden = !(media.mediaType == .video)
        case .document:
            setDocumentTypeIcon(.pages)
        case .audio:
            setDocumentTypeIcon(.audio)
        default:
            break
        }
    }

    private func setDocumentTypeIcon(_ icon: GridiconType) {
        let image = UIImage.gridicon(icon, size: CGSize(width: 96, height: 96))
        setAspectRatio(image.size.height / image.size.width)
        imageView.image = image
    }

    private func setImageConstraints(with media: Media) {
        guard let width = media.width?.floatValue,
              let height = media.height?.floatValue,
              width > 0 else {
            return
        }

        // Configure before the image is loaded to ensure the header
        // size is set to its final size before the image is loaded
        imageSizeConstraints = [
            imageView.widthAnchor.constraint(equalToConstant: CGFloat(width)),
            imageView.heightAnchor.constraint(equalToConstant: CGFloat(height))
        ]
        for constraint in imageSizeConstraints {
            constraint.priority = .defaultHigh
            constraint.isActive = true
        }

        // Prevent the image view from losing the aspect ratio when scaled down
        setAspectRatio(CGFloat(height / width))
    }

    private func setAspectRatio(_ ratio: CGFloat) {
        if let aspectRatioConstraint = aspectRatioConstraint {
            imageView.removeConstraint(aspectRatioConstraint)
        }
        aspectRatioConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: ratio, constant: 1.0)
        aspectRatioConstraint?.isActive = true
    }
}

private enum Strings {
    static let accessibilityLabel = NSLocalizedString("siteMediaItem.contentViewAccessibilityLabel", value: "Preview media", comment: "Accessibility label for media item preview for user's viewing an item in their media library")
    static let accessibilityHint = NSLocalizedString("siteMediaItem.contentViewAccessibilityHint", value: "Tap to view media in full screen", comment: "Accessibility hint for media item preview for user's viewing an item in their media library")
}
