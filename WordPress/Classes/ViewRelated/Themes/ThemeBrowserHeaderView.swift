import UIKit

public class ThemeBrowserHeaderView: UICollectionReusableView {
        
    // MARK: - Constants

    public static let reuseIdentifier = "ThemeBrowserHeaderView"

    // MARK: - Private Aliases
    
    private typealias Styles = WPStyleGuide.Themes

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
        currentThemeBorder.layer.borderColor = Styles.borderColor.CGColor;
        currentThemeBorder.backgroundColor = Styles.dividerColor;
        
        currentThemeLabel.font = Styles.currentThemeLabelFont
        currentThemeLabel.textColor = Styles.currentThemeLabelColor
        
        currentThemeName.font = Styles.currentThemeNameFont
        currentThemeName.textColor = Styles.currentThemeNameColor
        
        for button in [customizeButton, detailsButton, supportButton] {
            button.titleLabel?.font = Styles.currentThemeButtonFont
            button.setTitleColor(Styles.currentThemeButtonColor, forState: .Normal)
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
