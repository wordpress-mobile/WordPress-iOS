import UIKit

class DashboardPageCell: UITableViewCell, Reusable {

    // MARK: Variables

    // MARK: Views

    // MARK: Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: View Lifecycle

    override func prepareForReuse() {

    }
    
    // MARK: Public Functions
    
    func configure(using page: Page) {
        
    }

    // MARK: Helpers

    private func commonInit() {

    }

}
