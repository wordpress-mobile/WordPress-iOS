import UIKit
import Gridicons
import WordPressShared

final class MediaItemHeaderView: UIView {
    private let imageView = CachedAnimatedImageView()
    private let errorView = UIImageView()
    private let videoIconView = PlayIconView()
    let loadingIndicator = UIActivityIndicatorView(style: .large)

    private var isVideo: Bool {
        set {
            videoIconView.isHidden = !newValue
        }
        get {
            return !videoIconView.isHidden
        }
    }

    private var aspectRatioConstraint: NSLayoutConstraint? = nil

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

#warning("TODO: resize to fit readable content width")
#warning("TODO: fix portraint mode on iPad (dynamic size? max height 320 or smth?)")
    private func setupImageView() {
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let inset: CGFloat = 16
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: inset),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -inset),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: inset),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -inset)
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
        accessibilityLabel = NSLocalizedString("Preview media", comment: "Accessibility label for media item preview for user's viewing an item in their media library")
        accessibilityHint = NSLocalizedString("Tap to view media in full screen", comment: "Accessibility hint for media item preview for user's viewing an item in their media library")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        videoIconView.center = center
    }

    // MARK: - Media

    func configure(with media: Media) {
        switch media.mediaType {
        case .image, .video:
            setAspectRatio(with: media)

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

            isVideo = media.mediaType == .video
        case .document:
            aspectRatioConstraint.map(imageView.removeConstraint)
            imageView.image = UIImage.gridicon(.pages, size: Constants.documentTypeIconSize)
        case .audio:
            aspectRatioConstraint.map(imageView.removeConstraint)
            imageView.image = UIImage.gridicon(.audio, size: Constants.documentTypeIconSize)
        default:
            break
        }
    }

    private func setAspectRatio(with media: Media) {
        guard let width = media.width, let height = media.height, width.floatValue > 0 else {
            return
        }
        let aspectRatio = CGFloat(height.floatValue / width.floatValue)
        setAspectRatio(aspectRatio)
    }

    private func setAspectRatio(_ ratio: CGFloat) {
        if let aspectRatioConstraint = aspectRatioConstraint {
            imageView.removeConstraint(aspectRatioConstraint)
        }
        aspectRatioConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: ratio, constant: 1.0)
        aspectRatioConstraint?.isActive = true
    }
}

private enum Constants {
    static let documentTypeIconSize = CGSize(width: 80, height: 80)
}
