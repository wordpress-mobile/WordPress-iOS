import UIKit
import Gridicons

class RestorePostTableViewCell: UITableViewCell, ConfigurablePostView, InteractivePostView {
    @IBOutlet var postContentView: UIView! {
        didSet {
            postContentView.backgroundColor = .listForeground
        }
    }
    @IBOutlet var restoreLabel: UILabel!
    @IBOutlet var restoreButton: UIButton!
    @IBOutlet var topMargin: NSLayoutConstraint!

    private weak var delegate: InteractivePostViewDelegate?

    var isCompact: Bool = false {
        didSet {
            isCompact ? configureCompact() : configureDefault()
        }
    }
    var post: Post?

    func configure(with post: Post) {
        self.post = post
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Don't respond to taps in margins.
        if !postContentView.frame.contains(point) {
            return nil
        }
        return super.hitTest(point, with: event)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureView()
        applyStyles()
    }

    private func configureView() {
        restoreLabel.text = NSLocalizedString("Post moved to trash.", comment: "A short message explaining that a post was moved to the trash bin.")
        let buttonTitle = NSLocalizedString("Undo", comment: "The title of an 'undo' button. Tapping the button moves a trashed post out of the trash folder.")
        restoreButton.setTitle(buttonTitle, for: .normal)
        restoreButton.setImage(Gridicon.iconOfType(.undo, withSize: CGSize(width: Constants.imageSize,
                                                                           height: Constants.imageSize)), for: .normal)
    }

    private func configureCompact() {
        topMargin.constant = Constants.compactMargin
        postContentView.layer.borderWidth = 0
    }

    private func configureDefault() {
        topMargin.constant = Constants.defaultMargin
        postContentView.layer.borderColor = WPStyleGuide.postCardBorderColor.cgColor
        postContentView.layer.borderWidth = .hairlineBorderWidth
    }

    private func applyStyles() {
        WPStyleGuide.applyPostCardStyle(self)
        WPStyleGuide.applyRestorePostLabelStyle(restoreLabel)
        WPStyleGuide.applyRestorePostButtonStyle(restoreButton)
    }

    @IBAction func restore(_ sender: Any) {
        guard let post = post else {
            return
        }

        delegate?.restore(post)
    }

    func setInteractionDelegate(_ delegate: InteractivePostViewDelegate) {
        self.delegate = delegate
    }

    private enum Constants {
        static let defaultMargin: CGFloat = 16
        static let compactMargin: CGFloat = 0
        static let imageSize: CGFloat = 18.0
    }
}
