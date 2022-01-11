import UIKit

class ReaderDetailCommentsHeader: UITableViewHeaderFooterView, NibReusable {

    static let estimatedHeight: CGFloat = 80
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var followButton: UIButton!

    private var followConversationEnabled = true {
        didSet {
            followButton.isHidden = !FeatureFlag.followConversationPostDetails.enabled || !followConversationEnabled
        }
    }

    private var isSubscribedComments: Bool = false {
        didSet {
            configureButton()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }

    func configure(totalComments: Int, followConversationEnabled: Bool, isSubscribedComments: Bool) {
        self.followConversationEnabled = followConversationEnabled
        self.isSubscribedComments = isSubscribedComments

        titleLabel.text = {
            switch totalComments {
            case 0:
                return Titles.comments
            case 1:
                return String(format: Titles.singularCommentFormat, totalComments)
            default:
                return String(format: Titles.pluralCommentsFormat, totalComments)
            }
        }()
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
        followButton.addTarget(self, action: #selector(followButtonTapped), for: .touchUpInside)

        if isSubscribedComments {
            followButton.setImage(UIImage.init(systemName: "bell"), for: .normal)
            followButton.setTitle(nil, for: .normal)
        } else {
            followButton.setTitle(Titles.followButton, for: .normal)
            followButton.setTitleColor(.primary, for: .normal)
            followButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.footnote)
            followButton.setImage(nil, for: .normal)
        }
    }

    @objc func followButtonTapped() {
        // TODO: implement following
    }

    struct Titles {
        static let singularCommentFormat = NSLocalizedString("%1$d Comment", comment: "Singular label displaying number of comments. %1$d is a placeholder for the number of Comments.")
        static let pluralCommentsFormat = NSLocalizedString("%1$d Comments", comment: "Plural label displaying number of comments. %1$d is a placeholder for the number of Comments.")
        static let comments = NSLocalizedString("Comments", comment: "Comments table header label.")
        static let followButton = NSLocalizedString("Follow Conversation", comment: "Button title. Follow the comments on a post.")
    }

}
