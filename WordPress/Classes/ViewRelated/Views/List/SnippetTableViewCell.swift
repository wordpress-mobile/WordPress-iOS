import UIKit

class SnippetTableViewCell: UITableViewCell, NibReusable {
    // MARK: IBOutlets

    @IBOutlet private weak var indicatorView: UIView!
    @IBOutlet private weak var avatarView: CircularImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var snippetLabel: UILabel!
    @IBOutlet private weak var indicatorWidthConstraint: NSLayoutConstraint!

    // MARK: Properties

    @objc var indicatorColor: UIColor = .clear

    @objc var showsIndicator: Bool = false {
        didSet {
            indicatorView.backgroundColor = showsIndicator ? indicatorColor : .clear
        }
    }

    @objc var placeholderImage: UIImage = Style.placeholderImage

    @objc var imageURL: URL? {
        didSet {
            guard imageURL != oldValue else {
                return
            }
            downloadImage(with: imageURL)
        }
    }

    @objc var attributedTitleText: NSAttributedString? {
        get {
            titleLabel.attributedText
        }
        set {
            titleLabel.attributedText = newValue ?? NSAttributedString()
        }
    }

    @objc var snippetText: String? {
        get {
            snippetLabel.text
        }
        set {
            snippetLabel.text = newValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? String()
        }
    }

    // MARK: Initialization

    override func awakeFromNib() {
        super.awakeFromNib()

        configureViews()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    private func configureViews() {
        // indicator view
        indicatorView.layer.cornerRadius = indicatorWidthConstraint.constant / 2

        // TODO: temporary styling
        titleLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        titleLabel.textColor = UIColor.text
        titleLabel.numberOfLines = Constants.titleNumberOfLinesWithSnippet

        // snippet label
        snippetLabel.font = Style.snippetFont
        snippetLabel.textColor = Style.snippetTextColor
        snippetLabel.numberOfLines = Constants.snippetNumberOfLines
    }
}

// MARK: Private Helpers

private extension SnippetTableViewCell {

    /// Downloads the image to display in avatarView.
    func downloadImage(with url: URL?) {
        if let someURL = url, let gravatar = Gravatar(someURL) {
            avatarView.downloadGravatar(gravatar, placeholder: placeholderImage, animate: true) { error in
                if let error = error {
                    print(error)
                }
            }
            return
        }

        // handle non-gravatar images
        avatarView.downloadImage(from: url, placeholderImage: placeholderImage)
    }

}

// MARK: Constants

extension SnippetTableViewCell {
    typealias Style = WPStyleGuide.Snippet

    private struct Constants {
        static let titleNumberOfLinesWithoutSnippet = 3
        static let titleNumberOfLinesWithSnippet = 2
        static let snippetNumberOfLines = 2
    }
}
