import UIKit
import Gridicons
import WordPressShared

class MediaItemImageTableViewCell: WPTableViewCell {

    @objc let customImageView = CachedAnimatedImageView()
    @objc let videoIconView = PlayIconView()

    @objc lazy var imageLoader: ImageLoader = {
        return ImageLoader(imageView: customImageView, gifStrategy: .largeGIFs)
    }()

    @objc var isVideo: Bool {
        set {
            videoIconView.isHidden = !newValue
        }
        get {
            return !videoIconView.isHidden
        }
    }

    // MARK: - Initializers
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
        setupVideoIconView()
    }

    private func setupImageView() {
        contentView.addSubview(customImageView)
        customImageView.translatesAutoresizingMaskIntoConstraints = false
        customImageView.contentMode = .scaleAspectFit

        NSLayoutConstraint.activate([
            customImageView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            customImageView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            customImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            customImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])

        customImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    private func setupVideoIconView() {
        contentView.addSubview(videoIconView)
        videoIconView.isHidden = true
    }

    private var aspectRatioConstraint: NSLayoutConstraint? = nil

    @objc var targetAspectRatio: CGFloat {
        set {
            if let aspectRatioConstraint = aspectRatioConstraint {
                customImageView.removeConstraint(aspectRatioConstraint)
            }

            aspectRatioConstraint = customImageView.heightAnchor.constraint(equalTo: customImageView.widthAnchor, multiplier: newValue, constant: 1.0)
            aspectRatioConstraint?.priority = .defaultHigh
            aspectRatioConstraint?.isActive = true
        }
        get {
            return aspectRatioConstraint?.multiplier ?? 0
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        resetBackgroundColors()

        if animated {
            UIView.animate(withDuration: 0.2) {
                self.videoIconView.isHighlighted = highlighted
            }
        } else {
            videoIconView.isHighlighted = highlighted
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        resetBackgroundColors()
    }

    private func resetBackgroundColors() {
        contentView.backgroundColor = .listForeground
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        videoIconView.center = contentView.center
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoader.prepareForReuse()
    }
}

class MediaItemDocumentTableViewCell: WPTableViewCell {
    @objc let customImageView = UIImageView()

    // MARK: - Initializers
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

        contentView.addSubview(customImageView)
        customImageView.translatesAutoresizingMaskIntoConstraints = false
        customImageView.contentMode = .center

        NSLayoutConstraint.activate([
            customImageView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            customImageView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            customImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            customImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
    }

    @objc func showIconForMedia(_ media: Media) {
        let dimension = CGFloat(MediaDocumentRow.customHeight! / 2)
        let size = CGSize(width: dimension, height: dimension)

        if media.mediaType == .audio {
            customImageView.image = Gridicon.iconOfType(.audio, withSize: size)
        } else {
            customImageView.image = Gridicon.iconOfType(.pages, withSize: size)
        }
    }
}

struct MediaImageRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(MediaItemImageTableViewCell.self)

    let media: Media
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewCell(cell)

        if let cell = cell as? MediaItemImageTableViewCell {
            setAspectRatioFor(cell)
            loadImageFor(cell)
            cell.isVideo = media.mediaType == .video
        }
    }

    private func setAspectRatioFor(_ cell: MediaItemImageTableViewCell) {
        guard let width = media.width, let height = media.height, width.floatValue > 0 else {
            return
        }

        let mediaAspectRatio = CGFloat(height.floatValue) / CGFloat(width.floatValue)

        // Set a maximum aspect ratio for videos
        if media.mediaType == .video {
            cell.targetAspectRatio = min(mediaAspectRatio, 0.75)
        } else {
            cell.targetAspectRatio = mediaAspectRatio
        }
    }

    private func addPlaceholderImageFor(_ cell: MediaItemImageTableViewCell) {
        if let url = media.absoluteLocalURL,
            let image = UIImage(contentsOfFile: url.path) {
            cell.customImageView.image = image
        } else if let url = media.absoluteThumbnailLocalURL,
            let image = UIImage(contentsOfFile: url.path) {
            cell.customImageView.image = image
        }
    }

    private var placeholderImage: UIImage? {
        if let url = media.absoluteLocalURL {
            return UIImage(contentsOfFile: url.path)
        } else if let url = media.absoluteThumbnailLocalURL {
            return UIImage(contentsOfFile: url.path)
        }
        return nil
    }

    private func loadImageFor(_ cell: MediaItemImageTableViewCell) {
        cell.imageLoader.loadImage(media: media, placeholder: placeholderImage, success: nil) { (error) in
            self.show(error)
        }
    }

    private func show(_ error: Error?) {
        let alertController = UIAlertController(title: nil, message: NSLocalizedString("There was a problem loading the media item.",
                                                                                       comment: "Error message displayed when the Media Library is unable to load a full sized preview of an item."), preferredStyle: .alert)
        alertController.addCancelActionWithTitle(NSLocalizedString("Dismiss", comment: "Verb. User action to dismiss error alert when failing to load media item."))
        alertController.presentFromRootViewController()
    }
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
        }
    }
}
