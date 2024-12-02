import UIKit
import WordPressShared

final class ThemeBrowserHeaderView: UICollectionReusableView {
    // MARK: - Constants

    @objc public static let reuseIdentifier = "ThemeBrowserHeaderView"

    // MARK: - Outlets

    @IBOutlet weak var contentView: UIStackView!
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

    // MARK: - Properties

    fileprivate var theme: Theme? {
        didSet {
            currentThemeName.text = theme?.name
            var customTheme = false
            var hasDetailsURL = false

            if let theme {
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

    fileprivate var filterType: ThemeType = .all

    weak var presenter: ThemePresenter? {
        didSet {
            if let presenter {
                theme = presenter.currentTheme()

                if ThemeType.mayPurchase {
                    filterType = presenter.filterType
                } else {
                    // It will need to be re-implementing if purchasing support added
//                    filterBar.isHidden = true
                }
            }
        }
    }

    // MARK: - GUI

    override func awakeFromNib() {
        super.awakeFromNib()

        let buttons = [customizeButton, detailsButton, supportButton]
        buttons.forEach { $0?.isExclusiveTouch = true }

        applyStyles()
        setTextForLabels()
    }

    fileprivate func applyStyles() {
        backgroundColor = .clear
        contentView.backgroundColor = .systemBackground

        contentView.layer.cornerRadius = 12
        contentView.layer.cornerCurve = .continuous
        contentView.layer.masksToBounds = true

        currentThemeBar.backgroundColor = .systemBackground
        currentThemeContainer.backgroundColor = .systemBackground
        currentThemeDivider.backgroundColor = UIDevice.current.userInterfaceIdiom == .pad ? .clear : .separator

        currentThemeLabel.font = .preferredFont(forTextStyle: .footnote)
        currentThemeLabel.textColor = .secondaryLabel

        currentThemeName.font = .preferredFont(forTextStyle: .headline)
        currentThemeName.textColor = .label

        let currentThemeButtons = [customizeButton, detailsButton, supportButton]
        currentThemeButtons.forEach { WPStyleGuide.Themes.styleCurrentThemeButton($0!) }

        [customizeIcon, detailsIcon, supportIcon].forEach { $0?.tintColor = .secondaryLabel }
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

    override func prepareForReuse() {
        super.prepareForReuse()
        theme = nil
        presenter = nil
    }

    // MARK: - Actions

    @IBAction fileprivate func didTapCustomizeButton(_ sender: UIButton) {
        presenter?.presentCustomizeForTheme(theme)
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
