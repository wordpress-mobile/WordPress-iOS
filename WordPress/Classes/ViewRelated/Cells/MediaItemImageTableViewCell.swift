import UIKit
import WordPressShared

class MediaItemImageTableViewCell: WPTableViewCell {
    let customImageView = UIImageView()
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
    let activityMaskView = UIView()
    let videoIconView = PlayIconView()

    var isVideo: Bool {
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

    public required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    public convenience init() {
        self.init(style: .default, reuseIdentifier: nil)
    }

    func commonInit() {
        setupImageView()
        setupLoadingViews()
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

        customImageView.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
    }

    private func setupLoadingViews() {
        contentView.addSubview(activityMaskView)
        activityMaskView.translatesAutoresizingMaskIntoConstraints = false
        activityMaskView.backgroundColor = .black
        activityMaskView.alpha = 0.5

        contentView.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            activityMaskView.leadingAnchor.constraint(equalTo: customImageView.leadingAnchor),
            activityMaskView.trailingAnchor.constraint(equalTo: customImageView.trailingAnchor),
            activityMaskView.topAnchor.constraint(equalTo: customImageView.topAnchor),
            activityMaskView.bottomAnchor.constraint(equalTo: customImageView.bottomAnchor)
            ])
    }

    private func setupVideoIconView() {
        contentView.addSubview(videoIconView)
        videoIconView.isHidden = true
    }

    private var aspectRatioConstraint: NSLayoutConstraint? = nil

    var targetAspectRatio: CGFloat {
        set {
            if let aspectRatioConstraint = aspectRatioConstraint {
                customImageView.removeConstraint(aspectRatioConstraint)
            }

            aspectRatioConstraint = customImageView.heightAnchor.constraint(equalTo: customImageView.widthAnchor, multiplier: newValue, constant: 1.0)
            aspectRatioConstraint?.priority = UILayoutPriorityDefaultHigh
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
        customImageView.backgroundColor = .black
        contentView.backgroundColor = .white
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        videoIconView.center = contentView.center
    }

    // MARK: - Loading

    var isLoading: Bool = false {
        didSet {
            if isLoading {
                activityMaskView.alpha = 0.5
                activityIndicator.startAnimating()
            } else {
                activityMaskView.alpha = 0
                activityIndicator.stopAnimating()
            }
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

    func willDisplay(_ cell: UITableViewCell) {
        if let cell = cell as? MediaItemImageTableViewCell {
            cell.customImageView.backgroundColor = .black
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

    private func loadImageFor(_ cell: MediaItemImageTableViewCell) {
        if !cell.isLoading && cell.customImageView.image == nil {
            addPlaceholderImageFor(cell)

            cell.isLoading = true
            media.image(with: .zero,
                        completionHandler: { image, error in
                            DispatchQueue.main.async {
                                if let error = error, image == nil {
                                    cell.isLoading = false
                                    self.show(error)
                                } else if let image = image {
                                    self.animateImageChange(image: image, for: cell)
                                }
                            }
            })
        }
    }

    private func show(_ error: Error) {
        let alertController = UIAlertController(title: nil, message: NSLocalizedString("There was a problem loading the media item.",
                                                                                       comment: "Error message displayed when the Media Library is unable to load a full sized preview of an item."), preferredStyle: .alert)
        alertController.addCancelActionWithTitle(NSLocalizedString("Dismiss", comment: "Verb. User action to dismiss error alert when failing to load media item."))
        alertController.presentFromRootViewController()
    }

    private func animateImageChange(image: UIImage, for cell: MediaItemImageTableViewCell) {
        UIView.transition(with: cell.customImageView, duration: 0.2, options: .transitionCrossDissolve, animations: {
            cell.isLoading = false
            cell.customImageView.image = image
        }, completion: nil)
    }
}
