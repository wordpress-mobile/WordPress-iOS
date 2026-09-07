import UIKit
import WordPressShared
import WordPressUI

class NoteBlockImageTableViewCell: NoteBlockTableViewCell {
    // MARK: - Public Properties
    fileprivate var imageURL: URL?
    override var isBadge: Bool {
        didSet {
            backgroundColor = isBadge ? Styles.badgeBackgroundColor : Styles.blockBackgroundColor
        }
    }

    var backgroundImage: UIImage? {
        didSet {
            backgroundImageView?.image = backgroundImage
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

        blockImageView.downloadImage(from: url, success: nil, failure: { [weak self] _ in
                // Only reset if we're still pointing at the failed URL — the cell may have been reused for another notification in the meantime.
                guard let self, self.imageURL == url else {
                    return
                }
                self.imageURL = nil
            }
        )
    }

    // MARK: - View Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        blockImageView.image = nil
        backgroundImageView.image = nil
        imageURL = nil
        backgroundImage = nil
    }

    // MARK: - Helpers
    fileprivate typealias Styles = WPStyleGuide.Notifications

    // MARK: - IBOutlets
    @IBOutlet weak var blockImageView: UIImageView!
    @IBOutlet weak var backgroundImageView: UIImageView!
}
