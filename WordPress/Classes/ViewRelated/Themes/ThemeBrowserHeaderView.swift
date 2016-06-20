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
    @IBOutlet var filterBarBorders: [UIView]!
    @IBOutlet weak var filterBar: UIView!
    @IBOutlet weak var filterTypeButton: UIButton!

    // MARK: - Properties

    private var theme: Theme? {
        didSet {
            currentThemeName.text = theme?.name
        }
    }
    private var filterType: ThemeType = .All {
        didSet {
            Styles.styleSearchTypeButton(filterTypeButton, title: filterType.title)
        }
    }
    public weak var presenter: ThemePresenter? {
        didSet {
            if let presenter = presenter {
                theme = presenter.currentTheme()

                if ThemeType.mayPurchase {
                    filterType = presenter.filterType
                } else {
                    filterBar.hidden = true
                }
            }
        }
    }

    // MARK: - GUI

    override public func awakeFromNib() {
        super.awakeFromNib()

        let buttons = [customizeButton, detailsButton, supportButton, filterTypeButton]
        buttons.forEach { $0.exclusiveTouch = true }

        applyStyles()
        setTextForLabels()
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

        filterBar.backgroundColor = Styles.searchBarBackgroundColor
        filterBarBorders.forEach { $0.backgroundColor = Styles.searchBarBorderColor }
    }

    private func setTextForLabels() {
        currentThemeLabel.text = NSLocalizedString("Current Theme", comment: "Current Theme text that appears in the Theme Browser Header")
        customizeButton.setTitle(NSLocalizedString("Customize", comment: "Customize button that appears in the Theme Browser Header"), forState: .Normal)
        detailsButton.setTitle(NSLocalizedString("Details", comment: "Details button that appears in the Theme Browser Header"), forState: .Normal)
        supportButton.setTitle(NSLocalizedString("Support", comment: "Support button that appears in the Theme Browser Header"), forState: .Normal)
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

    private func updateFilterType(type: ThemeType) {
        guard type != filterType else {
            return
        }

        filterType = type
        presenter?.filterType = type
    }

    @IBAction func didTapSearchTypeButton(sender: UIButton) {
        let title = NSLocalizedString("Show themes:", comment: "Alert title picking theme type to browse")
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .ActionSheet)

        ThemeType.types.forEach { type in
            alertController.addActionWithTitle(type.title,
                style: .Default,
                handler: { [weak self] (action: UIAlertAction) in
                    self?.updateFilterType(type)
            })
        }

        alertController.modalPresentationStyle = .Popover
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = filterTypeButton
            popover.sourceRect = filterTypeButton.bounds
            popover.permittedArrowDirections = .Any
            popover.canOverlapSourceViewRect = true
        }
        alertController.presentFromRootViewController()
    }
}
