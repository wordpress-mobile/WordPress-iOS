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

        titleLabel.numberOfLines = 0
        titleLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        titleLabel.textColor = .text

        excerptLabel.numberOfLines = 3
        excerptLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        excerptLabel.textColor = .text
    }

    func configure(for post: RemoteReaderSimplePost) {
        featuredImageView.backgroundColor = .green // FIXME
        titleLabel.text = NSAttributedString.attributedStringWithHTML(post.title, attributes: nil).string
        excerptLabel.text = NSAttributedString.attributedStringWithHTML(post.excerpt, attributes: nil).string
    }

    private enum Constants {
        static let cornerRadius: CGFloat = 4
    }
}
