import Foundation
import WordPressShared.WPStyleGuide


class NoteBlockImageTableViewCell: NoteBlockTableViewCell {
    // MARK: - Public Properties
    fileprivate var imageURL: URL?
    override var isBadge: Bool {
        didSet {
            backgroundColor = isBadge ? Styles.badgeBackgroundColor : Styles.blockBackgroundColor
        }
    }

    // MARK: - Public Methods

    /// Downloads a remote image, given it's URL, assuming that we're already not displaying that very same image.
    ///
    /// - Parameter url: Target image URL.
    ///
    @objc func downloadImage(_ url: URL?) {
        guard imageURL != url else {
            return
        }

        imageURL = url

        blockImageView.downloadImage(from: url, success: { [weak blockImageView] _ in
            blockImageView?.expandSpringAnimation()
        })
    }

    // MARK: - View Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        blockImageView.image = nil
        imageURL = nil
    }

    // MARK: - Helpers
    fileprivate typealias Styles = WPStyleGuide.Notifications

    // MARK: - IBOutlets
    @IBOutlet weak var blockImageView: UIImageView!
}
