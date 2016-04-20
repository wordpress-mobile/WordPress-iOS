import UIKit
import WordPressShared

public class ThemeBrowserHeaderView: UICollectionReusableView
{
    // MARK: - Constants

    public static let reuseIdentifier = "ThemeBrowserHeaderView"

    // MARK: - Private Aliases
    
    private typealias Styles = WPStyleGuide.Themes

    // MARK: - Outlets

    @IBOutlet weak var currentThemeBar: UIView!
    @IBOutlet weak var currentThemeLabel: UILabel!
    @IBOutlet weak var currentThemeDivider: UIView!
    @IBOutlet weak var currentThemeName: UILabel!
    @IBOutlet weak var customizeButton: UIButton!
    @IBOutlet weak var detailsButton: UIButton!
    @IBOutlet weak var supportButton: UIButton!
    @IBOutlet var searchBarBorders: [UIView]!
    @IBOutlet weak var searchBar: UIView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchTypeButton: UIButton!
    
    // MARK: - Properties

    private var theme: Theme? {
        didSet {
            currentThemeName.text = theme?.name
        }
    }
    private var searchType: ThemeType = .All {
        didSet {
            Styles.styleSearchTypeButton(searchTypeButton, title: searchType.title)
        }
    }
    public weak var presenter: ThemePresenter? {
        didSet {
            if let presenter = presenter {
                theme = presenter.currentTheme()
                
                if ThemeType.mayPurchase {
                    searchType = presenter.searchType
                } else {
                    searchTypeButton.hidden = true
                }
            }
        }
    }
    
    // MARK: - GUI

    override public func awakeFromNib() {
        super.awakeFromNib()
        
        let buttons = [customizeButton, detailsButton, supportButton, searchButton, searchTypeButton]
        buttons.forEach { $0.exclusiveTouch = true }

        applyStyles()
    }
    
    private func applyStyles() {
        currentThemeBar.backgroundColor = Styles.currentThemeBackgroundColor
        currentThemeDivider.backgroundColor = Styles.currentThemeDividerColor

        currentThemeLabel.font = Styles.currentThemeLabelFont
        currentThemeLabel.textColor = Styles.currentThemeLabelColor
        
        currentThemeName.font = Styles.currentThemeNameFont
        currentThemeName.textColor = Styles.currentThemeNameColor
        
        let currentThemeButtons = [customizeButton, detailsButton, supportButton]
        currentThemeButtons.forEach { Styles.styleCurrentThemeButton($0) }

        searchBar.backgroundColor = Styles.searchBarBackgroundColor
        searchBarBorders.forEach { $0.backgroundColor = Styles.searchBarBorderColor }
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
    
    private func updateSearchType(type: ThemeType) {
        guard type != self.searchType else {
            return
        }
        
        self.searchType = type
        self.presenter?.searchType = type
    }
    
    @IBAction func didTapSearchTypeButton(sender: UIButton) {
        let title = NSLocalizedString("Show themes:", comment: "Alert title picking theme type to browse")
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .ActionSheet)
        
        ThemeType.types.forEach { type in
            alertController.addActionWithTitle(type.title,
                style: .Default,
                handler: { [weak self] (action: UIAlertAction) in
                    self?.updateSearchType(type)
            })
        }

        alertController.modalPresentationStyle = .Popover
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = searchTypeButton
            popover.sourceRect = searchTypeButton.bounds
            popover.permittedArrowDirections = .Any
            popover.canOverlapSourceViewRect = true
        }
        alertController.presentFromRootViewController()
    }
}
