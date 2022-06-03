import UIKit

extension UIScrollView {

    // MARK: - Vertical scrollview

    // Scroll to a specific view in a vertical scrollview so that it's top is at the top our scrollview
    @objc func scrollVerticallyToView(_ view: UIView, animated: Bool) {
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
                                        y: childStartPoint.y - Constants.targetRectPadding,
                                        width: Constants.targetRectDimension,
                                        height: safeAreaLayoutGuide.layoutFrame.height)
                scrollRectToVisible(targetRect, animated: animated)

                // This ensures scrolling to the correct position, especially when there are layout changes
                //
                // See: https://stackoverflow.com/a/35437399
                //
                layoutIfNeeded()
            } else {
                scrollToBottom(animated: true)
            }
        }
    }

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

    // MARK: - Horizontal scrollview

    // Scroll to a specific view in a horizontal scrollview so that it's leading edge is at the leading edge of our scrollview
    @objc func scrollHorizontallyToView(_ view: UIView, animated: Bool) {
        if let origin = view.superview {
            let childStartPoint = origin.convert(view.frame.origin, to: self).x
            let childEndPoint = childStartPoint + view.frame.width
            if userInterfaceLayoutDirection() == .leftToRight {
                normalScrollHorizontallyToPoint(childStartPoint, animated: true)
            } else {
                flippedScrollHorizontallyToPoint(childEndPoint, animated: true)
            }
        }
    }

    /// Scroll horizontally to a view with the provided starting point
    /// Used when the layout direction is Left to Right
    /// - Parameters:
    ///   - point: The point to scroll to. Normally the starting point of the view.
    ///   - animated: `true` if the scrolling should be animated, `false` if it should be immediate.
    private func normalScrollHorizontallyToPoint(_ point: CGFloat, animated: Bool) {
        // Scroll to a rectangle starting at the X of your subview, with a width of the scrollview safe area
        // if the end of the rectangle is within the content size width.
        //
        // Otherwise, scroll all the way to the end.
        //
        if point + safeAreaLayoutGuide.layoutFrame.width < contentSize.width {
            let targetRect = CGRect(x: point - Constants.targetRectPadding,
                                    y: 0,
                                    width: safeAreaLayoutGuide.layoutFrame.width,
                                    height: Constants.targetRectDimension)
            scrollRectToVisible(targetRect, animated: animated)

            // This ensures scrolling to the correct position, especially when there are layout changes
            //
            // See: https://stackoverflow.com/a/35437399
            //
            layoutIfNeeded()
        } else {
            scrollToEnd(animated: true)
        }
    }

    /// Scroll horizontally to a view with the provided end point
    /// Used when the layout direction is Right to Left
    /// - Parameters:
    ///   - point: The point to scroll to. Normally the ending point of the view.
    ///   - animated: `true` if the scrolling should be animated, `false` if it should be immediate.
    private func flippedScrollHorizontallyToPoint(_ point: CGFloat, animated: Bool) {
        // Scroll to a rectangle ending at the X of your subview, with a width of the scrollview safe area
        // if the start of the rectangle is within the content size width.
        //
        // Otherwise, scroll all the way to the start.
        //
        if point - safeAreaLayoutGuide.layoutFrame.width > 0 {
            let targetRect = CGRect(x: point - safeAreaLayoutGuide.layoutFrame.width,
                                    y: 0,
                                    width: safeAreaLayoutGuide.layoutFrame.width,
                                    height: Constants.targetRectDimension)
            scrollRectToVisible(targetRect, animated: animated)

            // This ensures scrolling to the correct position, especially when there are layout changes
            //
            // See: https://stackoverflow.com/a/35437399
            //
            layoutIfNeeded()
        } else {
            scrollToStart(animated: true)
        }
    }

    func scrollToEnd(animated: Bool) {
        let endOffset = CGPoint(x: contentSize.width - bounds.size.width, y: 0)
        if endOffset.x > 0 {
            setContentOffset(endOffset, animated: animated)
            layoutIfNeeded()
        }
    }

    func scrollToStart(animated: Bool) {
        let startOffset = CGPoint(x: 0, y: 0)
        setContentOffset(startOffset, animated: animated)
        layoutIfNeeded()
    }

    private enum Constants {
        /// An arbitrary placeholder value for the target rect -- must be some value larger than 0
        static let targetRectDimension: CGFloat = 1

        /// Padding for the target rect
        static let targetRectPadding: CGFloat = 20
    }
}
