import Aztec
import WordPressEditor


class RevisionPreviewViewController: UIViewController, StoryboardLoadable {
    static var defaultStoryboardName: String = "Revisions"

    var revision: Revision? {
        didSet {
            showRevision()
        }
    }

    private let textViewManager = RevisionPreviewTextViewManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupAztec()
    }
}


private extension RevisionPreviewViewController {
    private func setupAztec() {
        let aztext = Aztec.TextView(defaultFont: WPFontManager.notoRegularFont(ofSize: 16),
                                    defaultMissingImage: UIImage())
        aztext.translatesAutoresizingMaskIntoConstraints = false
        aztext.isEditable = false
        view.addSubview(aztext)
        view.pinSubviewToAllEdges(aztext)
        aztext.load(WordPressPlugin())
        aztext.textAttachmentDelegate = textViewManager

        let providers: [TextViewAttachmentImageProvider] = [
            SpecialTagAttachmentRenderer(),
            CommentAttachmentRenderer(font: AztecPostViewController.Fonts.regular),
            HTMLAttachmentRenderer(font: AztecPostViewController.Fonts.regular),
            GutenpackAttachmentRenderer()
        ]

        providers.forEach {
            aztext.registerAttachmentImageProvider($0)
        }
    }

    private func showRevision() {
        guard let revision = revision else {
            return
        }

        let title = revision.postTitle ?? NSLocalizedString("Untitled", comment: "Label for an untitled post in the revision browser")
        let titleHTML = "<h1>\(title)</h1>"

        let html = revision.postContent ?? ""
        aztext.setHTML(titleHTML + "\n" + html)
    }
}
