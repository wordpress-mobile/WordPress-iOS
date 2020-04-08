import UIKit
import Gridicons

protocol PrepublishingHeaderViewDelegate: class {
    func closeButtonTapped()
}

class PrepublishingHeaderView: UIView, NibLoadable {

    @IBOutlet weak var blogImageView: UIImageView!
    @IBOutlet weak var publishingToLabel: UILabel!
    @IBOutlet weak var blogTitleLabel: UILabel!
    @IBOutlet weak var closeButtonView: UIView!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var separator: UIView!

    weak var delegate: PrepublishingHeaderViewDelegate?

    func configure(_ blog: Blog) {
        blogImageView.downloadSiteIcon(for: blog)
        blogTitleLabel.text = blog.title
    }

    // MARK: - Close button

    func hideCloseButton() {
        closeButtonView.layer.opacity = 0
        closeButtonView.isHidden = true
        leadingConstraint.constant = Constants.leftRightInset
        layoutIfNeeded()
    }

    func showCloseButton() {
        closeButtonView.layer.opacity = 1
        closeButtonView.isHidden = false
        leadingConstraint.constant = 0
        layoutIfNeeded()
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        delegate?.closeButtonTapped()
    }

    // MARK: - Style

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackButton()
        configurePublishingToLabel()
        configureBlogTitleLabel()
        configureSeparator()
    }

    private func configureBackButton() {
        closeButtonView.isHidden = true
        closeButton.setImage(.gridicon(.cross, size: Constants.backButtonSize), for: .normal)
        closeButton.accessibilityHint = Constants.doubleTapToDismiss

        // Only show close button for accessibility purposes
        UIAccessibility.isVoiceOverRunning ? showCloseButton() : hideCloseButton()
    }

    private func configurePublishingToLabel() {
        publishingToLabel.text = publishingToLabel.text?.uppercased()
        publishingToLabel.font = WPStyleGuide.TableViewHeaderDetailView.titleFont
        publishingToLabel.textColor = WPStyleGuide.TableViewHeaderDetailView.titleColor
    }

    private func configureBlogTitleLabel() {
        WPStyleGuide.applyPostTitleStyle(blogTitleLabel)
    }

    private func configureSeparator() {
        WPStyleGuide.applyBorderStyle(separator)
    }

    private enum Constants {
        static let backButtonSize = CGSize(width: 28, height: 28)
        static let leftRightInset: CGFloat = 20
        static let title = NSLocalizedString("Publishing To", comment: "Label that describes in which blog the user is publishing to")
        static let doubleTapToDismiss = NSLocalizedString("Double tap to dismiss", comment: "Voiceover accessibility hint informing the user they can double tap a modal alert to dismiss it")
    }
}
