import SwiftUI
import UIKit
import WordPressUI

/// Hosts the injected comment content renderer as a fixed, edge-pinned
/// subview. The renderer scrolls internally (its contract), so this is the
/// only scroll surface for the comment body. `render(html:)` runs on the first
/// update and whenever the HTML changes.
struct CommentContentRegion: UIViewRepresentable {
    let renderer: any CommentContentRendering
    let html: String

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.addSubview(renderer.view)
        renderer.view.pinEdges()
        return container
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
