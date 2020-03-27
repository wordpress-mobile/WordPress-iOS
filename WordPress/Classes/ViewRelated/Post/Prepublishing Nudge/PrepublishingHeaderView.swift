import UIKit
import Gridicons

protocol PrepublishingHeaderViewDelegate: class {
    func backButtonTapped()
}

class PrepublishingHeaderView: UIView, NibLoadable {

    @IBOutlet weak var blogImageView: UIImageView!
    @IBOutlet weak var publishingToLabel: UILabel!
    @IBOutlet weak var blogTitleLabel: UILabel!
    @IBOutlet weak var backButtonView: UIView!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var separator: UIView!

    weak var delegate: PrepublishingHeaderViewDelegate?

    func configure(_ blog: Blog) {
        blogImageView.downloadSiteIcon(for: blog)
        blogTitleLabel.text = blog.title
    }

    // MARK: - Back button

    func hideBackButton() {
        backButtonView.layer.opacity = 0
        backButtonView.isHidden = true
        leadingConstraint.constant = Constants.leftRightInset
        layoutIfNeeded()
    }

    func showBackButton() {
        backButtonView.layer.opacity = 1
        backButtonView.isHidden = false
        leadingConstraint.constant = 0
        layoutIfNeeded()
    }

    @IBAction func backButtonTapped(_ sender: Any) {
        delegate?.backButtonTapped()
    }

    // MARK: - Title

    func setTitle(_ title: String?, transitionDuration: TimeInterval = 0.2) {
        UIView.transition(with: publishingToLabel,
                          duration: transitionDuration,
                          options: .transitionCrossDissolve,
                          animations: {
            self.publishingToLabel.text = title?.uppercased()
        })
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
        backButtonView.isHidden = true
        backButton.setImage(Gridicon.iconOfType(.chevronLeft, withSize: Constants.backButtonSize), for: .normal)
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
    }
}
