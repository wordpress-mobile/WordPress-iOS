// View Controller for the Revision HML preview
//
class RevisionDiffViewController: UIViewController, StoryboardLoadable {
    static var defaultStoryboardName: String = "Revisions"

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var contentLabel: UILabel!
    @IBOutlet private var scrollView: UIScrollView!

    var revision: Revision?


    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showRevision()
    }
}

private extension RevisionDiffViewController {
    private func setupUI() {
        view.backgroundColor = .basicBackground
        scrollView.backgroundColor = .basicBackground

        titleLabel.font = WPFontManager.notoBoldFont(ofSize: 24.0)
        contentLabel.font = WPFontManager.notoRegularFont(ofSize: 16)
        titleLabel.textColor = .text
        contentLabel.textColor = .text
    }

    private func showRevision() {
        guard let revision = revision else {
            return
        }

        titleLabel.attributedText = revision.diff?.titleToAttributedString
        contentLabel.attributedText = revision.diff?.contentToAttributedString
    }
}
