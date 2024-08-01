import UIKit

extension UIScrollView {
    @objc func scrollToTop(animated: Bool) {
        let topOffset = CGPoint(x: 0, y: -adjustedContentInset.top)
        setContentOffset(topOffset, animated: animated)
        layoutIfNeeded()
    }

    @objc func scrollToBottom(animated: Bool) {
        let bottomOffset = CGPoint(x: 0, y: contentSize.height - bounds.size.height + adjustedContentInset.bottom)
        if bottomOffset.y > 0 {
            setContentOffset(bottomOffset, animated: animated)
            layoutIfNeeded()
        }
    }
}
