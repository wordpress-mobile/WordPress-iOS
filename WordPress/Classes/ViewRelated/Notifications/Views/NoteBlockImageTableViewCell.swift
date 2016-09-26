import Foundation
import WordPressShared.WPStyleGuide


class NoteBlockImageTableViewCell: NoteBlockTableViewCell
{
    // MARK: - Public Properties
    private var imageURL: NSURL?
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
    func downloadImage(url: NSURL?) {
        guard imageURL != url else {
            return
        }

        imageURL = url

        blockImageView.downloadImage(url, placeholderImage: nil, success: { image in
            self.blockImageView.image = image
            self.blockImageView.expandSpringAnimation()
        })
    }

    // MARK: - View Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }

    // MARK: - Helpers
    private typealias Styles = WPStyleGuide.Notifications

    // MARK: - IBOutlets
    @IBOutlet weak var blockImageView: UIImageView!
}
