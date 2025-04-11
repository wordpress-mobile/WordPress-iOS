import UIKit
import WordPressUI

final class ReaderDiscoverTabViewController: ReaderDiscoverViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "reader-menu-search"), style: .plain, target: self, action: #selector(buttonSearchTapped))
    }

    @objc private func buttonSearchTapped() {
        let searchVC = ReaderSearchViewController()
        searchVC.isStandaloneAppModeEnabled = true
        searchVC.navigationItem.largeTitleDisplayMode = .always
        navigationController?.pushViewController(searchVC, animated: true)
    }
}
