import Foundation

public class ThemeBrowserCell : UICollectionViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var imageView : UIImageView!
    @IBOutlet weak var nameLabel : UILabel!
    
    // MARK: - Properties
    
    private var theme : Theme? {
        didSet {
            self.refreshGUI()
        }
    }
    
    // MARK: - Additional initialization
    
    public func configureWithTheme(theme: Theme?) {
        self.theme = theme;
    }
    
    // MARK: - GUI
    
    private func refreshGUI() {
        if let unwrappedTheme = self.theme {
            if let unwrappedPreviewUrl = unwrappedTheme.previewUrl {
                self.refreshPreviewImage(unwrappedPreviewUrl)
            }
            
            self.nameLabel.text = unwrappedTheme.name
        }
    }
    
    private func refreshPreviewImage(imageUrl: String) {    
        let imageUrl = NSURL(string: imageUrl)
        
        self.imageView.downloadImage(imageUrl, placeholderImage: nil)
    }
}