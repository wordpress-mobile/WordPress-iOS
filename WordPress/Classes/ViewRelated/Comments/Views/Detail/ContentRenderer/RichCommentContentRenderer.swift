import UIKit
import AsyncImageKit
import WordPressReader

/// Renders the comment body through `WPRichContentView`.
///
class RichCommentContentRenderer: NSObject, CommentContentRenderer {
    weak var delegate: CommentContentRendererDelegate?

    var view: UIView { textView }

    weak var richContentDelegate: WPRichContentViewDelegate? = nil
    var attributedText: NSAttributedString?
    var comment: Comment?

    lazy var textView = newRichContentView()

    required override init() {}

    func render(comment: String) {
        textView.attributedText = attributedText
        textView.delegate = self
    }

    func prepareForReuse() {
        // Do nothing
    }
}

// MARK: - WPRichContentViewDelegate

extension RichCommentContentRenderer: WPRichContentViewDelegate {
    func richContentView(_ richContentView: WPRichContentView, didReceiveImageAction image: WPRichTextImage) {
        richContentDelegate?.richContentView(richContentView, didReceiveImageAction: image)
    }

    func interactWith(URL: URL) {
        delegate?.renderer(self, interactedWithURL: URL)
    }

    func richContentViewShouldUpdateLayoutForAttachments(_ richContentView: WPRichContentView) -> Bool {
        richContentDelegate?.richContentViewShouldUpdateLayoutForAttachments?(richContentView) ?? false
    }

    func richContentViewDidUpdateLayoutForAttachments(_ richContentView: WPRichContentView) {
        richContentDelegate?.richContentViewDidUpdateLayoutForAttachments?(richContentView)
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        richContentDelegate?.textViewDidChangeSelection?(textView)
    }
}

// MARK: - Private Helpers

private extension RichCommentContentRenderer {
    struct Constants {
        // Because a stackview is managing layout we tweak text insets to fine tune things.
        static let textViewInsets = UIEdgeInsets(top: -8, left: -4, bottom: -24, right: 0)
    }

    func newRichContentView() -> WPRichContentView {
        let newTextView = WPRichContentView(frame: .zero, textContainer: nil)
        newTextView.translatesAutoresizingMaskIntoConstraints = false
        newTextView.isScrollEnabled = false
        newTextView.isEditable = false
        newTextView.backgroundColor = .clear
        newTextView.mediaHost = mediaHost
        newTextView.textContainerInset = Constants.textViewInsets

        return newTextView
    }

    var mediaHost: MediaHost {
        guard let comment else {
            return .publicSite
        }
        if let blog = comment.blog {
            return MediaHost(blog)
        } else if let post = comment.post as? ReaderPost, post.isBlogPrivate {
            return MediaHost(post)
        }

        return .publicSite
    }
}
