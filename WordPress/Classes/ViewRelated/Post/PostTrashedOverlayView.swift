import UIKit

final class TrashedPostOverlayView: UIView {
    var onOverlayTapped: ((TrashedPostOverlayView) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        onOverlayTapped?(self)
    }
}
