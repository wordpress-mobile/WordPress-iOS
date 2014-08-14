import Foundation


@objc public class NoteBlockTableViewCell : WPTableViewCell
{
    private let PaddingY: CGFloat = 1;
    
    public func layoutHeightWithWidth(width: CGFloat) -> CGFloat {
        // Layout: Setup the cell with the given width
        bounds = CGRect(x: 0, y: 0, width: width, height: CGRectGetHeight(self.bounds))
        layoutIfNeeded()

        // iPad: Limit the width
        let cappedWidth = min(WPTableViewFixedWidth, width)
        let maximumSize = CGSize(width: cappedWidth, height: 0)
        let layoutSize  = contentView.systemLayoutSizeFittingSize(maximumSize)
        
        return ceil(layoutSize.height) + PaddingY;
    }
    
    public class func reuseIdentifier() -> String! {
        let name = NSStringFromClass(self)

        if let nameWithoutNamespaces = name.componentsSeparatedByString(".").last {
            return nameWithoutNamespaces
        } else {
            return name
        }
    }
}
