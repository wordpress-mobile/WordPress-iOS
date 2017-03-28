import Foundation
import WordPressShared.WPStyleGuide

/// Actions provided in cell button triggered action sheet
///
public enum ThemeAction {
    case activate
    case customize
    case details
    case support
    case tryCustomize
    case view

    static let actives = [customize, details, support]
    static let inactives = [tryCustomize, activate, view, details, support]

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

    open static let reuseIdentifier = "ThemeBrowserCell"

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

    open var theme: Theme? {
        didSet {
            refreshGUI()
        }
    }
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

        layer.borderWidth = 1
        infoBar.layer.borderWidth = 1
        nameLabel.font = Styles.cellNameFont
        infoLabel.font = Styles.cellInfoFont
        actionButton.layer.borderWidth = 1
    }

    override open func prepareForReuse() {
        super.prepareForReuse()
        theme = nil
        presenter = nil
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
                layer.borderColor = Styles.activeCellBorderColor.cgColor
                infoBar.layer.borderColor = Styles.activeCellDividerColor.cgColor
                actionButton.layer.borderColor = Styles.activeCellDividerColor.cgColor
                actionButton.setImage(activeEllipsisImage, for: UIControlState())

                nameLabel.textColor = Styles.activeCellNameColor
                infoLabel.textColor = Styles.activeCellInfoColor
                infoLabel.text = NSLocalizedString("ACTIVE", comment: "Label for active Theme browser cell")
            } else {
                backgroundColor = Styles.inactiveCellBackgroundColor
                layer.borderColor = Styles.inactiveCellBorderColor.cgColor
                infoBar.layer.borderColor = Styles.inactiveCellDividerColor.cgColor
                actionButton.layer.borderColor = Styles.inactiveCellDividerColor.cgColor
                actionButton.setImage(inactiveEllipsisImage, for: UIControlState())

                nameLabel.textColor = Styles.inactiveCellNameColor
                if theme.isPremium() {
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
        let imageUrlForWidth = imageUrl + "?w=\(presenter!.screenshotWidth)"
        let screenshotUrl = URL(string: imageUrlForWidth)

        imageView.backgroundColor = Styles.placeholderColor
        activityView.startAnimating()
        imageView.downloadImage(screenshotUrl,
            placeholderImage: nil,
            success: { [weak self] (image: UIImage) in
                self?.showScreenshot()
        }, failure: { [weak self] (error: Error?) in
                if let error = error as NSError?, error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                    return
                }
                DDLogSwift.logError("Error loading theme screenshot: \(String(describing: error?.localizedDescription))")
                self?.showPlaceholder()
        })
    }

    // MARK: - Actions

    @IBAction fileprivate func didTapActionButton(_ sender: UIButton) {
        guard let theme = theme, let presenter = presenter else {
            return
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let themeActions = theme.isCurrentTheme() ? ThemeAction.actives : ThemeAction.inactives
        themeActions.forEach { themeAction in
            alertController.addActionWithTitle(themeAction.title,
                style: .default,
                handler: { (action: UIAlertAction) in
                    themeAction.present(theme, presenter)
                })
        }

        alertController.modalPresentationStyle = .popover
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = actionButton
            popover.sourceRect = actionButton.bounds
            popover.permittedArrowDirections = .any
            popover.canOverlapSourceViewRect = true
        } else {
            let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel action title")
            alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
        }
        alertController.presentFromRootViewController()
    }

}
