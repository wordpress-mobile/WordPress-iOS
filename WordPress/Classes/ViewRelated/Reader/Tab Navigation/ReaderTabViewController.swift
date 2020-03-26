import UIKit

class ReaderTabViewController: UIViewController {

    @objc convenience init(view: ReaderTabView) {
        self.init()
        self.view = view
        self.title = NSLocalizedString("Reader", comment: "The default title of the Reader")
        setupSearchButton()
    }

    func setupSearchButton() {
      navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search,
                                                          target: self,
                                                          action: #selector(didTapSearchButton))
    }
}

// MARK: - Actions
extension ReaderTabViewController {
    /// Search button
    @objc private func didTapSearchButton() {
        // TODO: - Implementation
    }
}
