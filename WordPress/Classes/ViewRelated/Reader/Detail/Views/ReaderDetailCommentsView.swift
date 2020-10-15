import UIKit
import Gridicons

class ReaderDetailCommentsView: UIView, NibLoadable {
    @IBOutlet weak var viewCommentsButton: UIButton!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var disclosureImageView: UIImageView!
    @IBOutlet weak var addButton: UIButton!

    /// The reader post that the toolbar interacts with
    private var post: ReaderPost?

    /// The VC where the toolbar is inserted
    private weak var viewController: UIViewController?

    /// Returns the current comment count
    private var commentCount: Int {
        return post?.commentCount()?.intValue ?? 0
    }

    /// Configures the view for the given post
    func configure(for post: ReaderPost, in viewController: UIViewController) {
        self.post = post
        self.viewController = viewController

        guard shouldShowCommentAction else {
            isHidden = true
            return
        }

        commentsLabel.text = commentTitle()
        addButton.setTitle(Strings.addComment, for: .normal)

        applyStyles()
        isHidden = false
    }

    // MARK: - IBAction's
    @IBAction func didTapViewCommentsButton(_ sender: Any) {
        guard let post = post, let viewController = viewController else {
            return
        }

        ReaderCommentAction().execute(post: post, origin: viewController)
    }

    @IBAction func didTapAddCommentButton(_ sender: Any) {
        guard let post = post, let viewController = viewController else {
            return
        }

        ReaderCommentAction().execute(post: post,
                                      origin: viewController,
                                      promptToAddComment: true)
    }

    // MARK: - Private: Helpers
    private func commentTitle() -> String {
        var format: String
        switch commentCount {
            case let count where count == 1:
                format = Strings.commentFormat
            case let count where count > 0:
                format = Strings.commentFormatPlural
            default:
                format = Strings.noCommentFormat
        }

        return String(format: format, "\(commentCount)")
    }

    private var shouldShowCommentAction: Bool {
        // Show comments if logged in and comments are enabled, or if comments exist.
        // But only if it is from wpcom (jetpack and external is not yet supported).
        // Nesting this conditional cos it seems clearer that way
        guard let post = post else {
            return false
        }

        if post.isWPCom || post.isJetpack {
            if (ReaderHelpers.isLoggedIn() && post.commentsOpen) || commentCount > 0 {
                return true
            }
        }

        return false
    }

    // MARK: - Styles
    private func applyStyles() {
        commentsLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        commentsLabel.textColor = .text
        addButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body)
        addButton.titleLabel?.textColor = UIColor.muriel(color: .primary, .shade40)

        let iconColor = UIColor(light: .lightGray, dark: .white)

        let icon: UIImage = UIImage.gridicon(.chevronRight, size: CGSize(width: 20, height: 20))
        disclosureImageView.image = icon.imageWithTintColor(iconColor)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        applyStyles()
    }

    // MARK: - Constants
    private struct Strings {
        static let noCommentFormat = NSLocalizedString("Comments", comment: "Accessibility label for comments button with no comments")
        static let commentFormat = NSLocalizedString("%@ comment", comment: "Accessibility label for comments button (singular)")
        static let commentFormatPlural = NSLocalizedString("%@ comments", comment: "Accessibility label for comments button (plural)")
        static let addComment = NSLocalizedString("Add Comment", comment: "Accessibility label for add comment button")
    }
}
