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
        // Do nothing
    }

    func renderer(_ renderer: any CommentContentRenderer, asyncRenderCompletedWithHeight height: CGFloat) {
        heightConstraint.constant = height
    }
}

@available(iOS 17, *)
#Preview("Plain Text, Single Line") {
    makeView(comment: "<p>Thank you so much! You should see it now &#8211; people are losing their minds!</p>\n")
}

@MainActor
private func makeView(comment: String) -> UIView {
    let webView = CommentWebView(comment: comment)
    webView.layer.borderColor = UIColor.opaqueSeparator.cgColor
    webView.layer.borderWidth = 0.5

    let container = UIView()
    container.addSubview(webView)
    webView.pinEdges(insets: UIEdgeInsets(.all, 16))
    return container
}
