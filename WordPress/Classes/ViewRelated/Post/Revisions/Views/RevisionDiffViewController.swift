import WebKit
import Aztec

class RevisionDiffViewController: UIViewController {
    @IBOutlet var webView: WKWebView?
    var revision: Revision? {
        didSet {
            showRevision()
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

        let aztext = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 15.0), defaultMissingImage: UIImage())
        aztext.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(aztext)
        view.pinSubviewToAllEdges(aztext)

        let html = revision.postContent ?? ""
        aztext.insertText(html)
     }
}
