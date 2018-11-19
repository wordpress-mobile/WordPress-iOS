class RevisionDiffViewController: UIViewController {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var contentLabel: UILabel!

    var revision: Revision? {
        didSet {
            showRevision()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.font = WPFontManager.notoBoldFont(ofSize: 24.0)
        contentLabel.font = WPFontManager.notoRegularFont(ofSize: 16)
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
