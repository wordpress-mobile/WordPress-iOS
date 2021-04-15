import Foundation

class UserProfileSiteCell: UITableViewCell, NibReusable {

    // MARK: - Properties

    @IBOutlet weak var siteIconImageView: UIImageView!
    @IBOutlet weak var siteNameLabel: UILabel!
    @IBOutlet weak var siteUrlLabel: UILabel!

    static let estimatedRowHeight: CGFloat = 50

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        configureCell()
    }

    // MARK: - Public Methods

    func configure() {
        downloadIconWithURL(nil)
    }
}

// MARK: - Private Extension

private extension UserProfileSiteCell {

    func configureCell() {
        siteNameLabel.textColor = .text
        siteUrlLabel.textColor = .textSubtle
    }

    func downloadIconWithURL(_ url: String?) {
        // Always reset icon
        siteIconImageView.cancelImageDownload()
        siteIconImageView.image = .siteIconPlaceholderImage

        guard let url = url,
              let iconURL = URL(string: url) else {
            return
        }

        siteIconImageView.downloadImage(from: iconURL, placeholderImage: .siteIconPlaceholderImage)
    }

}
