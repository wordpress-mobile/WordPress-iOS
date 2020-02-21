import Foundation

class BasePageListCell: UITableViewCell {

    /// A block that represents an action triggered by tapping on a button in a cell.
    ///
    /// - Parameters:
    ///     - cell: the cell that contains the button that was tapped.
    ///     - button: the button that was tapped.
    ///     - page: the page represented by the cell that was tapped.
    ///
    typealias ActionBlock = (_ cell: BasePageListCell, _ button: UIButton, _ page: Page) -> Void

    /// The page represented by this cell.
    ///
    var page: Page? = nil

    /// The block that will be executed when the main button inside this cell is tapped.
    ///
    var onAction: ActionBlock? = nil

    /// Configure the cell to represent the specified page.
    ///
    func configure(with page: Page) {
        self.page = page
    }

    @IBAction func onAction(_ sender: UIButton) {
        guard let page = page else {
            return
        }

        onAction?(self, sender, page)
    }
}
