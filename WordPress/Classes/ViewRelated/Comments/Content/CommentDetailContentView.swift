import UIKit

final class CommentDetailContentView: UIView {

    // MARK: - Properties

    private var state: State = .loading {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    private var renderer: CommentContentRenderer?
    private var contentView: UIView?
    private var configuration: Configuration?

    override var intrinsicContentSize: CGSize {
        return .init(width: UIView.noIntrinsicMetric, height: state.height)
    }

    func configure(with config: Configuration) {
        // Update configuration
        self.configuration = config

        // skip creating the renderer if the content does not change.
        // this prevents the cell to jump multiple times due to consecutive reloadData calls.
        if let renderer = renderer, renderer.matchesContent(from: config.comment) {
            return
        }

        // clean out any pre-existing renderer just to be sure.
        self.resetRenderedContents()

        // Creeate renderer
        var renderer: CommentContentRenderer = WebCommentContentRenderer(comment: config.comment, displaySetting: .standard)
        renderer.delegate = self
        self.renderer = renderer

        // Render comment
        let contentView = renderer.render()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(contentView)
        self.pinSubviewToAllEdges(contentView)
        self.contentView = contentView
    }

    private func resetRenderedContents() {
        self.state = .loading
        self.renderer = nil
        self.contentView?.removeFromSuperview()
    }

    struct Configuration {
        let comment: Comment
        let onContentLoaded: ((CGFloat) -> Void)?
        let onContentLinkTapped: ((URL) -> Void)?
    }

    enum State {
        case loading
        case rendered(CGFloat)

        var height: CGFloat {
            switch self {
            case .loading: return .leastNormalMagnitude
            case .rendered(let height): return height
            }
        }
    }
}

extension CommentDetailContentView: CommentContentRendererDelegate {

    func renderer(_ renderer: CommentContentRenderer, asyncRenderCompletedWithHeight height: CGFloat) {
        self.state = .rendered(height)
        self.configuration?.onContentLoaded?(height)
    }

    func renderer(_ renderer: CommentContentRenderer, interactedWithURL url: URL) {
        self.configuration?.onContentLinkTapped?(url)
    }
}
