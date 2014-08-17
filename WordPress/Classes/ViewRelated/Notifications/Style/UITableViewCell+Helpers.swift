import Foundation


extension UITableViewCell
{
    public func layoutHeightWithWidth(width: CGFloat) -> CGFloat {
        // Layout: Setup the cell with the given width
        bounds = CGRect(x: 0, y: 0, width: width, height: self.bounds.height)
        layoutIfNeeded()
        
        // iPad: Limit the width
        let cappedWidth = min(WPTableViewFixedWidth, width)
        let maximumSize = CGSize(width: cappedWidth, height: 0)
        let layoutSize  = contentView.systemLayoutSizeFittingSize(maximumSize)
        
        // Workaround: Layout calculations fail under certain scenarios by 1px, cutting labels
        let PaddingY: CGFloat = 1
        
        return ceil(layoutSize.height) + PaddingY;
    }
    
    public class func reuseIdentifier() -> String {
        let name = NSStringFromClass(self)
        
        if let nameWithoutNamespaces = name.componentsSeparatedByString(".").last {
            return nameWithoutNamespaces
        } else {
            return name
        }
    }
}
