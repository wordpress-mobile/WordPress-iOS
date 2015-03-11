import Foundation

// Makes a UIImageView circular. Handy for gravatars
class CircularImageView : UIImageView
{
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        layer.masksToBounds = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.masksToBounds = true
    }

    override init() {
        super.init()

        layer.masksToBounds = true
    }

    override var frame: CGRect {
        didSet {
            layer.cornerRadius = (frame.width * 0.5)
        }
    }
}
