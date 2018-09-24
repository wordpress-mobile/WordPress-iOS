import UIKit

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
        switch(gesture.state){
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
