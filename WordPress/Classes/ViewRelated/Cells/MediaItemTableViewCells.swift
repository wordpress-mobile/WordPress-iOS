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
}

struct MediaImageRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(MediaItemImageTableViewCell.self)

    let mediaID: TaggedManagedObjectID<Media>
    let isBlogAtomic: Bool
    let placeholderURL: URL?
    let mediaType: MediaType
    let size: CGSize?
    let action: ImmuTableAction?

    init(media: Media, action: ImmuTableAction?) {
        self.mediaID = .init(media)
        self.mediaType = media.mediaType
        if let width = media.width, let height = media.height, width.floatValue > 0 {
            self.size = CGSize(width: width.doubleValue, height: height.doubleValue)
        } else {
            self.size = nil
        }
        self.placeholderURL = media.absoluteLocalURL ?? media.absoluteThumbnailLocalURL
        self.isBlogAtomic = media.blog.isAtomic()

        self.action = action
    }

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewCell(cell)

        if let cell = cell as? MediaItemImageTableViewCell {
            setAspectRatioFor(cell)
            loadImageFor(cell)
            cell.isVideo = mediaType == .video
            cell.accessibilityTraits = .button
            cell.accessibilityLabel = NSLocalizedString("Preview media", comment: "Accessibility label for media item preview for user's viewing an item in their media library")
            cell.accessibilityHint = NSLocalizedString("Tap to view media in full screen", comment: "Accessibility hint for media item preview for user's viewing an item in their media library")
        }
    }

    private func setAspectRatioFor(_ cell: MediaItemImageTableViewCell) {
        guard let size else {
            return
        }

        let mediaAspectRatio = size.height / size.width

        // Set a maximum aspect ratio for videos
        if mediaType == .video {
            cell.targetAspectRatio = min(mediaAspectRatio, 0.75)
        } else {
            cell.targetAspectRatio = mediaAspectRatio
        }
    }

    private var placeholderImage: UIImage? {
        if let url = placeholderURL {
            return UIImage(contentsOfFile: url.path)
        }
        return nil
    }

    private func loadImageFor(_ cell: MediaItemImageTableViewCell) {
        guard let media = try? ContextManager.shared.mainContext.existingObject(with: mediaID) else {
            return
        }
        cell.imageLoader.loadImage(media: media, placeholder: placeholderImage, isBlogAtomic: isBlogAtomic, success: nil) { (error) in
            self.show(error)
        }
    }

    private func show(_ error: Error?) {
        let alertController = UIAlertController(title: nil, message: NSLocalizedString("There was a problem loading the media item.",
                                                                                       comment: "Error message displayed when the Media Library is unable to load a full sized preview of an item."), preferredStyle: .alert)
        alertController.addCancelActionWithTitle(NSLocalizedString(
            "mediaItemTable.errorAlert.dismissButton",
            value: "Dismiss",
            comment: "Verb. User action to dismiss error alert when failing to load media item."
        ))
        alertController.presentFromRootViewController()
    }
}

struct MediaDocumentRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(MediaItemDocumentTableViewCell.self)
    static let customHeight: Float? = 96.0

    let mediaType: MediaType
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewCell(cell)

        if let cell = cell as? MediaItemDocumentTableViewCell {
            cell.customImageView.tintColor = cell.textLabel?.textColor

            let dimension = CGFloat(MediaDocumentRow.customHeight! / 2)
            let size = CGSize(width: dimension, height: dimension)
            cell.customImageView.image = .gridicon(mediaType == .audio ? .audio : .pages, size: size)

            cell.accessibilityTraits = .button
            cell.accessibilityLabel = NSLocalizedString("Preview media", comment: "Accessibility label for media item preview for user's viewing an item in their media library")
            cell.accessibilityHint = NSLocalizedString("Tap to view media in full screen", comment: "Accessibility hint for media item preview for user's viewing an item in their media library")
        }
    }
}
