import SwiftUI
import UIKit

/// Hosts the injected comment content renderer as a fixed subview filling the
/// region. The renderer scrolls internally and insets its own content (its
/// contract), so this is the only scroll surface for the comment body and it
/// applies no padding of its own. `render(html:)` runs on the first update and
/// whenever the HTML changes.
struct CommentContentRegion: UIViewRepresentable {
    let renderer: any CommentContentRendering
    let html: String

    func makeUIView(context: Context) -> UIView {
        IntegralFrameContainer(content: renderer.view)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard context.coordinator.lastRenderedHTML != html else { return }
        context.coordinator.lastRenderedHTML = html
        renderer.render(html: html)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var lastRenderedHTML: String?
    }
}

/// Gives its content a whole-point frame. SwiftUI hands the region whatever
/// height the header leaves, usually fractional; WebKit lays a document out
/// at a whole-point viewport rounded up, so a comment that fits would still
/// overflow by under a point and scroll by that much. Flooring leaves at most
/// a point uncovered at the trailing edges, which the clear background hides.
private final class IntegralFrameContainer: UIView {
    private let content: UIView

    init(content: UIView) {
        self.content = content
        super.init(frame: .zero)
        // The frame set below is the content's layout; no constraints apply.
        content.translatesAutoresizingMaskIntoConstraints = true
        addSubview(content)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        content.frame = CGRect(x: 0, y: 0, width: bounds.width.rounded(.down), height: bounds.height.rounded(.down))
    }
}
