import UIKit

public class ThemeBrowserHeaderView: UICollectionReusableView {
        
    // MARK: - Constants

    public static let reuseIdentifier = "ThemeBrowserHeaderView"

    // MARK: - Outlets

    @IBOutlet weak var currentThemeBorder: UIView!
    @IBOutlet weak var currentThemeLabel: UILabel!
    @IBOutlet weak var currentThemeName: UILabel!
    
    // MARK: - Properties

    private var theme: Theme? {
        didSet {
            currentThemeName.text = theme?.name
        }
    }
        
    // MARK: - Additional initialization
    
    public func configureWithTheme(theme: Theme?) {
        self.theme = theme
    }
    
    // MARK: - GUI

    override public func awakeFromNib() {
        super.awakeFromNib()
        
        currentThemeBorder.layer.borderWidth = 1;
        currentThemeBorder.layer.borderColor = WPStyleGuide.Themes.borderColor.CGColor;
        currentThemeBorder.backgroundColor = WPStyleGuide.Themes.borderColor;
        
        currentThemeLabel.font = WPStyleGuide.Themes.currentThemeLabelFont
        currentThemeLabel.textColor = WPStyleGuide.Themes.currentThemeLabelColor
        
        currentThemeName.font = WPStyleGuide.Themes.currentThemeNameFont
        currentThemeName.textColor = WPStyleGuide.Themes.currentThemeNameColor
    }
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        theme = nil
    }

}
