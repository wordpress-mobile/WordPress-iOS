import UIKit

/// Subclass of UILabel that includes a long press gesture recognizer.
/// The action attached to the recognizer will be set by the creator of the label.

class LongPressGestureLabel: UILabel {
    var longPressAction: (() -> Void)? {
        didSet {
            self.addGestureRecognizer(self.gesture)
        }
    }
    private lazy var gesture: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(_:)))
    }()

    @objc private func longPressAction(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            longPressAction?()
        default:
            break
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
