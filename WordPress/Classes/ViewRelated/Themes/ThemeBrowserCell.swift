import Foundation
import WordPressShared.WPStyleGuide
import CocoaLumberjack

/// Actions provided in cell button triggered action sheet
///
public enum ThemeAction {
    case activate
    case customize
    case details
    case support
    case tryCustomize
    case view

    static func activeActionsForTheme(_ theme: Theme) ->[ThemeAction] {
        if theme.custom {
            if theme.hasDetailsURL() {
                return [customize, details]
            }
            return [customize]
        }
        return [customize, details, support]
    }

    static func inactiveActionsForTheme(_ theme: Theme) ->[ThemeAction] {
        if theme.custom {
            if theme.hasDetailsURL() {
                return [tryCustomize, activate, details]
            }
            return [tryCustomize, activate]
        }
        return [tryCustomize, activate, view, details, support]
    }

    var title: String {
        switch self {
        case .activate:
            return NSLocalizedString("Activate", comment: "Theme Activate action title")
        case .customize:
            return NSLocalizedString("Customize", comment: "Theme Customize action title")
        case .details:
            return NSLocalizedString("Details", comment: "Theme Details action title")
        case .support:
            return NSLocalizedString("Support", comment: "Theme Support action title")
        case .tryCustomize:
            return NSLocalizedString("Try & Customize", comment: "Theme Try & Customize action title")
        case .view:
            return NSLocalizedString("View", comment: "Theme View action title")
        }
    }

    func present(_ theme: Theme, _ presenter: ThemePresenter) {
        switch self {
        case .activate:
            presenter.activateTheme(theme)
        case .customize:
            presenter.presentCustomizeForTheme(theme)
        case .details:
            presenter.presentDetailsForTheme(theme)
        case .support:
            presenter.presentSupportForTheme(theme)
        case .tryCustomize:
            presenter.presentPreviewForTheme(theme)
        case .view:
            presenter.presentViewForTheme(theme)
        }
    }
}

open class ThemeBrowserCell: UICollectionViewCell {
    // MARK: - Constants

    @objc public static let reuseIdentifier = "ThemeBrowserCell"

    // MARK: - Private Aliases

    fileprivate typealias Styles = WPStyleGuide.Themes

    // MARK: - Outlets

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var infoBar: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var highlightView: UIView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!

    // MARK: - Properties

    @objc open var theme: Theme? {
        didSet {
            refreshGUI()
        }
    }

    @objc open var showPriceInformation: Bool = false
    open weak var presenter: ThemePresenter?

    fileprivate var placeholderImage = UIImage(named: "theme-loading")
    fileprivate var activeEllipsisImage = UIImage(named: "icon-menu-ellipsis-white")
    fileprivate var inactiveEllipsisImage = UIImage(named: "icon-menu-ellipsis")

    // MARK: - GUI

