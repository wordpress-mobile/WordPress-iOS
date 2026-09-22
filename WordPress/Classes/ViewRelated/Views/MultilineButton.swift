import UIKit

/// A `UIButton` with a multiline title label doesn't update it's height based on the number of lines.
///
/// The `MultilineButton` custom button calculates it's intrinsic content height based on the title label's height.
///
class MultilineButton: UIButton {

    /// Vertical padding kept around a title that wraps. It mirrors the vertical
    /// content insets set in Interface Builder, which `UIButton` only exposes
    /// through a deprecated property.
    var verticalTitlePadding: CGFloat = 0

    override var intrinsicContentSize: CGSize {

        guard let labelSize = titleLabel?.sizeThatFits(CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude)),
              labelSize.height > frame.size.height else {
            return super.intrinsicContentSize
        }

        let desiredHeight = labelSize.height + verticalTitlePadding

        return CGSize(width: frame.size.width, height: desiredHeight)
    }
}
