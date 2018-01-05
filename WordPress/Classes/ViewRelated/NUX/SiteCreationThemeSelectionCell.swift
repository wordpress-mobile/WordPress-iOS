import UIKit

class SiteCreationThemeSelectionCell: UICollectionViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "themeSelectionCell"
    private var placeholderImage = UIImage(named: "theme-loading")
    private typealias Styles = WPStyleGuide.Themes

    @IBOutlet weak var themeImageView: UIImageView!
    @IBOutlet weak var themeTitleLabel: UILabel!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var infoBar: UIView!

    var displayTheme: Theme? {
        didSet {
            updateTheme()
        }
    }

    // MARK: - Init

    override func awakeFromNib() {
        super.awakeFromNib()
        configureColors()
    }

    // MARK: - Display

    private func configureColors() {
        themeTitleLabel.font = Styles.cellNameFont
        themeTitleLabel.textColor = Styles.inactiveCellNameColor
        layer.borderWidth = Styles.cellBorderWidth
        infoBar.layer.borderWidth = Styles.cellBorderWidth
        layer.borderColor = Styles.inactiveCellBorderColor.cgColor
        infoBar.layer.borderColor = Styles.inactiveCellDividerColor.cgColor
    }

    private func updateTheme() {
        guard let displayTheme = displayTheme else {
            return
        }

        themeTitleLabel.text = displayTheme.name

        if let imageUrl = displayTheme.screenshotUrl, !imageUrl.isEmpty {
            refreshScreenshot(url: imageUrl)
        } else {
            showPlaceholder()
        }
    }

    private func refreshScreenshot(url imageUrl: String) {
        themeImageView.backgroundColor = Styles.placeholderColor
        activityView.startAnimating()
        themeImageView.downloadImage(URL(string: imageUrl),
                                placeholderImage: nil,
                                success: { [weak self] (image: UIImage) in
                                    self?.showScreenshot()
            }, failure: { [weak self] (error: Error?) in
                if let error = error as NSError?, error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                    return
                }
                DDLogError("Error loading theme screenshot: \(String(describing: error?.localizedDescription))")
                self?.showPlaceholder()
        })
    }

    private func showScreenshot() {
        themeImageView.contentMode = .scaleAspectFit
        themeImageView.backgroundColor = UIColor.clear
        activityView.stopAnimating()
    }

    private func showPlaceholder() {
        themeImageView.contentMode = .center
        themeImageView.backgroundColor = Styles.placeholderColor
        themeImageView.image = placeholderImage
        activityView.stopAnimating()
    }

}
