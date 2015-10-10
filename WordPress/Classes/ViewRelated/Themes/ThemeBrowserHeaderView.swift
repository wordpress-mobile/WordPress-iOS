import UIKit

public class ThemeBrowserHeaderView: UICollectionReusableView {
        
    // MARK: - Constants

    public static let reuseIdentifier = "ThemeBrowserHeaderView"

    // MARK: - Outlets

    @IBOutlet weak var currentThemeBorder: UIView!
    @IBOutlet weak var currentThemeLabel: UILabel!
    @IBOutlet weak var currentThemeName: UILabel!
    @IBOutlet weak var customizeButton: UIButton!
    @IBOutlet weak var detailsButton: UIButton!
    @IBOutlet weak var supportButton: UIButton!
    
    // MARK: - Properties

    private var theme: Theme? {
        didSet {
            currentThemeName.text = theme?.name
        }
    }
    private var presenter: ThemePresenter?
    
    // MARK: - Additional initialization
    
    public func configureWithTheme(theme: Theme?, presenter: ThemePresenter?) {
        self.theme = theme
        self.presenter = presenter
    }
    
    // MARK: - GUI

    override public func awakeFromNib() {
        super.awakeFromNib()
        
        applyStyles()
    }
    
    private func applyStyles() {
        currentThemeBorder.layer.borderWidth = 1;
        currentThemeBorder.layer.borderColor = WPStyleGuide.Themes.borderColor.CGColor;
        currentThemeBorder.backgroundColor = WPStyleGuide.Themes.dividerColor;
        
        currentThemeLabel.font = WPStyleGuide.Themes.currentThemeLabelFont
        currentThemeLabel.textColor = WPStyleGuide.Themes.currentThemeLabelColor
        
        currentThemeName.font = WPStyleGuide.Themes.currentThemeNameFont
        currentThemeName.textColor = WPStyleGuide.Themes.currentThemeNameColor
        
        for button in [customizeButton, detailsButton, supportButton] {
            button.titleLabel?.font = WPStyleGuide.Themes.currentThemeButtonFont
            button.setTitleColor(WPStyleGuide.Themes.currentThemeButtonColor, forState: .Normal)
        }
    }
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        theme = nil
        presenter = nil
    }

    // MARK: - Actions
    
    @IBAction private func didTapCustomizeButton(sender: UIButton) {
        presenter?.presentCustomizeForTheme(theme)
    }
    
    @IBAction private func didTapDetailsButton(sender: UIButton) {
        presenter?.presentDetailsForTheme(theme)
    }
    
    @IBAction private func didTapSupportButton(sender: UIButton) {
        presenter?.presentSupportForTheme(theme)
    }
    
}
