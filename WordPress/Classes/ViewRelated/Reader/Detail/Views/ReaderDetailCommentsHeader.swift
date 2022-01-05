import UIKit

class ReaderDetailCommentsHeader: UITableViewHeaderFooterView, NibReusable {

    static let estimatedHeight: CGFloat = 80
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet private weak var followButton: UIButton!
    private let buttonTitle = NSLocalizedString("Follow Conversation", comment: "Button title. Follow the comments on a post.")

    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }

}

private extension ReaderDetailCommentsHeader {

    func configureView() {
        contentView.backgroundColor = .basicBackground
        addBottomBorder(withColor: .divider)
        configureTitle()
        configureButton()
    }

    func configureTitle() {
        titleLabel.textColor = .text
        titleLabel.font = WPStyleGuide.serifFontForTextStyle(.title3, fontWeight: .semibold)
    }

    func configureButton() {
        guard FeatureFlag.followConversationPostDetails.enabled else {
            followButton.isHidden = true
            return
        }

        followButton.setTitle(buttonTitle, for: .normal)
        followButton.setTitleColor(.primary, for: .normal)
        followButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.footnote)
        followButton.addTarget(self, action: #selector(followButtonTapped), for: .touchUpInside)
    }

    @objc func followButtonTapped() {
        // TODO: implement following
    }

}
