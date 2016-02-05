import UIKit
import MRProgress

@IBDesignable
class PurchaseButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 3.0 {
        didSet {
            updateAppearance()
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 1.0 {
        didSet {
            updateAppearance()
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        
        updateAppearance()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setTitleColor(UIColor.whiteColor(), forState: [.Highlighted])
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        let verticalInset: CGFloat = 10.0
        let horizontalInset: CGFloat = 19.0
        
        contentEdgeInsets = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
        
        layer.masksToBounds = true
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
        layer.borderColor = tintColor.CGColor
        layer.borderColor = tintColor.CGColor
        
        setTitleColor(tintColor, forState: .Normal)
        
        setBackgroundImage(UIImage(color: tintColor), forState: .Highlighted)
    }
}
