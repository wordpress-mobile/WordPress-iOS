class RelatedPostsTableViewCell: UITableViewCell, NibReusable {

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
        titleLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        titleLabel.textColor = .text

        excerptLabel.numberOfLines = 0
        excerptLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        excerptLabel.textColor = .text
    }

    func configure() {
        featuredImageView.backgroundColor = .green // FIXME
        titleLabel.text = "Placeholder title" // FIXME
        excerptLabel.text = "Lorem ipsum..." // FIXME
    }

    private enum Constants {
        static let cornerRadius: CGFloat = 4
    }
}
