import UIKit

class SelectThemeCell: UICollectionViewCell {

    // MARK: - Properties

    open static let reuseIdentifier = "themeSelectionCell"
    fileprivate var placeholderImage = UIImage(named: "theme-loading")
    fileprivate typealias Styles = WPStyleGuide.Themes

    @IBOutlet weak var themeImageView: UIImageView!
    @IBOutlet weak var themeTitleLabel: UILabel!
    @IBOutlet weak var activityView: UIActivityIndicatorView!

    var displayTheme: Theme? {
        didSet {
            updateTheme()
        }
    }

    // MARK: - Init

    override open func awakeFromNib() {
        super.awakeFromNib()
    }

    override open func prepareForReuse() {
        super.prepareForReuse()
    }

    // MARK: - Display

    private func updateTheme() {
        guard let displayTheme = displayTheme else {
            return
        }

        themeTitleLabel.text = displayTheme.name

        if let imageUrl = displayTheme.screenshotUrl, !imageUrl.isEmpty {
            refreshScreenshotImage(imageUrl)
        } else {
            showPlaceholder()
        }
    }

    private func refreshScreenshotImage(_ imageUrl: String) {
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
