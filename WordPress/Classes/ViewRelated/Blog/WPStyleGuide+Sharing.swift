import Foundation
import WordPressShared

/// A WPStyleGuide extension with styles and methods specific to the
/// Sharing feature.
///
extension WPStyleGuide
{

    public class func sharingCellWarningAccessoryImageView() -> UIImageView {

        let imageSize = 22.0
        let imageView = UIImageView(frame:CGRect(x: 0, y: 0, width: imageSize, height: imageSize))

        let noticeImage = UIImage(named: "gridicons-notice")
        imageView.image = noticeImage?.imageWithRenderingMode(.AlwaysTemplate)
        imageView.tintColor = jazzyOrange()
        
        return imageView
    }

}
