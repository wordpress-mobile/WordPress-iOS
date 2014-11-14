import Foundation

// Makes a UIImageView circular. Handy for gravatars
class CircularImageView : UIImageView
{
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.layer.masksToBounds = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.layer.masksToBounds = true
    }

    override init() {
        super.init()

        self.layer.masksToBounds = true
    }

    override var frame: CGRect {
        didSet {
            self.layer.cornerRadius = self.frame.size.width / 2
        }
    }
}
