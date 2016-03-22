import UIKit

class AutoResizingLabel: UILabel {
    override func intrinsicContentSize() -> CGSize {
        var size = super.intrinsicContentSize()
        
        // This, unfortunately, fixes an issue seen in the plans feature list's self-sizing cells
        // where only the first line of text would display on the iPhone 6(s) Plus.
        if numberOfLines == 0 {
            size.height += 1
        }
        
        return size
    }
}
