import UIKit
import SwiftUI

final class CommentModerationSheetHostingView: UIView {

    private var hostingController: UIHostingController<Content>?
    private var intrinsicContentSizeChangeObservation: NSKeyValueObservation?

    init(viewModel: CommentModerationViewModel,
         parent: UIViewController,
         sizeChanged: @escaping (CGSize) -> Void) {
        super.init(frame: .zero)
        self.setup(
            with: viewModel,
            sizeChanged: sizeChanged,
            parent: parent
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(
        with viewModel: CommentModerationViewModel,
        sizeChanged: @escaping (CGSize) -> Void,
        parent: UIViewController
    ) {
        self.backgroundColor = .clear
        let content = Content(viewModel: viewModel, sizeChanged: sizeChanged)
        let controller = UIHostingController(rootView: content)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.backgroundColor = .clear
        controller.willMove(toParent: parent)
        self.addSubview(controller.view)
        self.pinSubviewToAllEdges(controller.view)
        parent.addChild(controller)
        controller.didMove(toParent: parent)
        self.hostingController = controller
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event),
              let hostingView = self.hostingController?.view,
              let parent = superview,
              hitView === hostingView
        else {
            return super.hitTest(point, with: event)
        }

        // Iterate through the parent's subviews to find the view that should respond to the touch event
        for subview in parent.subviews where subview !== self {
            let point = convert(point, to: subview)
            if let respondingView = subview.hitTest(point, with: event) {
                return respondingView
            }
        }

        // If no subviews are hit, return the parent view
        return parent
    }

    private struct Content: View {
        let viewModel: CommentModerationViewModel
        let sizeChanged: (CGSize) -> Void

        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                CommentModerationView(viewModel: viewModel)
                    .readSize(sizeChanged)
            }
        }
    }
}
