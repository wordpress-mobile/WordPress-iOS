import Foundation

public class ThemeBrowserCell : UICollectionViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var imageView : UIImageView!
    @IBOutlet weak var nameLabel : UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
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
        let imageRatio = CGFloat(0.75)
        let infoBarHeight = CGFloat(55)
        
        let imageHeight = width * imageRatio
        let height = imageHeight + infoBarHeight
        
        return height
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
            priceLabel.text = "" // FIXME: Add price to Core Data
        } else {
            imageView.image = nil
            nameLabel.text = nil
            priceLabel.text = nil
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