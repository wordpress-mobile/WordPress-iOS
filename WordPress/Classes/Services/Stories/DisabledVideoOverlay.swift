import UIKit

/// An overlay for videos that exceed allowed duration
class DisabledVideoOverlay: UIView {

    static let overlayTransparency: CGFloat = 0.8

    init() {
        super.init(frame: .zero)
        backgroundColor = .gray.withAlphaComponent(Self.overlayTransparency)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
