import Foundation
import WordPressShared.WPStyleGuide

@objc public class NoteBlockImageTableViewCell : NoteBlockTableViewCell
{
    // MARK: - Public Properties
    public override var isBadge: Bool {
        didSet {
            backgroundColor = isBadge ? Styles.badgeBackgroundColor : Styles.blockBackgroundColor
        }
    }

    // MARK: - Public Methods
    public func downloadImageWithURL(url: NSURL?) {
        let success = { (image: UIImage) in
            self.blockImageView.image = image
            self.blockImageView.displayWithSpringAnimation()
        }

        blockImageView.downloadImage(url, placeholderImage: nil, success: success, failure: nil)
    }

    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }

    // MARK: - Helpers
    private typealias Styles = WPStyleGuide.Notifications

    // MARK: - IBOutlets
    @IBOutlet weak var blockImageView: UIImageView!
}
