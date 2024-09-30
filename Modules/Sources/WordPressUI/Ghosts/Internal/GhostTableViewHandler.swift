import Foundation
import UIKit

/// GhostTableViewHandler: Encapsulates all of the methods required to setup a "Ghost UICollectionView".
///
class GhostTableViewHandler: NSObject {

    /// Ghost Settings!
    ///
    let options: GhostOptions

    /// Animation Style
    ///
    let style: GhostStyle

    /// Designated Initializer
    ///
    init(options: GhostOptions, style: GhostStyle) {
        self.options = options
        self.style = style
    }
}

/// GhostTableViewHandler: DataSource Methods
///
extension GhostTableViewHandler: UITableViewDataSource {

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return options.displaysSectionHeader ? " " : nil
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return options.rowsPerSection.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.rowsPerSection[section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: options.reuseIdentifier, for: indexPath)
        (cell as? GhostableView)?.ghostAnimationWillStart()
        cell.startGhostAnimation(style: style)
        return cell
    }
}

/// GhostTableViewHandler: Delegate Methods
///
extension GhostTableViewHandler: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}
