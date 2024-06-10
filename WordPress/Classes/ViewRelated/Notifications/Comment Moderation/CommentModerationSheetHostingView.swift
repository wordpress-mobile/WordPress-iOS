import UIKit
import SwiftUI

final class CommentModerationSheetHostingView: UIView {

    private let viewModel: CommentModerationViewModel

    private var hostingController: UIHostingController<Content>?

    init(viewModel: CommentModerationViewModel,
         parent: UIViewController,
         sizeChanged: @escaping (CGSize) -> Void) {
        self.viewModel = viewModel
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
        let content = Content(
            viewModel: viewModel,
            sizeChanged: sizeChanged,
            keyboardLayoutGuide: keyboardLayoutGuide
        )
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

    /// There was a bug where the moderation view did not resize correctly when the moderation view state changed,
    /// resulting in an incorrect view height after state transitions.
    ///
    /// To address this bug, the hosting view was laid out to the edges of `viewController.view` to provide enough space
    /// for the moderation view to animate smoothly. However, this setup caused the hosting view to intercept touch events,
    /// preventing them from passing through to underlying views.
    ///
    /// This custom `hitTest` method resolves the touch event handling issue by ensuring that touch events are forwarded to
    /// the appropriate subview or parent view.
    ///
    /// This method has unit tests to verify its functionality.
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
        @ObservedObject var viewModel: CommentModerationViewModel

        let sizeChanged: (CGSize) -> Void
        let keyboardLayoutGuide: UIKeyboardLayoutGuide

        var body: some View {
            CommentModerationKeyboardAvoidingView(layout: $viewModel.layout, keyboardLayoutGuide: keyboardLayoutGuide) {
                VStack(spacing: 0) {
                    Spacer()
                    CommentModerationView(viewModel: viewModel)
                        .readSize(sizeChanged)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
}

fileprivate struct CommentModerationKeyboardAvoidingView<T: View>: View {
    @ViewBuilder let content: () -> T

    @Binding private var layout: Layout

    @StateObject private var keyboardResponder = KeyboardResponder()

    private let keyboardLayoutGuide: UIKeyboardLayoutGuide

    init(
        layout: Binding<Layout>,
        keyboardLayoutGuide: UIKeyboardLayoutGuide,
        @ViewBuilder _ content: @escaping () -> T
    ) {
        self.content = content
        self.keyboardLayoutGuide = keyboardLayoutGuide
        self._layout = layout
    }

    var body: some View {
        GeometryReader { proxy in
            content()
                .transaction { t in
                    if t.animation != nil, keyboardResponder.isAnimating {
                        t.animation = keyboardResponder.animation
                    }
                }
                .onReceive(keyboardPublisher) { note in
                    self.keyboardResponder.notification = note

                    guard keyboardResponder.isAnimating else {
                        return
                    }

                    let layoutGuide = self.keyboardLayoutGuide

                    let frame: CGRect = {
                        var frame = proxy.frame(in: .local)
                        frame.size.height += proxy.safeAreaInsets.bottom
                        return frame
                    }()

                    let layout: Layout = {
                        let intersection = frame.intersection(layoutGuide.layoutFrame)
                        return intersection.height >= 100 ? .inputFocused : .normal
                    }()

                    if self.layout != layout {
                        withAnimation(keyboardResponder.animation) {
                            self.layout = layout
                        }
                    }
                }
        }
        .environmentObject(keyboardResponder)
    }

    typealias Layout = CommentModerationViewModel.Layout
}
