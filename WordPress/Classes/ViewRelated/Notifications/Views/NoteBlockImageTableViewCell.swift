import Foundation
import WordPressShared.WPStyleGuide


class NoteBlockImageTableViewCell: NoteBlockTableViewCell
{
    // MARK: - Public Properties
    override var isBadge: Bool {
        didSet {
            backgroundColor = isBadge ? Styles.badgeBackgroundColor : Styles.blockBackgroundColor
        }
    }

    // MARK: - Public Methods
    func downloadImageWithURL(url: NSURL?) {
        let success = { (image: UIImage) in
            self.blockImageView.image = image
            self.blockImageView.displayWithSpringAnimation()
        }

        blockImageView.downloadImage(url, placeholderImage: nil, success: success, failure: nil)
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
