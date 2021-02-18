import UIKit
import Gridicons
import Gutenberg

class FilterableCategoriesViewController: CollapsableHeaderViewController {
    let tableView: UITableView
    internal var selectedItem: IndexPath? = nil {
        didSet {
            if !(oldValue != nil && selectedItem != nil) {
                itemSelectionChanged(selectedItem != nil)
            }
        }
    }
    internal let filterBar: CollapsableHeaderFilterBar
    
    init(
        mainTitle: String,
        prompt: String,
        primaryActionTitle: String,
        secondaryActionTitle: String? = nil,
        defaultActionTitle: String? = nil
    ) {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero
        tableView.showsVerticalScrollIndicator = false
        filterBar = CollapsableHeaderFilterBar()
        super.init(scrollableView: tableView,
                   mainTitle: mainTitle,
                   prompt: prompt,
                   primaryActionTitle: primaryActionTitle,
                   secondaryActionTitle: secondaryActionTitle,
                   defaultActionTitle: defaultActionTitle,
                   accessoryView: filterBar)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
