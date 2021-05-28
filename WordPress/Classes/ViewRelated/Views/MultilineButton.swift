import UIKit

/// A `UIButton` with a multiline title label doesn't update it's height based on the number of lines.
///
/// The `MultilineButton` custom button calculates it's intrinsic content height based on the title label's height.
///
class MultilineButton: UIButton {

    override var intrinsicContentSize: CGSize {

        guard let labelSize = titleLabel?.sizeThatFits(CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude)),
              labelSize.height > frame.size.height else {
            return super.intrinsicContentSize
        }

        let desiredHeight = labelSize.height + contentEdgeInsets.top + contentEdgeInsets.bottom

        return CGSize(width: frame.size.width, height: desiredHeight)
    }
}
