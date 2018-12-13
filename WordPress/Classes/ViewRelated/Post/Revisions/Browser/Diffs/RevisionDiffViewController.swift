class RevisionDiffViewController: UIViewController, StoryboardLoadable {
    static var defaultStoryboardName: String = "Revisions"

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var contentLabel: UILabel!

    var revision: Revision?


    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.font = WPFontManager.notoBoldFont(ofSize: 24.0)
        contentLabel.font = WPFontManager.notoRegularFont(ofSize: 16)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showRevision()
    }
}


private extension RevisionDiffViewController {
    private func showRevision() {
        guard let revision = revision else {
            return
        }

        titleLabel.attributedText = revision.diff?.titleToAttributedString
        contentLabel.attributedText = revision.diff?.contentToAttributedString
    }
}
