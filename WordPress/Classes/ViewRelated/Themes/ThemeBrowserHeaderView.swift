import UIKit
import WordPressShared

open class ThemeBrowserHeaderView: UICollectionReusableView {
    // MARK: - Constants

    @objc public static let reuseIdentifier = "ThemeBrowserHeaderView"

    // MARK: - Private Aliases

    fileprivate typealias Styles = WPStyleGuide.Themes

    // MARK: - Outlets

    @IBOutlet weak var currentThemeBar: UIView!
    @IBOutlet weak var currentThemeLabel: UILabel!
    @IBOutlet weak var currentThemeDivider: UIView!
    @IBOutlet weak var currentThemeContainer: UIView!
    @IBOutlet weak var currentThemeName: UILabel!
    @IBOutlet weak var customizeButton: UIButton!
    @IBOutlet weak var customizeIcon: UIImageView!
    @IBOutlet weak var detailsButton: UIButton!
    @IBOutlet weak var detailsIcon: UIImageView!
    @IBOutlet weak var supportButton: UIButton!
    @IBOutlet weak var supportIcon: UIImageView!
    @IBOutlet var filterBarBorders: [UIView]!
    @IBOutlet weak var filterBar: UIView!
    @IBOutlet weak var filterTypeButton: UIButton!
    var quickStartSpotlightView = QuickStartSpotlightView()

    // MARK: - Properties

    private var observer: NSObjectProtocol?

    fileprivate var theme: Theme? {
        didSet {
            currentThemeName.text = theme?.name
            var customTheme = false
            var hasDetailsURL = false

            if let theme = theme {
                customTheme = theme.custom
                hasDetailsURL = theme.hasDetailsURL()
            }

            supportButton.isHidden = customTheme
            supportIcon.isHidden = customTheme
            detailsButton.isHidden = customTheme && !hasDetailsURL
            detailsIcon.isHidden = customTheme && !hasDetailsURL

            prepareForVoiceOver()
        }
    }
    fileprivate var filterType: ThemeType = .all {
        didSet {
            Styles.styleSearchTypeButton(filterTypeButton, title: filterType.title)
        }
    }
    open weak var presenter: ThemePresenter? {
        didSet {
            if let presenter = presenter {
                theme = presenter.currentTheme()

                if ThemeType.mayPurchase {
                    filterType = presenter.filterType
                } else {
                    filterBar.isHidden = true
                }
            }
        }
    }

    // MARK: - GUI

    override open func awakeFromNib() {
        super.awakeFromNib()

        let buttons = [customizeButton, detailsButton, supportButton, filterTypeButton]
        buttons.forEach { $0?.isExclusiveTouch = true }

        applyStyles()
        setTextForLabels()

        startObservingForQuickStart()
    }

    fileprivate func applyStyles() {
        currentThemeBar.backgroundColor = Styles.currentThemeBackgroundColor
        currentThemeContainer.backgroundColor = Styles.currentThemeBackgroundColor
        currentThemeDivider.backgroundColor = Styles.currentThemeDividerColor

        currentThemeLabel.font = Styles.currentThemeLabelFont
        currentThemeLabel.textColor = Styles.currentThemeLabelColor

        currentThemeName.font = Styles.currentThemeNameFont
        currentThemeName.textColor = Styles.currentThemeNameColor

        let currentThemeButtons = [customizeButton, detailsButton, supportButton]
        currentThemeButtons.forEach { Styles.styleCurrentThemeButton($0!) }

        [customizeIcon, detailsIcon, supportIcon].forEach { $0?.tintColor = .listIcon }

        spotlightCustomizeButtonIfTourIsActive()

        filterBar.backgroundColor = Styles.searchBarBackgroundColor
        filterBarBorders.forEach { $0.backgroundColor = Styles.searchBarBorderColor }
    }

    private func spotlightCustomizeButtonIfTourIsActive() {

        if QuickStartTourGuide.shared.isCurrentElement(.customize) {
            customizeButton.addSubview(quickStartSpotlightView)
            quickStartSpotlightView.translatesAutoresizingMaskIntoConstraints = false
            addConstraints([
                quickStartSpotlightView.centerYAnchor.constraint(equalTo: customizeButton.centerYAnchor),
                quickStartSpotlightView.trailingAnchor.constraint(equalTo: customizeButton.trailingAnchor, constant: Constants.spotlightViewPadding)
                ])
        }
    }

    private func startObservingForQuickStart() {
        observer = NotificationCenter.default.addObserver(forName: .QuickStartTourElementChangedNotification, object: nil, queue: nil) { [weak self] (notification) in
            self?.spotlightCustomizeButtonIfTourIsActive()
        }
    }

    fileprivate func setTextForLabels() {
        currentThemeLabel.text = NSLocalizedString("Current Theme",
                                                   comment: "Current Theme text that appears in Theme Browser Header")

        let customizeButtonText = NSLocalizedString("Customize",
                                                    comment: "Customize button that appears in Theme Browser Header")
        customizeButton.setTitle(customizeButtonText, for: .normal)

        let detailsButtonText = NSLocalizedString("Details",
                                                  comment: "Details button that appears in the Theme Browser Header")
        detailsButton.setTitle(detailsButtonText, for: .normal)

        let supportButtonText = NSLocalizedString("Support",
                                                  comment: "Support button that appears in the Theme Browser Header")
        supportButton.setTitle(supportButtonText, for: .normal)
    }

    override open func prepareForReuse() {
        super.prepareForReuse()
        theme = nil
        presenter = nil
    }

    // MARK: - Actions

    @IBAction fileprivate func didTapCustomizeButton(_ sender: UIButton) {
        presenter?.presentCustomizeForTheme(theme)

        quickStartSpotlightView.removeFromSuperview()
    }

    @IBAction fileprivate func didTapDetailsButton(_ sender: UIButton) {
        presenter?.presentDetailsForTheme(theme)
    }

    @IBAction fileprivate func didTapSupportButton(_ sender: UIButton) {
        presenter?.presentSupportForTheme(theme)
    }

    fileprivate func updateFilterType(_ type: ThemeType) {
        guard type != filterType else {
            return
        }

        filterType = type
        presenter?.filterType = type
    }

    @IBAction func didTapSearchTypeButton(_ sender: UIButton) {
        let title = NSLocalizedString("Show themes:", comment: "Alert title picking theme type to browse")
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

        ThemeType.types.forEach { type in
            alertController.addActionWithTitle(type.title,
                style: .default,
                handler: { [weak self] (action: UIAlertAction) in
                    self?.updateFilterType(type)
            })
        }

        alertController.modalPresentationStyle = .popover
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = filterTypeButton
            popover.sourceRect = filterTypeButton.bounds
            popover.permittedArrowDirections = .any
            popover.canOverlapSourceViewRect = true
        }
        alertController.presentFromRootViewController()
    }

    private enum Constants {
        static let spotlightViewPadding: CGFloat = -5.0
    }
}

extension ThemeBrowserHeaderView: Accessible {
    func prepareForVoiceOver() {
        prepareThemeBarForVoiceOver()
    }

    private func prepareThemeBarForVoiceOver() {
        currentThemeContainer.isAccessibilityElement = true
        if let currentThemeLabel = currentThemeLabel.text, let currentThemeName = currentThemeName.text {
            currentThemeContainer.accessibilityLabel = currentThemeLabel + ", " + currentThemeName + "."
        }
    }
}
