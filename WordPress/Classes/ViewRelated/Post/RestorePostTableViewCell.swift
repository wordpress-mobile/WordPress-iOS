import UIKit

class RestorePostTableViewCell: UITableViewCell, ConfigurablePostView, InteractivePostView {
    @IBOutlet var postContentView: UIView!
    @IBOutlet var restoreLabel: UILabel!
    @IBOutlet var restoreButton: UIButton!

    private weak var delegate: InteractivePostViewDelegate?

    var post: Post!

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
    }

    private func applyStyles() {
        WPStyleGuide.applyPostCardStyle(self)
        WPStyleGuide.applyRestorePostLabelStyle(restoreLabel)
        WPStyleGuide.applyRestorePostButtonStyle(restoreButton)

        postContentView.layer.borderColor = WPStyleGuide.postCardBorderColor().cgColor
        postContentView.layer.borderWidth = 1.0 / UIScreen.main.scale
    }

    @IBAction func restore(_ sender: Any) {
        delegate?.restore(post)
    }

    func setInteractionDelegate(_ delegate: InteractivePostViewDelegate) {
        self.delegate = delegate
    }
}
