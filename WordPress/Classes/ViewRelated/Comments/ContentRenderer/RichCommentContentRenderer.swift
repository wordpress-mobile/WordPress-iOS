/// Renders the comment body through `WPRichContentView`.
///
class RichCommentContentRenderer: NSObject, CommentContentRenderer {
    weak var delegate: CommentContentRendererDelegate?

    weak var richContentDelegate: WPRichContentViewDelegate? = nil

    private let comment: Comment

    required init(comment: Comment) {
        self.comment = comment
    }

    func render() -> UIView {
        let textView = newRichContentView()
        textView.attributedText = WPRichContentView.formattedAttributedStringForString(comment.content)
        textView.delegate = self

        return textView
    }

    func matchesContent(from comment: Comment) -> Bool {
        return self.comment.content == comment.content
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
        if let blog = comment.blog {
            return MediaHost(with: blog, failure: { error in
                // We'll log the error, so we know it's there, but we won't halt execution.
                WordPressAppDelegate.crashLogging?.logError(error)
            })
        } else if let post = comment.post as? ReaderPost, post.isPrivate() {
            return MediaHost(with: post, failure: { error in
                // We'll log the error, so we know it's there, but we won't halt execution.
                WordPressAppDelegate.crashLogging?.logError(error)
            })
        }

        return .publicSite
    }
}
