import Foundation
import WordPressShared.WPStyleGuide

/**
 *  @brief      Actions provided in cell button triggered action sheet
 */
public enum ThemeAction
{
    case Activate
    case Customize
    case Details
    case Support
    case TryCustomize
    case View
    
    static let actives = [Customize, Details, Support]
    static let inactives = [TryCustomize, Activate, View, Details, Support]
    
    var title: String {
        switch self {
        case .Activate:
            return NSLocalizedString("Activate", comment: "Theme Activate action title")
        case .Customize:
            return NSLocalizedString("Customize", comment: "Theme Customize action title")
        case .Details:
            return NSLocalizedString("Details", comment: "Theme Details action title")
        case .Support:
            return NSLocalizedString("Support", comment: "Theme Support action title")
        case .TryCustomize:
            return NSLocalizedString("Try & Customize", comment: "Theme Try & Customize action title")
        case .View:
            return NSLocalizedString("View", comment: "Theme View action title")
        }
    }
    
    func present(theme: Theme, _ presenter: ThemePresenter) {
        switch self {
        case .Activate:
            presenter.activateTheme(theme)
        case .Customize:
            presenter.presentCustomizeForTheme(theme)
        case .Details:
            presenter.presentDetailsForTheme(theme)
        case .Support:
            presenter.presentSupportForTheme(theme)
        case .TryCustomize:
            presenter.presentPreviewForTheme(theme)
        case .View:
            presenter.presentViewForTheme(theme)
        }
    }
}

public class ThemeBrowserCell : UICollectionViewCell
{
    // MARK: - Constants
    
    public static let reuseIdentifier = "ThemeBrowserCell"
    
    // MARK: - Private Aliases
    
    private typealias Styles = WPStyleGuide.Themes
    
   // MARK: - Outlets
    
    @IBOutlet weak var imageView : UIImageView!
    @IBOutlet weak var infoBar: UIView!
    @IBOutlet weak var nameLabel : UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var highlightView: UIView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    public var theme : Theme? {
        didSet {
            refreshGUI()
        }
    }
    public weak var presenter: ThemePresenter?
    
    private var placeholderImage = UIImage(named: "theme-loading")
    private var activeEllipsisImage = UIImage(named: "icon-menu-ellipsis-white")
    private var inactiveEllipsisImage = UIImage(named: "icon-menu-ellipsis")
    
   // MARK: - GUI
        
    override public var highlighted: Bool {
        didSet {
            let alphaFinal: CGFloat = highlighted ? 0.3 : 0
            UIView.animateWithDuration(0.2) { [weak self] in
                self?.highlightView.alpha = alphaFinal
            }
        }
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        actionButton.exclusiveTouch = true
        
        layer.borderWidth = 1
        infoBar.layer.borderWidth = 1
        nameLabel.font = Styles.cellNameFont
        infoLabel.font = Styles.cellInfoFont
        actionButton.layer.borderWidth = 1
    }
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        theme = nil
        presenter = nil
    }
    
    private func refreshGUI() {
        if let theme = theme {
           if let imageUrl = theme.screenshotUrl where !imageUrl.isEmpty {
                refreshScreenshotImage(imageUrl)
            } else {
                showPlaceholder()
            }
            
            nameLabel.text = theme.name
            if theme.isCurrentTheme() {
                backgroundColor = Styles.activeCellBackgroundColor
                layer.borderColor = Styles.activeCellBorderColor.CGColor
                infoBar.layer.borderColor = Styles.activeCellDividerColor.CGColor
                actionButton.layer.borderColor = Styles.activeCellDividerColor.CGColor
                actionButton.setImage(activeEllipsisImage, forState: .Normal)
                
                nameLabel.textColor = Styles.activeCellNameColor
                infoLabel.textColor = Styles.activeCellInfoColor
                infoLabel.text = NSLocalizedString("ACTIVE", comment: "Label for active Theme browser cell")
            } else {
                backgroundColor = Styles.inactiveCellBackgroundColor
                layer.borderColor = Styles.inactiveCellBorderColor.CGColor
                infoBar.layer.borderColor = Styles.inactiveCellDividerColor.CGColor
                actionButton.layer.borderColor = Styles.inactiveCellDividerColor.CGColor
                actionButton.setImage(inactiveEllipsisImage, forState: .Normal)

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
    
    private func showPlaceholder() {
        imageView.contentMode = .Center
        imageView.backgroundColor = Styles.placeholderColor
        imageView.image = placeholderImage
        activityView.stopAnimating()
    }
    
    private func showScreenshot() {
        imageView.contentMode = .ScaleAspectFit
        imageView.backgroundColor = UIColor.clearColor()
        activityView.stopAnimating()
    }
    
    private func refreshScreenshotImage(imageUrl: String) {
        let imageUrlForWidth = imageUrl + "?w=\(presenter!.screenshotWidth)"
        let screenshotUrl = NSURL(string: imageUrlForWidth)
        
        imageView.backgroundColor = Styles.placeholderColor
        activityView.startAnimating()
        imageView.downloadImage(screenshotUrl,
            placeholderImage: nil,
            success: { [weak self] (image: UIImage) in
                self?.showScreenshot()
        }, failure: { [weak self] (error: NSError!) in
                if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                    return
                }
                DDLogSwift.logError("Error loading theme screenshot: \(error.localizedDescription)")
                self?.showPlaceholder()
        })
    }

    // MARK: - Actions
    
    @IBAction private func didTapActionButton(sender: UIButton) {
        guard let theme = theme, presenter = presenter else {
            return
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let themeActions = theme.isCurrentTheme() ? ThemeAction.actives : ThemeAction.inactives
        themeActions.forEach { themeAction in
            alertController.addActionWithTitle(themeAction.title,
                style: .Default,
                handler: { (action: UIAlertAction) in
                    themeAction.present(theme, presenter)
                })
        }
        
        alertController.modalPresentationStyle = .Popover
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = actionButton
            popover.sourceRect = actionButton.bounds
            popover.permittedArrowDirections = .Any
            popover.canOverlapSourceViewRect = true
        } else {
            let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel action title")
            alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
        }
        alertController.presentFromRootViewController()
    }

}
