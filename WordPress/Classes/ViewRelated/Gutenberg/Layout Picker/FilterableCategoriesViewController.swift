import UIKit
import Gridicons
import Gutenberg

class FilterableCategoriesViewController: CollapsableHeaderViewController {
    let tableView: UITableView
    
    init(
        mainTitle: String,
        prompt: String,
        primaryActionTitle: String,
        secondaryActionTitle: String? = nil,
        defaultActionTitle: String? = nil,
        accessoryView: UIView? = nil) {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero
        tableView.showsVerticalScrollIndicator = false
        super.init(scrollableView: tableView,
                   mainTitle: mainTitle,
                   prompt: prompt,
                   primaryActionTitle: primaryActionTitle,
                   secondaryActionTitle: secondaryActionTitle,
                   defaultActionTitle: defaultActionTitle,
                   accessoryView: accessoryView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
