import Foundation

public class ThemeBrowserCell : UICollectionViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var imageView : UIImageView!
    @IBOutlet weak var nameLabel : UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var highlightView: UIView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    public var theme : Theme? {
        didSet {
            refreshGUI()
        }
    }
    
    private var placeholderImage = UIImage(named: "theme-loading")
    
    // MARK: - Private Aliases
    
    private typealias Styles = WPStyleGuide.Themes
    
   // MARK: - GUI
    
    /**
    @brief Calculates cell height fitting a given width
    
    @param width    Intended width
    @return         Matching height
    */
    public class func heightForWidth(width: CGFloat) -> CGFloat {
        
        let imageHeight = (width - Styles.cellImageInset) * Styles.cellImageRatio
        let height = imageHeight + Styles.cellInfoBarHeight
        
        return height
    }
    
    override public var highlighted: Bool {
        didSet {
            let alphaFinal: CGFloat = highlighted ? 0.3 : 0
            UIView.animateWithDuration(0.2) { [weak self] in
                self?.highlightView.alpha = alphaFinal
            }
        }
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        nameLabel.font = Styles.cellNameFont
        infoLabel.font = Styles.cellInfoFont
        
        layer.borderColor = Styles.borderColor.CGColor
        layer.borderWidth = 1
    }
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        theme = nil
        activityView.stopAnimating()
    }
    
    private func refreshGUI() {
        if let theme = theme {
           if let imageUrl = theme.screenshotUrl where !imageUrl.isEmpty {
                refreshScreenshotImage(imageUrl)
            } else {
                showScreenshotPlaceholder()
            }
            
            nameLabel.text = theme.name
            if theme.isCurrentTheme() {
                backgroundColor = Styles.activeCellBackgroundColor
                nameLabel.textColor = Styles.activeCellNameColor
                infoLabel.textColor = Styles.activeCellInfoColor
                infoLabel.text = NSLocalizedString("ACTIVE", comment: "Label for active Theme browser cell")
            } else {
                backgroundColor = Styles.inactiveCellBackgroundColor
                nameLabel.textColor = Styles.inactiveCellNameColor
                if theme.isPremium() {
                    infoLabel.textColor = Styles.inactiveCellPriceColor
                    infoLabel.text = theme.price
                } else {
                    infoLabel.text = nil
                }
            }
        } else {
            imageView.image = nil
            nameLabel.text = nil
            infoLabel.text = nil
            activityView.stopAnimating()
        }
    }
    
    private func showScreenshotPlaceholder() {
        imageView.contentMode = .Center
        imageView.backgroundColor = Styles.placeholderColor
        imageView.image = placeholderImage
        activityView.stopAnimating()
    }
    
    private func refreshScreenshotImage(imageUrl: String) {
        let imageUrl = NSURL(string: imageUrl)
        
        showScreenshotPlaceholder()
        activityView.startAnimating()
        imageView.downloadImage(imageUrl,
            placeholderImage: placeholderImage,
            success: { [weak self] (image: UIImage) in
                self?.imageView.contentMode = .ScaleAspectFit
                self?.imageView.backgroundColor = UIColor.clearColor()
                self?.activityView.stopAnimating()
        }, failure: { [weak self] (error: NSError!) in
                DDLogSwift.logError("Error loading theme screenshot: \(error.localizedDescription)")
                self?.activityView.stopAnimating()
        })
    }

    // MARK: - Actions
    
    @IBAction private func didTapActionButton(sender: UIButton) {
        // TODO: Implement as per issue #3906
    }

}
