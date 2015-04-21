import Foundation

// Makes a UIImageView circular. Handy for gravatars
class CircularImageView : UIImageView
{
    var shouldRoundCorners : Bool = true {
        didSet {
            let rect = frame;
            frame = rect;
        }
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        layer.masksToBounds = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.masksToBounds = true
    }

    override init(image: UIImage!) {
        super.init(image: image)
        
        layer.masksToBounds = true
    }
    
    convenience init() {
        self.init(frame: CGRectZero)
    }

    override var frame: CGRect {
        didSet {
            if (shouldRoundCorners) {
                layer.cornerRadius = (frame.width * 0.5)
            } else {
                layer.cornerRadius = 0;
            }
        }
    }
}
