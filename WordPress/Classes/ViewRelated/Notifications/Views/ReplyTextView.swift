import Foundation


@objc public class ReplyTextView : UIView
{
    public func dismiss() {
        endEditing(true)
        textField.resignFirstResponder()
    }
    
    public var isVisible: Bool = true {
        didSet {
            let height: CGFloat = isVisible ? textViewHeight : CGFloat.min
            
            for constraint in constraints() as [NSLayoutConstraint] {
                if constraint.firstAttribute == NSLayoutAttribute.Height {
                    constraint.constant = height
                }
            }
        }
    }
    
    // MARK: - Constants
    private let textViewHeight: CGFloat = 44
    
    // MARK: - IBOutlets
    @IBOutlet private var textField: UITextField!
}
