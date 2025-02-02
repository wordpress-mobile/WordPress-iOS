import UIKit

/// -warning: It's not designed to be used publically yet.
@MainActor
final class CommentWebView: UIView, CommentContentRendererDelegate {
    let renderer = WebCommentContentRenderer()
    let webView: UIView
    lazy var heightConstraint = webView.heightAnchor.constraint(equalToConstant: 20)

    init(comment: String) {
        let webView = renderer.render(comment: comment)
        self.webView = webView

        super.init(frame: .zero)

        renderer.delegate = self

        addSubview(webView)
        webView.pinEdges()

        heightConstraint.isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: CommentContentRendererDelegate

    func renderer(_ renderer: any CommentContentRenderer, interactedWithURL url: URL) {
        print("interact:", url)
    }

    func renderer(_ renderer: any CommentContentRenderer, asyncRenderCompletedWithHeight height: CGFloat) {
        heightConstraint.constant = height
    }
}

@available(iOS 17, *)
#Preview("Plain Text") {
    makeView(comment: "<p>Thank you so much! You should see it now &#8211; people are losing their minds!</p>\n")
}

@available(iOS 17, *)
#Preview("Gutenberg") {
    makeView(comment: """
    <p>Thank you for putting this together, I’m in support of all proposed improvements, we know that the current experience is less-than-ideal. </p><blockquote class=\"wp-block-quote is-layout-flow wp-block-quote-is-layout-flow\"><p><strong>Get rid of This.</strong> We’re moving everything to That anyway, and this is our last remaining This instance in Jetpack. It’s not performing great, so let’s remove it.</p></blockquote><p><a href=\"https://tset.wordpress.com/mentions/test/\" class=\"__p2-hovercard mention\" data-type=\"fragment-mention\" data-username=\"tester\"><span class=\"mentions-prefix\">@</span>tester</a>‘s most recent review found <a href=\"https:://wordpress.com/" rel=\"nofollow ugc\">it failed to provide a valid response in more than half of interactions</a>.</p>
    """)
}

@MainActor
private func makeView(comment: String) -> UIView {
    let webView = CommentWebView(comment: comment)
    webView.layer.borderColor = UIColor.opaqueSeparator.withAlphaComponent(0.66).cgColor
    webView.layer.borderWidth = 0.5

    let container = UIView()
    container.addSubview(webView)
    webView.pinEdges(insets: UIEdgeInsets(.all, 16))

    return container
}
