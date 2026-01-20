import SwiftUI

/// A UIKit-based gesture overlay that handles tap, long-press, and horizontal pan gestures.
///
/// UIKit is used instead of SwiftUI gestures because:
/// - `UILongPressGestureRecognizer` properly fires after the minimum duration even without movement,
///   while SwiftUI's `DragGesture` requires actual dragging to trigger.
/// - `gestureRecognizerShouldBegin` allows immediate rejection of vertical pans based on velocity,
///   preventing interference with vertical scrolling.
struct ChartGestureOverlay: UIViewRepresentable {
    let onTap: (CGPoint) -> Void
    let onInteractionUpdate: (CGPoint) -> Void
    let onInteractionEnd: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))

        longPressGesture.minimumPressDuration = 0.33
        panGesture.delegate = context.coordinator

        view.addGestureRecognizer(tapGesture)
        view.addGestureRecognizer(longPressGesture)
        view.addGestureRecognizer(panGesture)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.onInteractionUpdate = onInteractionUpdate
        context.coordinator.onInteractionEnd = onInteractionEnd
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onTap: onTap,
            onInteractionUpdate: onInteractionUpdate,
            onInteractionEnd: onInteractionEnd
        )
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onTap: (CGPoint) -> Void
        var onInteractionUpdate: (CGPoint) -> Void
        var onInteractionEnd: () -> Void

        private var isInteracting = false

        init(
            onTap: @escaping (CGPoint) -> Void,
            onInteractionUpdate: @escaping (CGPoint) -> Void,
            onInteractionEnd: @escaping () -> Void
        ) {
            self.onTap = onTap
            self.onInteractionUpdate = onInteractionUpdate
            self.onInteractionEnd = onInteractionEnd
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard !isInteracting else { return }
            let location = gesture.location(in: gesture.view)
            onTap(location)
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            let location = gesture.location(in: gesture.view)

            switch gesture.state {
            case .began, .changed:
                isInteracting = true
                onInteractionUpdate(location)
            case .ended, .cancelled:
                isInteracting = false
                onInteractionEnd()
            default:
                break
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let location = gesture.location(in: gesture.view)

            switch gesture.state {
            case .began, .changed:
                isInteracting = true
                onInteractionUpdate(location)
            case .ended, .cancelled:
                isInteracting = false
                onInteractionEnd()
            default:
                break
            }
        }

        // UIGestureRecognizerDelegate - Allow pan to fail on vertical scrolls
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
                return true
            }

            let velocity = panGesture.velocity(in: gestureRecognizer.view)
            let isHorizontal = abs(velocity.x) > abs(velocity.y)
            return isHorizontal
        }

        // Allow all gestures to be recognized simultaneously
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return false
        }
    }
}
