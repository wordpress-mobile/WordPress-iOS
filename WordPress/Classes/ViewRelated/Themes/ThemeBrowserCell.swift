import Foundation
import WordPressShared.WPStyleGuide

public class ThemeBrowserCell : UICollectionViewCell {
    
    // MARK: - Constants
    
    public static let reuseIdentifier = "ThemeBrowserCell"
    
    // MARK: - Private Aliases
    
    private typealias Styles = WPStyleGuide.Themes
    
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
    
   // MARK: - GUI
        
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
        
        layer.borderWidth = 1
    }
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        theme = nil
    }
    
    private func refreshGUI() {
        if let theme = theme {
           if let imageUrl = theme.screenshotUrl where !imageUrl.isEmpty {
                refreshScreenshotImage(imageUrl)
            } else {
                showPlaceholder()
            }
            
            nameLabel.text = theme.name
            if theme.isCurrentTheme() {
                backgroundColor = Styles.activeCellBackgroundColor
                layer.borderColor = Styles.activeCellBackgroundColor.CGColor
                nameLabel.textColor = Styles.activeCellNameColor
                infoLabel.textColor = Styles.activeCellInfoColor
                infoLabel.text = NSLocalizedString("ACTIVE", comment: "Label for active Theme browser cell")
            } else {
                backgroundColor = Styles.inactiveCellBackgroundColor
                layer.borderColor = Styles.barBorderColor.CGColor
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
    
    private func showPlaceholder() {
        imageView.contentMode = .Center
        imageView.backgroundColor = Styles.placeholderColor
        imageView.image = placeholderImage
        activityView.stopAnimating()
    }
    
    private func showScreenshot() {
        imageView.contentMode = .ScaleAspectFit
        imageView.backgroundColor = UIColor.clearColor()
        activityView.stopAnimating()
    }
    
    private func refreshScreenshotImage(imageUrl: String) {
        let imageUrl = NSURL(string: imageUrl)
        
        imageView.backgroundColor = Styles.placeholderColor
        activityView.startAnimating()
        imageView.downloadImage(imageUrl,
            placeholderImage: nil,
            success: { [weak self] (image: UIImage) in
                self?.showScreenshot()
        }, failure: { [weak self] (error: NSError!) in
                if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                    return
                }
                DDLogSwift.logError("Error loading theme screenshot: \(error.localizedDescription)")
                self?.showPlaceholder()
        })
    }

    // MARK: - Actions
    
    @IBAction private func didTapActionButton(sender: UIButton) {
        // TODO: Implement as per issue #3906
    }

}
