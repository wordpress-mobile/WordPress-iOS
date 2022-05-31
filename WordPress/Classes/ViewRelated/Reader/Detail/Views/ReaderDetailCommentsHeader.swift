import UIKit

class ReaderDetailCommentsHeader: UITableViewHeaderFooterView, NibReusable {

    // MARK: - Properties

    static let estimatedHeight: CGFloat = 80
    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var followButton: UIButton!
    private var post: ReaderPost?
    private var readerCommentsFollowPresenter: ReaderCommentsFollowPresenter?
    private var tooltipPresenter: TooltipPresenter?
    private(set) var tooltip: Tooltip?

    private var totalComments = 0 {
        didSet {
            configureTitleLabel()
        }
    }

    private var followConversationEnabled = false {
        didSet {
            followButton.isHidden = !followConversationEnabled
        }
    }

    private var isSubscribedComments: Bool {
        return post?.isSubscribedComments ?? false
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }

    // MARK: - Configure

    func configure(post: ReaderPost, totalComments: Int, presentingViewController: UIViewController) {
        self.post = post
        self.totalComments = totalComments
        self.followConversationEnabled = post.commentsOpen && post.canSubscribeComments

        configureButton()

        readerCommentsFollowPresenter = ReaderCommentsFollowPresenter.init(
            post: post,
            delegate: self,
            presentingViewController: presentingViewController
        )
    }

    func configureTooltip(onView view: UIView, anchorAction: (() -> Void)?) {
        let tooltip = Tooltip()
        self.tooltip = tooltip

        tooltip.title = "Follow the conversation"
        tooltip.message = "Get notified."
        tooltip.primaryButtonTitle = "Got it"
        tooltip.secondaryButtonTitle = "Learn more"

        tooltipPresenter = TooltipPresenter(
            containerView: contentStackView,
            tooltip: tooltip,
            target: .view(followButton)
        )
        
        if let anchorAction = anchorAction {
            tooltipPresenter?.attachAnchor(
                withTitle: "New",
                onView: view,
                anchorAction: anchorAction
            )
        }
        tooltipPresenter?.showTooltip()
    }

    func updateFollowButtonState(post: ReaderPost) {
        self.post = post
        configureButton()
    }

    func toggleAnchorVisibility(_ isVisible: Bool) {
        tooltipPresenter?.toggleAnchorVisibility(isVisible)
    }
}

// MARK: - Private Extension

private extension ReaderDetailCommentsHeader {

    func configureView() {
        contentView.backgroundColor = .basicBackground
        addBottomBorder(withColor: .divider)
        configureTitle()

    }

    func configureTitle() {
        titleLabel.textColor = .text
        titleLabel.font = WPStyleGuide.serifFontForTextStyle(.title3, fontWeight: .semibold)
    }

    func configureTitleLabel() {
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

    func configureButton() {
        configureStackView()
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

    func configureStackView() {
        // If isAccessibilityCategory, display the content vertically.
        // This makes the Follow button "wrap" and appear under the title label.
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            contentStackView.axis = .vertical
            contentStackView.alignment = .leading
            contentStackView.distribution = .fill
            contentStackView.spacing = 10
        } else {
            contentStackView.axis = .horizontal
            contentStackView.alignment = .center
            contentStackView.distribution = .fill
            contentStackView.spacing = 0
        }
    }

    @objc func followButtonTapped() {
        isSubscribedComments ? readerCommentsFollowPresenter?.showNotificationSheet(sourceView: followButton) :
                               readerCommentsFollowPresenter?.handleFollowConversationButtonTapped()
    }

    struct Titles {
        static let singularCommentFormat = NSLocalizedString("%1$d Comment", comment: "Singular label displaying number of comments. %1$d is a placeholder for the number of Comments.")
        static let pluralCommentsFormat = NSLocalizedString("%1$d Comments", comment: "Plural label displaying number of comments. %1$d is a placeholder for the number of Comments.")
        static let comments = NSLocalizedString("Comments", comment: "Comments table header label.")
        static let followButton = NSLocalizedString("Follow Conversation", comment: "Button title. Follow the comments on a post.")
    }

}

// MARK: - ReaderCommentsFollowPresenterDelegate

extension ReaderDetailCommentsHeader: ReaderCommentsFollowPresenterDelegate {

    func followConversationComplete(success: Bool, post: ReaderPost) {
        self.post = post
        configureButton()
    }

    func toggleNotificationComplete(success: Bool, post: ReaderPost) {
        self.post = post
    }

}
