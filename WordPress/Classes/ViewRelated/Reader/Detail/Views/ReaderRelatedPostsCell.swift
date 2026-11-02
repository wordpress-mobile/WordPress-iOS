import UIKit
import WordPressKit
import WordPressShared

class ReaderRelatedPostsCell: UITableViewCell, NibReusable {

    @IBOutlet weak var featuredImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var excerptLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    private func applyStyles() {
        featuredImageView.clipsToBounds = true
        featuredImageView.layer.cornerRadius = Constants.cornerRadius
        featuredImageView.contentMode = .scaleAspectFill
        featuredImageView.backgroundColor = .placeholderText

        titleLabel.numberOfLines = 3
        titleLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        titleLabel.textColor = .label

        excerptLabel.numberOfLines = 3
        excerptLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        excerptLabel.textColor = .label
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        featuredImageView.image = nil
    }

    func configure(for post: RemoteReaderSimplePost) {
        let featuredImageURL = post.featuredImageURL
        featuredImageView.isHidden = featuredImageURL == nil
        featuredImageView.downloadImage(from: featuredImageURL)

        titleLabel.text = post.title.makePlainText()

        let excerpt = post.excerpt.makePlainText()
        excerptLabel.text = excerpt
        excerptLabel.isHidden = excerpt.isEmpty
    }

    private enum Constants {
        static let cornerRadius: CGFloat = 6
    }
}

extension RemoteReaderSimplePost {
    /// A card with only a title reads as a stray heading next to cards with an image and an
    /// excerpt, so such posts are left out of the related posts section.
    var hasContentForRelatedPostCard: Bool {
        featuredImageURL != nil || !excerpt.makePlainText().isEmpty
    }
}
