import WebKit
import Aztec

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
        view.addSubview(aztext)
        view.pinSubviewToAllEdges(aztext)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        showRevision()
    }

    private func showRevision() {
        guard let revision = revision else {
            return
        }

        let html = revision.postContent ?? ""
        aztext.setHTML("")
        aztext.insertText(html)
     }
}
