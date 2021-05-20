import UIKit
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
        featuredImageView.backgroundColor = .placeholderElement

        titleLabel.numberOfLines = 0
        titleLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        titleLabel.textColor = .text

        excerptLabel.numberOfLines = 3
        excerptLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        excerptLabel.textColor = .text
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        featuredImageView.image = nil
    }

    func configure(for post: RemoteReaderSimplePost) {
        configureFeaturedImage(for: post)
        configureLabels(for: post)
    }

    private func configureFeaturedImage(for post: RemoteReaderSimplePost) {
        var featuredImageUrlString: String? = nil
        if let urlString = post.featuredImageUrl, !urlString.isEmpty {
            featuredImageUrlString = urlString
        } else if let uriString = post.featuredMedia?.uri, !uriString.isEmpty {
            featuredImageUrlString = uriString
        }

        guard let urlString = featuredImageUrlString,
              let featuredImageUrl = URL(string: urlString) else {
            featuredImageView.isHidden = true
            return
        }

        featuredImageView.downloadImage(from: featuredImageUrl)
    }

    private func configureLabels(for post: RemoteReaderSimplePost) {
        titleLabel.text = post.title.makePlainText()
        excerptLabel.text = post.excerpt.makePlainText()
    }

    private enum Constants {
        static let cornerRadius: CGFloat = 4
    }
}
