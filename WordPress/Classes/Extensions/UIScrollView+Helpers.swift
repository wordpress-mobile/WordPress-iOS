import UIKit

extension UIScrollView {

    // MARK: - Vertical scrollview

    // Scroll to a specific view in a vertical scrollview so that it's top is at the top our scrollview
    @objc func scrollToView(_ view: UIView, animated: Bool) {
        if let origin = view.superview {

            // Get the Y position of your child view
            let childStartPoint = origin.convert(view.frame.origin, to: self)

            // Scroll to a rectangle starting at the Y of your subview, with a height of the scrollview safe area
            // if the bottom of the rectangle is within the content size height.
            //
            // Otherwise, scroll all the way to the bottom.
            //
            if childStartPoint.y + safeAreaLayoutGuide.layoutFrame.height < contentSize.height {
                let targetRect = CGRect(x: 0,
                                        y: childStartPoint.y - Constants.yOffset,
                                        width: Constants.targetRectWidth,
                                        height: safeAreaLayoutGuide.layoutFrame.height)
                scrollRectToVisible(targetRect, animated: animated)
            } else {
                scrollToBottom(animated: true)
            }

            // This ensures scrolling to the correct position, especially when there are layout changes
            //
            // See: https://stackoverflow.com/a/35437399
            //
            layoutIfNeeded()
        }
    }

    @objc func scrollToTop(animated: Bool) {
        let topOffset = CGPoint(x: 0, y: -adjustedContentInset.top)
        setContentOffset(topOffset, animated: animated)
    }

    @objc func scrollToBottom(animated: Bool) {
        let bottomOffset = CGPoint(x: 0, y: contentSize.height - bounds.size.height + adjustedContentInset.bottom)
        if bottomOffset.y > 0 {
            setContentOffset(bottomOffset, animated: animated)
        }
    }

    // MARK: - Horizontal scrollview

    func scrollToEnd(animated: Bool) {
        let endOffset = CGPoint(x: contentSize.width - bounds.size.width, y: 0)
        if endOffset.x > 0 {
            setContentOffset(endOffset, animated: animated)
        }
    }

    private enum Constants {
        /// An arbitrary placeholder value for the target rect -- must be some value larger than 0
        static let targetRectWidth: CGFloat = 1

        /// Vertical padding for the target rect
        static let yOffset: CGFloat = 24
    }
}
