import Foundation

// A UIView used to defined a spacer to be used in a UIStackView when custom spacing 
// is desired and the stack view's uniform spacing won't do the trick. 
// Defining the spacing via intrinsicContentSize plays nice with the UIStackView's 
// behavior of applying a 0 height constraint to hidden views. 
class ReaderSpacerView : UIView
{

    // Defined with var instead of let in order to set via User Defined Runtime Attributes in IB if needed.
    var space: Int = 8 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: space, height: space)
    }

}
