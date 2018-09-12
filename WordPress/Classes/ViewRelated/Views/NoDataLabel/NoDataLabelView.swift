import Foundation
import UIKit

/// This view shows a formatted view indicating there is nothing to show for the particular scenario.
/// Primarily used for no search results currently.
/// The intent is to also use this for Stats views in the future, where there is no data to display.
///

class NoDataLabelView: UIView {

    // MARK: - Properties

    @IBOutlet weak var noDataLabel: UILabel!

    // MARK: - Init

    class func instanceFromNib() -> NoDataLabelView {
        return Bundle.main.loadNibNamed("NoDataLabelView", owner: self, options: nil)?.first as! NoDataLabelView
    }
}
