import WebKit
import Aztec
import WordPressEditor

class RevisionDiffViewController: UIViewController {
    @IBOutlet private var webView: WKWebView?
    private let aztext = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 15.0), defaultMissingImage: UIImage())
    var revision: Revision? {
        didSet {
            showRevision()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        aztext.translatesAutoresizingMaskIntoConstraints = false
        aztext.isEditable = false
        view.addSubview(aztext)
        view.pinSubviewToAllEdges(aztext)
        aztext.load(WordPressPlugin())

        registerAttachmentImageProviders()
    }

    func registerAttachmentImageProviders() {
        let providers: [TextViewAttachmentImageProvider] = [
            SpecialTagAttachmentRenderer(),
            CommentAttachmentRenderer(font: AztecPostViewController.Fonts.regular),
            HTMLAttachmentRenderer(font: AztecPostViewController.Fonts.regular),
            GutenpackAttachmentRenderer()
        ]

        for provider in providers {
            aztext.registerAttachmentImageProvider(provider)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        showRevision()
    }

    private func showRevision() {
        guard let revision = revision else {
            return
        }

        let title = revision.postTitle ?? NSLocalizedString("Untitled", comment: "Label for an untitled post in the revision browser")
        let titleHTML = "<h3>\(title)</h3>"

        let html = revision.postContent ?? ""
        aztext.setHTML(titleHTML + html)
     }
}
