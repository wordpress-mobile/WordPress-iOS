/// Table view cell for the List component.
///
/// This is used in Comments and Notifications as part of the Comments
/// Unification project.
///
class ListTableViewCell: UITableViewCell, NibReusable {
    // MARK: IBOutlets

    @IBOutlet private weak var indicatorView: UIView!
    @IBOutlet private weak var avatarView: CircularImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var snippetLabel: UILabel!
    @IBOutlet private weak var indicatorWidthConstraint: NSLayoutConstraint!

    // MARK: Properties

    /// The color of the indicator circle.
    @objc var indicatorColor: UIColor = .clear {
        didSet {
            updateIndicatorColor()
        }
    }

    /// Toggle variable to determine whether the indicator circle should be shown.
    @objc var showsIndicator: Bool = false {
        didSet {
            updateIndicatorColor()
        }
    }

    /// The default placeholder image.
    @objc var placeholderImage: UIImage = Style.placeholderImage

    /// The image URL to be downloaded and displayed on avatarView.
    @objc var imageURL: URL? {
        didSet {
            guard imageURL != oldValue else {
                return
            }
            downloadImage(with: imageURL)
        }
    }

    /// The attributed string to be displayed in titleLabel.
    /// To keep the styles uniform between List components, refer to regular and bold styles in `WPStyleGuide+List`.
    @objc var attributedTitleText: NSAttributedString? {
        get {
            titleLabel.attributedText
        }
        set {
            titleLabel.attributedText = newValue ?? NSAttributedString()
        }
    }

    /// The snippet text, displayed in snippetLabel.
    /// Note that new values are trimmed of whitespaces and newlines.
    @objc var snippetText: String? {
        get {
            snippetLabel.text
        }
        set {
            snippetLabel.text = newValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? String()
            updateTitleTextLines()
        }
    }

    /// Convenience computed property to check whether the cell has a snippet text or not.
    private var hasSnippet: Bool {
        !(snippetText ?? "").isEmpty
    }

    // MARK: Initialization

    override func awakeFromNib() {
        super.awakeFromNib()
        configureSubviews()
    }
}

// MARK: Private Helpers

private extension ListTableViewCell {
    /// Apply styles for the subviews.
    func configureSubviews() {
        // indicator view
        indicatorView.layer.cornerRadius = indicatorWidthConstraint.constant / 2

        // TODO: temporary styling. will update this in later PRs.
        titleLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        titleLabel.textColor = UIColor.text
        titleLabel.numberOfLines = Constants.titleNumberOfLinesWithSnippet

        // snippet label
        snippetLabel.font = Style.snippetFont
        snippetLabel.textColor = Style.snippetTextColor
        snippetLabel.numberOfLines = Constants.snippetNumberOfLines
    }

    /// Show more lines in titleLabel when there's no snippet.
    func updateTitleTextLines() {
        titleLabel.numberOfLines = hasSnippet ? Constants.titleNumberOfLinesWithSnippet : Constants.titleNumberOfLinesWithoutSnippet
    }

    func updateIndicatorColor() {
        indicatorView.backgroundColor = showsIndicator ? indicatorColor : .clear
    }

    /// Downloads the image to display in avatarView.
    func downloadImage(with url: URL?) {
        if let someURL = url, let gravatar = Gravatar(someURL) {
            avatarView.downloadGravatar(gravatar, placeholder: placeholderImage, animate: true)
            return
        }

        // handle non-gravatar images
        avatarView.downloadImage(from: url, placeholderImage: placeholderImage)
    }
}

// MARK: Private Constants

private extension ListTableViewCell {
    typealias Style = WPStyleGuide.List

    struct Constants {
        static let titleNumberOfLinesWithoutSnippet = 3
        static let titleNumberOfLinesWithSnippet = 2
        static let snippetNumberOfLines = 2
    }
}
