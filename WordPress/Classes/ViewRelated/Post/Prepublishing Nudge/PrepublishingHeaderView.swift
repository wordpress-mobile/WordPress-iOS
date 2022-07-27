import UIKit
import Gridicons

protocol PrepublishingHeaderViewDelegate: AnyObject {
    func closeButtonTapped()
}

class PrepublishingHeaderView: UITableViewHeaderFooterView, NibLoadable {

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

    func toggleCloseButton(visible: Bool) {
        closeButtonView.layer.opacity = visible ? 1 : 0
        closeButtonView.isHidden = visible ? false : true
        leadingConstraint.constant = visible ? 0 : Constants.leftRightInset
        layoutIfNeeded()
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        delegate?.closeButtonTapped()
    }

    // MARK: - Style

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackgroundView()
        configureBackButton()
        configurePublishingToLabel()
        configureBlogTitleLabel()
        configureBlogImage()
        configureSeparator()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.delegate = nil
    }

    private func configureBackgroundView() {
        backgroundView = UIView()
        backgroundView?.backgroundColor = .basicBackground
    }

    private func configureBackButton() {
        closeButtonView.isHidden = true
        closeButton.setImage(.gridicon(.cross, size: Constants.backButtonSize), for: .normal)
        closeButton.accessibilityLabel = Constants.close
        closeButton.accessibilityHint = Constants.doubleTapToDismiss

        // Only show close button for accessibility purposes
        toggleCloseButton(visible: UIAccessibility.isVoiceOverRunning)
    }

    private func configurePublishingToLabel() {
        publishingToLabel.text = publishingToLabel.text?.uppercased()
        publishingToLabel.font = WPStyleGuide.TableViewHeaderDetailView.titleFont
        publishingToLabel.textColor = WPStyleGuide.TableViewHeaderDetailView.titleColor
    }

    private func configureBlogImage() {
        blogImageView.layer.cornerRadius = Constants.imageRadius
        blogImageView.clipsToBounds = true
    }

    private func configureBlogTitleLabel() {
        WPStyleGuide.applyPostTitleStyle(blogTitleLabel)
    }

    private func configureSeparator() {
        WPStyleGuide.applyBorderStyle(separator)
    }

    private enum Constants {
        static let backButtonSize = CGSize(width: 28, height: 28)
        static let imageRadius: CGFloat = 4
        static let leftRightInset: CGFloat = 16
        static let title = NSLocalizedString("Publishing To", comment: "Label that describes in which blog the user is publishing to")
        static let close = NSLocalizedString("Close", comment: "Voiceover accessibility label informing the user that this button dismiss the current view")
        static let doubleTapToDismiss = NSLocalizedString("Double tap to dismiss", comment: "Voiceover accessibility hint informing the user they can double tap a modal alert to dismiss it")
    }
}
