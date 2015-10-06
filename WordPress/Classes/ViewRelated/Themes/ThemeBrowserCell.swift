import Foundation

public class ThemeBrowserCell : UICollectionViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var imageView : UIImageView!
    @IBOutlet weak var nameLabel : UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    
    // MARK: - Properties
    
    private var theme : Theme? {
        didSet {
            refreshGUI()
        }
    }
    
    // MARK: - Additional initialization
    
    public func configureWithTheme(theme: Theme?) {
        self.theme = theme
    }
    
    // MARK: - GUI
    
    /**
    @brief Calculates cell height fitting a given width
    
    @param width    Intended width
    @return         Matching height
    */
    public class func heightForWidth(width: CGFloat) -> CGFloat {
        let imageInset = CGFloat(2)
        let imageRatio = CGFloat(0.75)
        let infoBarHeight = CGFloat(55)
        
        let imageHeight = (width - imageInset) * imageRatio
        let height = imageHeight + infoBarHeight
        
        return height
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        nameLabel.font = WPStyleGuide.regularTextFontSemiBold()
        infoLabel.font = WPFontManager.openSansSemiBoldFontOfSize(14)
        
        layer.shadowColor = WPStyleGuide.grey().CGColor
        layer.shadowOpacity = 0.7
        layer.shadowRadius = 2
        layer.shadowOffset = CGSize(width: 0.5,height: 0.5)
        layer.masksToBounds = false
    }
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        theme = nil
    }
    
    private func refreshGUI() {
        if let theme = theme {
           if let imageUrl = theme.screenshotUrl where !imageUrl.isEmpty {
                self.refreshScreenshotImage(imageUrl)
            } else {
                imageView.image = nil
            }
            
            nameLabel.text = theme.name
            if theme.isCurrentTheme() {
                backgroundColor = WPStyleGuide.mediumBlue()
                nameLabel.textColor = UIColor.whiteColor()
                infoLabel.textColor = WPStyleGuide.lightBlue()
                infoLabel.text = NSLocalizedString("ACTIVE", comment: "Label for active Theme browser cell")
            } else {
                backgroundColor = UIColor.whiteColor()
                nameLabel.textColor = WPStyleGuide.darkGrey()
                if !theme.isPremium() {
                    infoLabel.textColor = WPStyleGuide.validGreen()
                    infoLabel.text = "placeholder"
                } else {
                    infoLabel.text = nil
                }
            }
        } else {
            imageView.image = nil
            nameLabel.text = nil
            infoLabel.text = nil
        }
    }
    
    private func refreshScreenshotImage(imageUrl: String) {
        let imageUrl = NSURL(string: imageUrl)
        
        imageView.downloadImage(imageUrl, placeholderImage: nil)
    }

    // MARK: - Actions
    
    @IBAction private func didTapActionButton(sender: UIButton) {
    }
    
}