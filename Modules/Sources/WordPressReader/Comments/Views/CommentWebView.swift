import UIKit

/// -warning: It's not designed to be used publically yet.
@MainActor
final class CommentWebView: UIView, CommentContentRendererDelegate {
    let renderer = WebCommentContentRenderer()
    lazy var heightConstraint = renderer.view.heightAnchor.constraint(equalToConstant: 20)

    init(comment: String) {
        super.init(frame: .zero)

        addSubview(renderer.view)
        renderer.view.pinEdges()

        heightConstraint.isActive = true

        renderer.delegate = self
        renderer.render(comment: comment)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: CommentContentRendererDelegate

    func renderer(_ renderer: any CommentContentRenderer, interactedWithURL url: URL) {
        print("interact:", url)
    }

    func renderer(_ renderer: any CommentContentRenderer, asyncRenderCompletedWithHeight height: CGFloat, comment: String) {
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

@available(iOS 17, *)
#Preview("Media") {
    makeView(comment: """
    <p>Test image in the middle.</p>\n<figure class=\"wp-block-image size-medium\"><img src=\"https://fastly.picsum.photos/id/31/3264/4912.jpg?hmac=lfmmWE3h_aXmRwDDZ7pZb6p0Foq6u86k_PpaFMnq0r8\" alt=\"\" /></figure>\n<p>Text below.</p>\n
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
