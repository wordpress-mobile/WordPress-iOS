import Foundation


extension UITableViewCell
{
    public func layoutHeightWithWidth(width: CGFloat) -> CGFloat {
        // Layout: Setup the cell with the given width
        let cappedWidth = min(WPTableViewFixedWidth, width)
        bounds          = CGRect(x: 0, y: 0, width: cappedWidth, height: self.bounds.height)
        setNeedsLayout()
        layoutIfNeeded()
        
        // iPad: Limit the width
        let layoutSize  = contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        
        // Workaround: Layout calculations fail under certain scenarios by 1px, cutting labels
        let PaddingY: CGFloat = 1
        
        return ceil(layoutSize.height) + PaddingY;
    }
    
    public func isLayoutCell() -> Bool {
        return self.dynamicType.layoutIdentifier() == reuseIdentifier
    }
    
    public class func reuseIdentifier() -> String {
        return classNameWithoutNamespaces()
    }
    
    public class func layoutIdentifier() -> String {
        return classNameWithoutNamespaces() + "-Layout"
    }
}