    override open var isHighlighted: Bool {
        didSet {
            let alphaFinal: CGFloat = isHighlighted ? 0.3 : 0
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.highlightView.alpha = alphaFinal
            })
        }
    }

    override open func awakeFromNib() {
        super.awakeFromNib()

        actionButton.isExclusiveTouch = true

        layer.borderWidth = Styles.cellBorderWidth
        infoBar.layer.borderWidth = Styles.cellBorderWidth
        nameLabel.font = Styles.cellNameFont
        infoLabel.font = Styles.cellInfoFont
        actionButton.layer.borderWidth = Styles.cellBorderWidth
    }

    override open func prepareForReuse() {
        super.prepareForReuse()
        theme = nil
        presenter = nil
        showPriceInformation = false
    }

    fileprivate func refreshGUI() {
        if let theme = theme {
            if let imageUrl = theme.screenshotUrl, !imageUrl.isEmpty {
                refreshScreenshotImage(imageUrl)
            } else {
                showPlaceholder()
            }

            nameLabel.text = theme.name
            if theme.isCurrentTheme() {
                backgroundColor = Styles.activeCellBackgroundColor
                infoBar.backgroundColor = Styles.activeCellBackgroundColor
                layer.borderColor = Styles.activeCellBorderColor.cgColor
                infoBar.layer.borderColor = Styles.activeCellDividerColor.cgColor
                actionButton.layer.borderColor = Styles.activeCellDividerColor.cgColor
                actionButton.setImage(activeEllipsisImage, for: .normal)

                nameLabel.textColor = Styles.activeCellNameColor
                infoLabel.textColor = Styles.activeCellInfoColor
                infoLabel.text = NSLocalizedString("ACTIVE", comment: "Label for active Theme browser cell")
            } else {
                backgroundColor = Styles.inactiveCellBackgroundColor
                infoBar.backgroundColor = Styles.inactiveCellBackgroundColor
                layer.borderColor = Styles.inactiveCellBorderColor.cgColor
                infoBar.layer.borderColor = Styles.inactiveCellDividerColor.cgColor
                actionButton.layer.borderColor = Styles.inactiveCellDividerColor.cgColor
                actionButton.setImage(inactiveEllipsisImage, for: .normal)

                nameLabel.textColor = Styles.inactiveCellNameColor
                if theme.isPremium() && showPriceInformation {
                    infoLabel.textColor = Styles.inactiveCellPriceColor
                    infoLabel.text = theme.price
                } else {
                    infoLabel.text = nil
                }
            }
        } else {
            imageView.image = nil
            nameLabel.text = nil
            infoLabel.text = nil
            activityView.stopAnimating()
        }

        prepareForVoiceOver()
    }

    fileprivate func showPlaceholder() {
        imageView.contentMode = .center
        imageView.backgroundColor = Styles.placeholderColor
        imageView.image = placeholderImage
        activityView.stopAnimating()
    }

    fileprivate func showScreenshot() {
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.clear
        activityView.stopAnimating()
    }

    fileprivate func refreshScreenshotImage(_ imageUrl: String) {
        // Themes not hosted on WP.com have an incorrect screenshotUrl and do not correctly support the w param
        let imageUrlForWidth = imageUrl.hasPrefix("http") ? imageUrl + "?w=\(presenter!.screenshotWidth)" :
            String(format: "http:%@", imageUrl)
        let screenshotUrl = URL(string: imageUrlForWidth)

        imageView.backgroundColor = Styles.placeholderColor
        activityView.startAnimating()
        imageView.downloadImage(from: screenshotUrl, success: { [weak self] _ in
            self?.showScreenshot()
        }, failure: { [weak self] error in
                if let error = error as NSError?, error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                    return
                }
                DDLogError("Error loading theme screenshot: \(String(describing: error?.localizedDescription))")
                self?.showPlaceholder()
        })
    }

    // MARK: - Actions

    @IBAction fileprivate func didTapActionButton(_ sender: UIButton) {
        guard let theme = theme, let presenter = presenter else {
            return
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let themeActions = theme.isCurrentTheme() ? ThemeAction.activeActionsForTheme(theme) : ThemeAction.inactiveActionsForTheme(theme)
        themeActions.forEach { themeAction in
            alertController.addActionWithTitle(themeAction.title,
                                               style: .default,
                                               handler: { (action: UIAlertAction) in
                                                themeAction.present(theme, presenter)
            })
        }

        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel action title")
        alertController.addCancelActionWithTitle(cancelTitle, handler: nil)

        alertController.modalPresentationStyle = .popover
        alertController.presentFromRootViewController()

        if let popover = alertController.popoverPresentationController {
            popover.sourceView = actionButton
            popover.sourceRect = actionButton.bounds
            popover.permittedArrowDirections = .any
            popover.canOverlapSourceViewRect = true
        }
    }

}

extension ThemeBrowserCell: Accessible {
    func prepareForVoiceOver() {
        prepareCellForVoiceOver()
        prepareActionButtonForVoiceOver()
        prepareNameLabelForVoiceOver()
    }

    private func prepareCellForVoiceOver() {
        imageView.isAccessibilityElement = true
        if let name = theme?.name {
            imageView.accessibilityLabel = name
            imageView.accessibilityTraits = [.button, .summaryElement]
        }

        if let details = theme?.details {
            imageView.accessibilityHint = details
        }
    }

    private func prepareActionButtonForVoiceOver() {
        actionButton.isAccessibilityElement = true
        actionButton.accessibilityLabel = NSLocalizedString("More", comment: "Action button to display more available options")
        actionButton.accessibilityTraits = .button
    }

    private func prepareNameLabelForVoiceOver() {
        nameLabel.isAccessibilityElement = false
    }
}
