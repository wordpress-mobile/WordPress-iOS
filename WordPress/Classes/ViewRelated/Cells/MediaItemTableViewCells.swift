import UIKit
import Gridicons
import WordPressShared

#warning("TODO: remove unused imports")
#warning("TODO: add suppport for other formats")

final class MediaItemHeaderView: UIView {
    #warning("TODO: what about loaded image?")
    var loadedImage: UIImage? { imageView.image }

    let imageView = CachedAnimatedImageView()
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

    private var targetAspectRatio: CGFloat {
        set {
            if let aspectRatioConstraint = aspectRatioConstraint {
                imageView.removeConstraint(aspectRatioConstraint)
            }
            aspectRatioConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: newValue, constant: 1.0)
            aspectRatioConstraint?.isActive = true
        }
        get {
            return aspectRatioConstraint?.multiplier ?? 0
        }
    }

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

#warning("TODO: is the image size OK?")
#warning("TODO: improve error handling")
            print("did-load-image", image?.size)

            #warning("TODO: check image size; are we loading images that are too large?")
            #warning("TODO: verify that fullscreen image gets loaded")
        }

        isVideo = media.mediaType == .video
    }

    private func setAspectRatio(with media: Media) {
        guard let width = media.width, let height = media.height, width.floatValue > 0 else {
            return
        }

        let mediaAspectRatio = CGFloat(height.floatValue) / CGFloat(width.floatValue)

        // Set a maximum aspect ratio for videos
        if media.mediaType == .video {
            targetAspectRatio = min(mediaAspectRatio, 0.75)
        } else {
            targetAspectRatio = mediaAspectRatio
        }
    }

    private func placeholder(for media: Media) -> UIImage? {
        if let url = media.absoluteLocalURL {
            return UIImage(contentsOfFile: url.path)
        } else if let url = media.absoluteThumbnailLocalURL {
            return UIImage(contentsOfFile: url.path)
        }
        return nil
    }
}

class MediaItemDocumentTableViewCell: WPTableViewCell {
    @objc let customImageView = UIImageView()

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    public required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    public convenience init() {
        self.init(style: .default, reuseIdentifier: nil)
    }

    @objc func commonInit() {
        setupImageView()
    }

    private func setupImageView() {
        customImageView.backgroundColor = .clear

        addSubview(customImageView)
        customImageView.translatesAutoresizingMaskIntoConstraints = false
        customImageView.contentMode = .center

        NSLayoutConstraint.activate([
            customImageView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            customImageView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            customImageView.topAnchor.constraint(equalTo: topAnchor),
            customImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
    }

    @objc func showIconForMedia(_ media: Media) {
        let dimension = CGFloat(MediaDocumentRow.customHeight! / 2)
        let size = CGSize(width: dimension, height: dimension)

        if media.mediaType == .audio {
            customImageView.image = .gridicon(.audio, size: size)
        } else {
            customImageView.image = .gridicon(.pages, size: size)
        }
    }
}

struct MediaImageTableHeaderViewModel {
    let media: Media
    let action: ImmuTableAction?
}

struct MediaDocumentRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(MediaItemDocumentTableViewCell.self)
    static let customHeight: Float? = 96.0

    let media: Media
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewCell(cell)

        if let cell = cell as? MediaItemDocumentTableViewCell {
            cell.customImageView.tintColor = cell.textLabel?.textColor
            cell.showIconForMedia(media)
            cell.accessibilityTraits = .button
            cell.accessibilityLabel = NSLocalizedString("Preview media", comment: "Accessibility label for media item preview for user's viewing an item in their media library")
            cell.accessibilityHint = NSLocalizedString("Tap to view media in full screen", comment: "Accessibility hint for media item preview for user's viewing an item in their media library")
        }
    }
}
